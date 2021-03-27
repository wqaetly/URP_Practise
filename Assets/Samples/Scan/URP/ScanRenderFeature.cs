using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ScanRenderFeature : ScriptableRendererFeature
{
    public enum ax
    {
        X,
        Y,
        Z
    }

    [System.Serializable]
    public class setting
    {
        public Material mat = null;

        public RenderPassEvent Event = RenderPassEvent.AfterRenderingTransparents;

        [ColorUsage(true, true)] public Color ColorX = Color.white;

        [ColorUsage(true, true)] public Color ColorY = Color.white;

        [ColorUsage(true, true)] public Color ColorZ = Color.white;

        [ColorUsage(true, true)] public Color ColorEdge = Color.white;

        [ColorUsage(true, true)] public Color ColorOutline = Color.white;

        [Range(0, 0.2f), Tooltip("线框宽度")] public float Width = 0.1f;

        [Range(0.1f, 10), Tooltip("线框间距")] public float Spacing = 1;

        [Range(0, 10), Tooltip("滚动速度")] public float Speed = 1;

        [Range(0, 3), Tooltip("边缘采样半径")] public float EdgeSample = 1;

        [Range(0, 3), Tooltip("法线灵敏度")] public float NormalSensitivity = 1;

        [Range(0, 3), Tooltip("深度灵敏度")] public float DepthSensitivity = 1;


        [Tooltip("特效方向")] public ax AXIS;
    }

    public setting mysetting = new setting();

    class CustomRenderPass : ScriptableRenderPass
    {
        public Material mat = null;

        RenderTargetIdentifier sour;

        public Color ColorX = Color.white;

        public Color ColorY = Color.white;

        public Color ColorZ = Color.white;

        public Color ColorEdge = Color.white;

        public Color ColorOutline = Color.white;

        public float Width = 0.05f;

        public float Spacing = 2;

        public float Speed = 0.7f;

        public float EdgeSample = 1;

        public float NormalSensitivity = 1;

        public float DepthSensitivity = 1;

        public ax AXIS;

        public void set(RenderTargetIdentifier sour)
        {
            this.sour = sour;

            mat.SetColor("_colorX", ColorX);
            mat.SetColor("_colorY", ColorY);
            mat.SetColor("_colorZ", ColorZ);
            mat.SetColor("_ColorEdge", ColorEdge);
            mat.SetColor("_OutlineColor", ColorOutline);
            mat.SetFloat("_width", Width);
            mat.SetFloat("_Spacing", Spacing);
            mat.SetFloat("_Speed", Speed);
            mat.SetFloat("_EdgeSample", EdgeSample);
            mat.SetFloat("_NormalSensitivity", NormalSensitivity);
            mat.SetFloat("_DepthSensitivity", DepthSensitivity);

            if (AXIS == ax.X)
            {
                mat.DisableKeyword("_AXIS_Y");
                mat.DisableKeyword("_AXIS_Z");
                mat.EnableKeyword("_AXIS_X");
            }

            else if (AXIS == ax.Y)
            {
                mat.DisableKeyword("_AXIS_Z");
                mat.DisableKeyword("_AXIS_X");
                mat.EnableKeyword("_AXIS_Y");
            }

            else
            {
                mat.DisableKeyword("_AXIS_X");
                mat.DisableKeyword("_AXIS_Y");
                mat.EnableKeyword("_AXIS_Z");
            }
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            int temp = Shader.PropertyToID("temp");

            CommandBuffer cmd = CommandBufferPool.Get("扫描特效");

            RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
            //构建摄像机到深度的射线向量，存储在矩阵里，用于重建世界坐标
            {
                Camera cam = renderingData.cameraData.camera;

                float height = cam.nearClipPlane * Mathf.Tan(Mathf.Deg2Rad * cam.fieldOfView * 0.5f);
                Vector3 up = cam.transform.up * height;
                Vector3 right = cam.transform.right * height * cam.aspect;
                Vector3 forward = cam.transform.forward * cam.nearClipPlane;
                Vector3 ButtomLeft = forward - right - up;

                float scale = ButtomLeft.magnitude / cam.nearClipPlane;

                ButtomLeft.Normalize();
                ButtomLeft *= scale;
                Vector3 ButtomRight = forward + right - up;
                ButtomRight.Normalize();
                ButtomRight *= scale;
                Vector3 TopRight = forward + right + up;
                TopRight.Normalize();
                TopRight *= scale;
                Vector3 TopLeft = forward - right + up;
                TopLeft.Normalize();
                TopLeft *= scale;

                Matrix4x4 MATRIX = new Matrix4x4();

                MATRIX.SetRow(0, ButtomLeft);
                MATRIX.SetRow(1, ButtomRight);
                MATRIX.SetRow(2, TopRight);
                MATRIX.SetRow(3, TopLeft);

                mat.SetMatrix("Matrix", MATRIX);
            }
            
            cmd.GetTemporaryRT(temp, desc);
            cmd.Blit(sour, temp, mat);
            cmd.Blit(temp, sour);
            context.ExecuteCommandBuffer(cmd);

            cmd.ReleaseTemporaryRT(temp);

            CommandBufferPool.Release(cmd);
        }
    }

    CustomRenderPass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass();

        m_ScriptablePass.mat = mysetting.mat;

        m_ScriptablePass.renderPassEvent = mysetting.Event;

        m_ScriptablePass.ColorX = mysetting.ColorX;

        m_ScriptablePass.ColorY = mysetting.ColorY;

        m_ScriptablePass.ColorZ = mysetting.ColorZ;

        m_ScriptablePass.ColorEdge = mysetting.ColorEdge;

        m_ScriptablePass.ColorOutline = mysetting.ColorOutline;

        m_ScriptablePass.Width = mysetting.Width;

        m_ScriptablePass.Spacing = mysetting.Spacing;

        m_ScriptablePass.Speed = mysetting.Speed;

        m_ScriptablePass.EdgeSample = mysetting.EdgeSample;

        m_ScriptablePass.NormalSensitivity = mysetting.NormalSensitivity;

        m_ScriptablePass.DepthSensitivity = mysetting.DepthSensitivity;

        m_ScriptablePass.AXIS = mysetting.AXIS;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        m_ScriptablePass.set(renderer.cameraColorTarget);
        renderer.EnqueuePass(m_ScriptablePass);
    }
}