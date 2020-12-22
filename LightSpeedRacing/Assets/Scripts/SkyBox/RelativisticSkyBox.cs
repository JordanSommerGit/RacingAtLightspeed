using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RelativisticSkyBox : MonoBehaviour
{
    private Player player = null;
    MeshRenderer rend;

    void Start()
    {
        player = FindObjectOfType<Player>();
        rend = GetComponent<MeshRenderer>();
    }

    void Update()
    {
        rend.material.SetVector("_PlayerVelocity", player.velocity);
        rend.material.SetFloat("_PlayerSpeed", player.speed);
        rend.material.SetFloat("_SpeedOverSpeedOfLight", player.speed / player.speedOfLight);
    }
}
