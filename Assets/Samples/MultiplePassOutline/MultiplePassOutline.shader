Shader "URP_Practise/MultiplePassOutline"
{
    Properties
    {
        _MainTex("MainTex",2D)="White"{}
        _OutlineWidth("OutlineWidth",float) = 0
        _BaseColor("BaseColor",Color)=(1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="Opaque"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)

        float4 _MainTex_ST;
        half4 _BaseColor;
        float _OutlineWidth;

        CBUFFER_END

        TEXTURE2D(_MainTex);

        SAMPLER(sampler_MainTex);

        struct a2v_forOutLine
        {
            float4 positionOS:POSITION;
            float4 normalOS:NORMAL;
        };

        struct v2f_forOutLine
        {
            float4 positionCS:SV_POSITION;
        };

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
            Tags
            {
                "LightMode"="LightweightForward"
            }
            Cull Front
            HLSLPROGRAM
            #pragma vertex VERT
            #pragma fragment FRAG

            v2f VERT(a2v_forOutLine i)
            {
                i.positionOS.xyz += i.normalOS * _OutlineWidth;
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                return o;
            }

            half4 FRAG(v2f_forOutLine i):SV_TARGET
            {
                return _BaseColor;
            }
            ENDHLSL
        }

        pass
        {

            Cull Back
            HLSLPROGRAM
            #pragma vertex VERT
            #pragma fragment FRAG

            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord = TRANSFORM_TEX(i.texcoord, _MainTex);
                return o;
            }

            half4 FRAG(v2f i):SV_TARGET
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord) * _BaseColor;
                return tex;
            }
            ENDHLSL

        }
    }
}