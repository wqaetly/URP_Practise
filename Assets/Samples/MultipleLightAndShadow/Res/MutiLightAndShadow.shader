Shader "URP_Practise/MutiLightAndShadow"
{
    Properties
    {
        _MainTex("MainTex",2D)="white"{}
        _BaseColor("BaseColor",Color)=(1,1,1,1)
        [KeywordEnum(ON,OFF)]_ADD_LIGHT("AddLight",float)=1
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
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)

        float4 _MainTex_ST;
        half4 _BaseColor;

        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

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
            float3 WS_N:NORMAL;
            float3 WS_V:TEXCOORD1;
            float3 WS_P:TEXCOORD2;
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
            #pragma shader_feature _ADD_LIGHT_ON _ADD_LIGHT_OFF

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS

            #pragma multi_compile _ _SHADOWS_SOFT

            v2f_up VERT(a2v i)
            {
                v2f_up o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord = TRANSFORM_TEX(i.texcoord, _MainTex);
                o.WS_N = normalize(TransformObjectToWorldNormal(i.normalOS.xyz));
                o.WS_V = normalize(_WorldSpaceCameraPos - TransformObjectToWorld(i.positionOS.xyz));
                o.WS_P = TransformObjectToWorld(i.positionOS.xyz);
                return o;
            }

            real4 FRAG(v2f_up i):SV_TARGET
            {
                //Properties need
                half4 shadowTexcoord = TransformWorldToShadowCoord(i.WS_P);
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord) * _BaseColor;
                Light mylight = GetMainLight(shadowTexcoord);
                float3 WS_Light = normalize(mylight.direction);
                float3 WS_Normal = i.WS_N;
                float3 WS_View = i.WS_V;
                float3 WS_H = normalize(WS_View + WS_Light);
                float3 WS_Pos = i.WS_P;
                //calcute mainlight

                float4 maincolor = (dot(WS_Light, WS_Normal) * 0.5 + 0.5) * tex * float4(mylight.color, 1) * mylight.
                    shadowAttenuation;
                //calcute addlight

                real4 addcolor = real4(0, 0, 0, 1);
                #if _ADD_LIGHT_ON

                int addLightsCount = GetAdditionalLightsCount();

                for(int i=0;i<addLightsCount;i++)
                {
                    Light addlight=GetAdditionalLight(i,WS_Pos);
                    float3 WS_addLightDir=normalize(addlight.direction);
                    addcolor+=(dot(WS_Normal,WS_addLightDir)*0.5+0.5)*real4(addlight.color,1)*tex*addlight.distanceAttenuation*addlight.shadowAttenuation;
                }//half Lambert

                #else

                addcolor = real4(0, 0, 0, 1);

                #endif

                return maincolor + addcolor;
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}