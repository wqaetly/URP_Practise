using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ComputePostProcessRenderFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class setting
    {
        public ComputeShader CS = null;

        [Range(0, 2)] public float Saturate = 1;
        [Range(0, 2)] public float Bright = 1;
        [Range(-2, 3)] public float Constrast = 1;

        public RenderPassEvent Event = RenderPassEvent.AfterRenderingTransparents;
    }

    public setting mysetting;

    class CustomRenderPass : ScriptableRenderPass
    {
        private ComputeShader CS;
        private setting Myset;

        private RenderTargetIdentifier Sour;

        public CustomRenderPass(setting set)
        {
            this.Myset = set;
            this.CS = set.CS;
        }

        public void setup(RenderTargetIdentifier source)
        {
            this.Sour = source;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("ComputeShaderRGBAdjust");

            int tempCameraColorTexID = Shader.PropertyToID("tempCameraColorTexID");
            RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
            desc.enableRandomWrite = true;

            cmd.GetTemporaryRT(tempCameraColorTexID, desc);

            cmd.SetComputeFloatParam(CS, "_Bright", Myset.Bright);
            cmd.SetComputeFloatParam(CS, "_Saturate", Myset.Saturate);
            cmd.SetComputeFloatParam(CS, "_Constrast", Myset.Constrast);
            cmd.SetComputeTextureParam(CS, 0, "_Result", tempCameraColorTexID);
            cmd.SetComputeTextureParam(CS, 0, "_Sour", Sour);

            cmd.DispatchCompute(CS, 0, (int) desc.width / 8, (int) desc.height / 8, 1);

            cmd.Blit(tempCameraColorTexID, Sour);
            context.ExecuteCommandBuffer(cmd);

            CommandBufferPool.Release(cmd);
        }
    }

    CustomRenderPass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass(mysetting);
        m_ScriptablePass.renderPassEvent = mysetting.Event;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (mysetting.CS != null)
        {
            m_ScriptablePass.setup(renderer.cameraColorTarget);
            renderer.EnqueuePass(m_ScriptablePass);
        }

        else
        {
            Debug.LogError("ComputeShader missing!!");
        }
    }
}