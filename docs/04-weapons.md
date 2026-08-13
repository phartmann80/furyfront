# Weapons

Numbers in this document are **summaries**. Canonical fields: `data/weapons.json`, `data/attachments.json`. TTK assumes 100 HP, chest, 10 m, 0 ping.

## Class roles

| Class | Optimal | ADS | Move | Identity |
| --- | --- | --- | --- | --- |
| AR | 12–35 m | Mid | Mid | Default winners |
| SMG | 0–16 m | Fast | Fast | Sprint-out kings |
| LMG | 18–45 m | Slow | Slow | Lane lock |
| Sniper | 40 m+ | Slow | Mid | One-shot head (most) |
| Shotgun | 0–8 m | Fast | Mid | Pellet volume |
| Pistol | Panic / SMG swap | Fast | Fast | Always secondary |
| Launcher | Streaks / clusters | Slow | Slow | Utility
| Melee | 1.8 m | n/a | Fast | Finisher / silent |

## Recoil model

Each shot adds a kick sample `(yaw, pitch)` from the weapon pattern, then a **repeatable** pattern index, plus **bloom** (cone) that ADS reduces. Server uses bloom only (fairness). Client draws the pattern so skilled players compensate.

Recoil recover: 8–14 °/s toward rest when not firing.

## Damage curves

```
damage(d) =
  dmgMax                       if d <= falloffStart
  lerp(dmgMax, dmgMin, t)      if falloffStart < d < falloffEnd
  dmgMin                       if d >= falloffEnd
```

Head / limb multipliers apply after falloff.

## Launch roster (TTK chest @ 10 m)

| ID | Name | Class | RPM | Mag | Dmg | STK | TTK ms | Unlock |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ar_kf16 | KF-16 Vanguard | AR | 800 | 30 | 28 | 4 | 225 | 1 |
| ar_vesper | Vesper-47 | AR | 600 | 30 | 34 | 3 | 200 | 4 |
| ar_acr9 | ACR-9 Spear | AR | 625 | 30 | 32 | 4 | 288 | 13 |
| ar_rho45 | Rho-45 | AR | 900 | 30 | 24 | 5 | 267 | 21 |
| ar_mxr | MXR-Burst | AR | 3×720 burst | 30 | 36 | 3 (1 burst) | ~150 intra | 33 |
| smg_wasp | WASP-9 | SMG | 1100 | 32 | 22 | 5 | 218 | 1 |
| smg_mpxc | MPX-C | SMG | 800 | 30 | 26 | 4 | 225 | 7 |
| smg_raze | RAZE-90 | SMG | 950 | 50 | 21 | 5 | 253 | 16 |
| smg_cobra | Cobra Dual | SMG | 750 | 40 | 23 | 5 | 320 | 29 |
| lmg_saw60 | SAW-60 | LMG | 650 | 60 | 30 | 4 | 277 | 10 |
| lmg_harc | HARC-26 | LMG | 720 | 75 | 26 | 4 | 250 | 24 |
| lmg_brute | Brute | LMG | 500 | 100 | 38 | 3 | 240 | 41 |
| sn_longmere | Longmere .338 | Sniper | 48 | 5 | 95 | 2 body / 1 head | — | 14 |
| sn_kestrel | Kestrel 7.62 | Sniper | 55 | 10 | 80 | 2 / 1 head ADS | — | 27 |
| sn_amr50 | AMR-50 | Sniper | 32 | 5 | 120 | 1 body | — | 48 |
| sh_hollow | Hollow-12 | Shotgun | 70 | 8 | 12×8 pellets | 1 @ 6 m | — | 6 |
| sh_sweeper | Sweeper | Shotgun | 180 | 10 | 9×6 | 1 @ 5 m | — | 19 |
| sh_breach | Breach-4 | Shotgun | 90×2 | 2 | 16×6 | 1 @ 8 m | — | 36 |
| pis_k5 | K5 Compact | Pistol | 400 | 15 | 32 | 4 | 450 | 1 |
| pis_reckoning | .45 Reckoning | Pistol | 280 | 8 | 48 | 3 | 429 | 11 |
| pis_staccato | Staccato | Pistol | 900 | 20 | 18 | 6 | 333 | 31 |
| ln_hydra | RL-4 Hydra | Launcher | lock 1.2 s | 1 | 125 splash | streak/veh | — | 20 |
| ln_mgl | MGL-20 | Launcher | 80 | 4 | 90 splash 4.5 m | — | — | 38 |
| ln_hole | Holepunch | Launcher | 40 | 1 | 180 direct | wall | — | 52 |
| ml_knife | Combat Knife | Melee | — | — | 100 | 1 | lunge 1.8 m | 1 |
| ml_axe | Riot Axe | Melee | — | — | 100 | 1 | slower, 2.1 m | 25 |
| ml_baton | Stun Baton | Melee | — | — | 55 + 0.6 s stun | 2 | EMP tick | 44 |

MXR burst: three rounds 50 ms apart; if all chest connect, TTK ≈ 100 ms — **capped by burst cooldown 700 ms**. Missed bursts are the skill tax. Do not buff damage.

AMR-50: 1-shot chest, 1.15 s rechamber, glint +40%, move −12%. Intentional power weapon.

## Attachments (slots)

Optic, Muzzle, Barrel, Underbarrel, Magazine, Stock, Laser, Ammunition.

**Stacking caps** (cannot exceed):

| Stat | Cap vs base |
| --- | --- |
| ADS time | −18% |
| Recoil | −28% |
| Mag size | +20 rounds AR/SMG, +30 LMG |
| Damage | **0%** (ammo types change falloff or flinch only) |
| Move speed | +6% / −12% |

Ammunition types: FMJ (wall +15%), Subsonic (suppress + range −12%), Hollow (limb 1.0, head 1.25 instead of class), Incendiary (2 dmg/s 1.5 s, −8% mag).

## Skins

Rarity: Standard, Rare, Epic, Legendary, Prestige. Legendary may change tracer, inspect, and muzzle color — **never hitbox or damage**.

## Audio variations

Each gun: outdoor / indoor / suppressed / ADS (filtered) / third-person (distant LP). Tail convolution by map (harbor vs snow). See audio doc.

## Weapon XP

| Level | Unlock |
| --- | --- |
| 1–5 | optics |
| 6–12 | muzzles / barrels |
| 13–20 | mags / grips |
| 21–30 | stocks / lasers |
| 31–40 | perks / ammo |
| 41–50 | mastery camo challenges |

Weapon XP: 1 XP per damage dealt + 25 per kill + 10 assist, × mode modifier.
