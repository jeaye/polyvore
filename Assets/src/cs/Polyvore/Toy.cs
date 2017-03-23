using System.Collections.Generic;
using UnityEngine;

namespace Polyvore
{
  [ExecuteInEditMode]
  public class Toy : MonoBehaviour
  {
    public List<Color> colors;

    private void Start()
    {
      var mesh = GetComponent<MeshFilter>().sharedMesh;
      foreach(Color color in mesh.colors)
      { Debug.Log("color: " + color); }
    }
  }
}
