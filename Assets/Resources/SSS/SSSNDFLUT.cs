using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class SSSNDFLUT : MonoBehaviour
{
    private RenderTexture NDFLUTRT;
    
    public enum Quality
    {
        low = 256,
        middle = 1024,
        high = 2048,
        veryHigh = 4096
    }
    public Quality quality = Quality.middle;
    private int resolution;
    private Texture2D NDFLUTTex;
    public TextureWrapMode texWrapMode = TextureWrapMode.Clamp;
    public bool isSRGB = false;
    
    void Start()
    {
        if (NDFLUTRT != null) RenderTexture.ReleaseTemporary(NDFLUTRT);
        if (NDFLUTTex != null) Texture2D.Destroy(NDFLUTTex);
        ComputeShader computeShader = Resources.Load<ComputeShader>("SSS/CS_SSSNDFLUT");
        if (computeShader == null)
        {
            Debug.LogError("SSS NDF LUT compute shader is missing");
        }
        
        resolution = (int)quality;
        
        NDFLUTRT = RenderTexture.GetTemporary(resolution, resolution, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        NDFLUTRT.enableRandomWrite = true;
        NDFLUTTex = new Texture2D(resolution, resolution, TextureFormat.RFloat, true, true);
        
        var kernelIndex = computeShader.FindKernel("SSSNDFLUT");
        computeShader.SetTexture(kernelIndex, "_RW_OutputTex", NDFLUTRT);
        computeShader.SetVector("_NDFLUTSize", new Vector4(resolution, resolution, 1f / resolution, 1f / resolution));
        computeShader.Dispatch(kernelIndex, resolution / 8, resolution / 8, 1);
        
        RenderTexture.active = NDFLUTRT;
        NDFLUTTex.ReadPixels(new Rect(0, 0, resolution, resolution), 0, 0);
        RenderTexture.active = null;

        var savePath = "Assets/Resources/SSS/SSSNDFLut.jpg";
        System.IO.File.WriteAllBytes("Assets/Resources/SSS/SSSNDFLut.jpg", NDFLUTTex.EncodeToJPG());
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
        RenderTexture.ReleaseTemporary(NDFLUTRT);
        Texture2D.Destroy(NDFLUTTex);
    }
}
