using System;
using UnityEngine.Rendering;

namespace UnityEngine.Experimental.Rendering.HDPipeline
{
    // TODO: Fix RTHandle resizing support

    using RTHandle = RTHandleSystem.RTHandle;

    [Serializable]
    public sealed class AmbientOcclusion : VolumeComponent
    {
        [Tooltip("Degree of darkness added by ambient occlusion.")]
        public ClampedFloatParameter intensity = new ClampedFloatParameter(0f, 0f, 4f);

        [Tooltip("Modifies thickness of occluders. This increases dark areas but also introduces dark halo around objects.")]
        public ClampedFloatParameter thicknessModifier = new ClampedFloatParameter(1f, 1f, 10f);

        [Tooltip("Defines how much of the occlusion should be affected by ambient lighting.")]
        public ClampedFloatParameter directLightingStrength = new ClampedFloatParameter(1f, 0f, 1f);

        // Only used if GTAOMultiBounce is active
        // TODO: Custom editor needed to filter this option out if GTAOMultiBounce is active
        [Tooltip("Custom color to use for the ambient occlusion.")]
        public ColorParameter color = new ColorParameter(Color.black, false, false, true);

        // Hidden parameters
        [HideInInspector] public ClampedFloatParameter noiseFilterTolerance = new ClampedFloatParameter(0f, -8f, 0f);
        [HideInInspector] public ClampedFloatParameter blurTolerance = new ClampedFloatParameter(-4.6f, -8f, 1f);
        [HideInInspector] public ClampedFloatParameter upsampleTolerance = new ClampedFloatParameter(-12f, -12f, -1f);
    }

    public class AmbientOcclusionSystem
    {
        enum MipLevel { Original, L1, L2, L3, L4, L5, L6, Count }

        RenderPipelineResources m_Resources;

        // The arrays below are reused between frames to reduce GC allocation.
        readonly float[] m_SampleThickness =
        {
            Mathf.Sqrt(1f - 0.2f * 0.2f),
            Mathf.Sqrt(1f - 0.4f * 0.4f),
            Mathf.Sqrt(1f - 0.6f * 0.6f),
            Mathf.Sqrt(1f - 0.8f * 0.8f),
            Mathf.Sqrt(1f - 0.2f * 0.2f - 0.2f * 0.2f),
            Mathf.Sqrt(1f - 0.2f * 0.2f - 0.4f * 0.4f),
            Mathf.Sqrt(1f - 0.2f * 0.2f - 0.6f * 0.6f),
            Mathf.Sqrt(1f - 0.2f * 0.2f - 0.8f * 0.8f),
            Mathf.Sqrt(1f - 0.4f * 0.4f - 0.4f * 0.4f),
            Mathf.Sqrt(1f - 0.4f * 0.4f - 0.6f * 0.6f),
            Mathf.Sqrt(1f - 0.4f * 0.4f - 0.8f * 0.8f),
            Mathf.Sqrt(1f - 0.6f * 0.6f - 0.6f * 0.6f)
        };

        readonly float[] m_InvThicknessTable = new float[12];
        readonly float[] m_SampleWeightTable = new float[12];

        readonly int[] m_Widths = new int[7];
        readonly int[] m_Heights = new int[7];

        RTHandle m_AmbientOcclusionTex;

        // All the targets needed are pre-allocated and only released on cleanup for now to avoid
        // having to constantly allo/dealloc on every frame
        RTHandle m_LinearDepthTex;

        RTHandle m_LowDepth1Tex;
        RTHandle m_LowDepth2Tex;
        RTHandle m_LowDepth3Tex;
        RTHandle m_LowDepth4Tex;

        RTHandle m_TiledDepth1Tex;
        RTHandle m_TiledDepth2Tex;
        RTHandle m_TiledDepth3Tex;
        RTHandle m_TiledDepth4Tex;

        RTHandle m_Occlusion1Tex;
        RTHandle m_Occlusion2Tex;
        RTHandle m_Occlusion3Tex;
        RTHandle m_Occlusion4Tex;

