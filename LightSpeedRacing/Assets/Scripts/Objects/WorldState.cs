using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WorldState : MonoBehaviour
{
    [SerializeField]
    private const float speedOfLight = 100;
    public float SpeedOfLight { get => speedOfLight; }
}
