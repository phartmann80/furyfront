using UnityEngine;

namespace FF.Net
{
    /// <summary>
    /// Server rewind: store pose history at 30 Hz, raycast against capsules at clientTime.
    /// Window: 120 ms ranked / 180 ms casual, never beyond.
    /// </summary>
    public sealed class LagCompensation
    {
        public const float RankedWindow = 0.12f;
        public const float CasualWindow = 0.18f;
        public const float MuzzleToleranceM = 0.45f;

        public readonly struct PoseSample
        {
            public readonly float Time;
            public readonly Vector3 Position;
            public readonly Quaternion Rotation;

            public PoseSample(float time, Vector3 position, Quaternion rotation)
            {
                Time = time;
                Position = position;
                Rotation = rotation;
            }
        }

        public static float RewindWindow(bool ranked, float rttMs)
        {
            float cap = ranked ? RankedWindow : CasualWindow;
            return Mathf.Min(cap, rttMs / 2000f + 0.04f);
        }

        public static PoseSample Interpolate(PoseSample a, PoseSample b, float t)
        {
            float u = Mathf.InverseLerp(a.Time, b.Time, t);
            return new PoseSample(
                t,
                Vector3.Lerp(a.Position, b.Position, u),
                Quaternion.Slerp(a.Rotation, b.Rotation, u));
        }

        public static bool MuzzleValid(Vector3 clientOrigin, Vector3 serverMuzzle)
        {
            return (clientOrigin - serverMuzzle).sqrMagnitude <= MuzzleToleranceM * MuzzleToleranceM;
        }
    }
}