        RTHandle m_Combined1Tex;
        RTHandle m_Combined2Tex;
        RTHandle m_Combined3Tex;

        readonly ScaleFunc[] m_ScaleFunctors;

        public AmbientOcclusionSystem(HDRenderPipelineAsset hdAsset)
        {
            m_Resources = hdAsset.renderPipelineResources;

            // Destination target
            if (hdAsset.renderPipelineSettings.supportSSAO)
            {
                // TODO: This gets allocated no matter what even if the user don't want AO... Should be fixed
                m_AmbientOcclusionTex = RTHandles.Alloc(Vector2.one,
                    filterMode: FilterMode.Bilinear,
                    colorFormat: RenderTextureFormat.R8,
                    sRGB: false,
                    enableRandomWrite: true,
                    name: "AmbientOcclusion"
                );
            }

            // Prepare scale functors
            m_ScaleFunctors = new ScaleFunc[(int)MipLevel.Count];
            m_ScaleFunctors[0] = size => size; // 0 is original size (mip0)

            for (int i = 1; i < m_ScaleFunctors.Length; i++)
            {
                int mult = i;
                m_ScaleFunctors[i] = size =>
                {
                    int div = 1 << mult;
                    return new Vector2Int(
                        (size.x + (div - 1)) / div,
                        (size.y + (div - 1)) / div
                    );
                };
            }

            // All of these are pre-allocated to 1x1 and will be automatically scaled properly by
            // the internal RTHandle system
            Alloc(out m_LinearDepthTex, MipLevel.Original, RenderTextureFormat.RHalf, true);

            Alloc(out m_LowDepth1Tex, MipLevel.L1, RenderTextureFormat.RFloat, true);
            Alloc(out m_LowDepth2Tex, MipLevel.L2, RenderTextureFormat.RFloat, true);
            Alloc(out m_LowDepth3Tex, MipLevel.L3, RenderTextureFormat.RFloat, true);
            Alloc(out m_LowDepth4Tex, MipLevel.L4, RenderTextureFormat.RFloat, true);

            AllocArray(out m_TiledDepth1Tex, MipLevel.L3, RenderTextureFormat.RHalf, true);
            AllocArray(out m_TiledDepth2Tex, MipLevel.L4, RenderTextureFormat.RHalf, true);
            AllocArray(out m_TiledDepth3Tex, MipLevel.L5, RenderTextureFormat.RHalf, true);
            AllocArray(out m_TiledDepth4Tex, MipLevel.L6, RenderTextureFormat.RHalf, true);

            Alloc(out m_Occlusion1Tex, MipLevel.L1, RenderTextureFormat.R8, true);
            Alloc(out m_Occlusion2Tex, MipLevel.L2, RenderTextureFormat.R8, true);
            Alloc(out m_Occlusion3Tex, MipLevel.L3, RenderTextureFormat.R8, true);
            Alloc(out m_Occlusion4Tex, MipLevel.L4, RenderTextureFormat.R8, true);

            Alloc(out m_Combined1Tex, MipLevel.L1, RenderTextureFormat.R8, true);
            Alloc(out m_Combined2Tex, MipLevel.L2, RenderTextureFormat.R8, true);
            Alloc(out m_Combined3Tex, MipLevel.L3, RenderTextureFormat.R8, true);
        }

        public void Cleanup()
        {
            RTHandles.Release(m_AmbientOcclusionTex);

            RTHandles.Release(m_LinearDepthTex);
            
            RTHandles.Release(m_LowDepth1Tex);
            RTHandles.Release(m_LowDepth2Tex);
            RTHandles.Release(m_LowDepth3Tex);
            RTHandles.Release(m_LowDepth4Tex);
            
            RTHandles.Release(m_TiledDepth1Tex);
            RTHandles.Release(m_TiledDepth2Tex);
            RTHandles.Release(m_TiledDepth3Tex);
            RTHandles.Release(m_TiledDepth4Tex);
            
            RTHandles.Release(m_Occlusion1Tex);
            RTHandles.Release(m_Occlusion2Tex);
            RTHandles.Release(m_Occlusion3Tex);
            RTHandles.Release(m_Occlusion4Tex);
            
            RTHandles.Release(m_Combined1Tex);
            RTHandles.Release(m_Combined2Tex);
            RTHandles.Release(m_Combined3Tex);
        }

