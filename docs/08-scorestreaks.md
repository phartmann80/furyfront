# Scorestreaks

Scorestreaks charge from **score**, not only kills: 100 kill, 50 assist, 75–150 objective, 25 streak bonus. Dies: **reset** unless Hardline perk (10% cost reduction, keep 25% on death — perk unlock lvl 26).

| ID | Name | Cost | Duration | Role | Counter |
| --- | --- | --- | --- | --- | --- |
| str_uav | UAV | 500 | 12 s | Radar sweep 4 s interval | EMP, Hex, ghost perk (unlock 32) |
| str_cuav | Counter-UAV | 650 | 12 s | Enemy minimap down | EMP |
| str_airstrike | Airstrike | 900 | 1 pass | 3 bombs, 6 m lethal, player-aimed | Trophy, buildings |
| str_sentry | Sentry Turret | 1000 | 40 s | 28 dmg, 500 RPM, 45° cone, 400 HP | EMP, explosives, Hex |
| str_supply | Supply Drop | 1100 | crate | Random: ammo + 1 rare lethal **or** 500 score | Stealable |
| str_drones | Drone Swarm | 1300 | 8 s | 6 drones, 18 dmg/hit, chase LOS | EMP, shooting drones 40 HP |
| str_jug | Juggernaut Armor | 1600 | 25 s or 250 absorb | +250 absorb, −20% move, minigun SAW-60 reskin | Launchers, thermite, knives still 100 |

## Rules

- One streak slot chain: 3 equipped (low/mid/high). Cannot duplicate.
- Call-in: 1.2 s tablet, vulnerable.
- UAV does not show crouched Nyx with Ghost.
- Airstrike: danger close friendly 50% (casual 0%).
- Juggernaut: no slide, no tactical sprint, no other streaks until end. Exits at 0 absorb (not extra lives).
- 20v20: costs ×1.15.

## VFX / audio profile

- UAV: jet flyby, map ping tone 440 Hz team / 180 Hz enemy warning.
- Airstrike: laser paint, incoming whistle 1.4 s.
- Sentry: deploy clank, servo, tracer green.
- Drones: bee-swarm doppler, red LEDs.
- Juggernaut: stomp bus, low-pass world mix 2 s on call-in.

## UI

Streak pips above ammo. Hold `4` to select if multiple ready. Mobile: right-side streak stack.
