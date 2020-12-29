Shader "Relativistic/Relativity"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            //Color shift variables, used to make guassians for XYZ curves
            //Source: OpenRelativity
            #define xla 0.39952807612909519
            #define xlb 444.63156780935032
            #define xlc 20.095464678736523

            #define xha 1.1305579611401821
            #define xhb 593.23109262398259
            #define xhc 34.446036241271742

            #define ya 1.0098874822455657
            #define yb 556.03724875218927
            #define yc 46.184868454550838

            #define za 2.0648400466720593
            #define zb 448.45126344558236
            #define zc 22.357297606503543

            //Used to determine where to center UV/IR curves
            //Source: OpenRelativity
            #define IR_RANGE 400
            #define IR_START 700
            #define UV_RANGE 380
            #define UV_START 0

            float4 _PlayerVelocity = float4(0, 0, 0, 0);
            float _PlayerSpeed = 0;
            float4 _PlayerOffset = float4(0, 0, 0, 0);
            float _WorldTime = 0;
            float _LightSpeed = 100;
            float4x4 _VelocityRotation;
            float4x4 _InverseVelocityRotation;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float angle : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata input)
            {
                v2f o;


                o.vertex = mul(unity_ObjectToWorld, input.vertex);
                //Transform position so our player is the origin
                o.vertex -= _PlayerOffset;

                //Calculate angle for Dopplershift
                o.angle = acos(dot(normalize(_PlayerVelocity), normalize(o.vertex)));

                float4 pos = o.vertex;
                if (_PlayerSpeed != 0)
                {
                    //Rotate position towards velocity to make boost in X possible
                    pos = mul(pos, _VelocityRotation);
                    float4 rotatedVelocity = mul(_PlayerVelocity, _VelocityRotation);

                    //Calculate time
                    float rSquared = dot(pos, pos);
                    float vSquared = dot(rotatedVelocity, rotatedVelocity);
                    float rv = 2.0f * dot(pos, rotatedVelocity);
                    float d = dot(rotatedVelocity, rotatedVelocity) - pow(_LightSpeed, 2);

                    float vertexTime = (-2.0f * rv - (sqrt((rv * rv) - 4.0f * d * rSquared))) / (2.0f * d);

                    //Apply time dialation
                    pos -= rotatedVelocity * vertexTime;

                    //Apply Lorentz transformation
                    //pos.x = (pos.x - _PlayerSpeed * vertexTime) / sqrt(1 - pow(_PlayerSpeed, 2) / pow(_LightSpeed, 2));
                    float newz = (_PlayerSpeed * _LightSpeed) * vertexTime;
                    newz = pos.x + newz;
                    newz /= sqrt(1 - pow(_PlayerSpeed, 2) / pow(_LightSpeed, 2));
                    pos.x = newz;

                    //Rotate position back
                    pos = mul(pos, _InverseVelocityRotation);
                }

                //Invert offset
                pos += _PlayerOffset;

                pos = mul(unity_WorldToObject, float4(pos.x, pos.y, pos.z, 1));

                o.vertex = UnityObjectToClipPos(pos);
                o.uv = TRANSFORM_TEX(input.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float Linearize(float value)
            {
                float newValue = 0.0f;
                if (value < 0.04045f)
                    newValue = value / 12.92f;
                else
                    newValue = pow((value + 0.055f) / 1.055f, 2.4f);
                return newValue;
            }

            float3 RGBtoXYZ(float3 rgb)
            {
                float3 xyz = rgb;

                xyz.x = Linearize(xyz.x);
                xyz.y = Linearize(xyz.y);
                xyz.z = Linearize(xyz.z);

                float3x3 convM =
                {
                    0.4124564f, 0.3575761f, 0.1804375f,
                    0.2126729f, 0.7151522f, 0.0721750f,
                    0.0193339f, 0.1191920f, 0.9503041f
                };
                
                return mul(convM, xyz);
            }

            float Delinearize(float value)
            {
                float newValue = 0.0f;
                if (value < 0.0031308)
                    newValue = value * 12.92f;
                else
                    newValue = 1.055f * pow(value, 1.0f / 2.4f) - 0.055f;
                return newValue;
            }

            float3 XYZtoRGB(float3 xyz)
            {
                float3 rgb = xyz;

                float3x3 convM =
                {
                    3.2404542f, -1.5371385f, -0.4985314f,
                    -0.9692660, 1.8760108f, 0.0415560f,
                    0.0556434f, -0.2040259f, 1.0572252f
                };

                rgb = mul(convM, rgb);

                rgb.x = Delinearize(rgb.x);
                rgb.y = Delinearize(rgb.y);
                rgb.z = Delinearize(rgb.z);

                return rgb;
            }

            //Source: OpenRelativity
            float3 WeightFromXYZCurves(float3 xyz)
            {
                float3 weight;
                weight.x = 0.0735806 * xyz.x - 0.0380793 * xyz.y - 0.00860837 * xyz.z;
                weight.y = -0.0665378 * xyz.x + 0.134408 * xyz.y - 0.000417865 * xyz.z;
                weight.z = 0.00000299624 * xyz.x - 0.00000605249 * xyz.y + 0.0484424 * xyz.z;
                return weight;
            }

            //Source: OpenRelativity
            float GetXFromCurve(float3 param, float shift)
            {
                float top1 = param.x * xla * exp((float)(-(pow((param.y * shift) - xlb, 2)
                    / (2 * (pow(param.z * shift, 2) + pow(xlc, 2)))))) * sqrt(2.0f * 3.14159265358979323f);
                float bottom1 = sqrt((float)(1 / pow(param.z * shift, 2)) + (1 / pow(xlc, 2)));

                float top2 = param.x * xha * exp(float(-(pow((param.y * shift) - xhb, 2)
                    / (2 * (pow(param.z * shift, 2) + pow(xhc, 2)))))) * sqrt(2.0f * 3.14159265358979323f);
                float bottom2 = sqrt((float)(1 / pow(param.z * shift, 2)) + (1 / pow(xhc, 2)));

                return (top1 / bottom1) + (top2 / bottom2);
            }

            //Source: OpenRelativity
            float GetYFromCurve(float3 param, float shift)
            {
                float top = param.x * ya * exp(float(-(pow((param.y * shift) - yb, 2)
                    / (2 * (pow(param.z * shift, 2) + pow(yc, 2)))))) * sqrt(2.0f * 3.14159265358979323f);
                float bottom = sqrt((float)(1 / pow(param.z * shift, 2)) + (1 / pow(yc, 2)));

                return top / bottom;
            }

            //Source: OpenRelativity
            float GetZFromCurve(float3 param, float shift)
            {
                float top = param.x * za * exp(float(-(pow((param.y * shift) - zb, 2)
                    / (2 * (pow(param.z * shift, 2) + pow(zc, 2)))))) * sqrt(2.0f * 3.14159265358979323f);
                float bottom = sqrt((float)(1 / pow(param.z * shift, 2)) + (1 / pow(zc, 2)));

                return top / bottom;
            }

            float4 frag (v2f i) : SV_Target
            {
                //Sample
                float4 col = tex2D(_MainTex, i.uv);
                
                //Convert to XYZ
                float3 colXYZ = RGBtoXYZ(float3(col.x, col.y, col.z));

                //Calculate Doppler shift
                float dopplerShift = (1 - (_PlayerSpeed / _LightSpeed) * cos(i.angle))
                    / (sqrt(1 - pow(_PlayerSpeed / _LightSpeed, 2)));

                //Shift
                float3 weights = WeightFromXYZCurves(colXYZ);
                float3 rArgs = float3(weights.x, 615.f, 8.f);
                float3 gArgs = float3(weights.y, 550.f, 4.f);
                float3 bArgs = float3(weights.z, 463.f, 5.f);

                float x = pow((1 / dopplerShift), 3) * 
                    (GetXFromCurve(rArgs, dopplerShift) + GetXFromCurve(gArgs, dopplerShift) + GetXFromCurve(bArgs, dopplerShift));
                float y = pow((1 / dopplerShift), 3) * 
                    (GetYFromCurve(rArgs, dopplerShift) + GetYFromCurve(gArgs, dopplerShift) + GetYFromCurve(bArgs, dopplerShift));
                float z = pow((1 / dopplerShift), 3) * 
                    (GetZFromCurve(rArgs, dopplerShift) + GetZFromCurve(gArgs, dopplerShift) + GetZFromCurve(bArgs, dopplerShift));
                
                // Convert back into RGB
                colXYZ = XYZtoRGB(float3(x, y, z));

                //Constraint values
                colXYZ.x = clamp(colXYZ.x, 0.0f, 1.0f);
                colXYZ.y = clamp(colXYZ.y, 0.0f, 1.0f);
                colXYZ.z = clamp(colXYZ.z, 0.0f, 1.0f);
                
                return float4(colXYZ.x, colXYZ.y, colXYZ.z, col.w);
            }
            ENDCG
        }
    }
}