        public void Render(CommandBuffer cmd, HDCamera camera, RTHandle depthMap)
        {
            // Grab current settings
            var settings = VolumeManager.instance.stack.GetComponent<AmbientOcclusion>();

            if (!camera.frameSettings.enableSSAO || settings.intensity <= 0f)
            {
                // No AO applied - neutral is black, see the comment in the shaders
                cmd.SetGlobalTexture(HDShaderIDs._AmbientOcclusionTexture, Texture2D.blackTexture);
                cmd.SetGlobalVector(HDShaderIDs._AmbientOcclusionParam, Vector4.zero);
                return;
            }
            
            using (new ProfilingSample(cmd, "Render SSAO", CustomSamplerId.RenderSSAO.GetSampler()))
            {
                // Base size
                m_Widths[0] = camera.actualWidth;
                m_Heights[0] = camera.actualHeight;

                // L1 -> L6 sizes
                // We need to recalculate these on every frame, we can't rely on RTHandle width/height
                // values as they may have been rescaled and not the actual size we want
                for (int i = 1; i < (int)MipLevel.Count; i++)
                {
                    int div = 1 << i;
                    m_Widths[i]  = (m_Widths[0]  + (div - 1)) / div;
                    m_Heights[i] = (m_Heights[0] + (div - 1)) / div;
                }

                // Grab current viewport scale factor - needed to handle RTHandle auto resizing
                var viewport = camera.doubleBufferedViewportScale;

                // Render logic
                PushDownsampleCommands(cmd, camera, depthMap);

                float tanHalfFovH = CalculateTanHalfFovHeight(camera);
                PushRenderCommands(cmd, viewport, m_TiledDepth1Tex, m_Occlusion1Tex, settings, GetSizeArray(MipLevel.L3), tanHalfFovH);
                PushRenderCommands(cmd, viewport, m_TiledDepth2Tex, m_Occlusion2Tex, settings, GetSizeArray(MipLevel.L4), tanHalfFovH);
                PushRenderCommands(cmd, viewport, m_TiledDepth3Tex, m_Occlusion3Tex, settings, GetSizeArray(MipLevel.L5), tanHalfFovH);
                PushRenderCommands(cmd, viewport, m_TiledDepth4Tex, m_Occlusion4Tex, settings, GetSizeArray(MipLevel.L6), tanHalfFovH);

                PushUpsampleCommands(cmd, viewport, m_LowDepth4Tex, m_Occlusion4Tex, m_LowDepth3Tex,   m_Occlusion3Tex, m_Combined3Tex,        settings, GetSize(MipLevel.L4), GetSize(MipLevel.L3));
                PushUpsampleCommands(cmd, viewport, m_LowDepth3Tex, m_Combined3Tex,  m_LowDepth2Tex,   m_Occlusion2Tex, m_Combined2Tex,        settings, GetSize(MipLevel.L3), GetSize(MipLevel.L2));
                PushUpsampleCommands(cmd, viewport, m_LowDepth2Tex, m_Combined2Tex,  m_LowDepth1Tex,   m_Occlusion1Tex, m_Combined1Tex,        settings, GetSize(MipLevel.L2), GetSize(MipLevel.L1));
                PushUpsampleCommands(cmd, viewport, m_LowDepth1Tex, m_Combined1Tex,  m_LinearDepthTex, null,            m_AmbientOcclusionTex, settings, GetSize(MipLevel.L1), GetSize(MipLevel.Original));

                cmd.SetGlobalTexture(HDShaderIDs._AmbientOcclusionTexture, m_AmbientOcclusionTex);
                cmd.SetGlobalVector(HDShaderIDs._AmbientOcclusionParam, new Vector4(settings.color.value.r, settings.color.value.g, settings.color.value.b, settings.directLightingStrength.value));

                // TODO: All the pushdebug stuff should be centralized somewhere
                (RenderPipelineManager.currentPipeline as HDRenderPipeline).PushFullScreenDebugTexture(camera, cmd, m_AmbientOcclusionTex, FullScreenDebugMode.SSAO);
            }
        }

