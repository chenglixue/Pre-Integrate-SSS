#pragma once
#include "Assets/Resources/Library/Common.hlsl"
#include "Assets/Resources/Library/BRDF.hlsl"

cbuffer UnityPerMaterial
{
    int _Enable_Albedo;
    int _Enable_Mask;
    int _Enable_Emission;
    int _Enable_Normal;
    int _Enable_Metallic;
    int _Enable_Roughness;
    int _Enable_AO;
    int _Enable_GI;

    float4 _Albedo;
    half4  _AlbedoTint;
    half   _AlbedoPow;
    half   _Mask;
    float3 _Emission;
    
    float3 _Normal;
    half    _NormalIntensity;
    
    float _Metallic;
    float _Roughness;
    float _AO;
    
    half    _Cutoff;
    
    float4 _AlbedoTex_ST;
    float4 _NormalTex_ST;

    // subsurface
    half3 _SubsurfaceTint;
    half  _SubsurfaceSpecularIntensity;
    half  _CurveFactor;
    int   _BlurNormalIntensity;
}

Texture2D<float4> _AlbedoTex;
Texture2D<float>  _MaskTex;
Texture2D<float4> _NormalTex;
Texture2D<float>  _MetallicTex;
Texture2D<float>  _RoughnessTex;
Texture2D<float>  _AOTex;
Texture2D<float4> _EmissionTex;
Texture2D<float3> _PreIntegrateSSSLutTex;
Texture2D<float>  _SSSNDFLutTex;

samplerCUBE _DiffuseIBLTex;
samplerCUBE _SpecularIBLTex;
Texture2D<float3> _SpecularFactorLUTTex;

struct VSInput
{
    float3      posOS        : POSITION;

    float3       normalOS      : NORMAL;
    float4       tangentOS     : TANGENT;

    float2      uv           : TEXCOORD0;
    float2      lightmapUV   : TEXCOORD1;
};

struct PSInput
{
    float2      uv              : TEXCOORD0;
    float2      lightmapUV      : TEXCOORD1;

    float3      posWS           : TEXCOORD2;
    float4      posCS           : SV_POSITION;

    float3      normalWS        : NORMAL;
    float3      tangentWS       : TANGENT;
    float3      bitTangentWS    : TEXCOORD3;
};

struct PSOutput
{
    float4      color           : SV_TARGET;
};



PSInput PBRVS(VSInput i)
{
    PSInput o;
    
    o.posWS = mul(unity_ObjectToWorld, float4(i.posOS, 1.f));
    o.posCS = TransformObjectToHClip(i.posOS);

    const VertexNormalInputs vertexNormalData = GetVertexNormalInputs(i.normalOS, i.tangentOS);
    o.normalWS = vertexNormalData.normalWS;
    o.tangentWS = vertexNormalData.tangentWS;
    o.bitTangentWS = vertexNormalData.bitangentWS;

    o.uv = i.uv;
    o.lightmapUV = i.lightmapUV;

    return o;
}

