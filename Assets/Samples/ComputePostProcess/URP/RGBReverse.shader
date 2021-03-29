Shader "URP_Practise/RGBReverse"
{
    Properties
    {
        [HideInInspector]_MainTex("MainTex",2D)="white"{}
    }

    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMatrial)

            float4 _MainTex_TexelSize;

            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;

                output.vertex  = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;

                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                float4 color = 1 - SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);

                return color;
            }
            ENDHLSL
        }
    }
    FallBack "Diffuse"
}