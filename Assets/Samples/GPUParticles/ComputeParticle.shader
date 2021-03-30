Shader "URP_Practise/ComputeParticle"
{
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipline"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        struct data
        {
            float3 position;
            float4 color;
        };

        StructuredBuffer<data> inputbuffer;

        struct v2f
        {
            float4 color : COLOR;
            float4 positionCS : SV_POSITION;
        };
        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert(uint id:SV_VertexID)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(inputbuffer[id].position);
                o.color = inputbuffer[id].color;
                return o;
            }

            float4 frag(v2f i) : COLOR
            {
                return i.color;
            }
            ENDHLSL
        }
    }
}