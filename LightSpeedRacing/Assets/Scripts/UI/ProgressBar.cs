using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ProgressBar : MonoBehaviour
{
    [SerializeField]
    private Image bar = null;

    public void UpdateBar(float percentage)
    {
        if (bar)
            bar.fillAmount = percentage;
    }
}
