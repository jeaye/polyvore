Shader "FX/Water"
{
  Properties
  {
    _Color0 ("Light color", Color) = (1.0, 1.0, 1.0, 1.0)
    _Color1 ("Mid color", Color) = (1.0, 1.0, 1.0, 1.0)
    _Color2 ("Dark color", Color) = (1.0, 1.0, 1.0, 1.0)
    _Transparency ("Water transparency", Range(0, 1.0)) = 0.75
    _SinSpeed ("Sine speed", Float) = 0.5
    _SinScale ("Sine scale", Float) = 0.3
    _ReflDistort ("Reflection distort", Range(0,1.5)) = 0.44
    _RefrDistort ("Refraction distort", Range(0,1.5)) = 0.40
    _RefrWaveScale ("Refraction wave scale", Range(0.02,0.15)) = 0.063
    _RefrColor ("Refraction color", Color)  = ( .34, .85, .92, 1)
    _SpecColor ("Specular color", Color) = (1.0, 1.0, 1.0, 1.0)
    _Shininess ("Shininess", Float) = 10
    [NoScaleOffset] _Fresnel ("Fresnel (A) ", 2D) = "gray" {}
    [NoScaleOffset] _BumpMap ("Normalmap ", 2D) = "bump" {}
    WaveSpeed ("Wave speed (map1 x,y; map2 x,y)", Vector) = (19,9,-16,-7)
    [NoScaleOffset] _ReflectiveColor ("Reflective color (RGB) fresnel (A) ", 2D) = "" {}
    [HideInInspector] _ReflectionTex ("Internal Reflection", 2D) = "" {}
    [HideInInspector] _RefractionTex ("Internal Refraction", 2D) = "" {}
  }

  Subshader
  {
    Tags
    {
      "WaterMode" = "Refractive"
      "RenderType" = "Transparent"
    }
    LOD 100
    //Blend One OneMinusSrcAlpha

    Pass
    {
      Tags
      {
        "LightMode" = "ForwardBase"
      }

      GLSLPROGRAM

#include "UnityCG.glslinc"

      uniform vec4 _WaveScale4;
      uniform vec4 _WaveOffset;

      uniform float _ReflDistort;
      uniform float _RefrDistort;

#ifdef VERTEX
      attribute vec4 Tangent;

      flat out vec4 color;
      smooth out vec4 reflection;
      smooth out vec4 view_dir;
      smooth out vec2 bumpuv0;
      smooth out vec2 bumpuv1;

#include "Assets/Specular.glsl"
#include "Assets/Water.glsl"

      vec4 ComputeScreenPos(vec4 pos)
      {
        vec4 o = pos * 0.5;
        o.xy = vec2(o.x, o.y*_ProjectionParams.x) + o.w;
        o.zw = pos.zw;
        return o;
      }

      void main()
      {
        vec4 vertex = step_vertex(gl_Vertex);
        gl_Position = gl_ModelViewProjectionMatrix * vertex;

        vec3 new_normal = update_normal(vertex, gl_Normal, Tangent.xyz);
        color = specular(vertex, new_normal, gl_LightModel.ambient.rgb);
        reflection = ComputeScreenPos(gl_Position) + (vertex.y * _ReflDistort);

        /* Scroll bump waves. */
        vec4 wpos = unity_ObjectToWorld * vertex;
        vec4 temp = wpos.xzxz * _WaveScale4 + _WaveOffset;
        bumpuv0 = temp.xy;
        bumpuv1 = temp.wz;

        /* Object space view direction (will normalize per pixel). */
        view_dir.xzy = WorldSpaceViewDir(vertex);
      }
#endif

#ifdef FRAGMENT
      uniform float _Transparency;
      uniform sampler2D _ReflectionTex;
      uniform sampler2D _ReflectiveColor;
      uniform sampler2D _Fresnel;
      uniform sampler2D _RefractionTex;
      uniform vec4 _RefrColor;
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

        /* Combine two scrolling bumpmaps into one. */
        vec3 bump1 = UnpackNormal(texture2D(_BumpMap, bumpuv0)).rgb;
        vec3 bump2 = UnpackNormal(texture2D(_BumpMap, bumpuv1)).rgb;
        vec3 bump = (bump1 + bump2) * 0.5;

        /* Fresnel factor. */
        float fres = dot(vec3(view_dir_norm), bump);

        /* Perturb reflection/refraction UVs by bumpmap, and lookup colors. */
        vec4 uv1 = reflection; uv1.xy += vec2(bump) * _ReflDistort;
        vec4 refl = texture2DProj(_ReflectionTex, uv1);
        vec4 uv2 = reflection; uv2.xy -= vec2(bump) * _RefrDistort;
        vec4 refr = texture2DProj(_RefractionTex, uv2) * _RefrColor;

        /* Final color is between refracted and reflected, based on fresnel. */
        float fresnel = texture2D(_Fresnel, vec2(fres, fres)).a;
        gl_FragColor = mix(refr, refl, fresnel) * color;
        gl_FragColor.a = _Transparency;
      }
#endif
      ENDGLSL
    }

    /* For additional light sources, use additive blending. */
    Pass
    {
      Tags
      {
        "LightMode" = "ForwardAdd"
      }
      Blend One One

      GLSLPROGRAM

#ifdef VERTEX
      attribute vec4 Tangent;

      flat out vec4 color;

#include "Assets/Specular.glsl"
#include "Assets/Water.glsl"

      void main()
      {
        vec4 vertex = step_vertex(gl_Vertex);
        gl_Position = gl_ModelViewProjectionMatrix * vertex;

        vec3 new_normal = update_normal(vertex, gl_Normal, Tangent.xyz);
        color = specular(vertex, new_normal, vec3(0.0));
      }
#endif

#ifdef FRAGMENT
      flat in vec4 color;

      void main()
      { gl_FragColor = color; }
#endif

      ENDGLSL
    }
  }
}
