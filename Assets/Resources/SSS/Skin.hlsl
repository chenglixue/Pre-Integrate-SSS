#pragma once

cbuffer PS_PROPERTIES_BUFFER
{
    float _CurveFactor;
}

Texture2D<float4> _GBuffer0;
Texture2D<float4> _GBuffer1;
Texture2D<float4> _GBuffer2;
Texture2D<float>  _CameraDepthTexture;

Texture2D<float3> _PreIntegrateSSSLutTex;

float3 GetAlbedo(float2 uv)
{
    return _GBuffer0.SampleLevel(Smp_ClampU_ClampV_Linear, uv, 0).rgb;
}
float GetSmoothness(float2 uv)
{
    return _GBuffer2.SampleLevel(Smp_ClampU_ClampV_Linear, uv, 0).a;
}
float GetRoughness(float smoothness)
{
    float roughness     = clamp(1 - smoothness, 0.02f, 1.f);

    return roughness;
}
float GetAO(float2 uv)
{
    return _GBuffer1.SampleLevel(Smp_ClampU_ClampV_Linear, uv, 0).a;
}
float3 GetNormalWS(float2 uv)
{
    float3 normal = _GBuffer2.SampleLevel(Smp_ClampU_ClampV_Linear, uv, 0).xyz;
    #if defined(_GBUFFER_NORMALS_OCT)
    float2 remappedOctNormalWS = Unpack888ToFloat2(normal);
    float2 octNormalWS = remappedOctNormalWS.xy * 2.0 - 1.0;
    normal = UnpackNormalOctQuadEncode(octNormalWS);
    #else
    normal = SafeNormalize(normal);
    #endif

    return normal;
}

