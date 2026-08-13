using System;
using UnityEngine;

namespace FF.Net
{
    /// <summary>
    /// Quantized snapshot. Production: delta vs last acked tick, bitpack, &lt; 1200 B.
    /// </summary>
    public struct PawnSnapshot
    {
        public uint Tick;
        public ushort PawnId;
        public Vector3 Position;
        public short Yaw;
        public short Pitch;
        public byte Health;
        public byte WeaponIndex;
        public byte Flags;
    }

    public static class SnapshotCodec
    {
        public static short QuantizeAngle(float deg) => (short)Mathf.Round(deg / 360f * 32767f);

        public static float DequantizeAngle(short q) => q / 32767f * 360f;

        public static void PackPosition(Vector3 p, out short x, out short y, out short z)
        {
            x = (short)Mathf.Round(p.x * 100f);
            y = (short)Mathf.Round(p.y * 100f);
            z = (short)Mathf.Round(p.z * 100f);
        }
    }

    public struct InputPacket
    {
        public uint Seq;
        public uint Tick;
        public byte Buttons;
        public short Yaw;
        public short Pitch;
        public uint FireId;
    }

    [Flags]
    public enum InputButtons : byte
    {
        Fire = 1,
        Ads = 2,
        Jump = 4,
        Crouch = 8,
        Sprint = 16,
        Lethal = 32,
        Tactical = 64,
        Ability = 128
    }
}
