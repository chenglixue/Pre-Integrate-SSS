using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

public class PreIntegrateSSSLUT : MonoBehaviour
{
    private RenderTexture SSSLUTRT;
    
    public enum Quality
    {
        low = 256,
        middle = 1024,
        high = 2048,
        veryHigh = 4096
    }
    public Quality quality = Quality.middle;
    private int resolution;
    private Texture2D SSSLUT;
    public TextureWrapMode texWrapMode = TextureWrapMode.Clamp;
    public bool isSRGB = false;
    
    
    void Start()
    {
        if (SSSLUTRT != null) RenderTexture.ReleaseTemporary(SSSLUTRT);
        if (SSSLUT != null) Texture2D.Destroy(SSSLUT);
        ComputeShader computeShader = Resources.Load<ComputeShader>("SSS/CS_PreIntegrateSSSLUT");
        if (computeShader == null)
        {
            Debug.LogError("PreIntegrateSSSLUT compute shader is missing");
        }

        resolution = (int)quality;

        SSSLUTRT = RenderTexture.GetTemporary(resolution, resolution, 0, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear);
        SSSLUTRT.enableRandomWrite = true;
        SSSLUT = new Texture2D(resolution, resolution, TextureFormat.RGB24, true, true);
        
        var kernelIndex = computeShader.FindKernel("PreIntegrateSSSLUT");
        computeShader.SetTexture(kernelIndex, "_RW_OutputTex", SSSLUTRT);
        computeShader.SetVector("_SSSLUTSize", new Vector4(resolution, resolution, 1f / resolution, 1f / resolution));
        computeShader.Dispatch(kernelIndex, resolution / 8, resolution / 8, 1);

        RenderTexture.active = SSSLUTRT;
        SSSLUT.ReadPixels(new Rect(0, 0, resolution, resolution), 0, 0);
        RenderTexture.active = null;

        var savePath = "Assets/Resources/SSS/PreIntegrateSSSLut.jpg";
        System.IO.File.WriteAllBytes(savePath, SSSLUT.EncodeToJPG());
        AssetDatabase.ImportAsset(savePath);
        var importer = AssetImporter.GetAtPath(savePath) as TextureImporter;
        importer.sRGBTexture = isSRGB;
        importer.maxTextureSize = resolution;
        importer.textureCompression = TextureImporterCompression.Uncompressed;
        importer.wrapMode = texWrapMode;
        importer.SaveAndReimport();
    }

    private void OnDestroy()
    {
        RenderTexture.ReleaseTemporary(SSSLUTRT);
        Texture2D.Destroy(SSSLUT);
    }
}
