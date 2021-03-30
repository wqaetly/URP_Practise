using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ComputeParticle : MonoBehaviour
{
    public struct particleData
    {
        public Vector3 position;
        public Vector4 color;
    }

    public Color color = Color.blue;
    [Range(0.5F, 10)] public float size = 2;

    public ComputeShader compute;
    public Material mymat;
    public MeshTopology mesh = MeshTopology.Points;
    public int count = 50000;
    ComputeBuffer Buffer;
    particleData[] datas;
    int stride;
    int kernelid;

    private void OnEnable()
    {
        //初始化
        int vector3stride = sizeof(float) * 3; //值为12 计算3个FLOAT的大小  1个单精度float是4字节
        int colorStride = sizeof(float) * 4; //4字节*4=16
        stride = vector3stride + colorStride; //统计一个结构体的长度  其值为12+16=28字节
        Buffer = new ComputeBuffer(count, stride); //count个粒子 每个粒子占用大小
        //Buffer=new ComputeBuffer(count,28);//这里吧stride改成28亦可
        kernelid = compute.FindKernel("ComputeParticle");

        //填充数据 给这几十万个粒子赋初始值
        datas = new particleData[count];
        for (int t = 0; t < datas.Length; t++)
        {
            datas[t] = new particleData();
        }

        Buffer.SetData(datas); //往buffer里填结构体数据
        compute.SetBuffer(kernelid, "outputData", Buffer); //把buffer里的数据传给compute shader去计算
        mymat.SetBuffer("inputbuffer", Buffer); // 把buffer的数据也传给vertex/fragment shader去渲染
    }

    private void OnRenderObject()
    {
        //发送数据
        color = Color.HSVToRGB(0.3f * Time.time - Mathf.Floor(0.3f * Time.time), 1, 1); //得到一个颜色变来变去的色彩
        compute.SetFloat("time", Time.time); //传时间
        compute.SetVector("mycolor", color); //传颜色
        compute.SetFloat("size", size); //传大小
        compute.Dispatch(kernelid, 5, 10, 100); //开始计算
        mymat.SetPass(0); //computeshader计算完后指定shader去渲染
        Graphics.DrawProceduralNow(mesh, Buffer.count); //制作绘制的网格内容和数量
    }

    private void OnDisable()
    {
        Buffer.Release();
        Buffer.Dispose();
    }
}