        void Alloc(out RTHandle rt, MipLevel size, RenderTextureFormat format, bool uav)
        {
            rt = RTHandles.Alloc(
                scaleFunc: m_ScaleFunctors[(int)size],
                dimension: TextureDimension.Tex2D,
                colorFormat: format,
                depthBufferBits: DepthBits.None,
                autoGenerateMips: false,
                enableMSAA: false,
                enableRandomWrite: uav,
                sRGB: false,
                filterMode: FilterMode.Point
            );
        }

        void AllocArray(out RTHandle rt, MipLevel size, RenderTextureFormat format, bool uav)
        {
            rt = RTHandles.Alloc(
                scaleFunc: m_ScaleFunctors[(int)size],
                dimension: TextureDimension.Tex2DArray,
                colorFormat: format,
                depthBufferBits: DepthBits.None,
                slices: 16,
                autoGenerateMips: false,
                enableMSAA: false,
                enableRandomWrite: uav,
                sRGB: false,
                filterMode: FilterMode.Point
            );
        }

        float CalculateTanHalfFovHeight(HDCamera camera)
        {
            return 1f / camera.projMatrix[0, 0];
        }

        Vector2 GetSize(MipLevel mip)
        {
            return new Vector2(m_Widths[(int)mip], m_Heights[(int)mip]);
        }

        Vector3 GetSizeArray(MipLevel mip)
        {
            return new Vector3(m_Widths[(int)mip], m_Heights[(int)mip], 16);
        }

        void PushDownsampleCommands(CommandBuffer cmd, HDCamera camera, RTHandle depthMap)
        {
            // 1st downsampling pass.
            var cs = m_Resources.aoDownsample1;
            int kernel = cs.FindKernel("KMain");

            cmd.SetComputeTextureParam(cs, kernel, HDShaderIDs._LinearZ, m_LinearDepthTex);
            cmd.SetComputeTextureParam(cs, kernel, HDShaderIDs._DS2x, m_LowDepth1Tex);
            cmd.SetComputeTextureParam(cs, kernel, HDShaderIDs._DS4x, m_LowDepth2Tex);
            cmd.SetComputeTextureParam(cs, kernel, HDShaderIDs._DS2xAtlas, m_TiledDepth1Tex);
            cmd.SetComputeTextureParam(cs, kernel, HDShaderIDs._DS4xAtlas, m_TiledDepth2Tex);
            cmd.SetComputeTextureParam(cs, kernel, HDShaderIDs._Depth, depthMap);

            cmd.DispatchCompute(cs, kernel, m_Widths[(int)MipLevel.L4], m_Heights[(int)MipLevel.L4], 1);

            // 2nd downsampling pass.
            cs = m_Resources.aoDownsample2;
            kernel = cs.FindKernel("KMain");

            cmd.SetComputeTextureParam(cs, kernel, HDShaderIDs._DS4x, m_LowDepth2Tex);
            cmd.SetComputeTextureParam(cs, kernel, HDShaderIDs._DS8x, m_LowDepth3Tex);
            cmd.SetComputeTextureParam(cs, kernel, HDShaderIDs._DS16x, m_LowDepth4Tex);
            cmd.SetComputeTextureParam(cs, kernel, HDShaderIDs._DS8xAtlas, m_TiledDepth3Tex);
            cmd.SetComputeTextureParam(cs, kernel, HDShaderIDs._DS16xAtlas, m_TiledDepth4Tex);

            cmd.DispatchCompute(cs, kernel, m_Widths[(int)MipLevel.L6], m_Heights[(int)MipLevel.L6], 1);
        }

