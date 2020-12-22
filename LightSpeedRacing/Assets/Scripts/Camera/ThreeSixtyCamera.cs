using UnityEngine;

public class ThreeSixtyCamera : MonoBehaviour
{
    [SerializeField]
    private RenderTexture cubeMap = null;
    [SerializeField]
    private RenderTexture equirectTexture = null;

    private void Update()
    {
        if (!cubeMap || !equirectTexture)
            return;
        Camera.main.RenderToCubemap(cubeMap, 63, Camera.MonoOrStereoscopicEye.Mono);
        cubeMap.ConvertToEquirect(equirectTexture, Camera.MonoOrStereoscopicEye.Mono);
    }
}
