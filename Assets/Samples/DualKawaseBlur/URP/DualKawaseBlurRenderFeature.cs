using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DualKawaseBlurRenderFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class mysetting //定义一个设置的类
    {
        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingTransparents; //默认插到透明完成后
        public Material mymat;

        [Range(1, 8)] public int downsample = 2;

        [Range(2, 8)] public int loop = 2;

        [Range(0.5f, 5f)] public float blur = 0.5f;

        public string RenderFeatherName = "DualKawaseBlurPass"; //render feature的名字
    }

    public mysetting setting = new mysetting();

    class CustomRenderPass : ScriptableRenderPass //自定义pass
    {
        public Material passMat = null;

        public int passdownsample = 2; //降采样

        public int passloop = 2; //模糊的迭代次数

        public float passblur = 4;

        private RenderTargetIdentifier passSource { get; set; }
        
        string RenderFeatherName; //feather名

        struct LEVEL //
        {
            public int down;
            public int up;
        };

        LEVEL[] my_level;
        
        public CustomRenderPass(string name) //构造函数
        {
            RenderFeatherName = name;
        }

        public void setup(RenderTargetIdentifier sour) //初始化，接收render feather传的图
        {
            this.passSource = sour;
            my_level = new LEVEL[passloop];

            for (int t = 0; t < passloop; t++)
            {
                my_level[t] = new LEVEL
                {
                    down = Shader.PropertyToID("_BlurMipDown" + t),
                    up = Shader.PropertyToID("_BlurMipUp" + t)
                };
            }
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) //执行
        {
            CommandBuffer cmd = CommandBufferPool.Get(RenderFeatherName); //定义cmd
            
            cmd.SetGlobalFloat(DualKawaseBlur, passblur); //指定材质参数
            //cmd.SetGlobalFloat("_Blur",passblur);//设置模糊,但是我不想全局设置怕影响其他的shader，所以注销它了用上面那个，但是cmd这个性能可能好些？

            RenderTextureDescriptor opaquedesc = renderingData.cameraData.cameraTargetDescriptor; //定义屏幕图像参数结构体
            int width = opaquedesc.width / passdownsample; //第一次降采样是使用的参数，后面就是除2去降采样了
            int height = opaquedesc.height / passdownsample;
            opaquedesc.depthBufferBits = 0;

            //down
            RenderTargetIdentifier LastDown = passSource; //把初始图像作为lastdown的起始图去计算

            for (int t = 0; t < passloop; t++)
            {
                int midDown = my_level[t].down; //middle down，即间接计算down的工具人ID
                int midUp = my_level[t].up; //middle Up，即间接计算的up工具人ID

                cmd.GetTemporaryRT(midDown, width, height, 0, FilterMode.Bilinear,
                    RenderTextureFormat.ARGB32); //对指定高宽申请RT，每个循环的指定RT都会变小为原来一半
                cmd.GetTemporaryRT(midUp, width, height, 0, FilterMode.Bilinear,
                    RenderTextureFormat.ARGB32); //同上，但是这里申请了并未计算，先把位置霸占了，这样在UP的循环里就不用申请RT了

                cmd.Blit(LastDown, midDown, passMat, 0); //计算down的pass
                LastDown = midDown; //工具人辛苦了
                width = Mathf.Max(width / 2, 1); //每次循环都降尺寸
                height = Mathf.Max(height / 2, 1);
            }

            //up
            int lastUp = my_level[passloop - 1].down; //把down的最后一次图像当成up的第一张图去计算up

            for (int j = passloop - 2; j >= 0; j--) //这里减2是因为第一次已经有了要减去1，但是第一次是直接复制的，所以循环完后还得补一次up
            {
                int midUp = my_level[j].up;
                cmd.Blit(lastUp, midUp, passMat, 1); //这里直接开干就是因为在down过程中已经把RT的位置霸占好了，这里直接用，不虚
                lastUp = midUp; //工具人辛苦了
            }

            cmd.Blit(lastUp, passSource, passMat, 1); //补一次up，顺便就输出了
            for (int k = 0; k < passloop; k++) //清RT，防止内存泄漏
            {
                cmd.ReleaseTemporaryRT(my_level[k].up);
                cmd.ReleaseTemporaryRT(my_level[k].down);
            }

            context.ExecuteCommandBuffer(cmd); //执行命令缓冲区的该命令
            CommandBufferPool.Release(cmd); //释放cmd
        }
    }

    CustomRenderPass mypass;
    private static readonly int DualKawaseBlur = Shader.PropertyToID("_DualKawaseBlur");

    public override void Create() //进行初始化,这里最先开始
    {
        mypass = new CustomRenderPass(setting.RenderFeatherName); //实例化一下并传参数,name就是tag

        mypass.renderPassEvent = setting.passEvent;

        mypass.passblur = setting.blur;

        mypass.passloop = setting.loop;

        mypass.passMat = setting.mymat;

        mypass.passdownsample = setting.downsample;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) //传值到pass里
    {
        mypass.setup(renderer.cameraColorTarget);

        renderer.EnqueuePass(mypass);
    }
}