Shader "FF/VFX/MuzzleFlash"
{
    Properties
    {
        _BaseMap ("Flash", 2D) = "white" {}
        _Color ("Color", Color) = (1, 0.78, 0.35, 1)
        _Intensity ("Intensity", Float) = 4
        _Age ("Age", Range(0,1)) = 0
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline" }
        Blend SrcAlpha One
        ZWrite Off
        Cull Off
        Pass
        {
            Name "Unlit"
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            float4 _Color;
            float _Intensity;
            float _Age;

            struct A { float4 pos : POSITION; float2 uv : TEXCOORD0; };
            struct V { float4 pos : SV_POSITION; float2 uv : TEXCOORD0; };

            V vert(A i)
            {
                V o;
                o.pos = TransformObjectToHClip(i.pos.xyz);
                o.uv = i.uv;
                return o;
            }

            half4 frag(V i) : SV_Target
            {
                half4 t = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                half fade = saturate(1.0h - _Age);
                fade *= fade;
                return t * _Color * _Intensity * fade;
            }
            ENDHLSL
        }
    }
}
