export type FireMode =
  | "auto"
  | "semi"
  | "burst3"
  | "bolt"
  | "pump"
  | "double"
  | "lockon"
  | "single"
  | "melee";

export type WeaponClass =
  | "ar"
  | "smg"
  | "lmg"
  | "sniper"
  | "shotgun"
  | "pistol"
  | "launcher"
  | "melee";

export interface RecoilProfile {
  pattern: [number, number][];
  recoverDegPerSec: number;
  bloomHip: number;
  bloomAds: number;
}

export interface Weapon {
  id: string;
  name: string;
  class: WeaponClass;
  unlockLevel: number;
  rpm: number;
  mag: number;
  reserves: number;
  damageMax: number;
  damageMin: number;
  falloffStart: number;
  falloffEnd: number;
  head: number;
  limb: number;
  adsMs: number;
  sprintOutMs: number;
  move: number;
  reloadMs: number;
  reloadEmptyMs: number;
  rangeOptimal: [number, number];
  pelletCount: number;
  fireMode: FireMode;
  burstDelayMs?: number;
  burstCooldownMs?: number;
  rechamberMs?: number;
  projectile?: boolean;
  lungeM?: number;
  recoil: RecoilProfile;
  audio: string;
  tracer: string | null;
}

export interface HitQuery {
  weapon: Weapon;
  rangeM: number;
  hitbox: "head" | "chest" | "limb";
  armorAbsorb?: number;
}

export const HEALTH_BASE = 100;
export const AR_TTK_MS = { min: 180, max: 320 } as const;
