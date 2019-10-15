using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CheckMatchTransforms : MonoBehaviour
{
    public Transform[] transforms;
    public float positionTolerance;
    public float rotationToleranceDeg;
    public GameObject alignedIndicator;

    void Update ()
    {
        if (transforms.Length < 2)
        {
            return;
        }

        float dPosition = Vector3.Distance( transforms[0].position, transforms[1].position );
        float dRotation = Quaternion.Angle( transforms[0].rotation, transforms[1].rotation ); 

        //Debug.Log(dPosition + " " + dRotation);

        if (dPosition <= positionTolerance && dRotation <= rotationToleranceDeg)
        {
            if (!alignedIndicator.activeSelf)
            {
                //Debug.Log("align");
                alignedIndicator.SetActive( true );
            }
        }
        else
        {
            if (alignedIndicator.activeSelf)
            {
                //Debug.Log("NOT ALIGN");
                alignedIndicator.SetActive( false );
            }
        }
    }
}
