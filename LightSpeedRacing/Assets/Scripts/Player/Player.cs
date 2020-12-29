﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Player : MonoBehaviour
{
    [SerializeField]
    private float maxSpeed = 3.0f;
    [SerializeField]
    private float speedIncrease = 10.0f;
    public Vector3 velocity = Vector3.zero;
    public float speed = 0.0f;

    Rigidbody rigid = null;

    private void Awake()
    {
        rigid = GetComponent<Rigidbody>();
    }

    private void Update()
    {
        if (!rigid)
            return;

        Vector2 movement = Vector2.zero;
        if (Input.GetKey(KeyCode.W))
            movement.y++;
        if (Input.GetKey(KeyCode.S))
            movement.y--;
        if (Input.GetKey(KeyCode.A))
            movement.x--;
        if (Input.GetKey(KeyCode.D))
            movement.x++;
        movement = movement.normalized;

        if (rigid.velocity.magnitude < maxSpeed)
            rigid.velocity += new Vector3(movement.x, 0, movement.y) * speedIncrease * Time.deltaTime;
        else
            if (movement.magnitude != 0)
                rigid.velocity = new Vector3(movement.x, 0, movement.y) * maxSpeed;

        velocity = rigid.velocity;
        speed = velocity.magnitude;

        Shader.SetGlobalVector("_PlayerVelocity", new Vector4(velocity.x, velocity.y, velocity.z, 1));
        Shader.SetGlobalFloat("_PlayerSpeed", velocity.magnitude);
        Shader.SetGlobalVector("_PlayerOffset", new Vector4(transform.position.x, transform.position.y, transform.position.z, 1));
        Quaternion velocityRotation = Quaternion.FromToRotation(velocity, Vector3.right);
        Shader.SetGlobalMatrix("_VelocityRotation", Matrix4x4.TRS(Vector3.zero, velocityRotation, Vector3.one));
        Shader.SetGlobalMatrix("_InverseVelocityRotation", Matrix4x4.TRS(Vector3.zero, velocityRotation, Vector3.one).inverse);
    }
}
