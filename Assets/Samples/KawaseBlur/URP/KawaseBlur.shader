Shader "URP_Practise/Kawaseblur"
{
    Properties
    {
        //虽然从来没有对这个MainTex赋过值，但是猜测在Blit的时候就将source的RT作为MainTex传过来了
        //并且，我尝试了将其关键字修改之后整个Shader就失效了，应该是个小Trick，记住就好
        _MainTex("MainTex",2D)="white"{}
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

        float _KawaseBlur;

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
            float2 texcoord:TEXCOORD;
        };

        //这是一种写法，规范来说其实应该把他放到下面的那个Pass里
        v2f_up VERT(a2v i) //水平方向的采样
        {
            v2f_up o;
            o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
            o.texcoord = i.texcoord;
            return o;
        }

        half4 FRAG(v2f_up i):SV_TARGET
        {
            half4 tex = half4(0,0,0,0);
            //_MainTex_TexelSize是当前屏幕分辨率的倒数
            tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord+float2(-1,-1)*_MainTex_TexelSize.xy*_KawaseBlur);

            tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord+float2(1,-1)*_MainTex_TexelSize.xy*_KawaseBlur);

            tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord+float2(-1,1)*_MainTex_TexelSize.xy*_KawaseBlur);

            tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord+float2(1,1)*_MainTex_TexelSize.xy*_KawaseBlur);

            return tex * 0.25;
        }
        ENDHLSL

        pass
        {
            HLSLPROGRAM
            #pragma vertex VERT

            #pragma fragment FRAG
            ENDHLSL
        }

    }

}