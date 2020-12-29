// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Relativistic/RelativisticShader"
{
	Properties
	{
		_MainTex("Main Texture", 2D) = "" {}
		_UVTex("Ultraviolet Texture",2D) = "" {}
		_IRTex("Infrared Texture",2D) = "" {}
	}

CGINCLUDE

#pragma glsl
#include "UnityCG.cginc"

// Color shift variables, used to make guassians for XYZ curves
// From OpenRelativity framework
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
#define IR_RANGE 400
#define IR_START 700
#define UV_RANGE 380
#define UV_START 0


	struct v2f
	{
		float4 pos : POSITION;
		float4 pos2 : TEXCOORD0; //World Position
		float2 uv1 : TEXCOORD1;
		float svc : TEXCOORD2; //sqrt( 1 - (v-c)^2)
	};


		//Variables that we use to access texture data
		sampler2D _Tex2D;

		float4 _PlayerVelocity = float4(0, 0, 0, 0); //velocity of player
		float4 _PlayerOffset = float4(0, 0, 0, 0); //player position in world
		float _LightSpeed = 100; //current speed of light
		float _colorShift = 1; //actually a boolean, should use color effects or not ( doppler + spotlight). 

		float xyr = 1; // xy ratio
		float xs = 1; // x scale

		v2f vert(appdata_img v)
		{
			v2f o;

			o.pos = mul(unity_ObjectToWorld, v.vertex); //get position in world frame	
			o.pos -= _PlayerOffset; //Shift such that we use a coordinate system where the player is at 0,0,0


			o.uv1.xy = v.texcoord; //get the UV coordinate for the current vertex, will be passed to fragment shade

			float speed = sqrt(pow((_PlayerVelocity.x), 2) + pow((_PlayerVelocity.y), 2) + pow((_PlayerVelocity.z), 2));

			// relative velocity calculation
			// no dynamic objects means, relative velocity = player velocity
			float4 vr = _PlayerVelocity * -1;
			//relative speed
			float speedr = sqrt(pow((vr.x), 2) + pow((vr.y), 2) + pow((vr.z), 2));
			o.svc = sqrt(1 - speedr * speedr);

			float4 riw = o.pos;

			if (speed != 0) // If speed is zero, rotation fails
			{
				float a;  //angle
				float ux;
				float uy;
				float ca; //cosine of a
				float sa; /// sine of a
				if (speed != 0)
				{
					//we're getting the angle between our z direction of movement and the world's Z axis
					a = -acos(-_PlayerVelocity.z / speed);
					if (_PlayerVelocity.x != 0 || _PlayerVelocity.y != 0)
					{
						ux = _PlayerVelocity.y / sqrt(_PlayerVelocity.x * _PlayerVelocity.x + _PlayerVelocity.y * _PlayerVelocity.y);
						uy = -_PlayerVelocity.x / sqrt(_PlayerVelocity.x * _PlayerVelocity.x + _PlayerVelocity.y * _PlayerVelocity.y);
					}
					else
					{
						ux = 0;
						uy = 0;
					}
					ca = cos(a);
					sa = sin(a);

					//And we rotate our point that much to make it as if our magnitude of velocity is in the Z direction
					riw.x = o.pos.x * (ca + ux * ux * (1 - ca)) + o.pos.y * (ux * uy * (1 - ca)) + o.pos.z * (uy * sa);
					riw.y = o.pos.x * (uy * ux * (1 - ca)) + o.pos.y * (ca + uy * uy * (1 - ca)) - o.pos.z * (ux * sa);
					riw.z = o.pos.x * (-uy * sa) + o.pos.y * (ux * sa) + o.pos.z * (ca);
				}

				float c = -(riw.x * riw.x + riw.y * riw.y + riw.z * riw.z);
				float d = (_LightSpeed * _LightSpeed);
				float tisw = (float)((-((float)4) * d * c)) / (((float)2) * d);

				//Apply Lorentz transform
				// float newz =(riw.z + state.PlayerVelocity * tisw) / state.SqrtOneMinusVSquaredCWDividedByCSquared;
				//I had to break it up into steps, unity was getting order of operations wrong.	
				float newz = (((float)speed * _LightSpeed) * tisw);

				newz = riw.z + newz;
				newz /= (float)sqrt(1 - (speed * speed));
				riw.z = newz;
				if (speed != 0)
				{
					float trx = riw.x;
					float trry = riw.y;

					riw.x = riw.x * (ca + ux * ux * (1 - ca)) + riw.y * (ux * uy * (1 - ca)) - riw.z * (uy * sa);
					riw.y = trx * (uy * ux * (1 - ca)) + riw.y * (ca + uy * uy * (1 - ca)) + riw.z * (ux * sa);
					riw.z = trx * (uy * sa) - trry * (ux * sa) + riw.z * (ca);
				}
			}

			riw += _PlayerOffset;

			o.pos = mul(unity_WorldToObject * 1.0, riw);
			o.pos = UnityObjectToClipPos(o.pos);

			o.pos2 = mul(unity_WorldToObject, o.pos);
			o.pos2 -= _PlayerOffset;

			return o;
		}

		//Color functions, there's no check for division by 0 which may cause issues on
		//some graphics cards.
		float3 RGBToXYZC(float r, float g, float b)
		{
			float3 xyz;
			xyz.x = 0.13514 * r + 0.120432 * g + 0.057128 * b;
			xyz.y = 0.0668999 * r + 0.232706 * g + 0.0293946 * b;
			xyz.z = 0.0 * r + 0.0000218959 * g + 0.358278 * b;
			return xyz;
		}
		float3 XYZToRGBC(float x, float y, float z)
		{
			float3 rgb;
			rgb.x = 9.94845 * x - 5.1485 * y - 1.16389 * z;
			rgb.y = -2.86007 * x + 5.77745 * y - 0.0179627 * z;
			rgb.z = 0.000174791 * x - 0.000353084 * y + 2.79113 * z;

			return rgb;
		}
		float3 weightFromXYZCurves(float3 xyz)
		{
			float3 returnVal;
			returnVal.x = 0.0735806 * xyz.x - 0.0380793 * xyz.y - 0.00860837 * xyz.z;
			returnVal.y = -0.0665378 * xyz.x + 0.134408 * xyz.y - 0.000417865 * xyz.z;
			returnVal.z = 0.00000299624 * xyz.x - 0.00000605249 * xyz.y + 0.0484424 * xyz.z;
			return returnVal;
		}

		float getXFromCurve(float3 param, float shift)
		{
			float top1 = param.x * xla * exp((float)(-(pow((param.y * shift) - xlb, 2)
				/ (2 * (pow(param.z * shift, 2) + pow(xlc, 2)))))) * sqrt((float)(float(2) * (float)3.14159265358979323));
			float bottom1 = sqrt((float)(1 / pow(param.z * shift, 2)) + (1 / pow(xlc, 2)));

			float top2 = param.x * xha * exp(float(-(pow((param.y * shift) - xhb, 2)
				/ (2 * (pow(param.z * shift, 2) + pow(xhc, 2)))))) * sqrt((float)(float(2) * (float)3.14159265358979323));
			float bottom2 = sqrt((float)(1 / pow(param.z * shift, 2)) + (1 / pow(xhc, 2)));

			return (top1 / bottom1) + (top2 / bottom2);
		}
		float getYFromCurve(float3 param, float shift)
		{
			float top = param.x * ya * exp(float(-(pow((param.y * shift) - yb, 2)
				/ (2 * (pow(param.z * shift, 2) + pow(yc, 2)))))) * sqrt(float(float(2) * (float)3.14159265358979323));
			float bottom = sqrt((float)(1 / pow(param.z * shift, 2)) + (1 / pow(yc, 2)));

			return top / bottom;
		}

		float getZFromCurve(float3 param, float shift)
		{
			float top = param.x * za * exp(float(-(pow((param.y * shift) - zb, 2)
				/ (2 * (pow(param.z * shift, 2) + pow(zc, 2)))))) * sqrt(float(float(2) * (float)3.14159265358979323));
			float bottom = sqrt((float)(1 / pow(param.z * shift, 2)) + (1 / pow(zc, 2)));

			return top / bottom;
		}

		float3 constrainRGB(float r, float g, float b)
		{
			float w;

			w = (0 < r) ? 0 : r;
			w = (w < g) ? w : g;
			w = (w < b) ? w : b;
			w = -w;

			if (w > 0) {
				r += w;  g += w; b += w;
			}
			w = r;
			w = (w < g) ? g : w;
			w = (w < b) ? b : w;

			if (w > 1)
			{
				r /= w;
				g /= w;
				b /= w;
			}
			float3 rgb;
			rgb.x = r;
			rgb.y = g;
			rgb.z = b;
			return rgb;

		};

		//Per pixel shader, does color modifications
		float4 frag(v2f i) : COLOR
		{
			//Used to maintian a square scale ( adjust for screen aspect ratio )
			float x1 = i.pos2.x * 2 * xs;
			float y1 = i.pos2.y * 2 * xs / xyr;
			float z1 = i.pos2.z;

			// ( 1 - (v/c)cos(theta) ) / sqrt ( 1 - (v/c)^2 )
			float shift = (1 - ((x1 * _PlayerVelocity.x + y1 * _PlayerVelocity.y + z1 * _PlayerVelocity.z) / sqrt(x1 * x1 + y1 * y1 + z1 * z1))) / i.svc;
			if (_colorShift == 0)
			{
				shift = 1.0f;
			}
			//Get initial color 
			float4 data = tex2D(_Tex2D, i.uv1).rgba;
			float UV = tex2D(_Tex2D, i.uv1).r;
			float IR = tex2D(_Tex2D, i.uv1).r;

			float3 rgb = data.xyz;

			//Color shift due to doppler, go from RGB -> XYZ, shift, then back to RGB.
			float3 xyz = RGBToXYZC(float(rgb.x),float(rgb.y),float(rgb.z));
			float3 weights = weightFromXYZCurves(xyz);
			float3 rParam,gParam,bParam,UVParam,IRParam;
			rParam.x = weights.x; rParam.y = (float)615; rParam.z = (float)8;
			gParam.x = weights.y; gParam.y = (float)550; gParam.z = (float)4;
			bParam.x = weights.z; bParam.y = (float)463; bParam.z = (float)5;
			UVParam.x = 0.02; UVParam.y = UV_START + UV_RANGE * UV; UVParam.z = (float)5;
			IRParam.x = 0.02; IRParam.y = IR_START + IR_RANGE * IR; IRParam.z = (float)5;

			float xf = pow((1 / shift),3) * (getXFromCurve(rParam, shift) + getXFromCurve(gParam,shift) + getXFromCurve(bParam,shift) + getXFromCurve(IRParam,shift) + getXFromCurve(UVParam,shift));
			float yf = pow((1 / shift),3) * (getYFromCurve(rParam, shift) + getYFromCurve(gParam,shift) + getYFromCurve(bParam,shift) + getYFromCurve(IRParam,shift) + getYFromCurve(UVParam,shift));
			float zf = pow((1 / shift),3) * (getZFromCurve(rParam, shift) + getZFromCurve(gParam,shift) + getZFromCurve(bParam,shift) + getZFromCurve(IRParam,shift) + getZFromCurve(UVParam,shift));

			float3 rgbFinal = XYZToRGBC(xf,yf,zf);
			rgbFinal = constrainRGB(rgbFinal.x,rgbFinal.y, rgbFinal.z); //might not be needed

			return float4(data.x, data.y, data.z, data.a); //use me for any real build
		}

			ENDCG

			Subshader {

			Pass{
				//Shader properties, for things such as transparency
				Cull Off ZWrite On
				ZTest LEqual
				Fog { Mode off } //Fog does not shift properly and there is no way to do so with this fog
				Tags {"RenderType" = "Transparent" "Queue" = "Transparent"}

				AlphaTest Greater[_Cutoff]
				Blend SrcAlpha OneMinusSrcAlpha

				CGPROGRAM

				#pragma fragmentoption ARB_precision_hint_nicest

				#pragma vertex vert
				#pragma fragment frag
				#pragma target 3.0

				ENDCG
			}
		}
		//Fallback "Unlit/Transparent"
}


