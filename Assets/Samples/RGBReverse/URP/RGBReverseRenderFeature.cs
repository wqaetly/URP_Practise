using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RGBReverseRenderFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class setting
    {
        public Material mat = null;
        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingOpaques;
    }

    public setting mysetting;

    class RGBReverseRenderPass : ScriptableRenderPass
    {
        setting mysetting = null;

        RenderTargetIdentifier sour;

        public void stetup(RenderTargetIdentifier source)
        {
            this.sour = source;
        }

        public RGBReverseRenderPass(setting set)
        {
            mysetting = set;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("RGBReversePass");
            
            RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
            int sourID = Shader.PropertyToID("_RGBReverseSourTex");

            cmd.GetTemporaryRT(sourID, desc);
            cmd.CopyTexture(sour, sourID);
            cmd.Blit(sourID, sour, mysetting.mat);
            
            context.ExecuteCommandBuffer(cmd);
            cmd.ReleaseTemporaryRT(sourID);
            CommandBufferPool.Release(cmd);
        }
    }

    RGBReverseRenderPass m_ColorSplit;
    
    public override void Create()
    {
        m_ColorSplit = new RGBReverseRenderPass(mysetting);
        m_ColorSplit.renderPassEvent = mysetting.passEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        m_ColorSplit.stetup(renderer.cameraColorTarget);
        renderer.EnqueuePass(m_ColorSplit);
    }
}