MyBRDFData SetBRDFData(float2 uv, float3 LightColor, float3 LightDir, inout MyLightData LightData)
{
    half3  albedoValue                     = _AlbedoTex.SampleLevel(Smp_RepeatU_RepeatV_Linear, uv * _AlbedoTex_ST.xy + _AlbedoTex_ST.zw, 0).rgb;
    float3 normalValue                     = UnpackNormalScale(_NormalTex.SampleLevel(Smp_RepeatU_RepeatV_Linear, uv * _NormalTex_ST.xy + _NormalTex_ST.zw, _BlurNormalIntensity), _NormalIntensity);
    half3  emissionValue                   = _EmissionTex.SampleLevel(Smp_RepeatU_RepeatV_Linear, uv, 0).rgb;
    half   metallicValue                   = _MetallicTex.SampleLevel(Smp_RepeatU_RepeatV_Linear, uv, 0).r;
    half   roughnessValue                  = _RoughnessTex.SampleLevel(Smp_RepeatU_RepeatV_Linear, uv, 0).r;
    half   AOValue                         = _AOTex.SampleLevel(Smp_RepeatU_RepeatV_Linear, uv, 0).r;
    half   maskValue                       = _MaskTex.SampleLevel(Smp_ClampU_ClampV_Linear, uv * _AlbedoTex_ST.xy + _AlbedoTex_ST.zw, 0).r;
    if(_Enable_Albedo)    albedoValue      = _Albedo;
    if(_Enable_Normal)    normalValue      = _Normal;
    if(_Enable_Metallic)  metallicValue    = _Metallic;
    if(_Enable_Roughness) roughnessValue   = _Roughness;
    if(_Enable_AO)        AOValue          = _AO;
    if(_Enable_Emission)  emissionValue    = _Emission;
    if(_Enable_Mask)      maskValue        = _Mask;

    float3 FO = lerp(0.04, albedoValue, metallicValue);
    float3 radiance = LightColor;

    MyBRDFData o;
    o.albedo  = albedoValue * _AlbedoTint * _AlbedoPow;
    o.opacity = maskValue;
    o.normal = SafeNormalize(mul(normalValue, LightData.TBN));
    o.emission = emissionValue;
    o.metallic = metallicValue;
    o.roughness = max(0.05f, roughnessValue);
    o.roughness2 = pow2(o.roughness);
    o.AO = AOValue;
    o.F0 = FO;
    o.radiance = radiance;

    float3 lightDir = SafeNormalize(LightDir);
    float3 halfVector = SafeNormalize(LightData.viewDirWS + lightDir);
    o.halfVector = halfVector;
    o.NoL = max(dot(o.normal, lightDir), FLT_EPS);
    o.NoV = max(dot(o.normal, LightData.viewDirWS), FLT_EPS);
    o.NoH = max(dot(o.normal, halfVector), FLT_EPS);
    o.HoV = max(dot(halfVector, LightData.viewDirWS), FLT_EPS);
    o.HoL = max(dot(halfVector, lightDir), FLT_EPS);
    o.HoX = max(dot(halfVector, LightData.tangentWS), FLT_EPS);
    o.HoY = max(dot(halfVector, LightData.bitTangentWS), FLT_EPS);

    LightData.normalWS = o.normal;
    LightData.reflectDirWS = reflect(-LightData.viewDirWS, o.normal);

    return o;
}
MyLightData SetLightData(PSInput i)
{
    MyLightData lightData;
    
    lightData.viewDirWS = SafeNormalize(GetCameraPositionWS() - i.posWS);
    lightData.tangentWS = SafeNormalize(i.tangentWS);
    lightData.bitTangentWS = SafeNormalize(i.bitTangentWS);
    lightData.normalWS = SafeNormalize(i.normalWS);
    lightData.TBN = half3x3(lightData.tangentWS, lightData.bitTangentWS, lightData.normalWS);
    
    return lightData;
}

