using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class OutlineRenderFeature : ScriptableRendererFeature
{
    public enum TYPE
    {
        INcolorON,
        INcolorOFF
    }

    [System.Serializable]
    public class setting
    {
        public Material mymat;

        public Color color = Color.blue;

        [Range(1000, 5000)] public int QueueMin = 2000;
        [Range(1000, 5000)] public int QueueMax = 2500;

        public LayerMask layer;

        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingSkybox;

        [Range(0.0f, 3.0f)] public float blur = 1.0f;

        [Range(1, 5)] public int passloop = 3;


        public TYPE ColorType = TYPE.INcolorON;
    }

    public setting mysetting = new setting();

    int solidcolorID;

    //第一个pass绘制纯色的图像

    class DrawSoildColorPass : ScriptableRenderPass
    {
        setting mysetting = null;

        OutlineRenderFeature SelectOutline = null;

        ShaderTagId shaderTag = new ShaderTagId("DepthOnly"); //只有在这个标签LightMode对应的shader才会被绘制

        FilteringSettings filter;

        public DrawSoildColorPass(setting setting, OutlineRenderFeature render)
        {
            mysetting = setting;
            SelectOutline = render;

            //过滤设定
            RenderQueueRange queue = new RenderQueueRange();

            queue.lowerBound = Mathf.Min(setting.QueueMax, setting.QueueMin);
            queue.upperBound = Mathf.Max(setting.QueueMax, setting.QueueMin);

            filter = new FilteringSettings(queue, setting.layer);
        }


        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            int temp = Shader.PropertyToID("_OutlineColor");

            RenderTextureDescriptor desc = cameraTextureDescriptor;
            cmd.GetTemporaryRT(temp, desc);
            SelectOutline.solidcolorID = temp;
            ConfigureTarget(temp);

            ConfigureClear(ClearFlag.All, Color.black);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("OutlineColorPass");

            cmd.SetGlobalColor("_OutlineColor", mysetting.color);

            //绘制设定
            var draw = CreateDrawingSettings(shaderTag, ref renderingData,
                renderingData.cameraData.defaultOpaqueSortFlags);

            draw.overrideMaterial = mysetting.mymat;
            draw.overrideMaterialPassIndex = 0;

            //开始绘制（准备好了绘制设定和过滤设定）
            context.DrawRenderers(renderingData.cullResults, ref draw, ref filter);
            context.ExecuteCommandBuffer(cmd);

            CommandBufferPool.Release(cmd);
        }
    }

    //第二个pass 计算颜色

    class Calculate : ScriptableRenderPass
    {
        setting mysetting = null;

        OutlineRenderFeature SelectOutline = null;

        struct LEVEL //
        {
            public int down;
            public int up;
        };

        LEVEL[] my_level;
        int maxLevel = 16;

        RenderTargetIdentifier sour;

        public Calculate(setting setting, OutlineRenderFeature render, RenderTargetIdentifier source)
        {
            mysetting = setting;
            SelectOutline = render;
            sour = source;
            my_level = new LEVEL[maxLevel];

            for (int t = 0; t < maxLevel; t++) //申请32个ID的，up和down各16个，用这个id去代替临时RT来使用
            {
                my_level[t] = new LEVEL
                {
                    down = Shader.PropertyToID("_OutlineBlurMipDown" + t),
                    up = Shader.PropertyToID("_OutlineBlurMipUp" + t)
                };
            }

            if (mysetting.ColorType == TYPE.INcolorON)
            {
                mysetting.mymat.EnableKeyword("_INCOLORON");
                mysetting.mymat.DisableKeyword("_INCOLOROFF");
            }

            else
            {
                mysetting.mymat.EnableKeyword("_INCOLOROFF");
                mysetting.mymat.DisableKeyword("_INCOLORON");
            }
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("OutlinePass");
            RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
            int SourID = Shader.PropertyToID("_OutlineSourTex");

            cmd.GetTemporaryRT(SourID, desc);
            cmd.CopyTexture(sour, SourID);

            //计算双重kawase模糊
            int BlurID = Shader.PropertyToID("_OutlineBlurTex");
            cmd.GetTemporaryRT(BlurID, desc);
            
            cmd.SetGlobalFloat("_OutlineBlur",mysetting.blur);

            int width = desc.width / 2;
            int height = desc.height / 2;
            int LastDown = SelectOutline.solidcolorID;

            for (int t = 0; t < mysetting.passloop; t++)
            {
                int midDown = my_level[t].down; //middle down，即间接计算down的工具人ID
                int midUp = my_level[t].up; //middle Up，即间接计算的up工具人ID
                cmd.GetTemporaryRT(midDown, width, height, 0, FilterMode.Bilinear,
                    RenderTextureFormat.ARGB32); //对指定高宽申请RT，每个循环的指定RT都会变小为原来一半
                cmd.GetTemporaryRT(midUp, width, height, 0, FilterMode.Bilinear,
                    RenderTextureFormat.ARGB32); //同上，但是这里申请了并未计算，先把位置霸占了，这样在UP的循环里就不用申请RT了
                cmd.Blit(LastDown, midDown, mysetting.mymat, 1); //计算down的pass
                LastDown = midDown; //工具人辛苦了
                width = Mathf.Max(width / 2, 1); //每次循环都降尺寸
                height = Mathf.Max(height / 2, 1);
            }

            //up
            int lastUp = my_level[mysetting.passloop - 1].down; //把down的最后一次图像当成up的第一张图去计算up

            for (int j = mysetting.passloop - 2; j >= 0; j--) //这里减2是因为第一次已经有了要减去1，但是第一次是直接复制的，所以循环完后还得补一次up
            {
                int midUp = my_level[j].up;
                cmd.Blit(lastUp, midUp, mysetting.mymat, 2);
                lastUp = midUp;
            }

            cmd.Blit(lastUp, BlurID, mysetting.mymat, 2); //补一个up，顺便在模糊一下
            cmd.Blit(SelectOutline.solidcolorID, sour, mysetting.mymat, 3); //在第4个pass里合并所有图像

            context.ExecuteCommandBuffer(cmd);

            //回收
            for (int k = 0; k < mysetting.passloop; k++)
            {
                cmd.ReleaseTemporaryRT(my_level[k].up);
                cmd.ReleaseTemporaryRT(my_level[k].down);
            }

            cmd.ReleaseTemporaryRT(BlurID);
            cmd.ReleaseTemporaryRT(SourID);
            cmd.ReleaseTemporaryRT(SelectOutline.solidcolorID);

            CommandBufferPool.Release(cmd);
        }
    }

    DrawSoildColorPass m_DrawSoildColorPass;

    Calculate m_Calculate;

    public override void Create()
    {
        m_DrawSoildColorPass = new DrawSoildColorPass(mysetting, this);
        m_DrawSoildColorPass.renderPassEvent = RenderPassEvent.AfterRenderingPrePasses;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (mysetting.mymat != null)
        {
            RenderTargetIdentifier sour = renderer.cameraColorTarget;
            renderer.EnqueuePass(m_DrawSoildColorPass);
            m_Calculate = new Calculate(mysetting, this, sour);
            m_Calculate.renderPassEvent = mysetting.passEvent;
            renderer.EnqueuePass(m_Calculate);
        }

        else
        {
            Debug.LogError("材质球丢失！请设置材质球");
        }
    }
}