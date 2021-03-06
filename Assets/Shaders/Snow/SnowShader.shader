﻿Shader "Unlit/SnowShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_SnowColor ("Snow Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_SnowLevel ("Snow Level", Range(0, 0.4)) = 0
		_SnowDepth ("Snow Depth", Range(0, 0.5)) = 0.1
	}
	
	SubShader{

		Tags {"RenderType" = "Opaque"}

		CGINCLUDE
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#include "AutoLight.cginc"

		sampler2D _MainTex;
		float4 _MainTex_ST;
		float4 _SnowColor;
		float _SnowLevel;
		float _SnowDepth;
		
		struct a2v{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float2 texcoord : TEXCOORD0;	
		};

		struct v2f{
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
			float3 worldNormal : TEXCOORD1;
			float3 worldPos : TEXCOORD2;
			SHADOW_COORDS(3)
		};

		v2f vert(a2v v) {
			v2f o;
			
			o.pos = UnityObjectToClipPos(v.vertex);
			o.worldNormal = UnityObjectToWorldNormal(v.normal);
			o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			
			TRANSFER_SHADOW(o);
			return o;
		}

		fixed4 frag(v2f i) : SV_Target{
			//使用Lambert光照模型

			//采样反射率
			fixed3 albedo = tex2D(_MainTex, i.uv).rgb;
			//入射光方向(对指向光源方向取反)
			fixed3 worldLightDir = -normalize(UnityWorldSpaceLightDir(i.worldPos)); //unityworldspacelightdir函数为获取指向光源方向
			//世界法线
			fixed3 worldNormal = normalize(i.worldNormal);
			//环境光
			fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
			//漫反射光照
			fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
			//统一光照衰减和阴影
			UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
			//混合光照
			fixed3 lightColor = diffuse * atten + ambient;
			//纹理采样
			fixed4 color = tex2D(_MainTex, i.uv);
			//计算阈值，以世界法线和垂直方向夹角点积作为积雪厚度判断标准
			//一般来说，夹角越小(点积值越大)积雪越厚
			half SnowThreshold = dot(i.worldNormal, float3(0, 1, 0)) - lerp(1, -1, _SnowLevel);
			SnowThreshold = saturate(_SnowDepth / SnowThreshold);
			// SnowThreshold = saturate(_SnowDepth / SnowThreshold);
			color.rgb = lerp(color, _SnowColor, SnowThreshold);
			//混合颜色 输出，这里把插值函数第三个值置为1，可以得到一种类似卡通风格的渲染，也就是不计算光照
			fixed3 finalColor = lerp(lightColor, color, SnowThreshold);

			return float4(finalColor, 1);

		}

		ENDCG


		Pass{

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			ENDCG

		}

	}

	FallBack "Diffuse"
}
