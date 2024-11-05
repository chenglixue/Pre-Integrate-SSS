using System.Collections;
using System.Collections.Generic;
using UnityEditor.iOS;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteAlways]
public class SSS : MonoBehaviour
{
    public Shader m_SSSShader;
    public Texture2D m_PreIntegrateLUTTex;
    public Texture2D m_NDFLUTTex;
    
    void Start()
    {
        m_PreIntegrateLUTTex = Resources.Load<Texture2D>("SSS/PreIntegrateSSSLut");
        m_NDFLUTTex = Resources.Load<Texture2D>("SSS/SSSNDFLut");
        m_SSSShader = Shader.Find("Elysia/S_PBR");
        if (m_PreIntegrateLUTTex == null)
        {
            Debug.LogError("Pre Integrate LUT Tex miss");
            return;
        }
        if (m_NDFLUTTex == null)
        {
            Debug.LogError("NDF LUT Tex miss");
            return;
        }
        if (m_SSSShader == null)
        {
            Debug.LogError("SSS Shader miss");
            return;
        }
    }
    
    void Update()
    {
        Shader.SetGlobalTexture(Shader.PropertyToID("_PreIntegrateSSSLutTex"), m_PreIntegrateLUTTex);
        Shader.SetGlobalTexture(Shader.PropertyToID("_SSSNDFLutTex"), m_NDFLUTTex);
    }
}
