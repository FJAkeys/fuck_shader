Shader "HLSL/PlanarPlayerShadow" {
	Properties{
	_BaseMap("Example Texture", 2D) = "white" {}
	_BaseColor("Example Colour", Color) = (0, 0.66, 0.73, 1)
	_Cutoff("Alpha Cutoff", Float) = 0.5
	_Specular("Specular",Float) = 1
	_Smoothness("Smoothness",Float)=0.5
	_ShadowColor("ShadowColor",COLOR)=(0,0,0,0)
	_ShadowFalloff("ShadowFalloff",Range(0,1))=0.5
	_Plane("Plane",float)=0

	}
		SubShader{
		Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent"}

			HLSLINCLUDE
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

				CBUFFER_START(UnityPerMaterial)
				float4 _BaseMap_ST;
				float4 _BaseColor;
				float _Cutoff;
				float _Specular;
				float _Smoothness;


				float4 _ShadowColor;
				float _ShadowFalloff;
				float _Plane;
				CBUFFER_END
			ENDHLSL

			Pass {
				Name "Diff+Sp"
				Tags { "LightMode" = "UniversalForward" }

				HLSLPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
				#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
				#pragma multi_compile _ _SHADOWS_SOFT

				

				struct Attributes {
					float4 positionOS	: POSITION;
					float2 uv 		: TEXCOORD0;
					float4 color		: COLOR;

					float4 normalOS		: NORMAL;
				};

				struct Varyings {
					float4 positionCS	: SV_POSITION;
					float2 uv		: TEXCOORD0;
					float4 color		: COLOR;

					float3 normalWS		: NORMAL;
					float3 positionWS	: TEXCOORD2;
					float3 worldView	: TEXCOORD3;
				};

				TEXTURE2D(_BaseMap);
				SAMPLER(sampler_BaseMap);

				Varyings vert(Attributes IN) {
					Varyings OUT;

					VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
					OUT.positionCS = positionInputs.positionCS;
					// Or this :
					//OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);

					OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
					OUT.color = IN.color;

					OUT.positionWS = positionInputs.positionWS;

					VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS.xyz);
					OUT.normalWS = normalInputs.normalWS;

					OUT.worldView= _WorldSpaceCameraPos.xyz - OUT.positionWS;

					return OUT;
				}

				half4 frag(Varyings IN) : SV_Target {
					half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
					half4 color = baseMap * _BaseColor * IN.color;

					

					float4 shadowCoord = TransformWorldToShadowCoord(IN.positionWS.xyz);
					Light light = GetMainLight(shadowCoord);

					light.color *= light.shadowAttenuation;
					half3 shading = LightingLambert(light.color, light.direction, IN.normalWS);

					float Smoothness = exp2(10 * _Smoothness + 1);
					float3 WorldNormal = normalize(IN.normalWS);
					float3 WorldView = SafeNormalize(IN.worldView);
					half3 specular = LightingSpecular(light.color, light.direction, WorldNormal, WorldView, half4(_Specular, _Specular, _Specular, 0), Smoothness);

					return half4(color.rgb * shading+ specular, color.a);
				}
				ENDHLSL
				}
				Pass{
				Name "Planr Shadow"
				Tags{ "LightMode" = "SRPDefaultUnlit" }//URP不支持多pass，这样可以多pass，或者干脆不加tags也可以
				Stencil
				{
					Ref 0
					Comp equal
					Pass incrWrap
					Fail keep
					ZFail keep
				}

				Blend SrcAlpha OneMinusSrcAlpha

				ZWrite off

				Offset -1 , 0

				HLSLPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				struct Attributes {
					float4 positionOS	: POSITION;
				};

				struct Varyings {
					float4 positionCS	: SV_POSITION;
					float4 color : COLOR;
				};

				float3 ShadowProjectPos(float4 vertPos,float3 lightDir)
				{
					float3 shadowPos;

					//得到顶点的世界空间坐标
					float3 worldPos = TransformObjectToWorld(vertPos);

					//阴影的世界空间坐标（低于地面的部分不做改变）
					shadowPos.y = min(worldPos.y, _Plane);
					shadowPos.xz = worldPos.xz - lightDir.xz * max(0, worldPos.y - _Plane) / lightDir.y;

					return shadowPos;
				}
				Varyings vert(Attributes IN) {
					Varyings OUT;

					Light light = GetMainLight();

					//得到阴影的世界空间坐标
					float3 shadowPos = ShadowProjectPos(IN.positionOS, light.direction);

					OUT.positionCS = TransformWorldToHClip(shadowPos);

					//得到中心点世界坐标
					float3 center = float3(unity_ObjectToWorld[0].w, _Plane, unity_ObjectToWorld[2].w);
					//计算阴影衰减
					float falloff = 1 - saturate(distance(shadowPos, center) * _ShadowFalloff);

					//阴影颜色
					OUT.color = _ShadowColor;
					OUT.color.a *= falloff;


					return OUT;
				}
				half4 frag(Varyings IN) : SV_Target{
					return IN.color;
				}
				ENDHLSL
				}
	}
}