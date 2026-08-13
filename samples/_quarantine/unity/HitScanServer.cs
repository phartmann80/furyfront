using UnityEngine;

namespace FF.Net
{
    /// <summary>
    /// Dedicated-server hitscan. Client never confirms damage.
    /// </summary>
    public static class HitScanServer
    {
        public static bool TryHitscan(
            Vector3 origin,
            Vector3 direction,
            Vector3 serverMuzzle,
            float clientTime,
            float serverTime,
            bool ranked,
            float rttMs,
            LayerMask pawnMask,
            out RaycastHit hit)
        {
            hit = default;
            if (!LagCompensation.MuzzleValid(origin, serverMuzzle)) return false;
            float window = LagCompensation.RewindWindow(ranked, rttMs);
            if (serverTime - clientTime > window || clientTime > serverTime + 0.04f) return false;

            // Production: rewind all pawn capsules to clientTime, then raycast.
            const float maxRange = 180f;
            return Physics.Raycast(origin, direction.normalized, out hit, maxRange, pawnMask);
        }
    }
}
