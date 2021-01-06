using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HUD : MonoBehaviour
{
    [SerializeField]
    private ProgressBar speedBar = null;
    [SerializeField]
    private DynamicText lightSpeedText = null;
    [SerializeField]
    private DynamicText playerSpeedText = null;

    private Player player = null;
    private WorldState worldState = null;

    private void Start()
    {
        player = FindObjectOfType<Player>();
        worldState = FindObjectOfType<WorldState>();
    }

    private void Update()
    {
        if (speedBar)
            speedBar.UpdateBar(player.velocity.magnitude / worldState.SpeedOfLight);

        if (lightSpeedText)
            lightSpeedText.UpdateText(worldState.SpeedOfLight.ToString("F2"));

        if (playerSpeedText)
            playerSpeedText.UpdateText(player.velocity.magnitude.ToString("F2"));
    }
}
