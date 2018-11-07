using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEditor.Experimental.Rendering.LightweightPipeline;

namespace UnityEditor.Experimental.Rendering.LightweightPipeline.ShaderGUI
{
    internal class ParticlesUnlitShader : BaseShaderGUI
    {
        // Properties
        private BakedLitGUI.BakedLitProperties shadingModelProperties;
        private ParticleGUI.ParticleProperties particleProps;
        
        // List of renderers using this material in the scene, used for validating vertex streams
        List<ParticleSystemRenderer> m_RenderersUsingThisMaterial = new List<ParticleSystemRenderer>();
        
        public override void FindProperties(MaterialProperty[] properties)
        {
            base.FindProperties(properties);
            shadingModelProperties = new BakedLitGUI.BakedLitProperties(properties);
            particleProps = new ParticleGUI.ParticleProperties(properties);
        }
        
        public override void MaterialChanged(Material material)
        {
            if (material == null)
                throw new ArgumentNullException("material");
            
            material.shaderKeywords = null; // Clear all keywords

            SetupMaterialBlendMode(material);
            //SetupMaterialWithBlendMode(material, (BlendMode)material.GetFloat("_Blend"));
            ParticleGUI.SetupMaterialWithColorMode(material);
            ParticleGUI.SetMaterialKeywords(material); // Set particle specific keywords
            BakedLitGUI.SetMaterialKeywords(material); // Set lit specific 
        }
        
        public override void DrawSurfaceOptions(Material material)
        {
            // Detect any changes to the material
            EditorGUI.BeginChangeCheck();
            {
                base.DrawSurfaceOptions(material);
                DoPopup(ParticleGUI.Styles.colorMode, particleProps.colorMode, Enum.GetNames(typeof(ParticleGUI.ColorMode)));
            }
            if (EditorGUI.EndChangeCheck())
            {
                foreach (var obj in blendModeProp.targets)
                    MaterialChanged((Material)obj);
            }
        }
        
        public override void DrawSurfaceInputs(Material material)
        {
            base.DrawSurfaceInputs(material);
            BakedLitGUI.Inputs(shadingModelProperties, materialEditor);
            DrawEmissionProperties(material, true);
        }
        
        public override void DrawAdvancedOptions(Material material)
        {
            EditorGUI.BeginChangeCheck();
            {
                materialEditor.ShaderProperty(particleProps.flipbookMode, ParticleGUI.Styles.flipbookMode);
                ParticleGUI.FadingOptions(material, materialEditor, particleProps);
            }
            base.DrawAdvancedOptions(material);
        }

        public override void DrawAdditionalFoldouts(Material material)
        {
            var vertexStreams = EditorGUILayout.BeginFoldoutHeaderGroup(GetHeaderState(3), ParticleGUI.Styles.VertexStreams, EditorStyles.foldoutHeader, NullThing, ParticleGUI.Styles.vertexStreamIcon);
            if (vertexStreams)
            {
                ParticleGUI.DoVertexStreamsArea(material, m_RenderersUsingThisMaterial);
            }
            EditorGUILayout.EndFoldoutHeaderGroup();
            StoreHeaderState(vertexStreams, 3);
        }

        private static void NullThing(Rect rect){}

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            if (m_FirstTimeApply)
            {
                CacheRenderersUsingThisMaterial(materialEditor.target as Material);
                m_FirstTimeApply = false;
            }
            
            base.OnGUI(materialEditor, props);
        }

        void CacheRenderersUsingThisMaterial(Material material)
        {
            m_RenderersUsingThisMaterial.Clear();

            ParticleSystemRenderer[] renderers = UnityEngine.Object.FindObjectsOfType(typeof(ParticleSystemRenderer)) as ParticleSystemRenderer[];
            foreach (ParticleSystemRenderer renderer in renderers)
            {
                if (renderer.sharedMaterial == material)
                    m_RenderersUsingThisMaterial.Add(renderer);
            }
        }
    }
} // namespace UnityEditor
