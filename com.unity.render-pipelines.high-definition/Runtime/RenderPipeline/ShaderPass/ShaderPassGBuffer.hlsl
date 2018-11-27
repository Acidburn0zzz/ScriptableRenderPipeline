#if SHADERPASS != SHADERPASS_GBUFFER
#error SHADERPASS_is_not_correctly_define
#endif

#include "VertMesh.hlsl"

PackedVaryingsType Vert(AttributesMesh inputMesh)
{
    UNITY_SETUP_INSTANCE_ID(inputMesh);
    VaryingsType varyingsType;
    varyingsType.vmesh = VertMesh(inputMesh);
    PackedVaryingsType packedVaryingsType = PackVaryingsType(varyingsType);
    UNITY_TRANSFER_INSTANCE_ID(inputMesh, packedVaryingsType);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(packedVaryingsType);
    return packedVaryingsType;
}

#ifdef TESSELLATION_ON

PackedVaryingsToPS VertTesselation(VaryingsToDS input)
{
    UNITY_SETUP_INSTANCE_ID(inputMesh);
    VaryingsToPS varyingsType;
    varyingsType.vmesh = VertMeshTesselation(input.vmesh);
    PackedVaryingsToPS packedVaryingsType = PackVaryingsToPS(varyingsType);
    UNITY_TRANSFER_INSTANCE_ID(inputMesh, packedVaryingsType);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(packedVaryingsType);
    return packedVaryingsType;
}

#include "TessellationShare.hlsl"

#endif // TESSELLATION_ON

void Frag(  PackedVaryingsToPS packedInput,
            OUTPUT_GBUFFER(outGBuffer)
            #ifdef _DEPTHOFFSET_ON
            , out float outputDepth : SV_Depth
            #endif
            )
{
    UNITY_SETUP_INSTANCE_ID(packedInput);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(packedInput);
    FragInputs input = UnpackVaryingsMeshToFragInputs(packedInput.vmesh);

    // input.positionSS is SV_Position
    PositionInputs posInput = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, input.positionSS.z, input.positionSS.w, input.positionRWS);

#ifdef VARYINGS_NEED_POSITION_WS
    float3 V = GetWorldSpaceNormalizeViewDir(input.positionRWS);
#else
    // Unused
    float3 V = float3(1.0, 1.0, 1.0); // Avoid the division by 0
#endif

    SurfaceData surfaceData;
    BuiltinData builtinData;
    GetSurfaceAndBuiltinData(input, V, posInput, surfaceData, builtinData);

    ENCODE_INTO_GBUFFER(surfaceData, builtinData, posInput.positionSS, outGBuffer);

#ifdef _DEPTHOFFSET_ON
    outputDepth = posInput.deviceDepth;
#endif
}
