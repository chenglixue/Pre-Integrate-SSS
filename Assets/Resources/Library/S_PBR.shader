Shader "Elysia/S_PBR"
{
    Properties
    {
        [Header(Rendering Setting)]
        [Space(10)]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", int) = 2
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc("Blend Source", int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendDst("Blend Destination", int) = 0
        [Enum(UnityEngine.Rendering.BlendOp)]_BlendOp("Blend Operator", int) = 0
        [Enum(Off, 0, On, 1)] _ZWriteEnable("ZWrite Mode", int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTestCompare("ZTest Mode", int) = 4
        [Enum(UnityEngine.Rendering.ColorWriteMask)] _ColorMask("Color Mask", Int) = 15
        [Space(10)]
        [IntRange] _StencilRef("Stencil Ref", Range(0, 255)) = 0
        [IntRange] _StencilReadMask("Stencil Read Mask", Range(0, 255)) = 255
        [IntRange] _StencilWriteMask("Stencil Write Mask", Range(0, 255)) = 255
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilTestCompare("Stencil Test Compare", Int) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPassOp("Stencil Pass Operator", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilFailOp("Stencil Fail Operator", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilDepthFailOp("Stencil Depth Test Fail Operator", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilBackTestCompare("Stencil Back Test Compare", Int) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilBackPassOp("Stencil Back Pass Operator", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilBackFailOp("Stencil Back Fail Operator", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilBackDepthFailOp("Stencil Back Depth Fail Operator", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilFrontTestCompare("Stencil Front Test Compare", Int) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilFrontPassOp("Stencil Front Pass Operator", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilFrontFailOp("Stencil Front Fail Operator", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilFrontDepthFailOp("Stencil Front Depth Fail Operator", Int) = 0
        [KeywordEnum(Unlit, DefaultLit, Subsurface, Hair, Cloth, Clear Coat)] _ShadingModel("Shading Model", Float) = 0
        [Space(10)]
        
        [Toggle] _Enable_Albedo             ("Enable Albedo", Int)           = 0
        [Toggle] _Enable_Normal             ("Enable Normal", Int)           = 0
        [Toggle] _Enable_Metallic           ("Enable Metallic", Int)         = 0
        [Toggle] _Enable_Roughness          ("Enable Roughness", Int)        = 0
        [Toggle] _Enable_AO                 ("Enable AO", Int)               = 0
        [Toggle] _Enable_Emission           ("Enable Emission", Int)         = 0
        [Toggle] _Enable_Mask               ("Enable Mask", Int)             = 0
        [Toggle] _Enable_GI                 ("Enable GI", Int)               = 0
        
        [HDR]_Albedo                        ("Albedo Value", Color)          = (1, 1, 1, 1)
        _AlbedoTint                         ("Albedo Tint", Color)           = (1,1,1,1)
        _AlbedoPow                          ("Albedo Pow", Range(0, 2))     = 1
        _Mask                               ("Mask", Range(0, 1))            = 1
        _Normal                             ("Normal Value", Vector)         = (0.5, 0.5, 1, 1)
        _NormalIntensity                    ("Normal Intensity", Range(0, 1))= 1
        _Metallic                           ("Metallic Value", Range(0, 1))  = 0
        _Roughness                          ("Roughness Value", Range(0, 1)) = 0
        _AO                                 ("AO Value", Range(0, 1))        = 1
        _Emission                           ("Emission Value", Color)        = (0, 0, 0, 0)
        _Cutoff                             ("Cut off", Range(0, 1))         = 0.5
        
        [MainTex] _AlbedoTex                            ("Albedo Tex",    2D)                = "white" {}
        [Normal]  _NormalTex                            ("Normal Tex",    2D)                = "bump"  {}
        [NoScaleOffset]          _MaskTex               ("Mask Tex", 2D)                     = "white" {}
        [NoScaleOffset]          _MetallicTex           ("Metallic Tex",  2D)                = "black" {}
        [NoScaleOffset]          _RoughnessTex          ("Roughness Tex", 2D)                = "white" {}
        [NoScaleOffset]          _AOTex                 ("AO Tex",        2D)                = "white" {}
        [NoScaleOffset]          _EmissionTex           ("Emission Tex",  2D)                = "black" {}
        [NoScaleOffset]          _DiffuseIBLTex         ("Diffuse IBL Tex",  Cube)           = "black" {}
        [NoScaleOffset]          _SpecularIBLTex        ("Specular IBL Tex",  Cube)          = "black" {}
        [NoScaleOffset]          _SpecularFactorLUTTex  ("Specular Factor LUT Tex",  2D)     = "black" {}
        
        [Header(Subsurface)]
        [Space(10)]
        _SubsurfaceTint("Subsurface Tint", Color) = (0.95, 0.841, 0.841, 1)
        _SubsurfaceSpecularIntensity("Subsurface Specular Intensity", Range(0, 10)) = 1
        
        _CurveFactor ("Curve Factor", Range(0, 1)) = 1
        [IntRange]_BlurNormalIntensity("Blur Normal Intensity", Range(0, 7)) = 0
    }
    
    SubShader
    {
        Cull [_CullMode]
        Blend [_BlendSrc] [_BlendDst]
        BlendOp [_BlendOp]
        Stencil
        {
            Ref [_StencilRef]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
            
            Comp [_StencilTestCompare]
            Pass [_StencilPassOp]
            Fail [_StencilFailOp]
            ZFail [_StencilDepthFailOp]
            
            CompBack [_StencilBackTestCompare]
            PassBack [_StencilBackPassOp]
            FailBack [_StencilBackFailOp]
            ZFailBack [_StencilBackDepthFailOp]
            
            CompFront [_StencilFrontTestCompare]
            PassFront [_StencilFrontPassOp]
            FailFront [_StencilFrontFailOp]
            ZFailFront [_StencilFrontDepthFailOp]
        }
        ZWrite [_ZWriteEnable]
        ZTest [_ZTestCompare]
        ColorMask [_ColorMask]

        HLSLINCLUDE
        #pragma target 4.5
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS                    //接受阴影
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE            //产生阴影
        #pragma multi_compile _ _SHADOWS_SOFT                          //软阴影
        ENDHLSL
        
        Pass
        {
            Name "Elysia PBR"
            
            HLSLINCLUDE
            #include_with_pragmas "Assets/Resources/Library/PBR.hlsl"
            ENDHLSL

            HLSLPROGRAM
            #pragma shader_feature _PCF_LOW _PCF_MIDDLE _PCF_HIGH
            #pragma shader_feature _SHADINGMODEL_UNLIT _SHADINGMODEL_DEFAULTLIT _SHADINGMODEL_SUBSURFACE _ShadingModel_Hair _ShadingModel_Cloth _ShadingModel_ClearCoat
            #pragma vertex PBRVS
            #pragma fragment PBRPS
            ENDHLSL
        }

        Pass
        {
            Name "Sample Linear 01 Depth For Light Shaft"
            Tags
            {
                "LightMode" = "SampleLinear01Depth"
            }
            
            HLSLINCLUDE
            #include "Assets/Resources/Library/Common.hlsl"
            ENDHLSL
            
            HLSLPROGRAM
            #pragma vertex VS
            #pragma fragment SampleLinearDepth

            PSInput VS(VSInput i)
            {
                PSInput o;
                
                o.posCS = mul(UNITY_MATRIX_MVP, float4(i.posOS, 1.f));
                o.posWS = mul(UNITY_MATRIX_M, float4(i.posOS, 1.f));
                
                o.uv = i.uv;
                #if defined (UNITY_UV_STARTS_AT_TOP)
                    o.uv.y = 1 - o.uv.y;
                #endif

                return o;
            }

            PSOutput SampleLinearDepth(PSInput i)
            {
                PSOutput o;

                float viewDepth = length(i.posWS - _WorldSpaceCameraPos) / _ProjectionParams.z;
                o.color.r = viewDepth;
                
                return o;
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            // -------------------------------------
            // Universal Pipeline keywords

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            float3 _LightDirection;

            float4 GetShadowPositionHClip(VSInput input)
            {
                float3 positionWS = TransformObjectToWorld(input.posOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

                #if _CASTING_PUNCTUAL_LIGHT_SHADOW
                    float3 lightDirectionWS = normalize(_LightPosition - positionWS);
                #else
                    float3 lightDirectionWS = _LightDirection;
                #endif

                    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif

                return positionCS;
            }
            half Alpha(half albedoAlpha, half4 color, half cutoff)
            {
            #if !defined(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A) && !defined(_GLOSSINESS_FROM_BASE_ALPHA)
                half alpha = albedoAlpha * color.a;
            #else
                half alpha = color.a;
            #endif

            #if defined(_ALPHATEST_ON)
                clip(alpha - cutoff);
            #endif

                return alpha;
            }
            half4 SampleAlbedoAlpha(float2 uv, TEXTURE2D_PARAM(albedoAlphaMap, sampler_albedoAlphaMap))
            {
                return half4(SAMPLE_TEXTURE2D(albedoAlphaMap, sampler_albedoAlphaMap, uv));
            }

            PSInput ShadowPassVertex(VSInput input)
            {
                PSInput output;
                UNITY_SETUP_INSTANCE_ID(input);

                output.uv = TRANSFORM_TEX(input.uv, _AlbedoTex);
                output.posCS = GetShadowPositionHClip(input);
                return output;
            }

            half4 ShadowPassFragment(PSInput input) : SV_TARGET
            {
                Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_AlbedoTex, Smp_ClampU_ClampV_Linear)).a, _AlbedoTint, _Cutoff);
                return 0;
            }
            ENDHLSL
        }
    }
}
