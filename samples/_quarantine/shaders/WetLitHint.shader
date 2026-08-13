Shader "FF/World/WetLitHint"
{
    Properties
    {
        _BaseMap ("Albedo", 2D) = "white" {}
        _Wetness ("Wetness", Range(0,1)) = 0
        _Smoothness ("Smoothness", Range(0,1)) = 0.25
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            Name "Forward"
            Tags { "LightMode"="UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            float _Wetness;
            float _Smoothness;

            struct A { float4 pos : POSITION; float3 n : NORMAL; float2 uv : TEXCOORD0; };
            struct V { float4 pos : SV_POSITION; float2 uv : TEXCOORD0; float3 n : TEXCOORD1; };

            V vert(A i)
            {
                V o;
                o.pos = TransformObjectToHClip(i.pos.xyz);
                o.uv = i.uv;
                o.n = TransformObjectToWorldNormal(i.n);
                return o;
            }

            half4 frag(V i) : SV_Target
            {
                half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                albedo.rgb *= lerp(1.0h, 0.72h, _Wetness);
                Light l = GetMainLight();
                half ndl = saturate(dot(normalize(i.n), l.direction));
                half spec = pow(ndl, lerp(8, 48, _Wetness + _Smoothness));
                half3 col = albedo.rgb * (ndl * l.color + 0.18h) + spec * l.color * _Wetness;
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
