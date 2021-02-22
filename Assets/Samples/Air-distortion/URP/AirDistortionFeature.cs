using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

public class AirDistortionFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent Event = RenderPassEvent.AfterRenderingOpaques;
        public Material AirDistortionMaterial = null;
        
        /// <summary>
        /// 时间系数
        /// </summary>
        [Tooltip("时间系数")] public float DistortTimeFactor;

        /// <summary>
        /// 扭曲强度
        /// </summary>
        [Tooltip("扭曲强度")] public float DistortStrength;

        /// <summary>
        /// 噪声图
        /// </summary>
        [Tooltip("噪声图")] public Texture2D NoiseTex;
    }
    
    class AirDistortionRenderPass : ScriptableRenderPass
    {
        public Material blitMaterial = null;
        private RenderTargetIdentifier source { get; set; }
        private RenderTargetHandle destination { get; set; }

        RenderTargetHandle m_TemporaryColorTexture;
        string m_ProfilerTag;
    
        public AirDistortionRenderPass(RenderPassEvent renderPassEvent, Material blitMaterial)
        {
            this.renderPassEvent = renderPassEvent;
            this.blitMaterial = blitMaterial;
            m_ProfilerTag = "AirDistortion";
            m_TemporaryColorTexture.Init("_TemporaryColorTexture");
        }
    
        public void Setup(RenderTargetIdentifier source, RenderTargetHandle destination)
        {
            this.source = source;
            this.destination = destination;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);

            RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;

            cmd.GetTemporaryRT(m_TemporaryColorTexture.id, opaqueDesc);
            Blit(cmd, source, m_TemporaryColorTexture.Identifier(), blitMaterial);
            Blit(cmd, m_TemporaryColorTexture.Identifier(), source);
            cmd.ReleaseTemporaryRT(m_TemporaryColorTexture.id);
        
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
        }
    }

    public Settings settings = new Settings();

    AirDistortionRenderPass _airDistortionRenderPass;
    
    private static readonly int DistortTimeFactor = Shader.PropertyToID("_DistortTimeFactor");
    private static readonly int DistortStrength = Shader.PropertyToID("_DistortStrength");
    private static readonly int NoiseTex = Shader.PropertyToID("_NoiseTex");

    public override void Create()
    {
        this.settings.AirDistortionMaterial.SetFloat(DistortTimeFactor, this.settings.DistortTimeFactor);
        this.settings.AirDistortionMaterial.SetFloat(DistortStrength, this.settings.DistortStrength);
        this.settings.AirDistortionMaterial.SetTexture(NoiseTex, this.settings.NoiseTex);
        _airDistortionRenderPass = new AirDistortionRenderPass(settings.Event, settings.AirDistortionMaterial);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var src = renderer.cameraColorTarget;
        var dest = RenderTargetHandle.CameraTarget;

        _airDistortionRenderPass.Setup(src, dest);
        renderer.EnqueuePass(_airDistortionRenderPass);
    }
}