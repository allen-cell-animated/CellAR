// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/Volume" 
{
	Properties 
	{
		_TextureAtlas ("Texture Atlas", 2D) = "_TextureAtlas" {}
		_TextureAtlasMask ("Texture Atlas Mask", 2D) = "_TextureAtlasMask" {}
		_Atlas_X ("Atlas X Tiles", int) = 8
		_Atlas_Y ("Atlas Y Tiles", int) = 6
		_Slices ("Slices", int) = 46
	}
	SubShader 
	{
		Tags {
            "Queue" = "Transparent"
            "RenderType" = "Transparent" 
        }
        Blend One OneMinusSrcAlpha
		Cull Front
		Pass 
		{
		CGPROGRAM

		// The vertex and fragment shader names
		#pragma vertex vert
		#pragma fragment frag

		#include "UnityCG.cginc"

		struct v2f
		{
			float4 vertex : SV_POSITION;
			float3 pObj : TEXCOORD0;
		};

		// The vertex shader
		v2f vert (appdata_base v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.pObj = v.vertex;
			return o;
		}

		sampler2D _TextureAtlasMask;
		sampler2D _TextureAtlas;
		int _Atlas_X = 8;
		int _Atlas_Y = 6;
		int _Slices = 46;

		// constants
		static const float3 AABB_CLIP_MIN = float3(-0.5, -0.5, -0.5);
		static const float3 AABB_CLIP_MAX = float3(0.5, 0.5, 0.5);
		static const int BREAK_STEPS = 72;
		static const float BRIGHTNESS = 1;
		static const float DENS = 0.0820849986238988;
		//static const float maskAlpha = 0;
		static const float GAMMA_MIN = 0;
		static const float GAMMA_MAX = 1;
		static const float GAMMA_SCALE = 1;

		bool intersectBox (in float3 r_o, in float3 r_d, in float3 boxMin, in float3 boxMax, out float tnear, out float tfar)
		{ 
			float3 invR = float3(1.0,1.0,1.0) / r_d;
			float3 tbot = invR * (boxMin - r_o);
			float3 ttop = invR * (boxMax - r_o);
			float3 tmin = min(ttop, tbot);
			float3 tmax = max(ttop, tbot);
			float largest_tmin  = max(max(tmin.x, tmin.y), max(tmin.x, tmin.z));
			float smallest_tmax = min(min(tmax.x, tmax.y), min(tmax.x, tmax.z));
			tnear = largest_tmin;
			tfar = smallest_tmax;
			return (smallest_tmax > largest_tmin);
		}
		
		float rand(float2 co)
		{
			//return 0.0;
			float a = 12.9898;
			float b = 78.233;
			float c = 43758.5453;
			float dt = dot(co.xy, float2(a, b));
			float sn = fmod(dt, 3.14);
			return frac(sin(sn) * c );
		}
		
		float4 luma2Alpha (float4 col, float vmin, float vmax, float C)
		{
			float x = max(col[2], max(col[0], col[1]));
			float xi = (x - vmin) / (vmax - vmin);
			xi = clamp(xi, 0.0, 1.0);
			float y = pow(xi, C);
			y = clamp(y, 0.0, 1.0);
			col[3] = y;
			return(col);
		}

		float2 offsetFrontBack (float t, float nx, float ny)
		{
			float2 os = float2(fmod(t, nx)/nx, floor(t/nx)/ny);
			return os;
		}

		float4 sampleAs3DTexture (sampler2D tex, float4 pos) 
		{
			float bounds = float(pos[0] > 0.001 && pos[0] < 0.999 &&
								 pos[1] > 0.001 && pos[1] < 0.999 &&
								 pos[2] > 0.001 && pos[2] < 0.999 );
			float2 loc0 = float2(pos.x / _Atlas_X, (1.0 - pos.y) / _Atlas_Y);
			float z = pos.z * _Slices;
			float zfloor = floor(z);
			float z0  = zfloor;
			float z1 = zfloor + 1.0;
			z1 = clamp(z1, 0.0, _Slices);
			float2 o0 = offsetFrontBack(z0, _Atlas_X, _Atlas_Y);
			float2 o1 = offsetFrontBack(z1, _Atlas_X, _Atlas_Y);
			o0 = clamp(o0, 0.0, 1.0) + loc0;
			o1 = clamp(o1, 0.0, 1.0) + loc0;
			o0.y = 1.0 - o0.y;
			o1.y = 1.0 - o1.y;
			float t = z - zfloor;
			float4 slice0Color = tex2D(tex, o0);
			float4 slice1Color = tex2D(tex, o1);
			float slice0Mask = tex2D(_TextureAtlasMask, o0).x;
			float slice1Mask = tex2D(_TextureAtlasMask, o1).x;
			float maskVal = lerp(slice0Mask, slice1Mask, t);
			//maskVal = lerp(maskVal, 1.0, maskAlpha);
			float4 retval = lerp(slice0Color, slice1Color, t);
			retval.rgb *= maskVal;
			return bounds*retval; //bounds * 
		}

		float4 sampleStack (sampler2D tex, float4 pos) 
		{
			float4 col = sampleAs3DTexture(tex, pos);
			col = luma2Alpha(col, GAMMA_MIN, GAMMA_MAX, GAMMA_SCALE);
			return col;
		}

        float4 integrateVolume (float4 eye_o, float4 eye_d, float tnear, float tfar, float clipNear, float clipFar, sampler2D textureAtlas)
        {
        	float4 C = float4(0.0, 0.0, 0.0, 0.0);
        	float tend = tfar;
        	float tbegin = tnear;
        	int maxSteps = 256;
        	float csteps = float(BREAK_STEPS);
        	csteps = clamp(csteps, 0.0, float(maxSteps));
        	float isteps = 1.0 / csteps;
        	float r = 0.5 - 1.0 * rand(eye_d.xy);
        	float tstep = isteps / length(eye_d);
        	float tfarsurf = r * tstep;
        	float overflow = fmod((tfarsurf - tend), tstep);
        	float t = tbegin + overflow;
        	t += r * tstep;
			
        	float4 pos, col;
        	// gradient instruction used in a loop with varying iteration, forcing loop to unroll
        	// unable to unroll loop, loop does not appear to terminate in a timely manner (236 iterations) or unrolled loop is too large
        	// use the [unroll(n)] attribute to force and exact higher number
        	// https://forum.unity3d.com/threads/issues-with-shaderproperty-and-for-loop.344469/
        	[unroll(256)] for (int i = 0; i < maxSteps; i++) 
        	{
        		pos = eye_o + eye_d * t;
        		pos.xyz = (pos.xyz - AABB_CLIP_MIN) / (AABB_CLIP_MAX - AABB_CLIP_MIN); // map position from [boxMin, boxMax] to [0, 1] coordinates
        		col = sampleStack(textureAtlas, pos);

        		//Finish up by adding brightness/density
        		col.xyz *= BRIGHTNESS;
        		col.w *= DENS;
        		float s = 0.5 * float(256) / float(BREAK_STEPS);
        		float stepScale = (1.0 - pow((1.0 - col.w), s));
        		col.w = stepScale;
        		col.xyz *= col.w;
        		col = clamp(col, 0.0, 1.0);
        		C = (1.0 - C.w) * col + C;
        		t += tstep;
        		if (i > BREAK_STEPS || t  > tend || t > tbegin + clipFar ) { break; }
        		if (C.w > 1.0 ) { break; }
        	}
        	return C;
		}

		// The fragment shader, returns color as a float4
		float4 frag (v2f In): COLOR
		{
			float3 eyeRay_o = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0)).xyz;
			float3 eyeRay_d = In.pObj - eyeRay_o;
			float3 boxMin = AABB_CLIP_MIN;
			float3 boxMax = AABB_CLIP_MAX;
			float tnear, tfar;

			bool hit = intersectBox(eyeRay_o, eyeRay_d, boxMin, boxMax, tnear, tfar);
			if (!hit)
			{
     			return float4(0.0, 0.0, 0.0, 0.0);
     		}

     		float clipNear = 0.0;
     		float clipFar  = 10000.0;
     		float4 C = integrateVolume(float4(eyeRay_o, 1.0), float4(eyeRay_d, 0.0), tnear, tfar, clipNear, clipFar, _TextureAtlas);
     		C = clamp(C, 0.0, 1.0);
     		return C;
		}
 
		ENDCG
		}
	}
}