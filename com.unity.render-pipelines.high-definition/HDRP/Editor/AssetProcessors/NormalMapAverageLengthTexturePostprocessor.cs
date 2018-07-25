using System;
using UnityEngine;
using System.IO;

namespace UnityEditor.Experimental.Rendering.HDPipeline
{
    public class NormalMapAverageLengthTexturePostprocessor : AssetPostprocessor
    {
        // This class will process a normal map and add the value of average normal length to the blue or alpha channel
        // The texture is saved as BC7.
        // Tangent space normal map: BC7 RGB (normal xy - average normal length)
        // Object space normal map: BC7 RGBA (normal xyz - average normal length)
        static string s_Suffix = "_NA";
        static string s_SuffixOS = "_OSNA"; // Suffix for object space case

        static bool storeVariance = true; // Otherwise, we will store averageNormalLength
        static float highestVarianceAllowed = 0.03125f; // 0.25 * 0.25 / 2 = 0.0625 / 2 = 0.03125;
        static float lowestAverageNormalLengthAllowed = 0.8695f; // 0.03125 = (1-xx)/(4*(3*x-x*x*x)) where x is lowestAverageNormalLengthAllowed

        bool IsAssetTaggedAsTangentSpaceNormalMap()
        {
            return Path.GetFileNameWithoutExtension(assetPath).EndsWith(s_Suffix, StringComparison.InvariantCultureIgnoreCase);
        }

        bool IsAssetTaggedAsObjectSpaceNormalMap()
        {
            return Path.GetFileNameWithoutExtension(assetPath).EndsWith(s_SuffixOS, StringComparison.InvariantCultureIgnoreCase);
        }

        void OnPreprocessTexture()
        {
            bool isNormalMapTangentSpace = IsAssetTaggedAsTangentSpaceNormalMap();
            bool isNormalMapObjectSpace = isNormalMapTangentSpace ? false : IsAssetTaggedAsObjectSpaceNormalMap();

            if (isNormalMapTangentSpace || isNormalMapObjectSpace)
            {
                // Make sure we don't convert as a normal map.
                TextureImporter textureImporter = (TextureImporter)assetImporter;
                textureImporter.convertToNormalmap = false;
                //textureImporter.alphaSource = isNormalMapTangentSpace ? TextureImporterAlphaSource.None : TextureImporterAlphaSource.FromInput;
                //bool inputHasAlphaChannel = textureImporter.DoesSourceTextureHaveAlpha();
                // Hack:
                // We need Unity to create an alpha channel when using object space normal maps!
                // If it doesn't find one in input, and we set TextureImporterAlphaSource.FromInput, it will ignore our alpha values we
                // set with SetPixels in OnPostProcess, even if the Texture2D format is eg RGBA.
                // So here, we force it to create a dummy one in all cases (from gray scale)
                textureImporter.alphaSource = isNormalMapTangentSpace ? TextureImporterAlphaSource.None : TextureImporterAlphaSource.FromGrayScale;
                textureImporter.alphaIsTransparency = false;
                textureImporter.mipmapEnabled = true;
                textureImporter.textureCompression = TextureImporterCompression.CompressedHQ; // This is BC7 for Mac/PC
                //textureImporter.textureCompression = TextureImporterCompression.Uncompressed;
                // We can also force a format like TextureImporterFormat.BC6H or TextureImporterFormat.BC7:
                var settings = textureImporter.GetPlatformTextureSettings("Standalone");
                settings.format = TextureImporterFormat.BC7;
                settings.overridden = true;
                textureImporter.SetPlatformTextureSettings(settings);
                textureImporter.isReadable = true;
                // ...works without, but Unity doc says to set it if we need read access during OnPostProcess:
                // https://docs.unity3d.com/ScriptReference/AssetPostprocessor.OnPostprocessTexture.html
#pragma warning disable 618 // remove obsolete warning for this one
                textureImporter.linearTexture = true; // Says deprecated but won't work without it.
#pragma warning restore 618
                textureImporter.sRGBTexture = false;  // But we're setting the new property just in case it changes later...
            }
        }

