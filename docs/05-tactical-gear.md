# Tactical Gear

Loadout: **1 Lethal**, **1 Tactical**, **1 Field Upgrade**. Extra lethal via Ash or scorestreak crate. Ranked uses the same kit; shop “health packs” do **not** inject into ranked loadouts.

## Lethal

| ID | Name | Fuse | Inner / outer | Effect |
| --- | --- | --- | --- | --- |
| leth_frag | Frag | 1.8 s cookable | 4.5 m / 8 m | 90 → 20 dmg |
| leth_semtex | Stick Charge | 1.4 s on stick | 3.5 / 6.5 | 95 → 25, sticks pawns/walls |
| leth_thermite | Thermite | instant burn | 2.2 m disk | 8 dmg/s, 6.5 s, blocks doors |
| leth_throwing | Throwing Knife | instant | hitscan-ish projectile | 100 chest/head, 80 limb |

Cook UI: needle 0–1.8 s. Dropped frag if killed while cooking (casual); ranked: drops live.

## Tactical

| ID | Name | Duration | Radius | Effect |
| --- | --- | --- | --- | --- |
| tac_smoke | Smoke | 9.5 s | 6.5 m | Blocks vis + heartbeat; thermal sees 40% |
| tac_flash | Flashbang | 2.8–4.5 s | 7 m | Full white if looking at; scaled by angle |
| tac_stun | Stun | 2.2 s | 6 m | Move −60%, turn −50% |
| tac_tear | Tear Gas | 7 s | 5.5 m | Cough, bloom +30%, HUD smear, 4 dmg/s (cap 20) |
| tac_emp | EMP Grenade | 4 s | 8 m | Minimap, streaks, optics, Nyx/Wraith electronics |

Flash vs looking away: 0.6 s. Smoke is the S&D meta; do not nerf duration below 8 s without map retune.

## Field upgrades

| ID | Name | Charge | Notes |
| --- | --- | --- | --- |
| fld_shield | Deployable Shield | 45 s | 2.0 × 1.2 m, 200 HP, 25 s life. Golem wall is larger; they do not stack stacked-HP exploits (second replaces). |
| fld_stim | Field Stim | 35 s | 18 HP over 2.5 s + clear stun 50%. Not a shop item in-match. |
| fld_trophy | Trophy Lite | 50 s | Eats 2 projectiles in 3.5 m, 20 s. |
| fld_recon | Recon Drone | 60 s | 12 s fly, mark 1 target; Hex EMP kills it. |
| fld_ammo | Ammo Box | 40 s | 1 mag per ally, 4 uses, 20 s. |

## Health kits (design resolution)

The shop request for “health packs” is implemented as:

1. **Field Stim** (loadout, earned) — the actual heal.
2. **Ration Token** (shop, **unranked / Horde only**): start match with Field Stim pre-charged. **Disabled in ranked and tournament.**
3. No mid-match IAP.

This keeps the feature without selling HP in competitive play.

## Throw rules

- Cook + throw from 18 m frag average.
- Left-click short toss, long-press overhand.
- Bounce restitution 0.35. Smoke pops 0.4 s after rest or 1.2 s air.
- Friendly smoke does not damage; tear gas does 50% to allies in 20v20 only.