        void PushRenderCommands(CommandBuffer cmd, Vector4 viewport, RTHandle source, RTHandle destination, AmbientOcclusion settings, Vector3 sourceSize, float tanHalfFovH)
        {
            // Here we compute multipliers that convert the center depth value into (the reciprocal
            // of) sphere thicknesses at each sample location. This assumes a maximum sample radius
            // of 5 units, but since a sphere has no thickness at its extent, we don't need to
            // sample that far out. Only samples whole integer offsets with distance less than 25
            // are used. This means that there is no sample at (3, 4) because its distance is
            // exactly 25 (and has a thickness of 0.)

            // The shaders are set up to sample a circular region within a 5-pixel radius.
            const float kScreenspaceDiameter = 10f;

            // SphereDiameter = CenterDepth * ThicknessMultiplier. This will compute the thickness
            // of a sphere centered at a specific depth. The ellipsoid scale can stretch a sphere
            // into an ellipsoid, which changes the characteristics of the AO.
            // TanHalfFovH: Radius of sphere in depth units if its center lies at Z = 1
            // ScreenspaceDiameter: Diameter of sample sphere in pixel units
            // ScreenspaceDiameter / BufferWidth: Ratio of the screen width that the sphere actually covers
            float thicknessMultiplier = 2f * tanHalfFovH * kScreenspaceDiameter / sourceSize.x;

            // This will transform a depth value from [0, thickness] to [0, 1].
            float inverseRangeFactor = 1f / thicknessMultiplier;

            // The thicknesses are smaller for all off-center samples of the sphere. Compute
            // thicknesses relative to the center sample.
            for (int i = 0; i < 12; i++)
                m_InvThicknessTable[i] = inverseRangeFactor / m_SampleThickness[i];

            // These are the weights that are multiplied against the samples because not all samples
            // are equally important. The farther the sample is from the center location, the less
            // they matter. We use the thickness of the sphere to determine the weight.  The scalars
            // in front are the number of samples with this weight because we sum the samples
            // together before multiplying by the weight, so as an aggregate all of those samples
            // matter more. After generating this table, the weights are normalized.
            m_SampleWeightTable[ 0] = 4 * m_SampleThickness[ 0];    // Axial
            m_SampleWeightTable[ 1] = 4 * m_SampleThickness[ 1];    // Axial
            m_SampleWeightTable[ 2] = 4 * m_SampleThickness[ 2];    // Axial
            m_SampleWeightTable[ 3] = 4 * m_SampleThickness[ 3];    // Axial
            m_SampleWeightTable[ 4] = 4 * m_SampleThickness[ 4];    // Diagonal
            m_SampleWeightTable[ 5] = 8 * m_SampleThickness[ 5];    // L-shaped
            m_SampleWeightTable[ 6] = 8 * m_SampleThickness[ 6];    // L-shaped
            m_SampleWeightTable[ 7] = 8 * m_SampleThickness[ 7];    // L-shaped
            m_SampleWeightTable[ 8] = 4 * m_SampleThickness[ 8];    // Diagonal
            m_SampleWeightTable[ 9] = 8 * m_SampleThickness[ 9];    // L-shaped
            m_SampleWeightTable[10] = 8 * m_SampleThickness[10];    // L-shaped
            m_SampleWeightTable[11] = 4 * m_SampleThickness[11];    // Diagonal

            // Zero out the unused samples.
            // FIXME: should we support SAMPLE_EXHAUSTIVELY mode?
            m_SampleWeightTable[0] = 0;
            m_SampleWeightTable[2] = 0;
            m_SampleWeightTable[5] = 0;
            m_SampleWeightTable[7] = 0;
            m_SampleWeightTable[9] = 0;

            // Normalize the weights by dividing by the sum of all weights
            float totalWeight = 0f;

            foreach (float w in m_SampleWeightTable)
                totalWeight += w;

            for (int i = 0; i < m_SampleWeightTable.Length; i++)
                m_SampleWeightTable[i] /= totalWeight;

            // Set the arguments for the render kernel.
            var cs = m_Resources.aoRender;
            int kernel = cs.FindKernel("KMainInterleaved");

            cmd.SetComputeFloatParams(cs, HDShaderIDs._InvThicknessTable, m_InvThicknessTable);
            cmd.SetComputeFloatParams(cs, HDShaderIDs._SampleWeightTable, m_SampleWeightTable);
            cmd.SetComputeVectorParam(cs, HDShaderIDs._InvSliceDimension, new Vector2(1f / sourceSize.x * viewport.x, 1f / sourceSize.y * viewport.y));
            cmd.SetComputeVectorParam(cs, HDShaderIDs._AdditionalParams, new Vector2(-1f / settings.thicknessModifier.value, settings.intensity.value));
            cmd.SetComputeTextureParam(cs, kernel, HDShaderIDs._Depth, source);
            cmd.SetComputeTextureParam(cs, kernel, HDShaderIDs._Occlusion, destination);

            // Calculate the thread group count and add a dispatch command with them.
            uint xsize, ysize, zsize;
            cs.GetKernelThreadGroupSizes(kernel, out xsize, out ysize, out zsize);

            cmd.DispatchCompute(
                cs, kernel,
                ((int)sourceSize.x + (int)xsize - 1) / (int)xsize,
                ((int)sourceSize.y + (int)ysize - 1) / (int)ysize,
                ((int)sourceSize.z + (int)zsize - 1) / (int)zsize
            );
        }

