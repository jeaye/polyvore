Shader "Flat/Basic"
{
  Properties
  {
  }

  Subshader
  {
    Tags
    {
      "RenderType" = "Opaque"
    }
    LOD 100

    Pass
    {
      GLSLPROGRAM

#include "UnityCG.glslinc"

#ifdef VERTEX
      flat out vec4 color;

      void main()
      {
        gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
        color = gl_Color;
      }
#endif

#ifdef FRAGMENT
      flat in vec4 color;

      void main()
      {
        gl_FragColor = color;
      }
#endif
      ENDGLSL
    }
  }
}
