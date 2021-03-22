Shader "URP_Practise/GlassBasedOnNromalMap"
{
    Properties

    {

        _NormalTex("Normal",2D)="bump"{}

        _NormalScale("NormalScale",Range(0,1))=1

        _BaseColor("BaseColor",Color)=(1,1,1,1)

        _Amount("amount",float)=100

        [KeywordEnum(WS_N,TS_N)]_NORMAL_STAGE("NormalStage",float)=1

    }

    SubShader

    {

        Tags
        {

            "RenderPipeline"="UniversalRenderPipeline"



        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)

        float4 _NormalTex_ST;

        half4 _BaseColor;

        float _NormalScale;

        float _Amount;

        CBUFFER_END

        float4 _CameraColorTexture_TexelSize; //该向量是非本shader独有，不能放在常量缓冲区

        TEXTURE2D(_NormalTex);

        SAMPLER(sampler_NormalTex);

        TEXTURE2D(_CameraColorTexture);
        SAMPLER(sampler_CameraColorTexture);


        struct a2v

        {
            float4 positionOS:POSITION;

            float4 normalOS:NORMAL;

            float2 texcoord:TEXCOORD;

            float4 tangentOS:TANGENT;
        };

        struct v2f

        {
            float4 positionCS:SV_POSITION;

            float2 texcoord:TEXCOORD;

            float4 normalWS:NORMAL;

            float4 tangentWS:TANGENT;

            float4 BtangentWS:TEXCOORD1;
        };
        ENDHLSL



        pass

        {

            Tags
            {

                "LightMode"="UniversalForward"

            }

            HLSLPROGRAM
            #pragma vertex VERT

            #pragma fragment FRAG

            #pragma shader_feature_local _NORMAL_STAGE_WS_N

            v2f VERT(a2v i)

            {
                v2f o;

                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                o.texcoord = TRANSFORM_TEX(i.texcoord, _NormalTex);

                o.normalWS.xyz = normalize(TransformObjectToWorldNormal(i.normalOS.xyz));

                o.tangentWS.xyz = normalize(TransformObjectToWorldDir(i.tangentOS.xyz));

                o.BtangentWS.xyz = cross(o.normalWS.xyz, o.tangentWS.xyz) * i.tangentOS.w * unity_WorldTransformParams.
                    w;

                float3 positionWS = TransformObjectToWorld(i.positionOS.xyz);

                o.tangentWS.w = positionWS.x;

                o.BtangentWS.w = positionWS.y;

                o.normalWS.w = positionWS.z;

                return o;
            }

            half4 FRAG(v2f i):SV_TARGET

            {
                half4 normalTex = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.texcoord) * _BaseColor; //获取法线贴图

                float3 normalTS = UnpackNormalScale(normalTex, _NormalScale); //得到我们想要对比的切线空间法线

                float2 SS_texcoord = i.positionCS.xy / _ScreenParams.xy; //获取屏幕UV


                #ifdef _NORMAL_STAGE_WS_N//计算偏移的2张方式

                float3x3 matrix_T2W = {i.tangentWS.xyz, i.BtangentWS.xyz, i.normalWS.xyz}; //构建tbn矩阵

                float3 WSnor = mul(normalTS, matrix_T2W); //得到我们想要的世界空间法线

                //return real4(WSnor,1);//测试世界空间法线

                float2 SS_bias = WSnor.xy * _Amount * _CameraColorTexture_TexelSize;
                //如果取的世界空间的法线则执行它计算偏移，但是世界空间的法线由世界空间确定，会随着模型的旋转而变化；

                #else

                float2 SS_bias=normalTS.xy*_Amount*_CameraColorTexture_TexelSize;//如果取的是切线空间的法线则执行它计算偏移，但是切线空间的法线不随着模型的旋转而变换；

                #endif


                float4 glassColor = SAMPLE_TEXTURE2D(_CameraColorTexture,
                                                     sampler_CameraColorTexture, SS_texcoord + SS_bias); //把最终的颜色输出到屏幕即可

                return real4(glassColor.xyz, 1);
            }
            ENDHLSL

        }



    }
}