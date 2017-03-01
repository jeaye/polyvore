using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
//[ExecuteInEditMode]
public class Grid : MonoBehaviour
{
  public int Width;
  public int Height;

  private Mesh mesh;

	void Start()
  {
    mesh = GetComponent<MeshFilter>().mesh;
    StartCoroutine(generate());
  }

	IEnumerator generate()
  {
    while(true)
    {
      const float sin_scale = 0.1f;
      const float speed = 1.0f;
      const float noise_strength = 1.0f;
      const float noise_walk = 1.0f;
      const float noise_speed = 0.5f;

      Vector3[] vertices = mesh.vertices;
      for(int i = 0; i < vertices.Length; ++i)
      {
        //vertices[i].y = Mathf.Sin(Time.time * speed + vertices[i].x + vertices[i].y + vertices[i].z) * sin_scale;
        //vertices[i].y += Mathf.PerlinNoise(vertices[i].x + noise_walk, vertices[i].y + Mathf.Sin(Time.time * noise_speed)) * noise_strength;
      }

      mesh.vertices = vertices;

      mesh.RecalculateNormals();

      yield return new WaitForSeconds(0.1f);
    }
	}
}
