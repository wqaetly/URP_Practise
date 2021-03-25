using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RadialBlurRenderFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class mysetting //定义一个设置的类
    {
        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingTransparents; //默认插到透明完成后
        public Material mymat;

        public Vector2 radialCenter = new Vector2(0.5f, 0.5f);

        public int loop = 2;

        [Range(0f, 1f)] public float radialblurRadius = 0.5f;

        public string RenderFeatherName = "RadialBlurPass"; //render feature的名字
    }

    public mysetting setting = new mysetting();

    class CustomRenderPass : ScriptableRenderPass //自定义pass
    {
        public Material passMat = null;

        public int passloop = 2; //模糊的迭代次数
        public Vector2 radialCenter;
        public float radialblurRadius = 4;

        private RenderTargetIdentifier passSource { get; set; }

        private static readonly int s_RadialBlurTempTexture = Shader.PropertyToID("_RadialBlurTempTexture");
        private static readonly int s_RadialBlurRadius = Shader.PropertyToID("_RadialBlurRadius");
        private static readonly int s_RadialBlurLoopCount = Shader.PropertyToID("_RadialBlurLoopCount");
        private static readonly int s_RadialBlurCenter = Shader.PropertyToID("_RadialBlurCenter");


        string RenderFeatherName; //feather名

        public CustomRenderPass(string name) //构造函数
        {
            RenderFeatherName = name;
        }

        public void setup(RenderTargetIdentifier sour) //初始化，接收render feather传的图
        {
            this.passSource = sour;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) //执行
        {
            CommandBuffer cmd = CommandBufferPool.Get(RenderFeatherName); //定义cmd

            cmd.SetGlobalInt(s_RadialBlurLoopCount, this.passloop); //指定材质参数
            cmd.SetGlobalFloat(s_RadialBlurRadius, this.radialblurRadius*0.02f);
            cmd.SetGlobalVector(s_RadialBlurCenter, this.radialCenter);

            RenderTextureDescriptor opaquedesc = renderingData.cameraData.cameraTargetDescriptor; //定义屏幕图像参数结构体
            int width = opaquedesc.width ; //第一次降采样是使用的参数，后面就是除2去降采样了
            int height = opaquedesc.height ;
            opaquedesc.depthBufferBits = 0;

            cmd.GetTemporaryRT(s_RadialBlurTempTexture, width, height, 0, FilterMode.Bilinear,
                RenderTextureFormat.ARGB32);

            cmd.Blit(passSource, s_RadialBlurTempTexture, passMat); //补一次up，顺便就输出了
            cmd.Blit(s_RadialBlurTempTexture, passSource); //补一次up，顺便就输出了

            cmd.ReleaseTemporaryRT(s_RadialBlurTempTexture);

            context.ExecuteCommandBuffer(cmd); //执行命令缓冲区的该命令
            CommandBufferPool.Release(cmd); //释放cmd
        }
    }

    CustomRenderPass mypass;

    public override void Create() //进行初始化,这里最先开始
    {
        mypass = new CustomRenderPass(setting.RenderFeatherName); //实例化一下并传参数,name就是tag

        mypass.renderPassEvent = setting.passEvent;

        mypass.radialblurRadius = setting.radialblurRadius;

        mypass.passloop = setting.loop;

        mypass.passMat = setting.mymat;

        mypass.radialCenter = setting.radialCenter;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) //传值到pass里
    {
        mypass.setup(renderer.cameraColorTarget);

        renderer.EnqueuePass(mypass);
    }
}