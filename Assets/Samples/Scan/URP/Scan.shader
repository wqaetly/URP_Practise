Shader "URP_Practise/Scan"
{
    Properties
    {
        [HideInInspector]_MainTex("MainTex",2D)="white"{}
        [HideInInspector][HDR]_colorX("ColorX",Color)=(1,1,1,1)
        [HideInInspector][HDR]_colorY("ColorY",Color)=(1,1,1,1)
        [HideInInspector][HDR]_ColorZ("ColorZ",Color)=(1,1,1,1)
        [HideInInspector][HDR]_ColorEdge("ColorEdge",Color)=(1,1,1,1)
        [HideInInspector]_width("Width",float)=0.1
        [HideInInspector]_Spacing("Spacing",float)=1
        [HideInInspector]_Speed("Speed",float)=1
        [HideInInspector]_EdgeSample("EdgeSample",Range(0,1))=1
        [HideInInspector]_NormalSensitivity("NormalSensitivity",float)=1
        [HideInInspector]_DepthSensitivity("DepthSensitivity",float)=1
        [HideInInspector][HDR]_OutlineColor("OutlineColr",Color)=(1,1,1,1)
        //[KeywordEnum(X,Y,Z)]_AXIS("Axis",float)=1
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
        
        real4 _colorX;
        real4 _colorY;
        real4 _ColorZ;
        real4 _ColorEdge;
        real4 _OutlineColor;
        float _width;
        float _Spacing;
        float _Speed;
        float _EdgeSample;
        float _NormalSensitivity;
        float _DepthSensitivity;

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        //TEXTURE2D(_CameraDepthTexture);//不需要这张图了

        //SAMPLER(sampler_CameraDepthTexture);//不需要这张图了

        TEXTURE2D(_CameraDepthNormalsTexture);
        SAMPLER(sampler_CameraDepthNormalsTexture);
        float4x4 Matrix;

        struct a2v
        {
            float4 positionOS:POSITION;
            float2 texcoord:TEXCOORD;
        };

        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float2 texcoord:TEXCOORD;
            float3 Dirction:TEXCOORD1;
        };
        ENDHLSL

        pass
        {

            HLSLPROGRAM
            #pragma vertex VERT
            #pragma fragment FRAG
            #pragma multi_compile_local _AXIS_X _AXIS_Y _AXIS_Z

            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord = i.texcoord;

                int t;
                if (i.texcoord.x < 0.5 && i.texcoord.y < 0.5)
                    t = 0;
                else if (i.texcoord.x > 0.5 && i.texcoord.y < 0.5)
                    t = 1;
                else if (i.texcoord.x > 0.5 && i.texcoord.y > 0.5)
                    t = 2;
                else
                    t = 3;
                //这个Direction从VS到FS会被线性插值，所以在FS中每个片元就可以用其LinearEyeDepth乘以这个方向再加上相机的世界坐标来重建世界坐标
                o.Dirction = Matrix[t].xyz;
                return o;
            }

            int sobel(v2f i);

            real4 FRAG(v2f i):SV_TARGET
            {
                int outline = sobel(i);

                //return outline;

                real4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);

                //return lerp(tex,_OutlineColor,outline);

                real4 depthnormal = SAMPLE_TEXTURE2D(_CameraDepthNormalsTexture, sampler_CameraDepthNormalsTexture,
                                                     i.texcoord);
                //因为这里使用了特殊的_CameraDepthNormalsTexture，所以获取01深度值的方式发生了变化
                float depth01 = depthnormal.z * 1.0 + depthnormal.w / 255.0;

                //return depth01;

                float3 WSpos = _WorldSpaceCameraPos + depth01 * i.Dirction * _ProjectionParams.z; //这样也可以得到正确的世界坐标

                //return real4(frac(ws),1);

                float3 WSpos01 = WSpos * _ProjectionParams.w;
                float3 Line = step(1 - _width, frac(WSpos / _Spacing)); //线框
                float4 Linecolor = Line.x * _colorX + Line.y * _colorY + Line.z * _ColorZ + outline * _OutlineColor;
                //计算线框颜色

                //return Linecolor+tex;

                #ifdef _AXIS_X

                float mask = saturate(pow(abs(frac(WSpos01.x + _Time.y * _Speed) - 0.75), 10) * 30); //在X轴方向计算mask
                mask += step(0.999, mask);

                #elif _AXIS_Y

                float mask=saturate(pow(abs(frac(WSpos01.y-_Time.y*_Speed)-0.25),10)*30);//在Y轴方向计算mask
                mask+=step(0.999,mask);

                #elif _AXIS_Z

                float mask=saturate(pow(abs(frac(WSpos01.z+_Time.y*_Speed)-0.75),10)*30);//在Z轴方向计算mask
                mask+=step(0.999,mask);
               
                #endif

                //return mask;

                return tex * saturate(1 - mask) + (Linecolor + _ColorEdge) * mask;
            }

            int sobel(v2f i) //定义索伯检测函数
            {
                real depth[4];

                real2 normal[4];

                float2 uv[4]; //计算采样需要的uv

                uv[0] = i.texcoord + float2(-1, -1) * _EdgeSample * _MainTex_TexelSize.xy;
                uv[1] = i.texcoord + float2(1, -1) * _EdgeSample * _MainTex_TexelSize.xy;
                uv[2] = i.texcoord + float2(-1, 1) * _EdgeSample * _MainTex_TexelSize.xy;
                uv[3] = i.texcoord + float2(1, 1) * _EdgeSample * _MainTex_TexelSize.xy;

                for (int t = 0; t < 4; t++)
                {
                    real4 depthnormalTex = SAMPLE_TEXTURE2D(_CameraDepthNormalsTexture,
                                                            sampler_CameraDepthNormalsTexture, uv[t]);
                    normal[t] = depthnormalTex.xy; //得到临时法线
                    depth[t] = depthnormalTex.z * 1.0 + depthnormalTex.w / 255.0; //得到线性深度
                }

                //depth检测
                int Dep = abs(depth[0] - depth[3]) * abs(depth[1] - depth[2]) * _DepthSensitivity > 0.01 ? 1 : 0;

                //normal检测
                float2 nor = abs(normal[0] - normal[3]) * abs(normal[1] - normal[2]) * _NormalSensitivity;
                int Nor = (nor.x + nor.y) > 0.01 ? 1 : 0;
                return saturate(Dep + Nor);
            }
            ENDHLSL

        }

    }
}