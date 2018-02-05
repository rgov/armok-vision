﻿Shader "Custom/Engraving" 
{
    Properties 
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Atlas ("Albedo (RGB)", 2DArray) = "white" {}
        _BumpAtlas ("Normal Map", 2DArray) = "bump" {}
        _SpecColor("Standard Specular Color", Color) = (0.220916301, 0.220916301, 0.220916301, 0.779083699)
        _TileIndex ("TileIndex (R)", 2D) = "gray" {}
        		_ContributionAlbedo ("Contribution / Albedo", Range(0,1)) = 0.0
		_ContributionSpecSmoothness ("Contribution / Smoothness", Range(0,1)) = 0.0
		_ContributionNormal ("Contribution / Normal", Range(0,1)) = 1.0
		_ContributionEmission ("Contribution / Emission", Range(0,1)) = 1.0

    }
    SubShader 
    {
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="Opaque" "ForceNoShadowCasting"="True"}
		LOD 300
		Offset -1, -1
		Blend SrcAlpha OneMinusSrcAlpha

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard finalgbuffer:DecalFinalGBuffer keepalpha exclude_path:forward exclude_path:prepass noshadow noforwardadd

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 4.0
        #pragma multi_compile _ _BOUNDING_BOX_ENABLED

        UNITY_DECLARE_TEX2DARRAY(_Atlas);
        UNITY_DECLARE_TEX2DARRAY(_BumpAtlas);
        sampler2D _TileIndex;

        struct Input 
        {
            float2 uv_Atlas;
            float2 uv_TileIndex;
            float3 worldPos;
        };

        float3      _ViewMin = float3(-99999, -99999, -99999);
        float3      _ViewMax = float3(99999, 99999, 99999);


UNITY_INSTANCING_BUFFER_START(MyProperties)
UNITY_DEFINE_INSTANCED_PROP(fixed4, _MatColor)
#define _MatColor_arr MyProperties
UNITY_DEFINE_INSTANCED_PROP(int, _MatIndex)
#define _MatIndex_arr MyProperties
UNITY_INSTANCING_BUFFER_END(MyProperties)

#include "blend.cginc"
#include "CustomMetallic.cginc"

		half _ContributionAlbedo;
		half _ContributionSpecSmoothness;
		half _ContributionNormal;
		half _ContributionEmission;


        void surf (Input IN, inout SurfaceOutputStandard o) 
        {
            #ifdef _BOUNDING_BOX_ENABLED
                clip(IN.worldPos - _ViewMin);
                clip(_ViewMax - IN.worldPos);
            #endif
            float4 index = floor(tex2D(_TileIndex, IN.uv_TileIndex) * 255);
            float3 uv = float3(IN.uv_Atlas, index.r);
            uv.xy -= index.ba;
            uv.xy *= index.g;

            //clip(UNITY_SAMPLE_TEX2DARRAY (_Atlas, uv).a - 0.5);

            fixed4 matColor = UNITY_SAMPLE_TEX2DARRAY (_Atlas, uv);

            o.Albedo = matColor.rgb;
            o.Alpha = matColor.a;
            o.Normal = UnpackNormal(1-UNITY_SAMPLE_TEX2DARRAY(_BumpAtlas, uv));
        }

        void DecalFinalGBuffer (Input IN, SurfaceOutputStandard o, inout half4 diffuse, inout half4 specSmoothness, inout half4 normal, inout half4 emission)
		{
			diffuse *= o.Alpha * _ContributionAlbedo; 
			specSmoothness *= o.Alpha * _ContributionSpecSmoothness; 
			normal *= o.Alpha * _ContributionNormal; 
			emission *= o.Alpha * _ContributionEmission; 
		}
        ENDCG
    }
	FallBack "Diffuse"
}
