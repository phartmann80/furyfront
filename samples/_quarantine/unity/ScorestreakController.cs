using UnityEngine;

namespace FF.Gameplay
{
    public sealed class ScorestreakController : MonoBehaviour
    {
        public int Score;
        public int[] EquippedCosts = { 500, 900, 1300 };
        readonly bool[] _ready = new bool[3];

        public void AddScore(int amount)
        {
            Score += amount;
            for (int i = 0; i < EquippedCosts.Length; i++)
                _ready[i] = Score >= EquippedCosts[i];
        }

        public void OnDeath(bool hardline)
        {
            if (hardline) Score = Mathf.RoundToInt(Score * 0.25f);
            else Score = 0;
            AddScore(0);
        }

        /// <summary>Server RPC: validate cost, play 1.2s tablet, spawn streak entity.</summary>
        public bool TryCallIn(int slot)
        {
            if (slot < 0 || slot >= EquippedCosts.Length) return false;
            if (!_ready[slot]) return false;
            _ready[slot] = false;
            EquippedCosts[slot] = int.MaxValue;
            return true;
        }
    }
}
