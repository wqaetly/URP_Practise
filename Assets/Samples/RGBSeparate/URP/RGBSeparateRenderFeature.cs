using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RGBSeparateRenderFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class setting
    {
        public Material mat = null;
        [Range(0, 1)] public float Instensity = 0.5f;
        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingOpaques;
    }

    public setting mysetting;

    class GlitchColorSplit : ScriptableRenderPass
    {
        setting mysetting = null;

        RenderTargetIdentifier sour;

        public void stetup(RenderTargetIdentifier source)
        {
            this.sour = source;
        }

        public GlitchColorSplit(setting set)
        {
            mysetting = set;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("RGBSeparatePass");

            cmd.SetGlobalFloat(Instensity, mysetting.Instensity);
            RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
            int sourID = Shader.PropertyToID("_RGBSeparateSourTex");

            cmd.GetTemporaryRT(sourID, desc);
            cmd.CopyTexture(sour, sourID);
            cmd.Blit(sourID, sour, mysetting.mat);
            
            context.ExecuteCommandBuffer(cmd);
            cmd.ReleaseTemporaryRT(sourID);
            CommandBufferPool.Release(cmd);
        }
    }

    GlitchColorSplit m_ColorSplit;
    private static readonly int Instensity = Shader.PropertyToID("_RGBSeparateInstensity");

    public override void Create()
    {
        m_ColorSplit = new GlitchColorSplit(mysetting);
        m_ColorSplit.renderPassEvent = mysetting.passEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        m_ColorSplit.stetup(renderer.cameraColorTarget);
        renderer.EnqueuePass(m_ColorSplit);
    }
}