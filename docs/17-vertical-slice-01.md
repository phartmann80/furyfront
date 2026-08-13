# Vertical Slice 0.1 — Operation: Broken Perimeter

**Platform:** Android first (editor keyboard allowed for development).  
**Map:** Ironfall Depot graybox (`game/scenes/maps/ironfall_depot.tscn`).  
**Operator:** Vex (Assault).  
**Enemy:** Shadowbreakers — Phantom, Hacker, Enforcer, then elite commander.

## Beat sheet

| # | Beat | Gameplay |
| --- | --- | --- |
| 0 | Cinematic 15–30 s | Depot establish → comms distortion → breach → alarm → deploy |
| 1 | Spawn | Security staging, loadout KF-16 |
| 2 | Alarm | HUD: SECURITY BREACH |
| 3 | Checkpoint attack | Phantoms push gate |
| 4 | Move to command | Objective: DEFEND COMMAND CENTER |
| 5 | Grid disabled | Security Integrity starts dropping |
| 6 | Engineer | Interact at Comms to restore (hold 3.5 s) |
| 7 | Grid restored | Integrity freeze / recover |
| 8 | Data steal | Hackers at Server room; Enemy Data Transfer rises |
| 9 | Extraction | Intercept LZ team |
| 10 | Commander | Elite Shadowbreaker |
| 11 | Collapse | Remaining AI retreat or die |
| 12 | Results | Success / fail, kills, time, integrity |

## Win / lose

- **Win:** commander down or retreat + transfer aborted + integrity > 0.  
- **Lose:** integrity 0, or data transfer 100%, or all Fury Front down (V0.1: player death can debug-respawn; mission fail if command lost).

## Autoloads

`EventBus`, `ContentCatalog`, `GameState`, `GraphicsProfile`, `AudioDirector`

## Input map

`move_*`, `look` (mouse), `fire`, `ads`, `reload`, `sprint`, `crouch`, `jump`, `weapon_next`, `grenade`, `tactical`, `interact`, `debug_reset`

Touch HUD duplicates all of these. Keyboard is not the architecture — `InputService` is.

## What V0.1 is not

Store, Pass, crates, 125 levels, 27 guns, 12 operators, BR, dedicated server, matchmaking.

## Cinematic

Text + camera rig only. No full-motion video. Gameplay immediately after.
