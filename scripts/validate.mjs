import { readFileSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const fail = [];
const warn = [];

function load(rel) {
  const p = join(root, rel);
  if (!existsSync(p)) {
    fail.push(`missing file ${rel}`);
    return null;
  }
  return JSON.parse(readFileSync(p, "utf8"));
}

const weapons = load("data/weapons.json");
const shop = load("data/shop.json");
const xp = load("data/xp-curve.json");
const maps = load("data/maps.json");
const modes = load("data/modes.json");
const operators = load("data/operators.json");
const enemies = load("data/enemies.json");
const missions = load("data/missions.json");
const factions = load("data/factions.json");
const balance = load("data/balance.json");

function dmgAt(w, range) {
  if (range <= w.falloffStart) return w.damageMax;
  if (range >= w.falloffEnd) return w.damageMin;
  const t = (range - w.falloffStart) / (w.falloffEnd - w.falloffStart);
  return w.damageMax + (w.damageMin - w.damageMax) * t;
}

function ttkMs(w) {
  if (w.projectile || w.fireMode === "melee") return null;
  if (w.class === "sniper" || w.class === "launcher") return null;
  const per = dmgAt(w, 10) * (w.pelletCount || 1);
  if (per <= 0) return null;
  const stk = Math.ceil(100 / per);
  if (w.fireMode === "burst3") return (Math.min(stk, 3) - 1) * (w.burstDelayMs || 50);
  return (stk - 1) * (60000 / w.rpm);
}

if (weapons) {
  const ids = new Set();
  for (const w of weapons.weapons) {
    if (ids.has(w.id)) fail.push(`duplicate weapon id ${w.id}`);
    ids.add(w.id);
    if (w.damageMax < 0 || w.damageMin < 0) fail.push(`${w.id} negative damage`);
    if (w.damageMax < w.damageMin) fail.push(`${w.id} inverted damage curve`);
    if (w.falloffEnd < w.falloffStart) fail.push(`${w.id} inverted falloff`);
    if (w.fireMode !== "melee") {
      if (!w.mag || w.mag < 1) fail.push(`${w.id} impossible magazine ${w.mag}`);
      if (w.rpm < balance.rpmBounds.min || w.rpm > balance.rpmBounds.max) {
        fail.push(`${w.id} rpm ${w.rpm} outside ${balance.rpmBounds.min}-${balance.rpmBounds.max}`);
      }
    }
    const ttk = ttkMs(w);
    if (ttk != null && ["ar", "smg", "lmg"].includes(w.class) && w.fireMode !== "burst3") {
      if (ttk < balance.ttkBandMs.oneFrameLethalMs) {
        fail.push(`${w.id} one-frame lethal TTK ${ttk.toFixed(1)}ms`);
      }
      const min = w.class === "smg" ? balance.ttkBandMs.smgMin : w.class === "lmg" ? balance.ttkBandMs.lmgMin : balance.ttkBandMs.arMin;
      const max = w.class === "smg" ? balance.ttkBandMs.smgMax : w.class === "lmg" ? balance.ttkBandMs.lmgMax : balance.ttkBandMs.arMax;
      if (ttk < min || ttk > max) {
        warn.push(`BALANCE_TARGET_V0 ${w.id} TTK ${ttk.toFixed(1)} outside ${min}-${max}`);
      }
    }
  }
}

if (operators) {
  const ids = new Set();
  for (const o of operators.operators) {
    if (ids.has(o.id)) fail.push(`duplicate operator ${o.id}`);
    ids.add(o.id);
  }
}

if (maps) {
  const ids = new Set();
  for (const m of maps.maps) {
    if (ids.has(m.id)) fail.push(`duplicate map ${m.id}`);
    ids.add(m.id);
    for (const modeId of m.modes || []) {
      const found = modes?.modes?.some((x) => x.id === modeId);
      if (!found) fail.push(`map ${m.id} unknown mode ${modeId}`);
    }
  }
}

if (modes?.modes?.some((m) => /zombie|horde/i.test(m.id + m.name))) {
  fail.push("Zombie Horde / horde mode must not exist");
}

if (factions) {
  if (factions.friendly?.id !== "faction_fury_front") fail.push("friendly faction lock");
  if (factions.enemy?.id !== "faction_shadowbreakers") fail.push("enemy faction lock");
}

if (enemies) {
  const wids = new Set(weapons?.weapons?.map((w) => w.id) || []);
  for (const e of enemies.archetypes) {
    if (!wids.has(e.weaponId)) fail.push(`enemy ${e.id} missing weapon ${e.weaponId}`);
    if (e.health <= 0) fail.push(`enemy ${e.id} health`);
  }
}

if (missions) {
  const wids = new Set(weapons?.weapons?.map((w) => w.id) || []);
  const oids = new Set(operators?.operators?.map((o) => o.id) || []);
  const mids = new Set(maps?.maps?.map((m) => m.id) || []);
  const modeIds = new Set(modes?.modes?.map((m) => m.id) || []);
  if (!modeIds.has(missions.modeId)) fail.push(`mission unknown mode ${missions.modeId}`);
  if (!mids.has(missions.mapId)) fail.push(`mission unknown map ${missions.mapId}`);
  if (!oids.has(missions.operatorId)) fail.push(`mission unknown operator ${missions.operatorId}`);
  for (const id of missions.playerWeapons || []) {
    if (!wids.has(id)) fail.push(`mission missing weapon ${id}`);
  }
}

if (shop) {
  const odds = shop.crate.odds;
  const sum = odds.standard + odds.rare + odds.epic + odds.legendary;
  if (Math.abs(sum - 1) > 1e-9) fail.push(`crate odds sum ${sum}`);
  if (shop.fairness?.noPowerIap !== true) fail.push("shop fairness noPowerIap");
}

if (xp) {
  if (xp.maxLevel !== 125) fail.push("maxLevel");
  if (xp.formula.base <= 0) fail.push("xp formula");
}

if (warn.length) console.warn(warn.join("\n"));
if (fail.length) {
  console.error(fail.join("\n"));
  process.exit(1);
}
console.log(
  `validate ok  weapons=${weapons.weapons.length} maps=${maps.maps.length} modes=${modes.modes.length} mission=${missions.id}`,
);