float3 ShadeDirectLight(MyBRDFData brdfData, MyLightData lightData, Light light, float3 posWS)
{
    float3 result = 0.f;
    #if defined (_SHADINGMODEL_DISNEY)
    float luminance      = Luminance(brdfData.albedo);                                                                          // rgb转换成luminance
    float3 colorTint     = luminance > 0.f ? brdfData.albedo * rcp(luminance) : float3(1, 1, 1);                                // 对baseColor按亮度归一化，从而独立出色调和饱和度，可以认为Ctint是与亮度无关的固有色调
    float3 colorSpecular = lerp(_Specular * 0.08f * lerp(1.f, colorTint, _SpecularTint), brdfData.albedo, brdfData.metallic);   // 高光底色
    float3 colorSheen    = lerp(1.f, colorTint, _SheenTint);                                                                    // 光泽颜色.光泽度用于补偿布料等材质在FresnelPeak处的额外光能，光泽颜色则从白色开始，按照输入的sheenTint插值
    
    // -----------------
    // Diffuse
    // -----------------
    float FNoL = SchlickFresnel(brdfData.NoL);                          // 返回(1-cosθ)^5
    float FNoV = SchlickFresnel(brdfData.NoV);                          // 返回(1-cosθ)^5
    float Fd90 = 0.5f + 2 * pow2(brdfData.HoL) * brdfData.roughness;    // 使用roughness计算diffuse
    float Fd   = lerp(1.f, Fd90, FNoL) * lerp(1.f, Fd90, FNoV);         // 还未乘上baseColor/pi，会在最后进行
    
    // -----------------
    // Subsurface
    // -----------------
    // 基于各向同性bssrdf的Hanrahan-Krueger brdf逼近
    // 1.25用于保留反照率
    float Fss90 = pow2(brdfData.HoL) * brdfData.roughness;              // 垂直于次表面的菲涅尔系数
    float Fss = lerp(1.f, Fss90, FNoL) * lerp(1.f, Fss90, FNoV);
    float ss = 1.25f * (Fss * (rcp(brdfData.NoL + brdfData.NoV) - 0.5f) + 0.5f);     // 还未乘上baseColor/pi，会在最后进行

    
    // -----------------
    // Specular
    // -----------------
    float aspect = sqrt(1.f - _Anisotropic * 0.9f);                                // aspect将anisotropic参数重映射到[0.1,1]空间，确保aspect不为0
    float ax = max(.001f, pow2(brdfData.roughness) / aspect);                      // ax随参数anisotropic的增加而增加
    float ay = max(.001f, pow2(brdfData.roughness) * aspect);                      // ay随着参数anisotropic的增加而减少，ax和ay在anisotropic值为0时相等
    float Ds = GTR2_aniso(brdfData.NoH, dot(brdfData.halfVector, lightData.tangentWS), dot(brdfData.halfVector, lightData.bitTangentWS), ax, ay);       // NDF:主波瓣 各项异性GTR2
    float FH = SchlickFresnel(brdfData.HoL);                                       // pow(1-cosθd,5)
    float3 Fs = lerp(colorSpecular, 1.f, FH);                                      // Fresnel:colorSpecular作为F0，模拟金属的菲涅尔色 
    float Gs;
    Gs  = smithG_GGX_aniso(brdfData.NoL, dot(light.direction, lightData.tangentWS), dot(light.direction, lightData.bitTangentWS), ax, ay);  // 遮蔽的几何项
    Gs *= smithG_GGX_aniso(brdfData.NoV, dot(lightData.viewDirWS, lightData.tangentWS), dot(lightData.viewDirWS, lightData.bitTangentWS), ax, ay);      // 阴影关联的几何项
    
    // -----------------
    // Sheen 作为边缘处漫反射的补偿
    // -----------------
    float3 Fsheen = FH * _Sheen * colorSheen;
    
    // -----------------
    // clearcoat (ior = 1.5 -> F0 = 0.04)
    // -----------------
    // 清漆层没有漫反射，只有镜面反射，使用独立的D,F和G项 
    // GTR1（berry）分布函数获取法线强度，第二个参数a（粗糙度）
    float Dr = D_GTR1(brdfData.NoH, lerp(0.1f, 0.001f, _ClearcoatGloss)); 
    float Fr = lerp(0.04f, 1.f, FH);                                                      // Fresnel最低值至0.04 
    float Gr = G_GGX(brdfData.NoL, 0.25f) * G_GGX(brdfData.NoV, .25);    // 几何项使用各项同性的smithG_GGX计算，a固定给0.25 
    
    result = (rcp(PI) * lerp(Fd, ss, _Subsurface) * brdfData.albedo + Fsheen) * (1 - brdfData.metallic);
    result        += Ds * Fs * Gs;
    result        += 0.25f * _Clearcoat * Dr * Fr * Gr;
    
    float3 directLight = result * light.color * brdfData.NoL;
    directLight *= light.shadowAttenuation * light.distanceAttenuation;
    result      += directLight;
    #elif defined(_SHADINGMODEL_DEFAULTLIT)
        const float NDF     = NDF_GGX(brdfData.roughness2, brdfData.NoH);
        const float G       = Geometry_Smiths_SchlickGGX(brdfData.NoV, brdfData.NoL, brdfData.roughness);
        const float3 F      = Fresnel_UE4(brdfData.HoV, brdfData.F0);
        const float denom   = 4.f * brdfData.NoL * brdfData.NoV + 0.0001f;
        float3 specular     = NDF * G * F * rcp(denom);

        const float3 Ks = F;                            // 计算镜面反射部分，等于入射光线被反射的能量所占的百分比
        float3 Kd       = (1.f - Ks);                   // 折射光部分可以直接由镜面反射部分计算得出
        Kd              *= 1.f - brdfData.metallic;     // 金属没有漫反射
        float3 diffuse  = Kd * brdfData.albedo;

        result += (specular + diffuse) * light.color * brdfData.NoL * light.shadowAttenuation * light.distanceAttenuation;


    #elif defined(_SHADINGMODEL_SUBSURFACE)
        
    #endif
    if(brdfData.NoL > 0.f)
    {
        float curve = saturate(_CurveFactor * length(fwidth(brdfData.normal)) / length(fwidth(posWS)));
        float3 diffuse = _PreIntegrateSSSLutTex.SampleLevel(Smp_ClampU_ClampV_Linear, float2(brdfData.NoL * 0.5f + 0.5f, curve), 0);
        result += diffuse * brdfData.albedo * _SubsurfaceTint;

        float3 halfVectorUnNor = light.direction + (GetCameraPositionWS() - posWS);
        float NoH = dot(lightData.normalWS, halfVectorUnNor);
        float NDF = pow(2.f * _SSSNDFLutTex.SampleLevel(Smp_ClampU_ClampV_Linear, float2(NoH, brdfData.roughness), 0), 10);
        float F = SchlickFresnel(brdfData.HoV, brdfData.F0);
        float G = dot(halfVectorUnNor, halfVectorUnNor);
        float3 specular = max(NDF * F * rcp(G), FLT_EPS);
        result += specular * brdfData.NoL * _SubsurfaceSpecularIntensity;
        
        result *= light.color * light.shadowAttenuation * light.distanceAttenuation;
    }
    
    return result;
}
float3 ShadeGI(MyBRDFData brdfData, MyLightData lightData)
{
    if(_Enable_GI == 0) return 0;
    
    // -----------------
    //GI Diffuse
    // -----------------
    float F0          = lerp(0.04f, brdfData.albedo, brdfData.metallic);
    float3 F_IBL      = FresnelSchlickRoughness(brdfData.NoV, F0, brdfData.roughness);
    float KD_IBL      = (1 - F_IBL) * (1 - brdfData.metallic);
    float3 irradiance = texCUBE(_DiffuseIBLTex, brdfData.normal).rgb;
    float3 GIDiffuse  = KD_IBL * brdfData.albedo * irradiance;

    // -----------------
    //GI Specular
    // -----------------
    float rgh                = brdfData.roughness * (1.7 - 0.7 * brdfData.roughness);
    float lod                = 6.f * rgh;
    float3 GISpecularColor   = texCUBElod(_SpecularIBLTex, float4(lightData.reflectDirWS, lod)).rgb;
    float3 GISpecularFactor  = _SpecularFactorLUTTex.SampleLevel(Smp_RepeatU_RepeatV_Linear, float2(brdfData.NoV, brdfData.roughness), 0).rgb;
    float3 GISpecular        = (GISpecularFactor.r * brdfData.F0 + GISpecularFactor.g) * GISpecularColor;

    return GIDiffuse + GISpecular;
}

