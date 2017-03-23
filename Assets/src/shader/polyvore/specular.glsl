#include "UnityCG.glslinc"

uniform vec4 _LightColor0;
uniform vec4 _SpecColor;
uniform float _Shininess;

uniform vec4 _Color0;
uniform vec4 _Color1;
uniform vec4 _Color2;

vec4 specular(vec4 vertex, vec3 normal, vec3 ambient_color)
{
  vec4 base_color = _Color0;
  //if(vertex.y < 0.1)
  //{ base_color = _Color2; }
  //else if(vertex.y < 0.2)
  //{ base_color = _Color1; }

  vec3 normalDirection = normalize(vec3(vec4(normal, 0.0) * unity_WorldToObject));
  vec3 viewDirection = normalize(vec3(vec4(_WorldSpaceCameraPos, 1.0) - unity_ObjectToWorld * vertex));
  vec3 lightDirection;
  float attenuation = 1.0;

  if(0.0 == _WorldSpaceLightPos0.w) /* Directional light? */
  {
    /* no attenuation. */
    lightDirection = normalize(vec3(_WorldSpaceLightPos0));
  }
  else /* Point or spot light. */
  {
    /* TODO: Take into account the range of the light. */
    vec3 vertexToLightSource = vec3(_WorldSpaceLightPos0 - unity_ObjectToWorld * vertex);
    float distance = length(vertexToLightSource);
    attenuation = 1.0 / distance; /* Linear attenuation. */
    lightDirection = normalize(vertexToLightSource);
  }

  vec3 ambientLighting = ambient_color * vec3(base_color);
  float sharpness = max(0.0, dot(normalDirection, lightDirection));
  vec3 diffuseReflection = attenuation * vec3(_LightColor0) * vec3(base_color) * sharpness;

  vec3 specularReflection;
  if(dot(normalDirection, lightDirection) < 0.0) /* Light source on the wrong side? */
  {
    /* No specular reflection. */
    specularReflection = vec3(0.0, 0.0, 0.0);
  }
  else /* Light source on the right side. */
  {
    specularReflection = attenuation * vec3(_LightColor0)
      * vec3(_SpecColor) * pow(max(0.0, dot(
              reflect(-lightDirection, normalDirection),
              viewDirection)), _Shininess);
  }

  return vec4(ambientLighting + diffuseReflection + specularReflection, 1.0);
}
