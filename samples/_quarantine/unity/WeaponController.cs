using UnityEngine;

namespace FF.Gameplay
{
    /// <summary>
    /// Client presentation + input. Ammo, RPM, and hits are confirmed by the server.
    /// Recoil pattern is local so skilled players can compensate; bloom is also sent as fireId seed.
    /// </summary>
    public sealed class WeaponController : MonoBehaviour
    {
        public WeaponStats Stats;
        public Vector2[] RecoilPattern;
        public Transform Muzzle;
        public AudioSource FireAudio;
        public ParticleSystem MuzzleFx;

        int _ammo;
        int _patternIndex;
        float _lastFire;
        float _recoilPitch;
        float _recoilYaw;

        public void ServerConfirmAmmo(int ammo) => _ammo = ammo;

        public bool TryFire(bool ads, float now, out FireInput input)
        {
            input = default;
            if (_ammo <= 0) return false;
            if (!DamageModel.FireLegal(Stats, _lastFire, now)) return false;

            _lastFire = now;
            Vector2 kick = RecoilPattern.Length == 0
                ? Vector2.zero
                : RecoilPattern[_patternIndex++ % RecoilPattern.Length];
            _recoilYaw += kick.x;
            _recoilPitch += kick.y;

            MuzzleFx?.Play();
            if (FireAudio) FireAudio.Play();

            input = new FireInput
            {
                Origin = Muzzle.position,
                Direction = Muzzle.forward,
                Ads = ads,
                ClientTime = now,
                FireId = (uint)Time.frameCount
            };
            return true;
        }

        void LateUpdate()
        {
            float recover = 11f * Time.deltaTime;
            _recoilPitch = Mathf.MoveTowards(_recoilPitch, 0f, recover);
            _recoilYaw = Mathf.MoveTowards(_recoilYaw, 0f, recover);
        }
    }

    public struct FireInput
    {
        public Vector3 Origin;
        public Vector3 Direction;
        public bool Ads;
        public float ClientTime;
        public uint FireId;
    }
}
