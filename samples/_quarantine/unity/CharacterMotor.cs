using UnityEngine;

namespace FF.Gameplay
{
    /// <summary>
    /// Same motor on client (predict) and server (auth). Corrections replay unacked inputs.
    /// </summary>
    public sealed class CharacterMotor : MonoBehaviour
    {
        public float Walk = 4.2f;
        public float Sprint = 6.2f;
        public float TacSprint = 7.75f;
        public float Gravity = -20f;
        public float JumpSpeed = 7.2f;
        public float SlideDuration = 0.45f;
        public float SlideSpeed = 8.4f;

        CharacterController _cc;
        Vector3 _vel;
        float _slideT;
        bool _grounded;

        void Awake() => _cc = GetComponent<CharacterController>();

        public void Simulate(Vector2 move, bool sprint, bool tac, bool jump, bool crouch, float dt)
        {
            _grounded = _cc.isGrounded;
            if (_grounded && _vel.y < 0f) _vel.y = -2f;

            float speed = Walk;
            if (sprint) speed = Sprint;
            if (tac) speed = TacSprint;
            if (_slideT > 0f)
            {
                _slideT -= dt;
                speed = SlideSpeed;
            }
            else if (crouch && sprint)
            {
                _slideT = SlideDuration;
            }

            Vector3 wish = transform.right * move.x + transform.forward * move.y;
            wish = Vector3.ClampMagnitude(wish, 1f) * speed;
            _vel.x = wish.x;
            _vel.z = wish.z;
            if (jump && _grounded) _vel.y = JumpSpeed;
            _vel.y += Gravity * dt;
            _cc.Move(_vel * dt);
        }
    }
}
