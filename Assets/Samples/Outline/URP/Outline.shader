Shader "URP_Practise/Outline"
{
    Properties
    {
        [HideInInspector]_MainTex("MainTex",2D)="white"{}
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

        float4 _MainTex_TexelSize;

        CBUFFER_END
        
        real4 _OutlineColor;
        float _Blur;

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_OutlineBlurTex);
        SAMPLER(sampler_OutlineBlurTex);
        TEXTURE2D(_OutlineSourTex);
        SAMPLER(sampler_OutlineSourTex);

        struct a2v
        {
            float4 positionOS:POSITION;
            float2 texcoord:TEXCOORD;
        };

        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float4 texcoord[4]:TEXCOORD;
        };
        ENDHLSL

        pass//上纯色
        {
            HLSLPROGRAM
            #pragma  vertex VERT
            #pragma fragment FRAG

            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                return o;
            }

            half4 FRAG(v2f i):SV_TARGET
            {
                return _OutlineColor;
            }
            ENDHLSL

        }

        pass//双重模糊DownPass
        {
            NAME"Down"
            HLSLPROGRAM
            #pragma vertex VERT

            #pragma fragment FRAG

            v2f VERT(a2v i)

            {
                v2f o;

                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                o.texcoord[2].xy = i.texcoord;
                o.texcoord[0].xy = i.texcoord + float2(1, 1) * _MainTex_TexelSize.xy * (1 + _Blur) * 0.5;
                o.texcoord[0].zw = i.texcoord + float2(-1, 1) * _MainTex_TexelSize.xy * (1 + _Blur) * 0.5;
                o.texcoord[1].xy = i.texcoord + float2(1, -1) * _MainTex_TexelSize.xy * (1 + _Blur) * 0.5;
                o.texcoord[1].zw = i.texcoord + float2(-1, -1) * _MainTex_TexelSize.xy * (1 + _Blur) * 0.5;
                return o;
            }

            half4 FRAG(v2f i):SV_TARGET
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

        pass//双重模糊upPass
        {

            NAME"Up"

            HLSLPROGRAM
            #pragma vertex VERT

            #pragma fragment FRAG

            v2f VERT(a2v i)

            {
                v2f o;

                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                o.texcoord[0].xy = i.texcoord + float2(1, 1) * _MainTex_TexelSize.xy * (1 + _Blur) * 0.5;
                o.texcoord[0].zw = i.texcoord + float2(-1, 1) * _MainTex_TexelSize.xy * (1 + _Blur) * 0.5;
                o.texcoord[1].xy = i.texcoord + float2(1, -1) * _MainTex_TexelSize.xy * (1 + _Blur) * 0.5;
                o.texcoord[1].zw = i.texcoord + float2(-1, -1) * _MainTex_TexelSize.xy * (1 + _Blur) * 0.5;
                o.texcoord[2].xy = i.texcoord + float2(0, 2) * _MainTex_TexelSize.xy * (1 + _Blur) * 0.5;
                o.texcoord[2].zw = i.texcoord + float2(0, -2) * _MainTex_TexelSize.xy * (1 + _Blur) * 0.5;
                o.texcoord[3].xy = i.texcoord + float2(-2, 0) * _MainTex_TexelSize.xy * (1 + _Blur) * 0.5;
                o.texcoord[3].zw = i.texcoord + float2(2, 0) * _MainTex_TexelSize.xy * (1 + _Blur) * 0.5;
                return o;
            }

            half4 FRAG(v2f i):SV_TARGET
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

        pass//合并所有图像
        {
            HLSLPROGRAM
            #pragma vertex VERT

            #pragma fragment FRAG

            #pragma multi_compile_local _INCOLORON _INCOLOROFF

            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord[0].xy = i.texcoord.xy;
                return o;
            }

            half4 FRAG(v2f i):SV_TARGET
            {
                real4 blur = SAMPLE_TEXTURE2D(_OutlineBlurTex, sampler_OutlineBlurTex, i.texcoord[0].xy);
                real4 sour = SAMPLE_TEXTURE2D(_OutlineSourTex, sampler_OutlineSourTex, i.texcoord[0].xy);
                real4 soild = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord[0].xy);
                real4 color;

                //用Blur的图减去纯色图，掏空它，由于Blur本身就自带了UV偏移效果，所以描边效果就有了
                #ifdef _INCOLORON

                color = abs(blur - soild) + sour;

                #elif _INCOLOROFF
    
                color = saturate(blur - soild) + sour;
    
                #endif

                return color;
            }
            ENDHLSL
        }
    }
}