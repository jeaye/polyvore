// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "FX/Water" {
  Properties {
    _WaveScale ("Wave scale", Range (0.02,0.15)) = 0.063
    _ReflDistort ("Reflection distort", Range (0,1.5)) = 0.44
    _RefrDistort ("Refraction distort", Range (0,1.5)) = 0.40
    _RefrColor ("Refraction color", COLOR)  = ( .34, .85, .92, 1)
    _SpecColor ("Specular color", Color) = (1.0, 1.0, 1.0, 1.0)
    _Shininess ("Shininess", Float) = 10
    [NoScaleOffset] _Fresnel ("Fresnel (A) ", 2D) = "gray" {}
    [NoScaleOffset] _BumpMap ("Normalmap ", 2D) = "bump" {}
    WaveSpeed ("Wave speed (map1 x,y; map2 x,y)", Vector) = (19,9,-16,-7)
    [NoScaleOffset] _ReflectiveColor ("Reflective color (RGB) fresnel (A) ", 2D) = "" {}
    _HorizonColor ("Simple water horizon color", COLOR)  = ( .172, .463, .435, 1)
    [HideInInspector] _ReflectionTex ("Internal Reflection", 2D) = "" {}
    [HideInInspector] _RefractionTex ("Internal Refraction", 2D) = "" {}
  }


  // -----------------------------------------------------------
  // Fragment program cards


  Subshader {
    Tags { "WaterMode"="Refractive" "RenderType"="Opaque" }
    Pass {
      CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile_fog
#pragma multi_compile WATER_REFRACTIVE WATER_REFLECTIVE WATER_SIMPLE

#if defined (WATER_REFLECTIVE) || defined (WATER_REFRACTIVE)
#define HAS_REFLECTION 1
#endif
#if defined (WATER_REFRACTIVE)
#define HAS_REFRACTION 1
#endif


#include "UnityCG.cginc"

      uniform float4 _LightColor0;
      uniform float4 _SpecColor;
      uniform float _Shininess;

      uniform float4 _WaveScale4;
      uniform float4 _WaveOffset;

#if HAS_REFLECTION
      uniform float _ReflDistort;
#endif
#if HAS_REFRACTION
      uniform float _RefrDistort;
#endif

      struct appdata {
        float4 vertex : POSITION;
        float3 normal : NORMAL;
      };

      struct v2f {
        float4 pos : SV_POSITION;
        float4 color : COLOR;
#if defined(HAS_REFLECTION) || defined(HAS_REFRACTION)
        float4 ref : TEXCOORD0;
        float2 bumpuv0 : TEXCOORD1;
        float2 bumpuv1 : TEXCOORD2;
        float3 viewDir : TEXCOORD3;
#else
        float2 bumpuv0 : TEXCOORD0;
        float2 bumpuv1 : TEXCOORD1;
        float3 viewDir : TEXCOORD2;
#endif
        UNITY_FOG_COORDS(4)
      };

      float4 specular(appdata input)
      {
        float4x4 modelMatrix = unity_ObjectToWorld;
        float3x3 modelMatrixInverse = unity_WorldToObject;
        float3 normalDirection = normalize(
            mul(input.normal, modelMatrixInverse));
        float3 viewDirection = normalize(_WorldSpaceCameraPos
            - mul(modelMatrix, input.vertex).xyz);
        float3 lightDirection;
        float attenuation;

        if (0.0 == _WorldSpaceLightPos0.w) // directional light?
        {
          attenuation = 1.0; // no attenuation
          lightDirection = normalize(_WorldSpaceLightPos0.xyz);
        }
        else // point or spot light
        {
          float3 vertexToLightSource = _WorldSpaceLightPos0.xyz
            - mul(modelMatrix, input.vertex).xyz;
          float distance = length(vertexToLightSource);
          attenuation = 1.0 / distance; // linear attenuation
          lightDirection = normalize(vertexToLightSource);
        }

        float3 diffuseReflection =
          attenuation * _LightColor0.rgb /* TODO: Vertex color * _Color.rgb */
          * max(0.0, dot(normalDirection, lightDirection));

        float3 specularReflection;
        if (dot(normalDirection, lightDirection) < 0.0)
          // light source on the wrong side?
        {
          specularReflection = float3(0.0, 0.0, 0.0);
          // no specular reflection
        }
        else // light source on the right side
        {
          specularReflection = attenuation * _LightColor0.rgb
            * _SpecColor.rgb * pow(max(0.0, dot(
                    reflect(-lightDirection, normalDirection),
                    viewDirection)), _Shininess);
        }

        return float4(diffuseReflection + specularReflection, 1.0);
      }

      v2f vert(appdata v)
      {
        v2f o;
        o.pos = mul (UNITY_MATRIX_MVP, v.vertex);


        // scroll bump waves
        float4 temp;
        float4 wpos = mul (unity_ObjectToWorld, v.vertex);
        temp.xyzw = wpos.xzxz * _WaveScale4 + _WaveOffset;
        o.bumpuv0 = temp.xy;
        o.bumpuv1 = temp.wz;

        // object space view direction (will normalize per pixel)
        o.viewDir.xzy = WorldSpaceViewDir(v.vertex);

#if defined(HAS_REFLECTION) || defined(HAS_REFRACTION)
        o.ref = ComputeNonStereoScreenPos(o.pos) + (v.vertex.y * _ReflDistort);
#endif

        o.color = specular(v);

        UNITY_TRANSFER_FOG(o,o.pos);
        return o;
      }

#if defined (WATER_REFLECTIVE) || defined (WATER_REFRACTIVE)
      sampler2D _ReflectionTex;
#endif
#if defined (WATER_REFLECTIVE) || defined (WATER_SIMPLE)
      sampler2D _ReflectiveColor;
#endif
#if defined (WATER_REFRACTIVE)
      sampler2D _Fresnel;
      sampler2D _RefractionTex;
      uniform float4 _RefrColor;
#endif
#if defined (WATER_SIMPLE)
      uniform float4 _HorizonColor;
#endif
      sampler2D _BumpMap;

      half4 frag( v2f i ) : SV_Target
      {
        i.viewDir = normalize(i.viewDir);

        // combine two scrolling bumpmaps into one
        half3 bump1 = UnpackNormal(tex2D( _BumpMap, i.bumpuv0 )).rgb;
        half3 bump2 = UnpackNormal(tex2D( _BumpMap, i.bumpuv1 )).rgb;
        half3 bump = (bump1 + bump2) * 0.5;

        // fresnel factor
        half fresnelFac = dot( i.viewDir, bump );

        // perturb reflection/refraction UVs by bumpmap, and lookup colors

#if HAS_REFLECTION
        float4 uv1 = i.ref; uv1.xy += bump * _ReflDistort;
        half4 refl = tex2Dproj( _ReflectionTex, UNITY_PROJ_COORD(uv1) );
#endif
#if HAS_REFRACTION
        float4 uv2 = i.ref; uv2.xy -= bump * _RefrDistort;
        half4 refr = tex2Dproj( _RefractionTex, UNITY_PROJ_COORD(uv2) ) * _RefrColor;
#endif

        // final color is between refracted and reflected based on fresnel
        half4 color;

#if defined(WATER_REFRACTIVE)
        half fresnel = UNITY_SAMPLE_1CHANNEL( _Fresnel, float2(fresnelFac,fresnelFac) );
        color = lerp( refr, refl, fresnel );
#endif

#if defined(WATER_REFLECTIVE)
        half4 water = tex2D( _ReflectiveColor, float2(fresnelFac,fresnelFac) );
        color.rgb = lerp( water.rgb, refl.rgb, water.a );
        color.a = refl.a * water.a;
#endif

#if defined(WATER_SIMPLE)
        half4 water = tex2D( _ReflectiveColor, float2(fresnelFac,fresnelFac) );
        color.rgb = lerp( water.rgb, _HorizonColor.rgb, water.a );
        color.a = _HorizonColor.a;
#endif

        color *= i.color;

        UNITY_APPLY_FOG(i.fogCoord, color);
        return color;
      }
      ENDCG
    }
  }
}
