using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ImportTrajectory : MonoBehaviour 
{
    AgentData _agentData;
    public AgentData agentData
    {
        get
        {
            if (_agentData == null)
            {
                _agentData = AgentData.CreateFromJSON("");
            }
            return _agentData;
        }
    }
}

[System.Serializable]
public class AgentData
{
    public string name;
    public Vector3 position;
    public Quaternion rotation;

    public AgentData (string _name, Vector3 _position, Quaternion _rotation)
    {
        name = _name;
        position = _position;
        rotation = _rotation;
    }

    public static AgentData CreateFromJSON (string json)
    {
        return JsonUtility.FromJson<AgentData>(json);
    }
}
