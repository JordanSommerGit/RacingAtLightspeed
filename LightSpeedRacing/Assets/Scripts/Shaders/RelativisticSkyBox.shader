Shader "Relativistic/RelativisticSkyBox"
{
    Properties
    {
        _Cube("CubeMap", Cube) = "" {}
        _PlayerVelocity("PlayerVelocity", Vector) = (0, 0, 0)
        _PlayerSpeed("PlayerSpeed", Float) = 0
        _SpeedOverSpeedOfLight("SpeedOverSpeedOfLight", Float) = 0
        _DopplerFraction("DopplerFraction", Float) = 1
        _SphereSize("SphereSize", Float) = 1
        
    }
    SubShader
    {
        Tags { "Queue" = "Background" }

        Pass
        {
            ZWrite Off
            Cull Front

            CGPROGRAM

            #pragma vertex vert  
            #pragma fragment frag 

            #include "UnityCG.cginc"

            uniform samplerCUBE _Cube;

            float4 _PlayerVelocity;
            float _PlayerSpeed;
            float _SpeedOverSpeedOfLight;
            float _DopplerFraction;
            float _SphereSize;

            struct vertexInput
            {
               float4 vertex : POSITION;
            };

            struct vertexOutput
            {
               float4 pos : POSITION;
               float3 viewDir : TEXCOORD1;
            };

            vertexOutput vert(vertexInput input)
            {
               vertexOutput output;

               output.viewDir = mul(unity_ObjectToWorld, input.vertex).xyz - _WorldSpaceCameraPos;

               //float3 forward = float3(0, 0, 1);
               //float angleToVertex = dot(forward, input.vertex);

               //float newAngle = (cos(angleToVertex) + _SpeedOverSpeedOfLight)
               //    / (1 + _SpeedOverSpeedOfLight * cos(angleToVertex));

               float sigma = dot(input.vertex, input.vertex) / _SphereSize;
               float sigmaSquared = sigma * sigma;
               float vSquared = _PlayerSpeed * _PlayerSpeed;
               float cSquared = _SpeedOverSpeedOfLight * _SpeedOverSpeedOfLight;

               float rho = sqrt((1.0 - vSquared * (sigmaSquared + (1.0 - sigmaSquared) * cSquared)) / (1.0 - vSquared));
               float3 newpos = (((sigma + _PlayerSpeed * _SpeedOverSpeedOfLight * rho) / (sigma * _PlayerSpeed * _SpeedOverSpeedOfLight + rho) - sigma) * _SphereSize) * _PlayerVelocity + input.vertex;

               output.pos = UnityObjectToClipPos(_SphereSize * normalize(newpos));
               return output;
            }

            float4 frag(vertexOutput input) : COLOR
            {
               return texCUBE(_Cube, input.viewDir);
            }

            ENDCG
        }
    }
}