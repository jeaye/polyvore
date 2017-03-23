uniform float _SinSpeed;
uniform float _SinScale;

vec4 step_vertex(vec4 v)
{
  vec3 vn = normalize(v.xyz);
  vec3 tmp = vn * sin(_Time.w * _SinSpeed + v.x + v.y + v.z) * _SinScale;
  tmp -= (vn * sin(-_Time.w * _SinSpeed - v.z) * _SinScale);
  return vec4(v.xyz + tmp, v.w);
}

vec3 update_normal(vec4 vert, vec3 normal, vec3 tangent)
{
  vec4 bitangent = vec4(cross(gl_Normal, Tangent.xyz), 0.0);
  vec4 vertex_tangent = step_vertex(gl_Vertex + Tangent * 0.01);
  vec4 vertex_bitangent = step_vertex(gl_Vertex + bitangent * 0.01);

  /* Remove the vertex and leave just the tangent/bitangent. */
  vec4 new_tangent = (vertex_tangent - vert);
  vec4 new_bitangent = (vertex_bitangent - vert);
  return cross(new_tangent.xyz, new_bitangent.xyz);
}