        private static Color GetColor(Color[] source, int x, int y, int width, int height)
        {
            x = (x + width) % width; // for NPOT textures
            y = (y + height) % height;

            int index = y * width + x;
            var c = source[index];

            return c;
        }

        private static Vector3 GetNormal(Color[] source, int x, int y, int width, int height)
        {
            Vector3 n = (Vector4)GetColor(source, x, y, width, height);
            n = 2.0f * n - Vector3.one;
            n.Normalize();

            return n;
        }

        private static Vector3 GetAverageNormal(Color[] source, int x, int y, int width, int height, int texelFootprintW, int texelFootprintH)
        {
            Vector3 averageNormal = new Vector3(0, 0, 0);

            // Calculate the average color over the texel footprint.
            for (int i = 0; i < texelFootprintH; ++i)
            {
                for (int j = 0; j < texelFootprintW; ++j)
                {
                    averageNormal += GetNormal(source, x + j, y + i, width, height);
                }
            }

            averageNormal /= (texelFootprintW * texelFootprintH);

            return averageNormal;
        }

        // Converts averageNormalLength to variance and
        // thresholds and remaps variance from [0, highestVarianceAllowed] to [0, 1]
        private static float GetEncodedVariance(float averageNormalLength)
        {
            // To decide to store or not the averageNormalLength directly we need to consider:
            //
            // 1) useful range vs block compression and bit encoding of that range,
            // 2) the possibly nonlinear conversion to variance,
            // 3) computation in the shader.
            //
            // For 2) we need something that can be linearly filtered by the hardware as much as possible.
            // Averages of length(average normal) are obviously not equal to length( of averages of normal)
            // (that's the point of normal map inferred-NDF filtering vs just using mip-mapping hardware on normal maps),
            // and the formula to get to variance via the vMF lobe fit is also quite nonlinear, although not
            // everywhere. We show below that the most useful part of this fit (near the 1.0 end of the length
            // of the average normal) is linear and so if we limit our range to that part, we could just
            // store and filter directly the averageNormalLength.
            // We can also directly store variance, as this is a filterable moment (cf LEAN, LEADR).
            // For 1), compression can further compound artefacts too so we need to consider the useful range.
            //
            // We recall:
            //
            // Ref: Frequency Domain Normal Map Filtering - http://www.cs.columbia.edu/cg/normalmap/normalmap.pdf
            // (equation 21)
            // The relationship between between the standard deviation of a Gaussian distribution and
            // the roughness parameter of a Beckmann distribution.is roughness^2 = 2 variance
            // Ref: Filtering Distributions of Normals for Shading Antialiasing, equation just after (14).
            // Relationship between gaussian lobe and vMF lobe is 2 * variance = 1 / (2 * kappa) = roughness^2
            // (Equation 36 of  Normal map filtering based on The Order : 1886 SIGGRAPH course notes implementation).
            //
            // So to get variance we must use variance = 1 / (4 * kappa)
            // where 
            // kappa = (averageNormalLength*(3.0f - averageNormalLengthSquared)) / (1.0f - averageNormalLengthSquared);
            //
            float averageNormalLengthSquared = averageNormalLength * averageNormalLength;
            float variance = 0.0f;
            if (averageNormalLengthSquared < 1.0f)
            {
                float kappa = (averageNormalLength * (3.0f - averageNormalLengthSquared)) / (1.0f - averageNormalLengthSquared);
                variance = 1.0f / (4.0f * kappa);
            }

            // The variance as a function of (averageNormalLength) is quite steep near 0 length, and 
            // from about averageNormalLength = 0.376, variance stays under 0.2, and
            // from about averageNormalLength = 0.603, variance stays under 0.1, and goes to 0 quite
            // linearly as averageNormalLength goes to 1 with a slope of -1/4
            // http://www.wolframalpha.com/input/?i=y(x)+:%3D+(1+-+x*x)%2F(4*(3x+-+x*x*x));+x+from+0+to+1

            // Remember we do + min(2.0 * variance, threshold * threshold)) to effectively limit the added_roughness^2
            // when doing normal map filtering by modifying underlying BSDF roughness.
            //
            // An added variance of 0.1 gives an increase of roughness = sqrt(2*0.1) = 0.447, which is a huge
            // increase already. For this reason, and since above we see that an averageNormalLength of about 0.6 gives
            // such a 0.1 variance, we could actually just scale and bias the averageNormalLength by
            // encodedAverageNormalLength = (averageNormalLength - 0.6f) / (1.0f - 0.6f);
            //
            // Also remember that we use a user specified threshold to effectively limit the added_roughness^2,
            // as shown above with + min(2.0 * variance, threshold * threshold)).
            // We consider the relationship between the considered range of useful added variance vs that threshold:
            // We have
            // 2*variance_max_allowed = roughness_threshold_max_allowed^2
            // variance_max_allowed = 0.5 * roughness_threshold_max_allowed^2
            //
            // Let's say we think an increased roughness^2 of threshold * threshold = 0.250^2 is enough such
            // that we will never set the threshold in the UI to anything higher than 0.250.
            // We then have:
            //
            // (0.250)^2 = (2 * variance_max_allowed)
            // variance_max_allowed = 0.25*0.25 / 2 = 0.0625/2 = 0.03125
            // 0.03125 = (1-xx)/(4*(3*x-x*x*x)) where x is lowestAverageNormalLengthAllowed
            // http://www.wolframalpha.com/input/?i=0.03125+%3D++(1+-+x*x)%2F(4*(3x+-+x*x*x));+solve+for+x+from+0+to+1
            // which gives our constants:
            //
            // highestVarianceAllowed = 0.03125f
            // lowestAverageNormalLengthAllowed = 0.8695f;
            //
            float encodedVariance = Math.Min(variance, highestVarianceAllowed) / highestVarianceAllowed;
            return encodedVariance;
        }