        void PushUpsampleCommands(CommandBuffer cmd, Vector4 viewport, RTHandle lowResDepth, RTHandle interleavedAO, RTHandle highResDepth, RTHandle highResAO, RTHandle dest, AmbientOcclusion settings, Vector3 lowResDepthSize, Vector2 highResDepthSize)
        {
            var cs = m_Resources.aoUpsample;
            int kernel = cs.FindKernel(highResAO == null ? "KMainInvert" : "KMainBlendout");

            float stepSize = 1920f / lowResDepthSize.x;
            float bTolerance = 1f - Mathf.Pow(10f, settings.blurTolerance.value) * stepSize;
            bTolerance *= bTolerance;
            float uTolerance = Mathf.Pow(10f, settings.upsampleTolerance.value);
            float noiseFilterWeight = 1f / (Mathf.Pow(10f, settings.noiseFilterTolerance.value) + uTolerance);

            cmd.SetComputeVectorParam(cs, HDShaderIDs._InvLowResolution, new Vector2(1f / lowResDepthSize.x * viewport.x, 1f / lowResDepthSize.y * viewport.y));
            cmd.SetComputeVectorParam(cs, HDShaderIDs._InvHighResolution, new Vector2(1f / highResDepthSize.x * viewport.x, 1f / highResDepthSize.y * viewport.y));
            cmd.SetComputeVectorParam(cs, HDShaderIDs._AdditionalParams, new Vector4(noiseFilterWeight, stepSize, bTolerance, uTolerance));

            cmd.SetComputeTextureParam(cs, kernel, HDShaderIDs._LoResDB, lowResDepth);
            cmd.SetComputeTextureParam(cs, kernel, HDShaderIDs._HiResDB, highResDepth);
            cmd.SetComputeTextureParam(cs, kernel, HDShaderIDs._LoResAO1, interleavedAO);

            if (highResAO != null)
                cmd.SetComputeTextureParam(cs, kernel, HDShaderIDs._HiResAO, highResAO);

            cmd.SetComputeTextureParam(cs, kernel, HDShaderIDs._AoResult, dest);

            int xcount = ((int)highResDepthSize.x + 17) / 16;
            int ycount = ((int)highResDepthSize.y + 17) / 16;
            cmd.DispatchCompute(cs, kernel, xcount, ycount, 1);
        }
    }
}
