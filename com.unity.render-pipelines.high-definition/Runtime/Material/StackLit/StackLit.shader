Shader "HDRenderPipeline/StackLit"
{
    Properties
    {
        // Versioning of material to help for upgrading
        [HideInInspector] _HdrpVersion("_HdrpVersion", Float) = 2

        // Following set of parameters represent the parameters node inside the MaterialGraph.
        // They are use to fill a SurfaceData. With a MaterialGraph this should not exist.

        // Reminder. Color here are in linear but the UI (color picker) do the conversion sRGB to linear
        // Be careful, do not change the name here to _Color. It will conflict with the "fake" parameters (see end of properties) required for GI.
        _BaseColor("BaseColor", Color) = (1,1,1,1)
        _BaseColorMap("BaseColor Map", 2D) = "white" {}
        _BaseColorUseMap("BaseColor UseMap", Float) = 0
        [HideInInspector] _BaseColorMapShow("BaseColor Map Show", Float) = 0
        _BaseColorMapUV("BaseColor Map UV", Float) = 0.0
        _BaseColorMapUVLocal("BaseColorMap UV Local", Float) = 0.0
        [ToggleUI] _BaseColorMapSamplerSharingOptout("BaseColorMap Sampler Sharing Opt-out", Float) = 0

        [Enum(Disney BaseColor and Metallic, 0, BaseColor as Diffuse and SpecularColor aka f0, 1)] _BaseParametrization("Base Parametrization", Float) = 0

        [HideInInspector] _MetallicMapShow("Metallic Map Show", Float) = 0
        _Metallic("Metallic", Range(0.0, 1.0)) = 0
        _MetallicMap("Metallic Map", 2D) = "black" {}
        _MetallicUseMap("Metallic Use Map", Float) = 0
        _MetallicMapUV("Metallic Map UV", Float) = 0.0
        _MetallicMapUVLocal("Metallic Map UV Local", Float) = 0.0
        _MetallicMapChannel("Metallic Map Channel", Float) = 0.0
        [HideInInspector] _MetallicMapChannelMask("Metallic Map Channel Mask", Vector) = (1, 0, 0, 0)
        _MetallicMapRemap("Metallic Remap", Vector) = (0, 1, 0, 0)
        [HideInInspector] _MetallicMapRange("Metallic Range", Vector) = (0, 1, 0, 0)
        [ToggleUI] _MetallicMapSamplerSharingOptout("MetallicMap Sampler Sharing Opt-out", Float) = 0

        _DielectricIor("DielectricIor IOR", Range(1.0, 2.5)) = 1.5

        _SpecularColor("SpecularColor", Color) = (1,1,1,1)
        _SpecularColorMap("SpecularColor Map", 2D) = "white" {}
        _SpecularColorUseMap("SpecularColor UseMap", Float) = 0
        [HideInInspector] _SpecularColorMapShow("SpecularColor Map Show", Float) = 0
        _SpecularColorMapUV("SpecularColor Map UV", Float) = 0.0
        _SpecularColorMapUVLocal("SpecularColorMap UV Local", Float) = 0.0
        [ToggleUI] _EnergyConservingSpecularColor("_EnergyConservingSpecularColor", Float) = 1.0
        [ToggleUI] _SpecularColorMapSamplerSharingOptout("SpecularColorMap Sampler Sharing Opt-out", Float) = 0

        [HideInInspector] _SmoothnessAMapShow("SmoothnessA Map Show", Float) = 0
        _SmoothnessA("SmoothnessA", Range(0.0, 1.0)) = 0.5
        _SmoothnessAMap("SmoothnessA Map", 2D) = "white" {}
        _SmoothnessAUseMap("SmoothnessA Use Map", Float) = 0
        _SmoothnessAMapUV("SmoothnessA Map UV", Float) = 0.0
        _SmoothnessAMapUVLocal("SmoothnessA Map UV Local", Float) = 0.0
        _SmoothnessAMapChannel("SmoothnessA Map Channel", Float) = 0.0
        [HideInInspector] _SmoothnessAMapChannelMask("SmoothnessA Map Channel Mask", Vector) = (1, 0, 0, 0)
        _SmoothnessAMapRemap("SmoothnessA Remap", Vector)  = (0, 1, 0, 0)
        [ToggleUI] _SmoothnessAMapRemapInverted("Invert SmoothnessA Remap", Float) = 0.0
        [HideInInspector] _SmoothnessAMapRange("SmoothnessA Range", Vector) = (0, 1, 0, 0)
        [ToggleUI] _SmoothnessAMapSamplerSharingOptout("SmoothnessAMap Sampler Sharing Opt-out", Float) = 0

        [Enum(Direct Parameter Control, 0, Hazy Gloss Parametrization of Barla Pacanowski Vangorp, 1)] _DualSpecularLobeParametrization("Dual Specular Lobe Parametrization", Float) = 0

        [ToggleUI] _EnableDualSpecularLobe("Enable Dual Specular Lobe", Float) = 0.0 // UI only
        [HideInInspector] _SmoothnessBMapShow("SmoothnessB Map Show", Float) = 0
        _SmoothnessB("SmoothnessB", Range(0.0, 1.0)) = 0.5
        _SmoothnessBMap("SmoothnessB Map", 2D) = "white" {}
        _SmoothnessBUseMap("SmoothnessB Use Map", Float) = 0
        _SmoothnessBMapUV("SmoothnessB Map UV", Float) = 0.0
        _SmoothnessAMapUVLocal("_SmoothnessB Map UV Local", Float) = 0.0
        _SmoothnessBMapChannel("SmoothnessB Map Channel", Float) = 0.0
        [HideInInspector] _SmoothnessBMapChannelMask("SmoothnessB Map Channel Mask", Vector) = (1, 0, 0, 0)
        _SmoothnessBMapRemap("SmoothnessB Remap", Vector) = (0, 1, 0, 0) // Note: this should always match Range() in _SmoothnessB above
        [ToggleUI] _SmoothnessBMapRemapInverted("Invert SmoothnessB Remap", Float) = 0.0
        [HideInInspector] _SmoothnessBMapRange("SmoothnessB Range", Vector) = (0, 1, 0, 0)
        [ToggleUI] _SmoothnessBMapSamplerSharingOptout("SmoothnessBMap Sampler Sharing Opt-out", Float) = 0

        [HideInInspector] _LobeMixMapShow("LobeMix Map Show", Float) = 0
        _LobeMix("LobeMix", Range(0.0, 1.0)) = 0
        _LobeMixMap("LobeMix Map", 2D) = "white" {}
        _LobeMixUseMap("LobeMix Use Map", Float) = 0
        _LobeMixMapUV("LobeMix Map UV", Float) = 0.0
        _LobeMixMapUVLocal("_LobeMix Map UV Local", Float) = 0.0
        _LobeMixMapChannel("LobeMix Map Channel", Float) = 0.0
        [HideInInspector] _LobeMixMapChannelMask("LobeMix Map Channel Mask", Vector) = (1, 0, 0, 0)
        _LobeMixMapRemap("LobeMix Remap", Vector) = (0, 1, 0, 0)
        [ToggleUI] _LobeMixMapRemapInverted("Invert LobeMix Remap", Float) = 0.0
        [HideInInspector] _LobeMixMapRange("LobeMix Range", Vector) = (0, 1, 0, 0)
        [ToggleUI] _LobeMixMapSamplerSharingOptout("LobeMixMap Sampler Sharing Opt-out", Float) = 0

        [HideInInspector] _HazinessMapShow("Haziness Map Show", Float) = 0
        _Haziness("Haziness", Range(0.0, 1.0)) = 0
        _HazinessMap("Haziness Map", 2D) = "white" {}
        _HazinessUseMap("Haziness Use Map", Float) = 0
        _HazinessMapUV("Haziness Map UV", Float) = 0.0
        _HazinessMapUVLocal("_Haziness Map UV Local", Float) = 0.0
        _HazinessMapChannel("Haziness Map Channel", Float) = 0.0
        [HideInInspector] _HazinessMapChannelMask("Haziness Map Channel Mask", Vector) = (1, 0, 0, 0)
        _HazinessMapRemap("Haziness Remap", Vector) = (0, 1, 0, 0)
        [ToggleUI] _HazinessMapRemapInverted("Invert Haziness Remap", Float) = 0.0
        [HideInInspector] _HazinessMapRange("Haziness Range", Vector) = (0, 1, 0, 0)
        [ToggleUI] _HazinessMapSamplerSharingOptout("HazinessMap Sampler Sharing Opt-out", Float) = 0

        [ToggleUI] _CapHazinessWrtMetallic("Cap Haziness Wrt Metallic", Float) = 0.0
        _HazyGlossMaxDielectricF0UIBuffer("Hazy Gloss Max Dielectric F0 When Using Metallic Parametrization", Range(0.0, 1.0)) = 1.0
        [HideInInspector] _HazyGlossMaxDielectricF0("Hazy Gloss Max Dielectric F0 When Using Metallic Parametrization", Range(0.0, 1.0)) = 1.0

        [HideInInspector] _HazeExtentMapShow("HazeExtent Map Show", Float) = 0
        _HazeExtentMapRangeScale("HazeExtent Range Scale", Float) = 8.0
        _HazeExtent("HazeExtent", Range(0.0, 1.0)) = 0
        _HazeExtentMap("HazeExtent Map", 2D) = "white" {}
        _HazeExtentUseMap("HazeExtent Use Map", Float) = 0
        _HazeExtentMapUV("HazeExtent Map UV", Float) = 0.0
        _HazeExtentMapUVLocal("_HazeExtent Map UV Local", Float) = 0.0
        _HazeExtentMapChannel("HazeExtent Map Channel", Float) = 0.0
        [HideInInspector] _HazeExtentMapChannelMask("HazeExtent Map Channel Mask", Vector) = (1, 0, 0, 0)
        _HazeExtentMapRemap("HazeExtent Remap", Vector) = (0, 1, 0, 0)
        [ToggleUI] _HazeExtentMapRemapInverted("Invert HazeExtent Remap", Float) = 0.0
        [HideInInspector] _HazeExtentMapRange("HazeExtent Range", Vector) = (0, 1, 0, 0)
        [ToggleUI] _HazeExtentMapSamplerSharingOptout("HazeExtentMap Sampler Sharing Opt-out", Float) = 0


        // TODO: CoatIorMap, ...

        [ToggleUI] _EnableAnisotropy("Enable Anisotropy", Float) = 0.0 // UI only

        [HideInInspector] _TangentMapShow("Tangent Map Show", Float) = 0.0
        _TangentMap("Tangent Map", 2D) = "bump" {}
        _TangentUseMap("Tangent UseMap", Float) = 0
        _TangentMapUV("Tangent Map UV", Float) = 0.0
        _TangentMapUVLocal("Tangent Map UV Local", Float) = 0.0
        _TangentMapObjSpace("Tangent Map ObjSpace", Float) = 0.0 // Tangent or object reference frame for normal maps
        [ToggleUI] _TangentMapSamplerSharingOptout("TangentMap Sampler Sharing Opt-out", Float) = 0


        // A note on how to use the same anisotropy map as one used with the Lit shader: 
        //
        // In StackLit, we don't multiply the _Anisotropy property with the map (the base property disappears
        // from the UI once a texture map is assigned), as our UI has a range remapping slider that has limits
        // of -1 to 1. By default, the remap range (that maps the texture [0,1] range to another interval) is
        // set from 0 to 1 with the UI looking like this:
        //
        // -1[.....======]+1
        // [ ] invert remapping
        //
        // so the [0,1] range of the map is mapped to the same.
        // That would be equivalent to Lit with _Anisotropy == 1.0 with a texture map assigned.
        //
        // If anisotropy along the other axis is wanted, eg in Lit with _Anisotropy == -1.0 and
        // again, with a texture map assigned, the interval segment of the UI can be dragged to cover -1 to 0
        // and the invert toggle checked, so that [0,1] is mapped to values from 0 to -1, with the UI looking
        // as such:
        //
        // -1[======.....]+1
        // [x] invert remapping
        //
        // Finally, any dampening of the effect of the map that can be obtained in Lit by multiplication by
        // the _Anisotropy propery set to a value < 1 or > -1 can be obtained here by dragging the extreme end
        // of the segment of the range slider (the end closer to +1 or -1 in the above configurations) closer
        // to the other endpoint standing at the middle (0) of the [-1,1] limits, so that the UI would look
        // like this:
        //
        // -1[.....====..]+1
        // [ ] invert remapping
        //
        // or this:
        //
        // -1[..====.....]+1
        // [x] invert remapping
        //

        [HideInInspector] _AnisotropyAMapShow("AnisotropyA Map Show", Float) = 0 // UI only
        _AnisotropyA("AnisotropyA", Range(-1.0, 1.0)) = 0.0 // Value when no texture map is assigned
        _AnisotropyAMap("AnisotropyA Map", 2D) = "white" {}
        _AnisotropyAUseMap("AnisotropyA Use Map", Float) = 0 // Internally set by the UI, also used when sampler sharing is on
        _AnisotropyAMapUV("AnisotropyA Map UV", Float) = 0.0 // UV set used (when using UVs)
        _AnisotropyAMapUVLocal("AnisotropyA Map UV Local", Float) = 0.0 // World or local (object) mapping when planar (or triplanar) mapping is used
        _AnisotropyAMapChannel("AnisotropyA Map Channel", Float) = 0.0 // UI only, transformed into this shader-used mask property:
        [HideInInspector] _AnisotropyAMapChannelMask("AnisotropyA Map Channel Mask", Vector) = (1, 0, 0, 0)
        _AnisotropyAMapRemap("AnisotropyA Remap", Vector) = (0, 1, 0, 0) // UI only
        [ToggleUI] _AnisotropyAMapRemapInverted("Invert AnisotropyA Remap", Float) = 0.0 // UI only
        // the two previous properties MapRemap and MapRemapInverted are combined in this shader-used range vector:
        [HideInInspector] _AnisotropyAMapRange("AnisotropyA Range", Vector) = (0, 1, 0, 0)
        [ToggleUI] _AnisotropyAMapSamplerSharingOptout("AnisotropyAMap Sampler Sharing Opt-out", Float) = 0

        [HideInInspector] _AnisotropyBMapShow("AnisotropyB Map Show", Float) = 0
        _AnisotropyB("AnisotropyB", Range(-1.0, 1.0)) = 0.0
        _AnisotropyBMap("AnisotropyB Map", 2D) = "white" {}
        _AnisotropyBUseMap("AnisotropyB Use Map", Float) = 0
        _AnisotropyBMapUV("AnisotropyB Map UV", Float) = 0.0
        _AnisotropyBMapUVLocal("AnisotropyB Map UV Local", Float) = 0.0
        _AnisotropyBMapChannel("AnisotropyB Map Channel", Float) = 0.0
        [HideInInspector] _AnisotropyBMapChannelMask("AnisotropyB Map Channel Mask", Vector) = (1, 0, 0, 0)
        _AnisotropyBMapRemap("AnisotropyB Remap", Vector) = (0, 1, 0, 0)
        [ToggleUI] _AnisotropyBMapRemapInverted("Invert AnisotropyB Remap", Float) = 0.0
        [HideInInspector] _AnisotropyBMapRange("AnisotropyB Range", Vector) = (0, 1, 0, 0)
        [ToggleUI] _AnisotropyBMapSamplerSharingOptout("AnisotropyBMap Sampler Sharing Opt-out", Float) = 0

        [ToggleUI] _EnableCoat("Enable Coat", Float) = 0.0 // UI only
        [HideInInspector] _CoatSmoothnessMapShow("CoatSmoothness Show", Float) = 0
        _CoatSmoothness("CoatSmoothness", Range(0.0, 1.0)) = 1.0
        _CoatSmoothnessMap("CoatSmoothness Map", 2D) = "white" {}
        _CoatSmoothnessUseMap("CoatSmoothness Use Map", Float) = 0
        _CoatSmoothnessMapUV("CoatSmoothness Map UV", Float) = 0.0
        _CoatSmoothnessMapUVLocal("CoatSmoothness Map UV Local", Float) = 0.0
        _CoatSmoothnessMapChannel("CoatSmoothness Map Channel", Float) = 0.0
        [HideInInspector] _CoatSmoothnessMapChannelMask("CoatSmoothness Map Channel Mask", Vector) = (1, 0, 0, 0)
        _CoatSmoothnessMapRemap("CoatSmoothness Remap", Vector) = (0, 1, 0, 0)
        [ToggleUI] _CoatSmoothnessMapRemapInverted("Invert CoatSmoothness Remap", Float) = 0.0
        [HideInInspector] _CoatSmoothnessMapRange("CoatSmoothness Range", Vector) = (0, 1, 0, 0)
        [ToggleUI] _CoatSmoothnessMapSamplerSharingOptout("CoatSmoothnessMap Sampler Sharing Opt-out", Float) = 0

        // TODOTODO
        [HideInInspector] _CoatIorMapShow("CoatIor Show", Float) = 0
        _CoatIor("Coat IOR", Range(1.0001, 2.0)) = 1.5
        _CoatIorMap("CoatIor Map", 2D) = "white" {}
        _CoatIorUseMap("CoatIor Use Map", Float) = 0
        _CoatIorMapUV("CoatIor Map UV", Float) = 0.0
        _CoatIorMapUVLocal("CoatIor Map UV Local", Float) = 0.0
        _CoatIorMapChannel("CoatIor Map Channel", Float) = 0.0
        [HideInInspector] _CoatIorMapChannelMask("CoatIor Map Channel Mask", Vector) = (1, 0, 0, 0)
        _CoatIorMapRemap("CoatIor Remap", Vector) = (1.0001, 2.0, 0, 0)
        _CoatIorMapM("CoatIor Remap", Vector) = (1.0001, 2.0, 0, 0)
        [ToggleUI] _CoatIorMapRemapInverted("Invert CoatIor Remap", Float) = 0.0
        [HideInInspector] _CoatIorMapUIRangeLimits("CoatIorMap UIRangeLimits", Vector) = (1.0001, 2.0, 0, 0)
        [HideInInspector] _CoatIorMapRange("CoatIor Range", Vector) = (0, 1, 0, 0)
        [ToggleUI] _CoatIorMapSamplerSharingOptout("CoatIorMap Sampler Sharing Opt-out", Float) = 0

        [HideInInspector] _CoatThicknessMapShow("CoatThickness Show", Float) = 0
        _CoatThickness("Coat Thickness", Range(0.0, 0.99)) = 0.0
        _CoatThicknessMap("CoatThickness Map", 2D) = "white" {}
        _CoatThicknessUseMap("CoatThickness Use Map", Float) = 0
        _CoatThicknessMapUV("CoatThickness Map UV", Float) = 0.0
        _CoatThicknessMapUVLocal("CoatThickness Map UV Local", Float) = 0.0
        _CoatThicknessMapChannel("CoatThickness Map Channel", Float) = 0.0
        [HideInInspector] _CoatThicknessMapChannelMask("CoatThickness Map Channel Mask", Vector) = (1, 0, 0, 0)
        _CoatThicknessMapRemap("CoatThickness Remap", Vector) = (0, 1, 0, 0)
        [ToggleUI] _CoatThicknessMapRemapInverted("Invert CoatThickness Remap", Float) = 0.0
        [HideInInspector] _CoatThicknessMapRange("CoatThickness Range", Vector) = (0, 1, 0, 0)
        [ToggleUI] _CoatThicknessMapSamplerSharingOptout("CoatThicknessMap Sampler Sharing Opt-out", Float) = 0

        [HideInInspector] _CoatExtinctionMapShow("Coat Extinction Coefficient Map Show", Float) = 0.0
        [HDR] _CoatExtinction("Coat Extinction Coefficient", Color) = (1,1,1) // in thickness^-1 units
        _CoatExtinctionMap("Coat Extinction Coefficient Map", 2D) = "white" {}
        _CoatExtinctionUseMap("Coat Extinction Coefficient Use Map", Float) = 0
        _CoatExtinctionMapUV("Coat Extinction Coefficient Map UV", Range(0.0, 1.0)) = 0
        _CoatExtinctionMapUVLocal("Coat Extinction Coefficient Map UV Local", Float) = 0.0
        [ToggleUI] _CoatExtinctionMapSamplerSharingOptout("CoatExtinctionCoefficientMap Sampler Sharing Opt-out", Float) = 0
        // TODO properties, stacklitdata

        [ToggleUI] _EnableCoatNormalMap("Enable Coat Normal Map", Float) = 0.0 // UI only
        [HideInInspector] _CoatNormalMapShow("Coat NormalMap Show", Float) = 0.0
        _CoatNormalMap("Coat NormalMap", 2D) = "bump" {}     // Tangent space normal map
        _CoatNormalUseMap("Coat Normal UseMap", Float) = 0
        _CoatNormalMapUV("Coat NormalMapUV", Float) = 0.0
        _CoatNormalMapUVLocal("Coat NormalMapUV Local", Float) = 0.0
        _CoatNormalMapObjSpace("Coat NormalMap ObjSpace", Float) = 0.0
        _CoatNormalScale("Coat NormalMap Scale", Range(0.0, 2.0)) = 1
        [ToggleUI] _CoatNormalMapSamplerSharingOptout("CoatNormalMap Sampler Sharing Opt-out", Float) = 0

        [HideInInspector] _NormalMapShow("NormalMap Show", Float) = 0.0
        _NormalMap("NormalMap", 2D) = "bump" {}     // Tangent space normal map
        _NormalUseMap("Normal UseMap", Float) = 0
        _NormalMapUV("NormalMapUV", Float) = 0.0
        _NormalMapUVLocal("NormalMapUV Local", Float) = 0.0
        _NormalMapObjSpace("NormalMapObjSpace", Float) = 0.0
        _NormalScale("Normal Scale", Range(0.0, 8.0)) = 1
        [ToggleUI] _NormalMapSamplerSharingOptout("NormalMap Sampler Sharing Opt-out", Float) = 0

        [HideInInspector] _BentNormalMapShow("Bent NormalMap Show", Float) = 0.0
        _BentNormalMap("Bent NormalMap", 2D) = "bump" {}     // Tangent space bent normal map
        _BentNormalUseMap("Bent Normal UseMap", Float) = 0
        //_BentNormalMapUV("Bent NormalMapUV", Float) = 0.0
        //_BentNormalMapUVLocal("Bent NormalMapUV Local", Float) = 0.0
        //_BentNormalMapObjSpace("Bent NormalMap ObjSpace", Float) = 0.0
        //_BentNormalScale("Bent NormalMap Scale", Range(0.0, 2.0)) = 1
        // Bent normal should reuse the mapping and scale of the normal map as their direction 
        // should be intimately tied on the user's (generation/artist pipeline) side

        // This will control SO whether bent normals are there or not (cf Lit where only bent normals have effect with the associated keyword)
        [ToggleUI] _EnableSpecularOcclusion("Enable Specular Occlusion", Float) = 0.0

        [HideInInspector] _AmbientOcclusionMapShow("AmbientOcclusion Map Show", Float) = 0
        _AmbientOcclusion("AmbientOcclusion", Range(0.0, 1.0)) = 1
        _AmbientOcclusionMap("AmbientOcclusion Map", 2D) = "white" {}
        _AmbientOcclusionUseMap("AmbientOcclusion Use Map", Float) = 0
        _AmbientOcclusionMapUV("AmbientOcclusion Map UV", Float) = 0.0
        _AmbientOcclusionMapUVLocal("AmbientOcclusion Map UV Local", Float) = 0.0
        _AmbientOcclusionMapChannel("AmbientOcclusion Map Channel", Float) = 0.0
        [HideInInspector] _AmbientOcclusionMapChannelMask("AmbientOcclusion Map Channel Mask", Vector) = (1, 0, 0, 0)
        _AmbientOcclusionMapRemap("AmbientOcclusion Remap", Vector) = (0, 1, 0, 0)
        [HideInInspector] _AmbientOcclusionMapRange("AmbientOcclusion Range", Vector) = (0, 1, 0, 0)
        // Forcing separate and unique sampler for the texture assigned on (eg) "_AmbientOcclusionMap"
        // (only relevant when sampler sharing is enabled):
        // 0 = disable sampler sharing for this texture
        // 1 = default behavior when this property isn't present (can use a shared sampler)
        [ToggleUI] _AmbientOcclusionMapSamplerSharingOptout("AmbientOcclusionMap Sampler Sharing Opt-out", Float) = 0

        [HideInInspector] _EmissiveColorMapShow("Emissive Color Map Show", Float) = 0.0
        [HDR] _EmissiveColor("EmissiveColor", Color) = (0, 0, 0)
        _EmissiveColorMap("Emissive Color Map", 2D) = "white" {}
        _EmissiveColorUseMap("Emissive Color Use Map", Float) = 0
        _EmissiveColorMapUV("Emissive Color Map UV", Range(0.0, 1.0)) = 0
        _EmissiveColorMapUVLocal("Emissive Color Map UV Local", Float) = 0.0
        [ToggleUI] _AlbedoAffectEmissive("Albedo Affect Emissive", Float) = 0.0
        [ToggleUI] _EmissiveColorMapSamplerSharingOptout("EmissiveColorMap Sampler Sharing Opt-out", Float) = 0
        [ToggleUI] _EmissiveColorMapSamplerSharingNullOptout("EmissiveColorMap Sampler Sharing Allow Null Opt-out", Float) = 1
        // ...tells to allow/honor optout option even on unassigned texture (only valid for shader generation)

        [ToggleUI] _EnableSubsurfaceScattering("Enable Subsurface Scattering", Float) = 0.0
        _DiffusionProfile("Diffusion Profile", Int) = 0
        [HideInInspector] _SubsurfaceMaskMapShow("Subsurface Mask Map Show", Float) = 0
        _SubsurfaceMask("Subsurface Mask", Range(0.0, 1.0)) = 1.0
        _SubsurfaceMaskMap("Subsurface Mask Map", 2D) = "black" {}
        _SubsurfaceMaskUseMap("Subsurface Mask Use Map", Float) = 0
        _SubsurfaceMaskMapUV("Subsurface Mask Map UV", Float) = 0.0
        _SubsurfaceMaskMapUVLocal("Subsurface Mask UV Local", Float) = 0.0
        _SubsurfaceMaskMapChannel("Subsurface Mask Map Channel", Float) = 0.0
        [HideInInspector] _SubsurfaceMaskMapChannelMask("Subsurface Mask Map Channel Mask", Vector) = (1, 0, 0, 0)
        _SubsurfaceMaskMapRemap("Subsurface Mask Remap", Vector) = (0, 1, 0, 0)
        [HideInInspector] _SubsurfaceMaskMapRange("Subsurface Mask Range", Vector) = (0, 1, 0, 0)
        [ToggleUI] _SubsurfaceMaskMapSamplerSharingOptout("SubsurfaceMaskMap Sampler Sharing Opt-out", Float) = 0

        [ToggleUI] _EnableTransmission("Enable Transmission", Float) = 0.0
        [HideInInspector] _ThicknessMapShow("Thickness Show", Float) = 0
        _Thickness("Thickness", Range(0.0, 1.0)) = 1.0
        _ThicknessMap("Thickness Map", 2D) = "black" {}
        _ThicknessUseMap("Thickness Use Map", Float) = 0
        _ThicknessMapUV("Thickness Map UV", Float) = 0.0
        _ThicknessMapUVLocal("Thickness Map UV Local", Float) = 0.0
        _ThicknessMapChannel("Thickness Map Channel", Float) = 0.0
        [HideInInspector] _ThicknessMapChannelMask("Thickness Map Channel Mask", Vector) = (1, 0, 0, 0)
        _ThicknessMapRemap("Thickness Remap", Vector) = (0, 1, 0, 0)
        [ToggleUI] _ThicknessMapRemapInverted("Invert Thickness Remap", Float) = 0.0
        [HideInInspector] _ThicknessMapRange("Thickness Range", Vector) = (0, 1, 0, 0)
        [ToggleUI] _ThicknessMapSamplerSharingOptout("ThicknessMap Sampler Sharing Opt-out", Float) = 0

        [ToggleUI] _EnableIridescence("Enable Iridescence", Float) = 0.0 // UI only
        _IridescenceIor("TopIOR over iridescent layer", Range(1.0, 2.0)) = 1.5
        [HideInInspector] _IridescenceThicknessMapShow("IridescenceThickness Map Show", Float) = 0
        _IridescenceThickness("IridescenceThickness", Range(0.0, 1.0)) = 0.0
        _IridescenceThicknessMap("IridescenceThickness Map", 2D) = "black" {}
        _IridescenceThicknessUseMap("IridescenceThickness Use Map", Float) = 0
        _IridescenceThicknessMapUV("IridescenceThickness Map UV", Float) = 0.0
        _IridescenceThicknessMapLocal("IridescenceThickness Map UV Local", Float) = 0.0
        _IridescenceThicknessMapChannel("IridescenceThickness Map Channel", Float) = 0.0
        [HideInInspector] _IridescenceThicknessMapChannelMask("IridescenceThickness Map Channel Mask", Vector) = (1, 0, 0, 0)
        _IridescenceThicknessMapRemap("IridescenceThickness Remap", Vector) = (0, 1, 0, 0)
        [ToggleUI] _IridescenceThicknessMapRemapInverted("Invert IridescenceThickness Remap", Float) = 0.0
        [HideInInspector] _IridescenceThicknessMapRange("IridescenceThickness Range", Vector) = (0, 1, 0, 0)
        [ToggleUI] _IridescenceThicknessMapSamplerSharingOptout("IridescenceThicknessMap Sampler Sharing Opt-out", Float) = 0

        [HideInInspector] _IridescenceMaskMapShow("Iridescence Mask Map Show", Float) = 0
        _IridescenceMask("Iridescence Mask", Range(0.0, 1.0)) = 1.0
        _IridescenceMaskMap("Iridescence Mask Map", 2D) = "black" {}
        _IridescenceMaskUseMap("Iridescence Mask Use Map", Float) = 0
        _IridescenceMaskMapUV("Iridescence Mask Map UV", Float) = 0.0
        _IridescenceMaskMapUVLocal("Iridescence Mask UV Local", Float) = 0.0
        _IridescenceMaskMapChannel("Iridescence Mask Map Channel", Float) = 0.0
        [HideInInspector] _IridescenceMaskMapChannelMask("Iridescence Mask Map Channel Mask", Vector) = (1, 0, 0, 0)
        _IridescenceMaskMapRemap("Iridescence Mask Remap", Vector) = (0, 1, 0, 0)
        [HideInInspector] _IridescenceMaskMapRange("Iridescence Mask Range", Vector) = (0, 1, 0, 0)
        [ToggleUI] _IridescenceMaskMapSamplerSharingOptout("IridescenceMaskMap Sampler Sharing Opt-out", Float) = 0

        // Detail map (mask, normal, smoothness)
        [ToggleUI] _EnableDetails("Enable Details", Float) = 0.0
        [HideInInspector] _DetailMaskMapShow("DetailMask Map Show", Float) = 0
        _DetailMaskMap("DetailMask Map", 2D) = "white" {}
        _DetailMaskUseMap("DetailMask UseMap", Float) = 0
        _DetailMaskMapUV("DetailMask Map UV", Float) = 0.0
        _DetailMaskMapUVLocal("DetailMask Map UV Local", Float) = 0.0
        _DetailMaskMapChannel("DetailMask Map Channel", Float) = 0.0
        [HideInInspector] _DetailMaskMapChannelMask("DetailSmoothness Map Channel Mask", Vector) = (1, 0, 0, 0)
        [ToggleUI] _DetailMaskMapSamplerSharingOptout("DetailMaskMap Sampler Sharing Opt-out", Float) = 0

        [HideInInspector] _DetailNormalMapShow("DetailNormalMap Show", Float) = 0.0
        _DetailNormalMap("DetailNormalMap", 2D) = "bump" {}     // Tangent space normal map
        _DetailNormalUseMap("DetailNormal Use Map", Float) = 0
        _DetailNormalMapUV("DetailNormalMapUV", Float) = 0.0
        _DetailNormalMapUVLocal("DetailNormalMapUV Local", Float) = 0.0
        _DetailNormalScale("DetailNormal Scale", Range(0.0, 2.0)) = 1
        [ToggleUI] _DetailNormalMapSamplerSharingOptout("DetailNormalMap Sampler Sharing Opt-out", Float) = 0

        [HideInInspector] _DetailSmoothnessMapShow("DetailSmoothness Map Show", Float) = 0
        _DetailSmoothnessMap("DetailSmoothness Map", 2D) = "lineargrey" {} // Neutral is 0.5 for detail map
        _DetailSmoothnessUseMap("DetailSmoothness Use Map", Float) = 0
        _DetailSmoothnessMapUV("DetailSmoothness Map UV", Float) = 0.0
        _DetailSmoothnessMapUVLocal("DetailSmoothness Map UV Local", Float) = 0.0
        _DetailSmoothnessMapChannel("DetailSmoothness Map Channel", Float) = 0.0
        [HideInInspector] _DetailSmoothnessMapChannelMask("DetailSmoothness Map Channel Mask", Vector) = (1, 0, 0, 0)
        _DetailSmoothnessMapRemap("DetailSmoothness Remap", Vector)  = (0, 1, 0, 0) // Leave this to (0, 1) or change StackLitData !
        [ToggleUI] _DetailSmoothnessMapRemapInverted("Invert SmoothnessA Remap", Float) = 0.0
        [HideInInspector] _DetailSmoothnessMapRange("DetailSmoothness Range", Vector) = (0, 1, 0, 0)
        _DetailSmoothnessScale("DetailSmoothness Scale", Range(0.0, 2.0)) = 1
        [ToggleUI] _DetailSmoothnessMapSamplerSharingOptout("DetailSmoothnessMap Sampler Sharing Opt-out", Float) = 0

        // Distortion
        _DistortionVectorMap("DistortionVectorMap", 2D) = "black" {}
        [ToggleUI] _DistortionEnable("Enable Distortion", Float) = 0.0
        [ToggleUI] _DistortionOnly("Distortion Only", Float) = 0.0
        [ToggleUI] _DistortionDepthTest("Distortion Depth Test Enable", Float) = 1.0
        [Enum(Add, 0, Multiply, 1)] _DistortionBlendMode("Distortion Blend Mode", Int) = 0
        [HideInInspector] _DistortionSrcBlend("Distortion Blend Src", Int) = 0
        [HideInInspector] _DistortionDstBlend("Distortion Blend Dst", Int) = 0
        [HideInInspector] _DistortionBlurSrcBlend("Distortion Blur Blend Src", Int) = 0
        [HideInInspector] _DistortionBlurDstBlend("Distortion Blur Blend Dst", Int) = 0
        [HideInInspector] _DistortionBlurBlendMode("Distortion Blur Blend Mode", Int) = 0
        _DistortionScale("Distortion Scale", Float) = 1
        _DistortionVectorScale("Distortion Vector Scale", Float) = 2
        _DistortionVectorBias("Distortion Vector Bias", Float) = -1
        _DistortionBlurScale("Distortion Blur Scale", Float) = 1
        _DistortionBlurRemapMin("DistortionBlurRemapMin", Float) = 0.0
        _DistortionBlurRemapMax("DistortionBlurRemapMax", Float) = 1.0

        // Transparency
        [ToggleUI] _PreRefractionPass("PreRefractionPass", Float) = 0.0

        [ToggleUI]  _AlphaCutoffEnable("Alpha Cutoff Enable", Float) = 0.0
        _AlphaCutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        _TransparentSortPriority("_TransparentSortPriority", Float) = 0

        // Stencil state
        [HideInInspector] _StencilRef("_StencilRef", Int) = 2 // StencilLightingUsage.RegularLighting  (fixed at compile time)
        [HideInInspector] _StencilWriteMask("_StencilWriteMask", Int) = 7 // StencilMask.Lighting  (fixed at compile time)
        [HideInInspector] _StencilRefMV("_StencilRefMV", Int) = 128 // StencilLightingUsage.RegularLighting  (fixed at compile time)
        [HideInInspector] _StencilWriteMaskMV("_StencilWriteMaskMV", Int) = 128 // StencilMask.ObjectsVelocity  (fixed at compile time)
        [HideInInspector] _StencilDepthPrepassRef("_StencilDepthPrepassRef", Int) = 16
        [HideInInspector] _StencilDepthPrepassWriteMask("_StencilDepthPrepassWriteMask", Int) = 16

        // Blending state
        [HideInInspector] _SurfaceType("__surfacetype", Float) = 0.0
        [HideInInspector] _BlendMode("__blendmode", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _CullMode("__cullmode", Float) = 2.0
        [HideInInspector] _CullModeForward("__cullmodeForward", Float) = 2.0 // This mode is dedicated to Forward to correctly handle backface then front face rendering thin transparent
        [HideInInspector] _ZTestDepthEqualForOpaque("_ZTestDepthEqualForOpaque", Int) = 4 // Less equal
        [HideInInspector] _ZTestModeDistortion("_ZTestModeDistortion", Int) = 8

        [ToggleUI] _GeometricNormalFilteringEnabled("GeometricNormalFilteringEnabled", Float) = 0.0
        [ToggleUI] _TextureNormalFilteringEnabled("TextureNormalFilteringEnabled", Float) = 0.0
        _SpecularAntiAliasingScreenSpaceVariance("SpecularAntiAliasingScreenSpaceVariance", Range(0.0, 1.0)) = 0.1
        _SpecularAntiAliasingThreshold("SpecularAntiAliasingThreshold", Range(0.0, 0.25)) = 0.2

        [ToggleUI] _EnableFogOnTransparent("Enable Fog", Float) = 1.0
        [ToggleUI] _EnableBlendModePreserveSpecularLighting("Enable Blend Mode Preserve Specular Lighting", Float) = 1.0

        [ToggleUI] _DoubleSidedEnable("Double sided enable", Float) = 0.0
        [Enum(Flip, 0, Mirror, 1, None, 2)] _DoubleSidedNormalMode("Double sided normal mode", Float) = 1 // This is for the editor only, see BaseLitUI.cs: _DoubleSidedConstants will be set based on the mode.
        [HideInInspector] _DoubleSidedConstants("_DoubleSidedConstants", Vector) = (1, 1, -1, 0)

        // Advanced options / feature toggles
        [ToggleUI] _EnableAnisotropyForAreaLights("Enable Anisotropy For Area Lights", Float) = 0.0 // UI only, toggles a shader_feature
        [ToggleUI] _VlayerRecomputePerLight("Vlayer Recompute Per Light", Float) = 0.0 // UI only, toggles a shader_feature
        [ToggleUI] _VlayerUseRefractedAnglesForBase("Vlayer Use Refracted Angles For Base", Float) = 0.0 // UI only, toggles a shader_feature
        [ToggleUI] _DebugEnable("Debug Enable", Float) = 0.0 // UI only, toggles a shader_feature
        // These are shader branches and/or values considered when _DebugEnable is on:
        _DebugEnvLobeMask("DebugEnvLobeMask", Vector) = (1, 1, 1, 1)
        _DebugLobeMask("DebugLobeMask", Vector) = (1, 1, 1, 1)
        _DebugAniso("DebugAniso", Vector) = (1, 0, 0, 1000.0)
        _DebugSpecularOcclusion("DebugSpecularOcclusion", Vector) = (2, 2, 1, 2)
        // .x = {0 = fromAO, 1 = conecone, 2 = SPTD} .y = bentao algo {0 = uniform, cos, bent cos}, .z = use hemisphere clipping, 
        // .w = {-1.0 => show SO algo used with tint, 
        //        1.0 to 4.0 => used with DEBUGLIGHTINGMODE_INDIRECT_SPECULAR_OCCLUSION
        //        1.0, 2.0, 3.0 show SO for COAT LOBE, BASE LOBEA and BASE LOBEB, 
        //        4.0 show the source screen space occlusion instead of specular occlusion.}

        // Shared samplers
        [ToggleUI] _EnableSamplerSharing("Enable Sampler Sharing", Float) = 1.0
        [ToggleUI] _EnableSamplerSharingAutoGeneration("Enable Sampler Sharing Auto Generation", Float) = 0.0
        [HideInInspector] _SamplerSharingUsage("SamplerSharingUsage", Vector) = (0, 0, 0, 0)
        [HideInInspector] _GeneratedShaderSamplerSharingUsage("GeneratedShaderSamplerSharingUsage", Vector) = (0, 0, 0, 0)
        // If you need more or less shared samplers, modify 
        // #define SHARED_SAMPLER_USED_NUM 5 
        // below in the file "Define" section.
        // 
        // _SharedSamplerUsedNumDefine is for the UI only:
        // This is set to match what SHARED_SAMPLER_USED_NUM is in this file.
        // If 0, it directs the UI to read the value from the shader file (which is another overhead on each UI ticks)
        // Otherwise, the value read from is assumed to match the #define in the file.
        _SharedSamplerUsedNumDefine("SharedSamplerUsedNumDefine", Float) = 0.0
        _SharedSamplerMap0("SharedSamplerMap0", 2D) = "black" {}
        _SharedSamplerMap1("SharedSamplerMap1", 2D) = "black" {}
        _SharedSamplerMap2("SharedSamplerMap2", 2D) = "black" {}
        _SharedSamplerMap3("SharedSamplerMap3", 2D) = "black" {}
        _SharedSamplerMap4("SharedSamplerMap4", 2D) = "black" {}
        
        _SharedSamplerMap5("SharedSamplerMap5", 2D) = "black" {}
        _SharedSamplerMap6("SharedSamplerMap6", 2D) = "black" {}
        _SharedSamplerMap7("SharedSamplerMap7", 2D) = "black" {}
        _SharedSamplerMap8("SharedSamplerMap8", 2D) = "black" {}
        _SharedSamplerMap9("SharedSamplerMap9", 2D) = "black" {}
        _SharedSamplerMap10("SharedSamplerMap10", 2D) = "black" {}
        _SharedSamplerMap11("SharedSamplerMap11", 2D) = "black" {}
        _SharedSamplerMap12("SharedSamplerMap12", 2D) = "black" {}

        // Sections show values.
        [HideInInspector] _BaseUnlitDistortionShow("_BaseUnlitDistortionShow", Float) = 0.0
        [HideInInspector] _MaterialFeaturesShow("_MaterialFeaturesShow", Float) = 1.0
        [HideInInspector] _StandardShow("_StandardShow", Float) = 0.0
        [HideInInspector] _DetailsShow("_DetailsShow", Float) = 0.0
        [HideInInspector] _EmissiveShow("_EmissiveShow", Float) = 0.0
        [HideInInspector] _CoatShow("_CoatShow", Float) = 0.0
        [HideInInspector] _DebugShow("_DebugShow", Float) = 0.0
        [HideInInspector] _SSSShow("_SSSShow", Float) = 0.0
        [HideInInspector] _DualSpecularLobeShow("_DualSpecularLobeShow", Float) = 0.0
        [HideInInspector] _TransmissionShow("_TransmissionShow", Float) = 0.0
        [HideInInspector] _IridescenceShow("_IridescenceShow", Float) = 0.0
        [HideInInspector] _SpecularAntiAliasingShow("_SpecularAntiAliasingShow", Float) = 0.0
        [HideInInspector] _SamplerSharingShow("_SamplerSharingShow", Float) = 0.0

        // Caution: C# code in BaseLitUI.cs call LightmapEmissionFlagsProperty() which assume that there is an existing "_EmissionColor"
        // value that exist to identify if the GI emission need to be enabled.
        // In our case we don't use such a mechanism but need to keep the code quiet. We declare the value and always enable it.
        // TODO: Fix the code in legacy unity so we can customize the beahvior for GI
        _EmissionColor("Color", Color) = (1, 1, 1)

        // HACK: GI Baking system relies on some properties existing in the shader ("_MainTex", "_Cutoff" and "_Color") for opacity handling, so we need to store our version of those parameters in the hard-coded name the GI baking system recognizes.
        _MainTex("Albedo", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)
        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        // This is required by motion vector pass to be able to disable the pass by default
        [HideInInspector] _EnableMotionVectorForVertexAnimation("EnableMotionVectorForVertexAnimation", Float) = 0.0

        [ToggleUI] _SupportDecals("Support Decals", Float) = 1.0
        [ToggleUI] _ReceivesSSR("Receives SSR", Float) = 1.0
    }

    HLSLINCLUDE

    #pragma target 4.5
    #pragma only_renderers d3d11 ps4 xboxone vulkan metal

    //-------------------------------------------------------------------------------------
    // Variant
    //-------------------------------------------------------------------------------------

    #pragma shader_feature _ALPHATEST_ON
    #pragma shader_feature _DOUBLESIDED_ON

    #pragma shader_feature _DETAILMAP
    #pragma shader_feature _BENTNORMALMAP
    #pragma shader_feature _TANGENTMAP
    #pragma shader_feature _ENABLESPECULAROCCLUSION // This will control SO whether bent normals are there or not (cf Lit where only bent normals have effect with this keyword)

    #pragma shader_feature _DISABLE_SAMPLER_SHARING

    #pragma shader_feature _ _REQUIRE_UV2 _REQUIRE_UV3
    #pragma shader_feature _MAPPING_TRIPLANAR // This shader makes use of TRIPLANAR mapping, we reuse the Lit keyword _MAPPING_TRIPLANAR

    #pragma shader_feature _DISABLE_DECALS
    #pragma shader_feature _DISABLE_SSR

    // Keyword for transparent
    #pragma shader_feature _SURFACE_TYPE_TRANSPARENT
    #pragma shader_feature _ _BLENDMODE_ALPHA _BLENDMODE_ADD _BLENDMODE_PRE_MULTIPLY
    #pragma shader_feature _BLENDMODE_PRESERVE_SPECULAR_LIGHTING // handled in material.hlsl
    #pragma shader_feature _ENABLE_FOG_ON_TRANSPARENT

    // MaterialFeature are used as shader feature to allow compiler to optimize properly
    #pragma shader_feature _MATERIAL_FEATURE_DUAL_SPECULAR_LOBE
    #pragma shader_feature _MATERIAL_FEATURE_ANISOTROPY
    #pragma shader_feature _MATERIAL_FEATURE_COAT
    #pragma shader_feature _MATERIAL_FEATURE_COAT_NORMALMAP
    #pragma shader_feature _MATERIAL_FEATURE_IRIDESCENCE
    #pragma shader_feature _MATERIAL_FEATURE_SUBSURFACE_SCATTERING
    #pragma shader_feature _MATERIAL_FEATURE_TRANSMISSION
    #pragma shader_feature _MATERIAL_FEATURE_SPECULAR_COLOR
    #pragma shader_feature _MATERIAL_FEATURE_HAZY_GLOSS

    // Performance vs appearance options
    // Handling of anisotropy for area lights:
    #pragma shader_feature _ANISOTROPY_FOR_AREA_LIGHTS
    // Vertically layered BSDF test/tweak
    #pragma shader_feature _VLAYERED_RECOMPUTE_PERLIGHT
    #pragma shader_feature _VLAYERED_USE_REFRACTED_ANGLES_FOR_BASE

    // Enables all UI driven branch on uniform options:
    #pragma shader_feature _STACKLIT_DEBUG

    // enable dithering LOD crossfade
    #pragma multi_compile _ LOD_FADE_CROSSFADE

    //enable GPU instancing support
    #pragma multi_compile_instancing
    #pragma instancing_options renderinglayer

    //-------------------------------------------------------------------------------------
    // Define
    //-------------------------------------------------------------------------------------

    #define UNITY_MATERIAL_STACKLIT // Need to be define before including Material.hlsl
    #define SHARED_SAMPLER_USED_NUM 5 // Maximum samplers reserved for the sharing system

    // If we use subsurface scattering, enable output split lighting (for forward pass)
    #if defined(_MATERIAL_FEATURE_SUBSURFACE_SCATTERING) && !defined(_SURFACE_TYPE_TRANSPARENT)
    #define OUTPUT_SPLIT_LIGHTING
    #endif

    //-------------------------------------------------------------------------------------
    // Include
    //-------------------------------------------------------------------------------------

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"

    //-------------------------------------------------------------------------------------
    // variable declaration
    //-------------------------------------------------------------------------------------

    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/StackLit/StackLitProperties.hlsl"

    // All our shaders use same name for entry point
    #pragma vertex Vert
    #pragma fragment Frag

    ENDHLSL

    SubShader
    {
        // This tags allow to use the shader replacement features
        Tags{ "RenderPipeline" = "HDRenderPipeline" "RenderType" = "HDStackLitShader" }

        Pass
        {
            Name "SceneSelectionPass" // Name is not used
            Tags { "LightMode" = "SceneSelectionPass" }

            Cull Off

            HLSLPROGRAM

            // Note: Require _ObjectId and _PassValue variables

            // We reuse depth prepass for the scene selection, allow to handle alpha correctly as well as tessellation and vertex animation
            #define SHADERPASS SHADERPASS_DEPTH_ONLY
            #define SCENESELECTIONPASS // This will drive the output of the scene selection shader
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/StackLit/ShaderPass/StackLitDepthPass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/StackLit/StackLitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassDepthOnly.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "Depth prepass"
            Tags{ "LightMode" = "DepthForwardOnly" }

            Cull[_CullMode]

            ZWrite On

            Stencil
            {
                WriteMask[_StencilDepthPrepassWriteMask]
                Ref[_StencilDepthPrepassRef]
                Comp Always
                Pass Replace
            }

            HLSLPROGRAM

            #pragma multi_compile _ WRITE_MSAA_DEPTH

            #define WRITE_NORMAL_BUFFER
            #define SHADERPASS SHADERPASS_DEPTH_ONLY
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            // As we enabled WRITE_NORMAL_BUFFER we need all regular interpolator
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/StackLit/ShaderPass/StackLitSharePass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/StackLit/StackLitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassDepthOnly.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "Motion Vectors"
            Tags{ "LightMode" = "MotionVectors" } // Caution, this need to be call like this to setup the correct parameters by C++ (legacy Unity)

            // If velocity pass (motion vectors) is enabled we tag the stencil so it don't perform CameraMotionVelocity
            Stencil
            {
                WriteMask [_StencilWriteMaskMV]
                Ref [_StencilRefMV]
                Comp Always
                Pass Replace
            }

            Cull[_CullMode]

            ZWrite On

            HLSLPROGRAM
            #define WRITE_NORMAL_BUFFER
            #pragma multi_compile _ WRITE_MSAA_DEPTH
            
            #define SHADERPASS SHADERPASS_VELOCITY
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/StackLit/ShaderPass/StackLitSharePass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/StackLit/StackLitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassVelocity.hlsl"

            ENDHLSL
        }

        // Extracts information for lightmapping, GI (emission, albedo, ...)
        // This pass it not used during regular rendering.
        Pass
        {
            Name "META"
            Tags{ "LightMode" = "Meta" }

            Cull Off

            HLSLPROGRAM

            // Lightmap memo
            // DYNAMICLIGHTMAP_ON is used when we have an "enlighten lightmap" ie a lightmap updated at runtime by enlighten.This lightmap contain indirect lighting from realtime lights and realtime emissive material.Offline baked lighting(from baked material / light,
            // both direct and indirect lighting) will hand up in the "regular" lightmap->LIGHTMAP_ON.

            #define SHADERPASS SHADERPASS_LIGHT_TRANSPORT
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/StackLit/ShaderPass/StackLitSharePass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/StackLit/StackLitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassLightTransport.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }

            Cull[_CullMode]

            ZClip [_ZClip]
            ZWrite On
            ZTest LEqual

            ColorMask 0

            HLSLPROGRAM

            #define SHADERPASS SHADERPASS_SHADOWS
            #define USE_LEGACY_UNITY_MATRIX_VARIABLES
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/StackLit/ShaderPass/StackLitDepthPass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/StackLit/StackLitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassDepthOnly.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "Distortion" // Name is not used
            Tags { "LightMode" = "DistortionVectors" } // This will be only for transparent object based on the RenderQueue index

            Blend [_DistortionSrcBlend] [_DistortionDstBlend], [_DistortionBlurSrcBlend] [_DistortionBlurDstBlend]
            BlendOp Add, [_DistortionBlurBlendOp]
            ZTest [_ZTestModeDistortion]
            ZWrite off
            Cull [_CullMode]

            HLSLPROGRAM

            #define SHADERPASS SHADERPASS_DISTORTION
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/StackLit/ShaderPass/StackLitDistortionPass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/StackLit/StackLitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassDistortion.hlsl"

            ENDHLSL
        }

        // StackLit shader always render in forward
        Pass
        {
            Name "Forward" // Name is not used
            Tags { "LightMode" = "ForwardOnly" }

            Stencil
            {
                WriteMask [_StencilWriteMask]
                Ref [_StencilRef]
                Comp Always
                Pass Replace
            }

            Blend [_SrcBlend] [_DstBlend]
            // In case of forward we want to have depth equal for opaque mesh
            ZTest [_ZTestDepthEqualForOpaque]
            ZWrite [_ZWrite]
            Cull [_CullModeForward]
            //
            // NOTE: For _CullModeForward, see BaseLitUI and the handling of TransparentBackfaceEnable:
            // Basically, we need to use it to support a TransparentBackface pass before this pass
            // (and it should be placed just before this one) for separate backface and frontface rendering,
            // eg for "hair shader style" approximate sorting, see eg Thorsten Scheuermann writeups on this:
            // http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.607.1272&rep=rep1&type=pdf
            // http://amd-dev.wpengine.netdna-cdn.com/wordpress/media/2012/10/Scheuermann_HairSketchSlides.pdf
            // http://web.engr.oregonstate.edu/~mjb/cs519/Projects/Papers/HairRendering.pdf
            //
            // See Lit.shader and the order of the passes after a DistortionVectors, we have:
            // TransparentDepthPrepass, TransparentBackface, Forward, TransparentDepthPostpass

            HLSLPROGRAM

            #pragma multi_compile _ DEBUG_DISPLAY
            //NEWLITTODO

            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            // Setup DECALS_OFF so the shader stripper can remove variants
            #pragma multi_compile DECALS_OFF DECALS_3RT DECALS_4RT
            
            // Supported shadow modes per light type
            #pragma multi_compile PUNCTUAL_SHADOW_LOW PUNCTUAL_SHADOW_MEDIUM PUNCTUAL_SHADOW_HIGH
            #pragma multi_compile DIRECTIONAL_SHADOW_LOW DIRECTIONAL_SHADOW_MEDIUM DIRECTIONAL_SHADOW_HIGH

            // #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/Lighting/Forward.hlsl" : nothing left in there.
            //#pragma multi_compile LIGHTLOOP_SINGLE_PASS LIGHTLOOP_TILE_PASS
            #define LIGHTLOOP_TILE_PASS
            #pragma multi_compile USE_FPTL_LIGHTLIST USE_CLUSTERED_LIGHTLIST

            #define SHADERPASS SHADERPASS_FORWARD
            // In case of opaque we don't want to perform the alpha test, it is done in depth prepass and we use depth equal for ztest (setup from UI)
            #ifndef _SURFACE_TYPE_TRANSPARENT
                #define SHADERPASS_FORWARD_BYPASS_ALPHA_TEST
            #endif
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #ifdef DEBUG_DISPLAY
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
            #endif
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"
            //...this will include #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl" but also LightLoop which the forward pass directly uses.

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/StackLit/ShaderPass/StackLitSharePass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/StackLit/StackLitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassForward.hlsl"

            ENDHLSL
        }

    }

    CustomEditor "Experimental.Rendering.HDPipeline.StackLitGUI"
}
