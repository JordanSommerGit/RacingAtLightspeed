using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WorldState : MonoBehaviour
{
    [SerializeField]
    private float speedOfLight = 100;
    public float SpeedOfLight { get => speedOfLight; }

    private Player player = null;

    private void Start()
    {
        player = FindObjectOfType<Player>();
    }

    private void Update()
    {
        Debug.Log("Beta: " + player.speed / speedOfLight);
        Shader.SetGlobalFloat("_LightSpeed", speedOfLight);
        Shader.SetGlobalFloat("_WorldTime", Time.time);
    }
}