        // Thresholds and remaps averageNormalLength from [lowestAverageNormalLengthAllowed, 1.0] to [0, 1]
        private static float GetEncodedAverageNormalLength(float averageNormalLength)
        {
            float encodedAverageNormalLength = (averageNormalLength - lowestAverageNormalLengthAllowed) / (1.0f - lowestAverageNormalLengthAllowed);
            encodedAverageNormalLength = Math.Max(0.0f, encodedAverageNormalLength);
            return encodedAverageNormalLength;
        }

        void OnPostprocessTexture(Texture2D texture)
        {
            bool isNormalMapTangentSpace = IsAssetTaggedAsTangentSpaceNormalMap();
            bool isNormalMapObjectSpace = isNormalMapTangentSpace ? false : IsAssetTaggedAsObjectSpaceNormalMap();

            if (isNormalMapTangentSpace || isNormalMapObjectSpace)
            {
                // Based on The Order : 1886 SIGGRAPH course notes implementation. Sample all normal map
                // texels from the base mip level that are within the footprint of the current mipmap texel.
                Color[] source = texture.GetPixels(0);
                for (int m = 1; m < texture.mipmapCount; m++)
                {
                    Color[] c = texture.GetPixels(m);

                    int mipWidth = Math.Max(1, texture.width >> m);
                    int mipHeight = Math.Max(1, texture.height >> m);
                    int texelFootprintW = texture.width / mipWidth;
                    int texelFootprintH = texture.height / mipHeight;
                    for (int y = 0; y < mipHeight; ++y)
                    {
                        for (int x = 0; x < mipWidth; ++x)
                        {
                            Vector3 averageNormal = GetAverageNormal(source, x * texelFootprintW, y * texelFootprintH,
                                    texture.width, texture.height, texelFootprintW, texelFootprintH);

                            int outputPosition = y * mipWidth + x;

                            // Check what's already in that mip level (see comment below)
                            Vector3 existingAverageNormal = (Vector4)c[outputPosition];
                            existingAverageNormal = 2.0f * existingAverageNormal - Vector3.one;
                            // Since we have enabled mipmaps, at this stage (OnPostprocessTexture), the mipmaps
                            // have already been created and contain an average pixel value also, so we could use
                            // that (from the c = texture.GetPixels(miplevel) array directly).
                            // The value will be the average of the (n + 1)/2 range encoded values, which is the
                            // (<n> + 1)/2 range encoded value of the average normal <n>: 
                            // ie: let <> be defined as the average of footprint, we have
                            // < (n + 1)/2 > = 1/2 [<n> + <1>] = (<n> + 1)/2
                            // so we can just decode the average with 2*pixel_value - 1 like we did above with
                            // existingAverageNormal.
                            // TODO: Validate. Also, would be faster. Even us doing manually 2 pass would be faster,
                            // reusing the previous level results doing the first pass where we calculate all averages,
                            // than the second pass which calculates the average's length, normalizes and store
                            // the final x,y,variance value.
                            //
                            // Whatever we decide to use (our own computation or what is already in the miplevel
                            // pixel), we need to normalize the result and store the x,y components in the proper
                            // (n + 1)/2 range encoded values in the R,G channels since only normalized normals
                            // are two channel encoded.

                            // Clamp to avoid any issue (shouldn't be required but sanitizes the normal map if needed)
                            // We will also write the custom data into the blue channel to streamline the unpacking
                            // shader code to fetch a 2 channel normal in RG whether we use normal map filtering or not.
                            float averageNormalLength = Math.Max(0.0f, Math.Min(1.0f, averageNormal.magnitude));
                            float encodedVariance = GetEncodedVariance(averageNormalLength);
                            float outputValue = storeVariance ? encodedVariance : GetEncodedAverageNormalLength(averageNormalLength);

                            // Finally, note that since we need to add custom data in a map channel, we can't use the Unity
                            // importer UI settings TextureType == NormalMap, since it leaves channel control to Unity in
                            // that case and will make it interpret the x,y,z input as the normal to compress (which it might
                            // do eg in 2 channels BC5)
                            //
                            // We need to normalize the resulting average normal and store the x,y components in the
                            // proper (n + 1)/2 range encoded values in the R,G channels:
                            averageNormal.Normalize();
                            c[outputPosition].r = (averageNormal.x + 1.0f) / 2.0f;
                            c[outputPosition].g = (averageNormal.y + 1.0f) / 2.0f;
                            if (isNormalMapTangentSpace)
                            {
                                c[outputPosition].b = outputValue;
                                c[outputPosition].a = 1.0f;
                            }
                            else
                            {
                                // Object space normal map needs 3 channels
                                c[outputPosition].b = (averageNormal.z + 1.0f) / 2.0f;
                                c[outputPosition].a = outputValue;
                            }
                        }
                    }

                    texture.SetPixels(c, m);
                }

                // Now overwrite the first mip average normal channel - order is important as above we read the mip0
                // For mip 0, set the normal length to 1.
                {
                    Color[] c = texture.GetPixels(0);
                    float outputValue = storeVariance ? GetEncodedVariance(1.0f) : GetEncodedAverageNormalLength(1.0f);
                    for (int i = 0; i < c.Length; i++)
                    {
                        if (isNormalMapTangentSpace)
                        {
                            c[i].b = outputValue;
                            c[i].a = 1.0f;
                        }
                        else
                        {
                            c[i].a = outputValue;
                        }
                    }
                    texture.SetPixels(c, 0);
                }
                //texture.mipMapBias = -1.0f;
                texture.Apply(updateMipmaps: false, makeNoLongerReadable: true);
            }
        }
    }
}
