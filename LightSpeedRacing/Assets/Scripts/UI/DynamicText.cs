using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class DynamicText : MonoBehaviour
{
    [SerializeField]
    private Text text = null;

    public void UpdateText(string newText)
    {
        text.text = newText;
    }
}
