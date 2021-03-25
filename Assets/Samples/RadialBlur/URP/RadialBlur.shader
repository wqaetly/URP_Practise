Shader "URP_Practise/RadialBlur"
{
    Properties
    {
        [HideInInspector]_MainTex("MainTex",2D)="white"{}
        //_Blur("Blur",float)=3
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
        }

        Cull Off ZWrite Off ZTest Always

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)

        float4 _MainTex_ST;

        float4 _MainTex_TexelSize;

        CBUFFER_END

        TEXTURE2D(_MainTex);

        SAMPLER(sampler_MainTex);

        float _RadialBlurRadius;
        float _RadialBlurLoopCount;
        float2 _RadialBlurCenter;

        struct a2v
        {
            float4 positionOS:POSITION;
            float2 texcoord:TEXCOORD;
        };

        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float2 texcoord:TEXCOORD;
        };
        ENDHLSL


        pass
        {
            HLSLPROGRAM
            #pragma vertex VERT

            #pragma fragment FRAG

            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord = i.texcoord;
                return o;
            }

            half4 FRAG(v2f i):SV_TARGET
            {
                float2 blurVector = (_RadialBlurCenter - i.texcoord.xy) * _RadialBlurRadius;

                half4 acumulateColor = half4(0, 0, 0, 0);
                
                for (int j = 0; j < _RadialBlurLoopCount; j ++)
                {
                    acumulateColor += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
                    i.texcoord.xy += blurVector;
                }

                return acumulateColor / _RadialBlurLoopCount;
            }
            ENDHLSL

        }
    }
}