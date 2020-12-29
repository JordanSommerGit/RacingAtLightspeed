using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RelativisticSkyBox : MonoBehaviour
{
    private Player player = null;
    private WorldState worldState = null;
    MeshRenderer rend;

    void Start()
    {
        player = FindObjectOfType<Player>();
        worldState = FindObjectOfType<WorldState>();
        rend = GetComponent<MeshRenderer>();
    }

    void Update()
    {
        if (!player || !worldState)
            return;
        rend.material.SetVector("_PlayerVelocity", player.velocity);
        rend.material.SetFloat("_PlayerSpeed", player.speed);
        rend.material.SetFloat("_SpeedOverSpeedOfLight", player.speed / worldState.SpeedOfLight);
    }
}