PSOutput Unlit(PSInput i)
{
    PSOutput o   = (PSOutput)0;
    
    MyLightData lightData;
    MyBRDFData  brdfData;
    lightData       = SetLightData(i);
    Light mainLight = GetMainLight();
    brdfData        = SetBRDFData(i.uv, mainLight.color, mainLight.direction, lightData);

    o.color.rgb += brdfData.emission;
    return o;
}
PSOutput DisneyPBR(PSInput i)
{
    PSOutput o   = (PSOutput)0;
    float3 color = 0.f;
    
    MyLightData lightData;
    MyBRDFData  brdfData;
    
    lightData       = SetLightData(i);
    Light mainLight = GetMainLight();
    brdfData        = SetBRDFData(i.uv, mainLight.color, mainLight.direction, lightData);
    color           += ShadeDirectLight(brdfData, lightData, mainLight, i.posWS);
    
    float3 GI = ShadeGI(brdfData, lightData);
    float3 emission          = brdfData.emission;
    color += (GI + emission) * brdfData.AO;
    o.color += float4(color, 1.f);
    o.color.a = brdfData.opacity;
    clip(o.color.a - _Cutoff);
    
    return o;
}
PSOutput DefaultLit(PSInput i)
{
    PSOutput o   = (PSOutput)0;
    float3 color = 0.f;
    
    MyLightData lightData;
    MyBRDFData  brdfData;
    lightData       = SetLightData(i);
    Light mainLight = GetMainLight();
    brdfData        = SetBRDFData(i.uv, mainLight.color, mainLight.direction, lightData);
    clip(o.color.a - _Cutoff);

    color += ShadeDirectLight(brdfData, lightData, mainLight, i.posWS);
    float3 GI = ShadeGI(brdfData, lightData);
    color += (GI + brdfData.emission) * brdfData.AO;
    
    o.color.rgb += color;
    o.color.a = brdfData.opacity;

    return o;
}
PSOutput Subsurface(PSInput i)
{
    PSOutput o   = (PSOutput)0;
    float3 color = 0.f;
    
    MyLightData lightData;
    MyBRDFData  brdfData;
    lightData       = SetLightData(i);
    Light mainLight = GetMainLight();
    brdfData        = SetBRDFData(i.uv, mainLight.color, mainLight.direction, lightData);
    clip(o.color.a - _Cutoff);

    color += ShadeDirectLight(brdfData, lightData, mainLight, i.posWS);
    float3 GI = ShadeGI(brdfData, lightData);
    color += (GI + brdfData.emission) * brdfData.AO;
    
    o.color.rgb += color;
    o.color.a = brdfData.opacity;

    return o;
}


void PBRPS(PSInput i, out PSOutput o)
{
    #if defined (_SHADINGMODEL_DEFAULTLIT)
        o = DefaultLit(i);
    #elif defined(_SHADINGMODEL_UNLIT)
        o = Unlit(i);
    #elif defined(_SHADINGMODEL_SUBSURFACE)
        o = Subsurface(i);
    #endif
}