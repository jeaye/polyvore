Shader "Unlit/WaterShader"
{
	Properties
	{
    _Color0 ("Color0", Color) = (1.0, 1.0, 1.0, 1.0)
    _Color1 ("Color1", Color) = (1.0, 1.0, 1.0, 1.0)
    _Color2 ("Color2", Color) = (1.0, 1.0, 1.0, 1.0)
    _SpecColor ("Specular Material Color", Color) = (1.0, 1.0, 1.0, 1.0)
    _Shininess ("Shininess", Float) = 10
    _ReflDistort ("Reflection distort", Range (0,1.5)) = 0.44
    _RefrDistort ("Refraction distort", Range (0,1.5)) = 0.40
    _RefrColor ("Refraction color", Color) = (0.34, 0.85, 0.92, 1.0)
    _Fresnel ("Fresnel (A) ", 2D) = "gray" {}
		[HideInInspector] _ReflectionTex ("", 2D) = "white" {}
		[HideInInspector] _RefractionTex ("", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" }
		LOD 100
    Blend SrcAlpha OneMinusSrcAlpha

    Pass
    {
      GLSLPROGRAM

      #include "UnityCG.glslinc"

      #ifdef VERTEX
      uniform vec4 _Color0;
      uniform vec4 _Color1;
      uniform vec4 _Color2;
      uniform vec4 _SpecColor;
      uniform float _Shininess;

      //uniform vec3 _WorldSpaceCameraPos; // camera position in world space
      uniform mat4 _Object2World; // model matrix
      uniform mat4 _World2Object; // inverse model matrix
      //uniform vec4 _WorldSpaceLightPos0; // direction to or position of light source
      uniform vec4 _LightColor0;
      //uniform vec4 _SinTime;

      flat out vec4 color;
      smooth out vec4 reflection;

      vec4 ComputeScreenPos(vec4 pos) {
        vec4 o = pos * 0.5f;
        o.xy = vec2(o.x, o.y*_ProjectionParams.x) + o.w;
        o.zw = pos.zw;
        return o;
      }

      vec4 specular()
      {
        mat4 modelMatrix = _Object2World;
        mat4 modelMatrixInverse = _World2Object;

        vec4 color = _Color0;
        if(gl_Vertex.y < 0.5)
        { color = _Color2; }
        else if(gl_Vertex.y < 0.75)
        { color = _Color1; }

        vec3 normalDirection = normalize(vec3(vec4(gl_Normal, 0.0) * modelMatrixInverse));
        vec3 viewDirection = normalize(vec3(vec4(_WorldSpaceCameraPos, 1.0) - modelMatrix * gl_Vertex));
        vec3 lightDirection;
        float attenuation = 1.0;

        if (0.0 == _WorldSpaceLightPos0.w) // directional light?
        {
          // no attenuation
          lightDirection = normalize(vec3(_WorldSpaceLightPos0));
        }
        else // point or spot light
        {
          vec3 vertexToLightSource = vec3(_WorldSpaceLightPos0 - modelMatrix * gl_Vertex);
          float distance = length(vertexToLightSource);
          attenuation = 1.0 / distance; // linear attenuation
          lightDirection = normalize(vertexToLightSource);
        }

        vec3 ambientLighting = vec3(gl_LightModel.ambient) * vec3(color);

        vec3 diffuseReflection = attenuation * vec3(_LightColor0) * vec3(color)
          * max(0.0, dot(normalDirection, lightDirection));

        vec3 specularReflection;
        if (dot(normalDirection, lightDirection) < 0.0) // light source on the wrong side?
        {
          specularReflection = vec3(0.0, 0.0, 0.0);
          // no specular reflection
        }
        else // light source on the right side
        {
          specularReflection = attenuation * vec3(_LightColor0)
            * vec3(_SpecColor) * pow(max(0.0, dot(
                    reflect(-lightDirection, normalDirection),
                    viewDirection)), _Shininess);
        }

        return vec4(ambientLighting + diffuseReflection + specularReflection, 1.0);
      }

      void main()
      {
        vec4 pos = gl_Vertex;
        gl_Position = gl_ModelViewProjectionMatrix * pos;
        color = specular();
				reflection = ComputeScreenPos(gl_Position);
      }
      #endif

      #ifdef FRAGMENT
			uniform sampler2D _ReflectionTex;
			uniform sampler2D _RefractionTex;
      uniform sampler2D _Fresnel;
			uniform float _ReflDistort;
			uniform float _RefrDistort;

      flat in vec4 color;
      smooth in vec4 reflection;

      void main()
      {
        gl_FragColor = color;

        // TODO: Distortion and refraction
				gl_FragColor *= textureProj(_ReflectionTex, reflection);
        gl_FragColor.a = 0.75f;
      }
      #endif

      ENDGLSL
    }
	}
}
