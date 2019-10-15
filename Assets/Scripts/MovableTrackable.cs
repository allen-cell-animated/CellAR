using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Vuforia;

public class MovableTrackable : MonoBehaviour
{
    Trackable _trackable;
    public Trackable trackable
    {
        get
        {
            if (_trackable == null)
            {
                _trackable = GetComponent<Trackable>();

            }
            return _trackable;
        }
    }


    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
