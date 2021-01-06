using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Player : MonoBehaviour
{
    [SerializeField]
    private float maxSpeed = 3.0f;
    [SerializeField]
    private float speedIncrease = 10.0f;
    [SerializeField]
    private float drag = 5.0f;
    [SerializeField]
    private float lookSpeed = 1.5f;
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

        //Input
        Vector3 movement = Vector2.zero;
        if (Input.GetKey(KeyCode.W))
            movement.z++;
        if (Input.GetKey(KeyCode.S))
            movement.z--;
        if (Input.GetKey(KeyCode.A))
            movement.x--;
        if (Input.GetKey(KeyCode.D))
            movement.x++;
        if (Input.GetKey(KeyCode.Space))
            movement.y++;
        if (Input.GetKey(KeyCode.LeftControl))
            movement.y--;
        movement = movement.normalized;
        movement = transform.rotation * movement;

        //Movement
        if (rigid.velocity.magnitude < maxSpeed)
            rigid.velocity += movement * speedIncrease * Time.deltaTime;
        else
            rigid.velocity -= rigid.velocity.normalized * drag * Time.deltaTime;

        if (movement.magnitude == 0.0f)
            rigid.velocity -= rigid.velocity.normalized * drag * Time.deltaTime;


        velocity = rigid.velocity;
        speed = velocity.magnitude;

        float yaw = Input.GetAxis("Mouse X");
        float pitch = Input.GetAxis("Mouse Y");
        transform.eulerAngles = new Vector3(transform.eulerAngles.x - pitch * lookSpeed, transform.eulerAngles.y + yaw * lookSpeed, 0);

        //Shader
        Shader.SetGlobalVector("_PlayerVelocity", new Vector4(velocity.x, velocity.y, velocity.z, 1));
        Shader.SetGlobalFloat("_PlayerSpeed", velocity.magnitude);
        Shader.SetGlobalVector("_PlayerOffset", new Vector4(transform.position.x, transform.position.y, transform.position.z, 1));
        Quaternion velocityRotation = Quaternion.FromToRotation(velocity, Vector3.right);
        Shader.SetGlobalMatrix("_VelocityRotation", Matrix4x4.TRS(Vector3.zero, velocityRotation, Vector3.one));
        Shader.SetGlobalMatrix("_InverseVelocityRotation", Matrix4x4.TRS(Vector3.zero, velocityRotation, Vector3.one).inverse);
    }
}
