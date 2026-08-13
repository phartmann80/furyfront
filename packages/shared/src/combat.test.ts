import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { isPrimaryTtkInBand, timeToKillMs, type Weapon } from "./combat.ts";
import { AR_TTK_MS } from "./types.ts";
import { totalXpToLevel, xpToNext } from "./xp.ts";
import { canBuyWeaponSkip, weaponSkipCredits } from "./economy.ts";

const root = join(dirname(fileURLToPath(import.meta.url)), "../../../");
const weapons = JSON.parse(readFileSync(join(root, "data/weapons.json"), "utf8")) as {
  weapons: Weapon[];
};

const arSmgLmg = weapons.weapons.filter((w) => ["ar", "smg", "lmg"].includes(w.class));
for (const w of arSmgLmg) {
  const ttk = timeToKillMs(w, 10);
  if (w.fireMode === "burst3") continue;
  assert.ok(ttk != null, `${w.id} missing TTK`);
  const band = w.class === "smg" ? { min: 140, max: 330 } : AR_TTK_MS;
  // LMG allowed slightly above AR max
  const max = w.class === "lmg" ? 340 : band.max;
  const min = w.class === "smg" ? 140 : AR_TTK_MS.min;
  assert.ok(
    isPrimaryTtkInBand(w, min, max) || (ttk >= min && ttk <= max),
    `${w.id} TTK ${ttk} outside ${min}-${max}`,
  );
}

assert.equal(xpToNext(125), 0);
assert.ok(totalXpToLevel(125) > 1_000_000);
assert.equal(canBuyWeaponSkip(10, 20), false);
assert.ok(weaponSkipCredits(20) > 0);

console.log(`ok  ${arSmgLmg.length} primaries  xp125=${totalXpToLevel(125)}`);
