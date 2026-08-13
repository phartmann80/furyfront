import shop from "../../../data/shop.json" with { type: "json" };

export function weaponSkipCredits(unlockLevel: number): number {
  if (unlockLevel <= 1) return 0;
  return shop.weaponSkipCredits.base + unlockLevel * shop.weaponSkipCredits.perLevel;
}

export function canBuyWeaponSkip(accountLevel: number, unlockLevel: number): boolean {
  return accountLevel >= unlockLevel;
}

export function crateRarity(roll: number, pityCount: number): "standard" | "rare" | "epic" | "legendary" {
  if (pityCount + 1 >= shop.crate.pityLegendary) return "legendary";
  const o = shop.crate.odds;
  if (roll < o.legendary) return "legendary";
  if (roll < o.legendary + o.epic) return "epic";
  if (roll < o.legendary + o.epic + o.rare) return "rare";
  return "standard";
}

export function duplicatePayout(rarity: keyof typeof shop.crate.duplicateCredits): number {
  return shop.crate.duplicateCredits[rarity];
}

export function crateUsesDirectPurchase(region: string): boolean {
  return shop.crate.directPurchaseRequiredRegions.includes(region);
}
