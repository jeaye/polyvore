using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
//[ExecuteInEditMode]
public class Grid : MonoBehaviour
{

  public int Width;
  public int Height;

  private Vector3[] vertices;
  private Mesh mesh;

	void Start()
  { StartCoroutine(generate()); }

  void OnDrawGizmos()
  {
    //if(vertices == null)
    //{ return; }

		//Gizmos.color = Color.black;
		//for(int i = 0; i < vertices.Length; ++i)
    //{ Gizmos.DrawSphere(vertices[i], 0.1f); }
	}

	void Update()
  { generate(); }

	IEnumerator generate()
  {
    while(true)
    {
      const float sin_scale = 0.5f;
      const float speed = 1.0f;
      const float noise_strength = 1.0f;
      const float noise_walk = 1.0f;
      const float noise_speed = 0.5f;

      //GetComponent<MeshFilter>().mesh = mesh = new Mesh();
      mesh = GetComponent<MeshFilter>().mesh;

      //vertices = new Vector3[(Width + 1) * (Height + 1)];
      vertices = mesh.vertices;
      //Vector2[] uv = new Vector2[vertices.Length];
      //Vector4[] tangents = new Vector4[vertices.Length];
      //Vector4 tangent = new Vector4(1f, 0f, 0f, -1f);
      //for(int i = 0, y = 0; y <= Height; ++y)
      {
        //for(int x = 0; x <= Width; ++x, ++i)
        for(int i = 0; i < vertices.Length; ++i)
        {
          //vertices[i] = new Vector3(x, 0.0f, y);
          vertices[i].y = Mathf.Sin(Time.time * speed + vertices[i].x + vertices[i].y + vertices[i].z) * sin_scale;
          vertices[i].y += Mathf.PerlinNoise(vertices[i].x + noise_walk, vertices[i].y + Mathf.Sin(Time.time * noise_speed)) * noise_strength;
          //uv[i] = new Vector2(x / Width, y / Height);
          //tangents[i] = tangent;
        }
      }

      //int[] triangles = new int[Width * Height * 6];
      //for(int ti = 0, vi = 0, y = 0; y < Height; ++y, ++vi)
      //{
      //  for(int x = 0; x < Width; x++, ti += 6, ++vi)
      //  {
      //    triangles[ti] = vi;
      //    triangles[ti + 3] = triangles[ti + 2] = vi + 1;
      //    triangles[ti + 4] = triangles[ti + 1] = vi + Width + 1;
      //    triangles[ti + 5] = vi + Width + 2;
      //  }
      //}

      mesh.name = "Procedural Grid";
      mesh.vertices = vertices;
      //mesh.uv = uv;
      //mesh.triangles = triangles;
      //mesh.tangents = tangents;

      Color32[] colors = new Color32[vertices.Length];
      for(int i = 0, y = 0; y <= Height; ++y)
      {
        for(int x = 0; x <= Width; ++x, ++i)
        { colors[i] = new Color32((byte)(Random.value * 255), (byte)(Random.value * 255), (byte)(Random.value * 255), 12); }
      }
      mesh.colors32 = colors;

      mesh.RecalculateNormals();
      mesh.RecalculateBounds();

      yield return new WaitForSeconds(0.1f);
    }
	}
}
