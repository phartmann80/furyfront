using System;
using UnityEngine;

namespace FF.Gameplay
{
    /// <summary>
    /// Mirrors packages/shared combat math. Keep test vectors in data/weapons.json in sync.
    /// </summary>
    public static class DamageModel
    {
        public const int HealthBase = 100;

        public static float DamageAtRange(WeaponStats w, float rangeM)
        {
            if (rangeM <= w.FalloffStart) return w.DamageMax;
            if (rangeM >= w.FalloffEnd) return w.DamageMin;
            float t = (rangeM - w.FalloffStart) / (w.FalloffEnd - w.FalloffStart);
            return Mathf.Lerp(w.DamageMax, w.DamageMin, t);
        }

        public static float HitboxMul(WeaponStats w, Hitbox box)
        {
            return box switch
            {
                Hitbox.Head => w.Head,
                Hitbox.Limb => w.Limb,
                _ => 1f
            };
        }

        public static int ApplyHit(WeaponStats w, float rangeM, Hitbox box, float armorAbsorb)
        {
            float raw = DamageAtRange(w, rangeM) * HitboxMul(w, box) * w.PelletCount;
            return Mathf.Max(0, Mathf.RoundToInt(raw - armorAbsorb));
        }

        public static bool FireLegal(WeaponStats w, float lastFireTime, float now)
        {
            float minGap = 60f / w.Rpm * 0.92f;
            return now - lastFireTime >= minGap;
        }
    }

    public enum Hitbox { Head, Chest, Limb }

    [Serializable]
    public struct WeaponStats
    {
        public string Id;
        public float Rpm;
        public float DamageMax;
        public float DamageMin;
        public float FalloffStart;
        public float FalloffEnd;
        public float Head;
        public float Limb;
        public int PelletCount;
    }
}
