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
            float _Angle;
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

                output.vertex = TransformObjectToHClip(input.positionOS.xyz);
                //output.uv = input.uv;
                output.uv.x = input.uv.x * cos(_Angle) - input.uv.y*sin(_Angle);
                output.uv.y = input.uv.x*sin(_Angle) + input.uv.y *cos(_Angle);
                //output.uv = float2(input.uv.x * cos(_Angle) - input.uv.y*sin(_Angle), input.uv.x*sin(_Angle) + input.uv.y *cos(_Angle));
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