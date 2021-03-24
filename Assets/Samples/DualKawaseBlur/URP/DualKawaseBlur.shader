Shader "URP_Practise/DualKawaseblur"
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

        float _DualKawaseBlur;

        CBUFFER_END

        TEXTURE2D(_MainTex);

        SAMPLER(sampler_MainTex);


        struct a2v
        {
            float4 positionOS:POSITION;
            float2 texcoord:TEXCOORD;
        };

        struct v2f_up
        {
            float4 positionCS:SV_POSITION;
            float4 texcoord[4]:TEXCOORD;
        };

        struct v2f_down
        {
            float4 positionCS:SV_POSITION;
            float4 texcoord[3]:TEXCOORD;
        };
        ENDHLSL


        pass//Down
        {
            NAME"Down"

            HLSLPROGRAM
            #pragma vertex VERT

            #pragma fragment FRAG

            v2f_down VERT(a2v i)
            {
                v2f_down o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord[2].xy = i.texcoord;
                o.texcoord[0].xy = i.texcoord + float2(1, 1) * _MainTex_TexelSize.xy * (1 + _DualKawaseBlur) * 0.5;
                o.texcoord[0].zw = i.texcoord + float2(-1, 1) * _MainTex_TexelSize.xy * (1 + _DualKawaseBlur) * 0.5;
                o.texcoord[1].xy = i.texcoord + float2(1, -1) * _MainTex_TexelSize.xy * (1 + _DualKawaseBlur) * 0.5;
                o.texcoord[1].zw = i.texcoord + float2(-1, -1) * _MainTex_TexelSize.xy * (1 + _DualKawaseBlur) * 0.5;

                return o;
            }

            half4 FRAG(v2f_down i):SV_TARGET
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord[2].xy) * 0.5;

                for (int t = 0; t < 2; t++)
                {
                    tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord[t].xy) * 0.125;
                    tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord[t].zw) * 0.125;
                }

                return tex;
            }
            ENDHLSL

        }

        pass//up
        {

            NAME"Up"

            HLSLPROGRAM
            #pragma vertex VERT

            #pragma fragment FRAG

            v2f_up VERT(a2v i)
            {
                v2f_up o;

                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                o.texcoord[0].xy = i.texcoord + float2(1, 1) * _MainTex_TexelSize.xy * (1 + _DualKawaseBlur) * 0.5;

                o.texcoord[0].zw = i.texcoord + float2(-1, 1) * _MainTex_TexelSize.xy * (1 + _DualKawaseBlur) * 0.5;

                o.texcoord[1].xy = i.texcoord + float2(1, -1) * _MainTex_TexelSize.xy * (1 + _DualKawaseBlur) * 0.5;

                o.texcoord[1].zw = i.texcoord + float2(-1, -1) * _MainTex_TexelSize.xy * (1 + _DualKawaseBlur) * 0.5;

                o.texcoord[2].xy = i.texcoord + float2(0, 2) * _MainTex_TexelSize.xy * (1 + _DualKawaseBlur) * 0.5;

                o.texcoord[2].zw = i.texcoord + float2(0, -2) * _MainTex_TexelSize.xy * (1 + _DualKawaseBlur) * 0.5;

                o.texcoord[3].xy = i.texcoord + float2(-2, 0) * _MainTex_TexelSize.xy * (1 + _DualKawaseBlur) * 0.5;

                o.texcoord[3].zw = i.texcoord + float2(2, 0) * _MainTex_TexelSize.xy * (1 + _DualKawaseBlur) * 0.5;

                return o;
            }

            half4 FRAG(v2f_up i):SV_TARGET
            {
                half4 tex = 0;

                for (int t = 0; t < 2; t++)
                {
                    tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord[t].xy) / 6;

                    tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord[t].zw) / 6;
                }

                for (int k = 2; k < 4; k++)
                {
                    tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord[k].xy) / 12;

                    tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord[k].zw) / 12;
                }
                return tex;
            }
            ENDHLSL

        }

    }
}