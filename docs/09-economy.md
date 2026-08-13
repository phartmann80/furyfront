# Economy

Two currencies. **No third “energy” gate.** Ranked cannot be pay-boosted.

## Currencies

| ID | Name | Earn | Spend |
| --- | --- | --- | --- |
| credits | Credits | Matches, missions | Weapon unlock *skips* (after level gate), rare cosmetics, crate keys |
| fury_coins | Fury Coins | IAP, 300 back from BP | Battle pass, legendary skins, bundles, coins-to-nothing (no credit conversion) |

**IAP coin packs (USD):** 500 / $4.99, 1100 / $9.99, 2400 / $19.99, 5000 / $39.99, 13500 / $99.99. First-time +10% once.

## What the shop sells

| Category | Currency | Notes |
| --- | --- | --- |
| Operator outfits | Coins or BP | Never stats |
| Weapon skins | Coins / credits | Tracer on legendary |
| Charms / emblems / finishers | Mixed | |
| Battle pass | 1000 coins | |
| Seasonal bundles | 1800–2600 coins | Show itemized value |
| XP boost 1h / 24h | Credits or coins | Max stack rule: no stack with event 2XP |
| Ration Token | Credits | Unranked stim precharge only |
| Crate keys | Credits (earned) or 200 coins | Cosmetic crate |
| Health packs | **Not sold as HP** | See gear doc |
| Weapons | Credits skip after `unlockLevel` | Cannot skip AMR-50 before 48 |

**Weapon purchase:** If account level ≥ weapon `unlockLevel`, player may buy with credits instead of playing. If below gate, **cannot buy**. This blocks pay-to-unlock-AMR.

Credit skip prices: `200 + unlockLevel * 40` (KF-16 free).

## Loot crates (legal)

- Cosmetic only. Odds published in-client and `data/shop.json`.
- Duplicate → 100–400 credits.
- Pity: legendary guaranteed by crate 30.
- **No** direct coin purchase of “rare weapon power.”
- Banned regions: convert crates to **direct pick** of the same pool (Belgium/NL policy flag `direct_purchase_required`).

Odds: Standard 55%, Rare 28%, Epic 14%, Legendary 3%.

## Credit sinks (inflation)

Match earn ~450–900 credits. Sinks: skips, rare shop rotation 48 h, charm crafts 1500, weekly crate 800.

Weekly credit earn cap: none at launch; watch telemetry. If median inventory > 80k at S1 week 8, raise skip prices 15%.

## Battle pass economy

Premium 1000 coins. Return 300 coins + ~12 cosmetics. Bundle “Starter” $9.99 = 1100 coins + KF-16 epic skin (not BP).

## Fairness checklist (live ops must sign)

- [ ] No HP/armor/damage/recoil/movement in IAP
- [ ] No premium-only competitive weapons
- [ ] Ranked: ration token / health packs off
- [ ] Health packs if sold at all: PvE / meta only, never competitive combat advantage
- [ ] Crates cosmetic-only (or removed)
- [ ] Attachment meta not gated behind crate
- [ ] Odds in UI
- [ ] Receipts validated server-side

V0.1 does **not** implement the shop, battle pass, crates, or premium currency.
