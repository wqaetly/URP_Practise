Shader "URP_Practise/EngryBasedOnDepthMap"
{
    Properties
    {
        _MainTex("MainTex",2D)="white"{}
        _BaseColor("BaseColor",Color)=(1,1,1,1)
        _depthoffset("depthoffset",float)=1
        [HDR]_emissioncolor("EmissionColor",Color )=(1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "Queue"="Transparent"

        }
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

        //#pragma shader_feature_local _ADDLIGHT_ON

        //#pragma multi_compile _ _MAIN_LIGHT_SHADOWS

        //#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

        //#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS

        //#pragma multi_compile _ _SHADOWS_SOFT

        CBUFFER_START(UnityPerMaterial)

        float4 _MainTex_ST;

        half4 _BaseColor;

        float _depthoffset;

        float4 _emissioncolor;

        CBUFFER_END

        TEXTURE2D(_MainTex);

        SAMPLER(sampler_MainTex);

        SAMPLER(_CameraDepthTexture);

        struct a2v
        {
            float4 positionOS:POSITION;
            float4 normalOS:NORMAL;
            float2 texcoord:TEXCOORD;
        };

        struct v2f_up
        {
            float4 positionCS:SV_POSITION;
            float2 texcoord:TEXCOORD;
            float4 sspos:TEXCOORD2;
            float3 positionWS:TEXCOORD3;
            float3 normalWS:TEXCOORD4;
        };
        ENDHLSL


        pass
        {

            Tags
            {

                "LightMode"="UniversalForward"
                "RenderType"="Transparent"
            }

            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex VERT

            #pragma fragment FRAG

            v2f_up VERT(a2v i)

            {
                v2f_up o;

                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                o.texcoord = TRANSFORM_TEX(i.texcoord, _MainTex);

                //屏幕坐标sspos，xy保存为未透除的屏幕uv，zw不变

                o.sspos.xy = o.positionCS.xy * 0.5 + 0.5 * float2(o.positionCS.w, o.positionCS.w);

                o.sspos.zw = o.positionCS.zw;

                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);

                o.normalWS = normalize(TransformObjectToWorldNormal(i.normalOS.xyz));

                return o;
            }

            half4 FRAG(v2f_up i):SV_TARGET

            {
                float2 uv = i.texcoord;

                uv.x += _Time.y * 0.2; //滚uv，以每秒钟滚0.2圈的速度旋转

                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv) * _BaseColor;

                //开始计算屏幕uv

                i.sspos.xy /= i.sspos.w; //透除

                #ifdef UNITY_UV_STARTS_AT_TOP//判断当前的平台是openGL还是dx

                i.sspos.y = 1 - i.sspos.y;

                #endif//得到正常的屏幕uv，也可以通过i.positionCS.xy/_ScreenParams.xy来得到屏幕uv

                //计算（山寨简化版）菲涅尔

                float3 WSview = normalize(_WorldSpaceCameraPos - i.positionWS);

                float fre = (1 - dot(i.normalWS, WSview)) * _depthoffset;


                //计算缓冲区深度，模型深度

                float4 depthcolor = tex2D(_CameraDepthTexture, i.sspos.xy);

                float depthbuffer = Linear01Depth(depthcolor, _ZBufferParams); //得到线性的深度缓冲

                //计算模型深度

                float depth = i.positionCS.z;

                depth = Linear01Depth(depth, _ZBufferParams); //得到模型的线性深度

                float edge = saturate(depth - depthbuffer + 0.005) * 100 * _depthoffset; //计算接触光

                //return edge;

                //计算扫光,这步看不懂建议用连连看还原，这是一个做特效的通用公式

                float flow = saturate(pow(1 - abs(frac(i.positionWS.y * 0.3 - _Time.y * 0.2) - 0.5), 10) * 0.3);

                float4 flowcolor = flow * _emissioncolor;

                //return flowcolor*2;

                return float4(tex.xyz, edge + fre) + flowcolor;
            }
            ENDHLSL

        }
    }
}