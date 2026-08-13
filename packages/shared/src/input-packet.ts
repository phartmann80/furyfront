/**
 * Example client input packet builder (web or native companion).
 * The Unity client is authoritative for sending these; this is the contract.
 */
export interface FirePacket {
  seq: number;
  tick: number;
  buttons: number;
  yaw: number;
  pitch: number;
  fireId: number;
  origin: [number, number, number];
  clientTime: number;
}

export const Buttons = {
  Fire: 1,
  Ads: 2,
  Jump: 4,
  Crouch: 8,
  Sprint: 16,
  Lethal: 32,
  Tactical: 64,
  Ability: 128,
} as const;

export function packInput(p: FirePacket): Uint8Array {
  const buf = new ArrayBuffer(45);
  const v = new DataView(buf);
  v.setUint32(0, p.seq, true);
  v.setUint32(4, p.tick, true);
  v.setUint8(8, p.buttons);
  v.setInt16(9, p.yaw, true);
  v.setInt16(11, p.pitch, true);
  v.setUint32(13, p.fireId, true);
  v.setFloat32(17, p.origin[0], true);
  v.setFloat32(21, p.origin[1], true);
  v.setFloat32(25, p.origin[2], true);
  v.setFloat32(29, p.clientTime, true);
  return new Uint8Array(buf);
}
