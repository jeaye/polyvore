Shader "FX/WaterGLSL" {
  Properties {
    _Color0 ("Light color", Color) = (1.0, 1.0, 1.0, 1.0)
    _Color1 ("Mid color", Color) = (1.0, 1.0, 1.0, 1.0)
    _Color2 ("Dark color", Color) = (1.0, 1.0, 1.0, 1.0)
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
    [HideInInspector] _ReflectionTex ("Internal Reflection", 2D) = "" {}
    [HideInInspector] _RefractionTex ("Internal Refraction", 2D) = "" {}
  }


  // -----------------------------------------------------------
  // Fragment program cards


  Subshader {
    Tags { "WaterMode"="Refractive" "RenderType"="Opaque" }
    Pass {
        GLSLPROGRAM

#include "UnityCG.glslinc"

      uniform mat4 _LightColor0;
      uniform mat4 _SpecColor;
      uniform float _Shininess;

      uniform mat4 _WaveScale4;
      uniform mat4 _WaveOffset;

      uniform float _ReflDistort;
      uniform float _RefrDistort;

#ifdef VERTEX
      uniform vec4 _Color0;
      uniform vec4 _Color1;
      uniform vec4 _Color2;

      flat out vec4 color;
      smooth out vec4 reflection;
      smooth out vec4 view_dir;
      smooth out vec2 bumpuv0;
      smooth out vec2 bumpuv1;

      vec4 ComputeScreenPos(vec4 pos)
      {
        vec4 o = pos * 0.5;
        o.xy = vec2(o.x, o.y*_ProjectionParams.x) + o.w;
        o.zw = pos.zw;
        return o;
      }

      void main()
      {
        // TODO: Modulate vertex and recalculate normal
        gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
        //color = specular(); // TODO
        color = _Color0;
        reflection = ComputeScreenPos(gl_Position) + (gl_Vertex.y * _ReflDistort);

        // scroll bump waves
        vec4 wpos = unity_ObjectToWorld * gl_Vertex;
        vec4 temp = wpos.xzxz * _WaveScale4;// + _WaveOffset; TODO
        bumpuv0 = temp.xy;
        bumpuv1 = temp.wz;

        // object space view direction (will normalize per pixel)
        view_dir.xzy = WorldSpaceViewDir(gl_Vertex);
      }
#endif

#ifdef FRAGMENT
      uniform sampler2D _ReflectionTex;
      uniform sampler2D _ReflectiveColor;
      uniform sampler2D _Fresnel;
      uniform sampler2D _RefractionTex;
      uniform mat4 _RefrColor;
      uniform sampler2D _BumpMap;

      flat in vec4 color;
      smooth in vec4 reflection;
      smooth in vec4 view_dir;
      smooth in vec2 bumpuv0;
      smooth in vec2 bumpuv1;

      vec3 UnpackNormal(vec4 norm)
      { return (vec3(norm) - 0.5) * 2.0; }

      void main()
      {
        vec4 view_dir_norm = normalize(view_dir);

        //// combine two scrolling bumpmaps into one
        vec3 bump1 = UnpackNormal(texture2D(_BumpMap, bumpuv0)).rgb;
        vec3 bump2 = UnpackNormal(texture2D(_BumpMap, bumpuv1)).rgb;
        vec3 bump = (bump1 + bump2) * 0.5;

        //// fresnel factor
        float fres = dot(vec3(view_dir_norm), bump);

        //// perturb reflection/refraction UVs by bumpmap, and lookup colors
        vec4 uv1 = reflection; uv1.xy += vec2(bump) * _ReflDistort;
        vec4 refl = texture2DProj(_ReflectionTex, uv1);
        vec4 uv2 = reflection; uv2.xy -= vec2(bump) * _RefrDistort;
        vec4 refr = texture2DProj(_RefractionTex, uv2) * _RefrColor;

        //// final color is between refracted and reflected based on fresnel
        float fresnel = texture2D(_Fresnel, vec2(fres, fres)).a;
        gl_FragColor = mix( refr, refl, fresnel) * color;
      }
#endif
      ENDGLSL
    }
  }
}
