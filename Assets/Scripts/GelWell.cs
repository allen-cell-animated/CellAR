using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GelWell : MonoBehaviour
{
    public bool touching;

    Material _material;
    Material theMaterial
    {
        get
        {
            if (_material == null)
            {
                _material = GetComponent<MeshRenderer>().material;
            }
            return _material;
        }
    }

    void OnTriggerEnter (Collider other)
    {
        if (!touching)
        {
            theMaterial.color = Color.green;
            touching = true;
        }
    }

    void OnTriggerExit (Collider other)
    {
        if (touching)
        {
            theMaterial.color = Color.white;
            touching = false;
        }
    }
}
