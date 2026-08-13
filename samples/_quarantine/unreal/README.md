# FuryFront Verse / Blueprint notes (non-primary)

Primary runtime is Unity. These samples exist so a parallel Unreal team can share **data contracts**, not a second live product.

## Verse — score grant (island / UEFN-style)

```verse
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

score_from_kill<public> : int = 100
score_from_assist<public> : int = 50

grant_score<public>(agent:agent, amount:int):void =
    Print("FF score {amount}")
```

Do not implement rewind hitreg in Verse — dedicated C++/Unity server remains authority if Unreal is ever used for a console SKU.

## Blueprint graph — UAV call-in

1. **Input Action** `CallStreak` → **Branch** `Score >= 500`.
2. **Play Montage** tablet 1.2 s (uninterruptible movement allowed, fire blocked).
3. **Spawn Actor** `BP_UAV` at +80 m, team id.
4. **Timer** 12 s, sweep every 4 s: **Get All Pawns** opposing team, **Set Minimap Ping**.
5. **On EMP overlap** → destroy UAV.

## Shared JSON

Import `data/*.json` via a DataTable converter. Do not fork numbers.
