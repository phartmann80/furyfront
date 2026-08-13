import { HEALTH_BASE, type HitQuery, type Weapon } from "./types.ts";

export function damageAtRange(weapon: Weapon, rangeM: number): number {
  if (rangeM <= weapon.falloffStart) return weapon.damageMax;
  if (rangeM >= weapon.falloffEnd) return weapon.damageMin;
  const t = (rangeM - weapon.falloffStart) / (weapon.falloffEnd - weapon.falloffStart);
  return weapon.damageMax + (weapon.damageMin - weapon.damageMax) * t;
}

export function hitboxMultiplier(weapon: Weapon, hitbox: HitQuery["hitbox"]): number {
  if (hitbox === "head") return weapon.head;
  if (hitbox === "limb") return weapon.limb;
  return 1;
}

/** Pellet or bullet damage after falloff, hitbox, and armor absorb. */
export function applyHit(query: HitQuery): { raw: number; applied: number } {
  const pellet = damageAtRange(query.weapon, query.rangeM) * hitboxMultiplier(query.weapon, query.hitbox);
  const raw = pellet * query.weapon.pelletCount;
  const absorb = query.armorAbsorb ?? 0;
  const applied = Math.max(0, raw - absorb);
  return { raw, applied };
}

export function intervalMs(rpm: number): number {
  return 60000 / rpm;
}

export function shotsToKill(damagePerShot: number, health = HEALTH_BASE): number {
  return Math.ceil(health / damagePerShot);
}

/**
 * Chest TTK at a range. BALANCE_TARGET_V0 (see data/balance.json) is a prototype
 * guardrail, not a frozen live-ops law. Burst first-burst kill ignores cooldown tax.
 */
export function timeToKillMs(weapon: Weapon, rangeM = 10, health = HEALTH_BASE): number | null {
  if (weapon.projectile || weapon.fireMode === "melee") return null;
  if (weapon.class === "sniper" || weapon.class === "launcher") return null;

  const perPellet = damageAtRange(weapon, rangeM);
  const perShot = perPellet * weapon.pelletCount;
  if (perShot <= 0) return null;
  const stk = shotsToKill(perShot, health);

  if (weapon.fireMode === "burst3" && weapon.burstDelayMs) {
    if (stk <= 3) return (stk - 1) * weapon.burstDelayMs;
    const bursts = Math.ceil(stk / 3);
    const extra = weapon.burstCooldownMs ?? 700;
    return (bursts - 1) * extra + 2 * weapon.burstDelayMs;
  }

  return (stk - 1) * intervalMs(weapon.rpm);
}

export function isPrimaryTtkInBand(weapon: Weapon, minMs: number, maxMs: number): boolean {
  if (weapon.class !== "ar" && weapon.class !== "smg" && weapon.class !== "lmg") return true;
  if (weapon.fireMode === "burst3") return true;
  const ttk = timeToKillMs(weapon, 10);
  if (ttk == null) return true;
  return ttk >= minMs && ttk <= maxMs;
}

/** Server-side fire rate slop: allow 8% faster than RPM before rejecting. */
export function fireLegal(weapon: Weapon, lastFireMs: number, nowMs: number): boolean {
  const minGap = intervalMs(weapon.rpm) * 0.92;
  return nowMs - lastFireMs >= minGap;
}

export function rewindWindowMs(ranked: boolean, rttMs: number): number {
  const cap = ranked ? 120 : 180;
  return Math.min(cap, rttMs / 2 + 40);
}
