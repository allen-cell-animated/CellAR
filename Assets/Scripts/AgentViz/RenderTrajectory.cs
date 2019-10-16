using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RenderTrajectory : MonoBehaviour 
{
    public int currentFrame;
    public int frameRate;
    public string trajectoryName;
    public GameObject[] geometryPrefabs;

    GameObjectList[] agentInstances;
    float lastTime;

    TrajectoryFrame[] _trajectory;
    public TrajectoryFrame[] trajectory
    {
        get
        {
            if (_trajectory == null)
            {
                TextAsset[] frames = Resources.LoadAll<TextAsset>(trajectoryName);
                _trajectory = new TrajectoryFrame[frames.Length];
                for (int i = 0; i < frames.Length; i++)
                {
                    _trajectory[i] = new TrajectoryFrame(VizData.GetAgentsFromJSON(frames[i].text));
                }
            }
            return _trajectory;
        }
    }

    void Start ()
    {
        CreateAgents(currentFrame);
    }

    void Update ()
    {
        if (Time.time - lastTime >= 1f / frameRate)
        {
            currentFrame = currentFrame >= trajectory.Length - 1 ? 0 : currentFrame + 1;
            RenderFrame(currentFrame);
            lastTime = Time.time;
        }
    }

    void CreateAgents (int _frame)
    {
        agentInstances = new GameObjectList[geometryPrefabs.Length];
        for (int i = 0; i < agentInstances.Length; i++)
        {
            agentInstances[i] = new GameObjectList();
        }

        int geometryIndex = 0;
        for (int i = 0; i < trajectory[_frame].agents.Length; i++)
        {
            Agent _agent = trajectory[_frame].agents[i];
            geometryIndex = _agent.type == 0 ? (geometryPrefabs.Length - 1) * (i % 2) : _agent.type;

            if (geometryIndex > geometryPrefabs.Length - 1)
            {
                Debug.Log("No geometry prefabs for agent type " + _agent.type);
                continue;
            }

            GameObject obj = Instantiate(geometryPrefabs[geometryIndex], transform);
            obj.transform.localPosition = _agent.position;
            obj.transform.localRotation = _agent.rotation;
            obj.transform.localScale = Vector3.one;

            agentInstances[geometryIndex].gameObjects.Add(obj);
        }
    }

    void RenderFrame (int _frame)
    {
        int[] currentAgents = new int[geometryPrefabs.Length];
        int geometryIndex = 0;
        for (int i = 0; i < trajectory[_frame].agents.Length; i++)
        {
            Agent _agent = trajectory[_frame].agents[i];
            geometryIndex = _agent.type == 0 ? (geometryPrefabs.Length - 1) * (i % 2) : _agent.type;

            if (currentAgents[geometryIndex] >= agentInstances[geometryIndex].gameObjects.Count)
            {
                GameObject obj = Instantiate(geometryPrefabs[geometryIndex], transform);
                obj.transform.localPosition = _agent.position;
                obj.transform.localRotation = _agent.rotation;
                obj.transform.localScale = Vector3.one;

                agentInstances[geometryIndex].gameObjects.Add(obj);
            }
            else
            {
                agentInstances[geometryIndex].gameObjects[currentAgents[geometryIndex]].transform.localPosition = _agent.position;
                agentInstances[geometryIndex].gameObjects[currentAgents[geometryIndex]].transform.localRotation = _agent.rotation;
                agentInstances[geometryIndex].gameObjects[currentAgents[geometryIndex]].SetActive(true);
            }
            currentAgents[geometryIndex]++;
        }

        for (int i = 0; i < agentInstances.Length; i++)
        {
            for (int j = currentAgents[i]; j < agentInstances[i].gameObjects.Count; j++)
            {
                agentInstances[i].gameObjects[j].SetActive(false);
            }
        }
    }
}

[System.Serializable]
public class VizData
{
    public float[] data;
    public int frameNumber;
    public int msgType;
    public float time;

    public static Agent[] GetAgentsFromJSON (string _json)
    {
        return JsonUtility.FromJson<VizData>(_json).GetAgents();
    }

    Agent[] GetAgents ()
    {
        Agent[] agents = new Agent[Mathf.FloorToInt(data.Length / 10f)];
        for (int a = 0; a < agents.Length; a++)
        {
            agents[a] = new Agent(
                Mathf.RoundToInt(data[10 * a + 1]),
                new Vector3(data[10 * a + 2], data[10 * a + 3], data[10 * a + 4]),
                Quaternion.Euler(Mathf.Rad2Deg * new Vector3(data[10 * a + 5], data[10 * a + 6], data[10 * a + 7]))
            );
        }
        return agents;
    }
}

[System.Serializable]
public class Agent
{
    public int type;
    public Vector3 position;
    public Quaternion rotation;

    public Agent (int _type, Vector3 _position, Quaternion _rotation)
    {
        type = _type;
        position = _position;
        rotation = _rotation;
    }

    public override string ToString ()
    {
        return "Agent[type=" + type.ToString() + ",pos=" + position.ToString() + ",rot=" + rotation.eulerAngles.ToString() + "]";
    }
}

[System.Serializable]
public class TrajectoryFrame
{
    public Agent[] agents;

    public TrajectoryFrame (Agent[] _agents)
    {
        agents = _agents;
    }
}

[System.Serializable]
public class GameObjectList
{
    public List<GameObject> gameObjects;

    public GameObjectList () 
    {
        gameObjects = new List<GameObject>();
    }
}
