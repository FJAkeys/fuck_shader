Shader "Keys/littoon"
{
    Properties
    {
        [HDR]Toon_Shaded_Color("Toon Shaded Color", Color) = (0.5019608, 0.3019608, 0.05882353, 1)
        [HDR]Toon_Lit_Color("Toon Lit Color", Color) = (0.9245283, 0.6391348, 0.2921858, 1)
        Toon_Color_Steps("Toon Color Steps", Range(1, 10)) = 9
        Toon_Color_Offset("Toon Color Offset", Range(-1, 1)) = 0.3
        Toon_Color_Spread("Toon Color Spread", Range(0, 1)) = 0.96
        Toon_Specular_Color("Toon Specular Color", Color) = (0.9528302, 0.9528302, 0.9528302, 0)
        Toon_Highlight_Intensity("Toon Highlight Intensity", Range(0, 0.25)) = 0.05
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "UniversalMaterialType" = "Lit"
            "Queue"="AlphaTest"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On


        HLSLPROGRAM

            // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag



            // Keywords
        #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _SPECULAR_SETUP
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_FORWARD
  

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh;
            #endif
            float4 fogFactorAndVertexLight;
            float4 shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpaceNormal;
            float3 TangentSpaceNormal;
            float3 WorldSpaceViewDirection;
            float3 AbsoluteWorldSpacePosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if defined(LIGHTMAP_ON)
            float2 interp4 : TEXCOORD4;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 interp5 : TEXCOORD5;
            #endif
            float4 interp6 : TEXCOORD6;
            float4 interp7 : TEXCOORD7;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy =  input.lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp5.xyz =  input.sh;
            #endif
            output.interp6.xyzw =  input.fogFactorAndVertexLight;
            output.interp7.xyzw =  input.shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.lightmapUV = input.interp4.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp5.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp6.xyzw;
            output.shadowCoord = input.interp7.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Toon_Shaded_Color;
        float4 Toon_Lit_Color;
        float Toon_Color_Steps;
        float Toon_Color_Offset;
        float Toon_Color_Spread;
        float4 Toon_Specular_Color;
        float Toon_Highlight_Intensity;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        // 74d2f54f0da2d6f91cdd2cd16c508b1e
        #include "Assets/URP_testbed/toontest/Custom Functions/MainLight.hlsl"

        struct Bindings_MainLight_ab9b6feadc505a54a9d799b7581b16e2
        {
            float3 AbsoluteWorldSpacePosition;
        };

        void SG_MainLight_ab9b6feadc505a54a9d799b7581b16e2(Bindings_MainLight_ab9b6feadc505a54a9d799b7581b16e2 IN, out half3 Direction_1, out half3 Color_2, out half DistanceAtten_3, out half ShadowAtten_4)
        {
            half3 _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_Direction_0;
            half3 _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_Color_1;
            half _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_DistanceAtten_3;
            half _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_ShaddowAtten_4;
            MainLight_half(IN.AbsoluteWorldSpacePosition, _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_Direction_0, _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_Color_1, _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_DistanceAtten_3, _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_ShaddowAtten_4);
            Direction_1 = _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_Direction_0;
            Color_2 = _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_Color_1;
            DistanceAtten_3 = _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_DistanceAtten_3;
            ShadowAtten_4 = _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_ShaddowAtten_4;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Posterize_float(float In, float Steps, out float Out)
        {
            Out = floor(In / (1 / Steps)) * (1 / Steps);
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Step_float(float Edge, float In, out float Out)
        {
            Out = step(Edge, In);
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float3 Specular;
            float Smoothness;
            float Occlusion;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_db3214fdfe4b4bce90985873eb534132_Out_0 = Toon_Shaded_Color;
            float4 _Property_eec6d81ed1e74bd5b2541481233fe313_Out_0 = Toon_Lit_Color;
            float _Property_2966c009297c4d3a868fb7fa62e11db9_Out_0 = Toon_Color_Offset;
            float _Property_7bbf90eb0e3b4686986a400bf55dd3a8_Out_0 = Toon_Color_Spread;
            float _Subtract_416c7f62ddf24fe5ba7fcb1fe061d237_Out_2;
            Unity_Subtract_float(_Property_2966c009297c4d3a868fb7fa62e11db9_Out_0, _Property_7bbf90eb0e3b4686986a400bf55dd3a8_Out_0, _Subtract_416c7f62ddf24fe5ba7fcb1fe061d237_Out_2);
            float _Add_1a8c8c870c17483dbc94972f23d8585b_Out_2;
            Unity_Add_float(_Property_2966c009297c4d3a868fb7fa62e11db9_Out_0, _Property_7bbf90eb0e3b4686986a400bf55dd3a8_Out_0, _Add_1a8c8c870c17483dbc94972f23d8585b_Out_2);
            Bindings_MainLight_ab9b6feadc505a54a9d799b7581b16e2 _MainLight_e35a2e59e0814bcf8d786edfac477a49;
            _MainLight_e35a2e59e0814bcf8d786edfac477a49.AbsoluteWorldSpacePosition = IN.AbsoluteWorldSpacePosition;
            half3 _MainLight_e35a2e59e0814bcf8d786edfac477a49_Direction_1;
            half3 _MainLight_e35a2e59e0814bcf8d786edfac477a49_Color_2;
            half _MainLight_e35a2e59e0814bcf8d786edfac477a49_DistanceAtten_3;
            half _MainLight_e35a2e59e0814bcf8d786edfac477a49_ShadowAtten_4;
            SG_MainLight_ab9b6feadc505a54a9d799b7581b16e2(_MainLight_e35a2e59e0814bcf8d786edfac477a49, _MainLight_e35a2e59e0814bcf8d786edfac477a49_Direction_1, _MainLight_e35a2e59e0814bcf8d786edfac477a49_Color_2, _MainLight_e35a2e59e0814bcf8d786edfac477a49_DistanceAtten_3, _MainLight_e35a2e59e0814bcf8d786edfac477a49_ShadowAtten_4);
            float _DotProduct_5b3f6c2a8d0d4bd48edadbdca99f697c_Out_2;
            Unity_DotProduct_float3(IN.WorldSpaceNormal, _MainLight_e35a2e59e0814bcf8d786edfac477a49_Direction_1, _DotProduct_5b3f6c2a8d0d4bd48edadbdca99f697c_Out_2);
            float _Saturate_d79689cba0bd48568abd6ab88c50d601_Out_1;
            Unity_Saturate_float(_DotProduct_5b3f6c2a8d0d4bd48edadbdca99f697c_Out_2, _Saturate_d79689cba0bd48568abd6ab88c50d601_Out_1);
            float _Multiply_dd07fecb3c494709a74e4c74a6c924d0_Out_2;
            Unity_Multiply_float(_Saturate_d79689cba0bd48568abd6ab88c50d601_Out_1, _MainLight_e35a2e59e0814bcf8d786edfac477a49_ShadowAtten_4, _Multiply_dd07fecb3c494709a74e4c74a6c924d0_Out_2);
            float _Smoothstep_0c9179213c87407aa7f92ecbb955b1d0_Out_3;
            Unity_Smoothstep_float(_Subtract_416c7f62ddf24fe5ba7fcb1fe061d237_Out_2, _Add_1a8c8c870c17483dbc94972f23d8585b_Out_2, _Multiply_dd07fecb3c494709a74e4c74a6c924d0_Out_2, _Smoothstep_0c9179213c87407aa7f92ecbb955b1d0_Out_3);
            float _Property_02ab2602ca53467aa93aab2e9b134d42_Out_0 = Toon_Color_Steps;
            float _Subtract_483bc27c9c804d85baf387d006b33f15_Out_2;
            Unity_Subtract_float(_Property_02ab2602ca53467aa93aab2e9b134d42_Out_0, 1, _Subtract_483bc27c9c804d85baf387d006b33f15_Out_2);
            float _Posterize_13251350164f4aaf86213bfe607f9018_Out_2;
            Unity_Posterize_float(_Smoothstep_0c9179213c87407aa7f92ecbb955b1d0_Out_3, _Subtract_483bc27c9c804d85baf387d006b33f15_Out_2, _Posterize_13251350164f4aaf86213bfe607f9018_Out_2);
            float4 _Lerp_9cba8439fec243989a471b60ab11f8a5_Out_3;
            Unity_Lerp_float4(_Property_db3214fdfe4b4bce90985873eb534132_Out_0, _Property_eec6d81ed1e74bd5b2541481233fe313_Out_0, (_Posterize_13251350164f4aaf86213bfe607f9018_Out_2.xxxx), _Lerp_9cba8439fec243989a471b60ab11f8a5_Out_3);
            float4 _Property_ea1afdfb5090417d9da45f0935033007_Out_0 = Toon_Specular_Color;
            float _Property_03d7c8b4d94341c0a27c54cd27dd6d55_Out_0 = Toon_Highlight_Intensity;
            float _OneMinus_2a4484cb358e4660b9897e0072879fdf_Out_1;
            Unity_OneMinus_float(_Property_03d7c8b4d94341c0a27c54cd27dd6d55_Out_0, _OneMinus_2a4484cb358e4660b9897e0072879fdf_Out_1);
            Bindings_MainLight_ab9b6feadc505a54a9d799b7581b16e2 _MainLight_53c9a92d53954cb9a0cce313143e42b1;
            _MainLight_53c9a92d53954cb9a0cce313143e42b1.AbsoluteWorldSpacePosition = IN.AbsoluteWorldSpacePosition;
            half3 _MainLight_53c9a92d53954cb9a0cce313143e42b1_Direction_1;
            half3 _MainLight_53c9a92d53954cb9a0cce313143e42b1_Color_2;
            half _MainLight_53c9a92d53954cb9a0cce313143e42b1_DistanceAtten_3;
            half _MainLight_53c9a92d53954cb9a0cce313143e42b1_ShadowAtten_4;
            SG_MainLight_ab9b6feadc505a54a9d799b7581b16e2(_MainLight_53c9a92d53954cb9a0cce313143e42b1, _MainLight_53c9a92d53954cb9a0cce313143e42b1_Direction_1, _MainLight_53c9a92d53954cb9a0cce313143e42b1_Color_2, _MainLight_53c9a92d53954cb9a0cce313143e42b1_DistanceAtten_3, _MainLight_53c9a92d53954cb9a0cce313143e42b1_ShadowAtten_4);
            float3 _Add_56015c4b7c404085be87200a0122fef5_Out_2;
            Unity_Add_float3(IN.WorldSpaceViewDirection, _MainLight_53c9a92d53954cb9a0cce313143e42b1_Direction_1, _Add_56015c4b7c404085be87200a0122fef5_Out_2);
            float3 _Normalize_e2878b987db846e099056a6666e22347_Out_1;
            Unity_Normalize_float3(_Add_56015c4b7c404085be87200a0122fef5_Out_2, _Normalize_e2878b987db846e099056a6666e22347_Out_1);
            float _DotProduct_3b99448b35a244589e171511e1de0956_Out_2;
            Unity_DotProduct_float3(_Normalize_e2878b987db846e099056a6666e22347_Out_1, IN.WorldSpaceNormal, _DotProduct_3b99448b35a244589e171511e1de0956_Out_2);
            float _Step_182201ee2df641d3bedee50d2d490ee6_Out_2;
            Unity_Step_float(_OneMinus_2a4484cb358e4660b9897e0072879fdf_Out_1, _DotProduct_3b99448b35a244589e171511e1de0956_Out_2, _Step_182201ee2df641d3bedee50d2d490ee6_Out_2);
            float4 _Lerp_2aed4c0303244957ad67f3e7416bc742_Out_3;
            Unity_Lerp_float4(_Lerp_9cba8439fec243989a471b60ab11f8a5_Out_3, _Property_ea1afdfb5090417d9da45f0935033007_Out_0, (_Step_182201ee2df641d3bedee50d2d490ee6_Out_2.xxxx), _Lerp_2aed4c0303244957ad67f3e7416bc742_Out_3);
            surface.BaseColor = IsGammaSpace() ? float3(0, 0, 0) : SRGBToLinear(float3(0, 0, 0));
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Emission = (_Lerp_2aed4c0303244957ad67f3e7416bc742_Out_3.xyz);
            surface.Specular = IsGammaSpace() ? float3(0.5, 0.5, 0.5) : SRGBToLinear(float3(0.5, 0.5, 0.5));
            surface.Smoothness = 0;
            surface.Occlusion = 1;
            surface.Alpha = 1.41;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);


            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);


            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.AbsoluteWorldSpacePosition =  GetAbsolutePositionWS(input.positionWS);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

            ENDHLSL
        }
        
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma multi_compile _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _SPECULAR_SETUP
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_SHADOWCASTER
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Toon_Shaded_Color;
        float4 Toon_Lit_Color;
        float Toon_Color_Steps;
        float Toon_Color_Offset;
        float Toon_Color_Spread;
        float4 Toon_Specular_Color;
        float Toon_Highlight_Intensity;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            // GraphFunctions: <None>

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            surface.Alpha = 1.41;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _SPECULAR_SETUP
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHONLY
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Toon_Shaded_Color;
        float4 Toon_Lit_Color;
        float Toon_Color_Steps;
        float Toon_Color_Offset;
        float Toon_Color_Spread;
        float4 Toon_Specular_Color;
        float Toon_Highlight_Intensity;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            // GraphFunctions: <None>

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            surface.Alpha = 1.41;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _SPECULAR_SETUP
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 normalWS;
            float4 tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 TangentSpaceNormal;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float4 interp1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.normalWS;
            output.interp1.xyzw =  input.tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.normalWS = input.interp0.xyz;
            output.tangentWS = input.interp1.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Toon_Shaded_Color;
        float4 Toon_Lit_Color;
        float Toon_Color_Steps;
        float Toon_Color_Offset;
        float Toon_Color_Spread;
        float4 Toon_Specular_Color;
        float Toon_Highlight_Intensity;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            // GraphFunctions: <None>

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 NormalTS;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Alpha = 1.41;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);



            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);


        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            // Render State
            Cull Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _SPECULAR_SETUP
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_META
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceViewDirection;
            float3 AbsoluteWorldSpacePosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float3 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.viewDirectionWS = input.interp2.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Toon_Shaded_Color;
        float4 Toon_Lit_Color;
        float Toon_Color_Steps;
        float Toon_Color_Offset;
        float Toon_Color_Spread;
        float4 Toon_Specular_Color;
        float Toon_Highlight_Intensity;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        // 74d2f54f0da2d6f91cdd2cd16c508b1e
        #include "Assets/URP_testbed/toontest/Custom Functions/MainLight.hlsl"

        struct Bindings_MainLight_ab9b6feadc505a54a9d799b7581b16e2
        {
            float3 AbsoluteWorldSpacePosition;
        };

        void SG_MainLight_ab9b6feadc505a54a9d799b7581b16e2(Bindings_MainLight_ab9b6feadc505a54a9d799b7581b16e2 IN, out half3 Direction_1, out half3 Color_2, out half DistanceAtten_3, out half ShadowAtten_4)
        {
            half3 _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_Direction_0;
            half3 _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_Color_1;
            half _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_DistanceAtten_3;
            half _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_ShaddowAtten_4;
            MainLight_half(IN.AbsoluteWorldSpacePosition, _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_Direction_0, _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_Color_1, _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_DistanceAtten_3, _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_ShaddowAtten_4);
            Direction_1 = _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_Direction_0;
            Color_2 = _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_Color_1;
            DistanceAtten_3 = _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_DistanceAtten_3;
            ShadowAtten_4 = _MainLightCustomFunction_f3be4cc08a9149bcb8a27b71206a30f0_ShaddowAtten_4;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Posterize_float(float In, float Steps, out float Out)
        {
            Out = floor(In / (1 / Steps)) * (1 / Steps);
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Step_float(float Edge, float In, out float Out)
        {
            Out = step(Edge, In);
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 Emission;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_db3214fdfe4b4bce90985873eb534132_Out_0 = Toon_Shaded_Color;
            float4 _Property_eec6d81ed1e74bd5b2541481233fe313_Out_0 = Toon_Lit_Color;
            float _Property_2966c009297c4d3a868fb7fa62e11db9_Out_0 = Toon_Color_Offset;
            float _Property_7bbf90eb0e3b4686986a400bf55dd3a8_Out_0 = Toon_Color_Spread;
            float _Subtract_416c7f62ddf24fe5ba7fcb1fe061d237_Out_2;
            Unity_Subtract_float(_Property_2966c009297c4d3a868fb7fa62e11db9_Out_0, _Property_7bbf90eb0e3b4686986a400bf55dd3a8_Out_0, _Subtract_416c7f62ddf24fe5ba7fcb1fe061d237_Out_2);
            float _Add_1a8c8c870c17483dbc94972f23d8585b_Out_2;
            Unity_Add_float(_Property_2966c009297c4d3a868fb7fa62e11db9_Out_0, _Property_7bbf90eb0e3b4686986a400bf55dd3a8_Out_0, _Add_1a8c8c870c17483dbc94972f23d8585b_Out_2);
            Bindings_MainLight_ab9b6feadc505a54a9d799b7581b16e2 _MainLight_e35a2e59e0814bcf8d786edfac477a49;
            _MainLight_e35a2e59e0814bcf8d786edfac477a49.AbsoluteWorldSpacePosition = IN.AbsoluteWorldSpacePosition;
            half3 _MainLight_e35a2e59e0814bcf8d786edfac477a49_Direction_1;
            half3 _MainLight_e35a2e59e0814bcf8d786edfac477a49_Color_2;
            half _MainLight_e35a2e59e0814bcf8d786edfac477a49_DistanceAtten_3;
            half _MainLight_e35a2e59e0814bcf8d786edfac477a49_ShadowAtten_4;
            SG_MainLight_ab9b6feadc505a54a9d799b7581b16e2(_MainLight_e35a2e59e0814bcf8d786edfac477a49, _MainLight_e35a2e59e0814bcf8d786edfac477a49_Direction_1, _MainLight_e35a2e59e0814bcf8d786edfac477a49_Color_2, _MainLight_e35a2e59e0814bcf8d786edfac477a49_DistanceAtten_3, _MainLight_e35a2e59e0814bcf8d786edfac477a49_ShadowAtten_4);
            float _DotProduct_5b3f6c2a8d0d4bd48edadbdca99f697c_Out_2;
            Unity_DotProduct_float3(IN.WorldSpaceNormal, _MainLight_e35a2e59e0814bcf8d786edfac477a49_Direction_1, _DotProduct_5b3f6c2a8d0d4bd48edadbdca99f697c_Out_2);
            float _Saturate_d79689cba0bd48568abd6ab88c50d601_Out_1;
            Unity_Saturate_float(_DotProduct_5b3f6c2a8d0d4bd48edadbdca99f697c_Out_2, _Saturate_d79689cba0bd48568abd6ab88c50d601_Out_1);
            float _Multiply_dd07fecb3c494709a74e4c74a6c924d0_Out_2;
            Unity_Multiply_float(_Saturate_d79689cba0bd48568abd6ab88c50d601_Out_1, _MainLight_e35a2e59e0814bcf8d786edfac477a49_ShadowAtten_4, _Multiply_dd07fecb3c494709a74e4c74a6c924d0_Out_2);
            float _Smoothstep_0c9179213c87407aa7f92ecbb955b1d0_Out_3;
            Unity_Smoothstep_float(_Subtract_416c7f62ddf24fe5ba7fcb1fe061d237_Out_2, _Add_1a8c8c870c17483dbc94972f23d8585b_Out_2, _Multiply_dd07fecb3c494709a74e4c74a6c924d0_Out_2, _Smoothstep_0c9179213c87407aa7f92ecbb955b1d0_Out_3);
            float _Property_02ab2602ca53467aa93aab2e9b134d42_Out_0 = Toon_Color_Steps;
            float _Subtract_483bc27c9c804d85baf387d006b33f15_Out_2;
            Unity_Subtract_float(_Property_02ab2602ca53467aa93aab2e9b134d42_Out_0, 1, _Subtract_483bc27c9c804d85baf387d006b33f15_Out_2);
            float _Posterize_13251350164f4aaf86213bfe607f9018_Out_2;
            Unity_Posterize_float(_Smoothstep_0c9179213c87407aa7f92ecbb955b1d0_Out_3, _Subtract_483bc27c9c804d85baf387d006b33f15_Out_2, _Posterize_13251350164f4aaf86213bfe607f9018_Out_2);
            float4 _Lerp_9cba8439fec243989a471b60ab11f8a5_Out_3;
            Unity_Lerp_float4(_Property_db3214fdfe4b4bce90985873eb534132_Out_0, _Property_eec6d81ed1e74bd5b2541481233fe313_Out_0, (_Posterize_13251350164f4aaf86213bfe607f9018_Out_2.xxxx), _Lerp_9cba8439fec243989a471b60ab11f8a5_Out_3);
            float4 _Property_ea1afdfb5090417d9da45f0935033007_Out_0 = Toon_Specular_Color;
            float _Property_03d7c8b4d94341c0a27c54cd27dd6d55_Out_0 = Toon_Highlight_Intensity;
            float _OneMinus_2a4484cb358e4660b9897e0072879fdf_Out_1;
            Unity_OneMinus_float(_Property_03d7c8b4d94341c0a27c54cd27dd6d55_Out_0, _OneMinus_2a4484cb358e4660b9897e0072879fdf_Out_1);
            Bindings_MainLight_ab9b6feadc505a54a9d799b7581b16e2 _MainLight_53c9a92d53954cb9a0cce313143e42b1;
            _MainLight_53c9a92d53954cb9a0cce313143e42b1.AbsoluteWorldSpacePosition = IN.AbsoluteWorldSpacePosition;
            half3 _MainLight_53c9a92d53954cb9a0cce313143e42b1_Direction_1;
            half3 _MainLight_53c9a92d53954cb9a0cce313143e42b1_Color_2;
            half _MainLight_53c9a92d53954cb9a0cce313143e42b1_DistanceAtten_3;
            half _MainLight_53c9a92d53954cb9a0cce313143e42b1_ShadowAtten_4;
            SG_MainLight_ab9b6feadc505a54a9d799b7581b16e2(_MainLight_53c9a92d53954cb9a0cce313143e42b1, _MainLight_53c9a92d53954cb9a0cce313143e42b1_Direction_1, _MainLight_53c9a92d53954cb9a0cce313143e42b1_Color_2, _MainLight_53c9a92d53954cb9a0cce313143e42b1_DistanceAtten_3, _MainLight_53c9a92d53954cb9a0cce313143e42b1_ShadowAtten_4);
            float3 _Add_56015c4b7c404085be87200a0122fef5_Out_2;
            Unity_Add_float3(IN.WorldSpaceViewDirection, _MainLight_53c9a92d53954cb9a0cce313143e42b1_Direction_1, _Add_56015c4b7c404085be87200a0122fef5_Out_2);
            float3 _Normalize_e2878b987db846e099056a6666e22347_Out_1;
            Unity_Normalize_float3(_Add_56015c4b7c404085be87200a0122fef5_Out_2, _Normalize_e2878b987db846e099056a6666e22347_Out_1);
            float _DotProduct_3b99448b35a244589e171511e1de0956_Out_2;
            Unity_DotProduct_float3(_Normalize_e2878b987db846e099056a6666e22347_Out_1, IN.WorldSpaceNormal, _DotProduct_3b99448b35a244589e171511e1de0956_Out_2);
            float _Step_182201ee2df641d3bedee50d2d490ee6_Out_2;
            Unity_Step_float(_OneMinus_2a4484cb358e4660b9897e0072879fdf_Out_1, _DotProduct_3b99448b35a244589e171511e1de0956_Out_2, _Step_182201ee2df641d3bedee50d2d490ee6_Out_2);
            float4 _Lerp_2aed4c0303244957ad67f3e7416bc742_Out_3;
            Unity_Lerp_float4(_Lerp_9cba8439fec243989a471b60ab11f8a5_Out_3, _Property_ea1afdfb5090417d9da45f0935033007_Out_0, (_Step_182201ee2df641d3bedee50d2d490ee6_Out_2.xxxx), _Lerp_2aed4c0303244957ad67f3e7416bc742_Out_3);
            surface.BaseColor = IsGammaSpace() ? float3(0, 0, 0) : SRGBToLinear(float3(0, 0, 0));
            surface.Emission = (_Lerp_2aed4c0303244957ad67f3e7416bc742_Out_3.xyz);
            surface.Alpha = 1.41;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);


            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph


            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.AbsoluteWorldSpacePosition =  GetAbsolutePositionWS(input.positionWS);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"

            ENDHLSL
        }
        
 
    }
    
    FallBack "Hidden/Shader Graph/FallbackError"
}