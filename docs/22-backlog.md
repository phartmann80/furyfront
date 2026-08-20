# Fury Front backlog

## Fury Front Landing Page — Final Launch Polish (DEFERRED)

Approved 2026-08-14: the current cinematic landing at `furyfront.app/` is **good enough for this development stage**. Do not spend engineering time on it unless something is broken.

Return to this list only after Operation: Broken Perimeter is a genuinely playable combat slice.

- Privacy Policy
- Terms of Service
- Cookie / privacy controls where required
- Legal notice / company information
- Support / contact
- Footer links
- Accessibility review
- SEO
- Final responsive pass
- Final landing performance pass
- Final launch / legal review

The hero still, branding, PLAY FURY FRONT, and trailer modal stay as-is until then.

---

## Active product priority

V0.1 gameplay is **accepted** (production `000fc95`). Active work is **Visual Benchmark 0.2** — see `docs/24-visual-benchmark-02.md` and `docs/23-v02-performance-budget.md`.

Human playtest of https://furyfront.app/play/ stays open. Genuine blockers outrank art.

Do not expand into BR, DMZ, ranked, store, battle pass, 27 weapons, 12 operators, or eight maps. Ironfall Depot and Broken Perimeter look and feel first.

## Known polish (does not block the web build)

- **FPS grip / viewmodel crop.** Automated snap/curl at ship clearance. Index-in-the-well and support-corner contact still miss on close-ups. Hip/ADS were pulled inward for the web FOV so the clay arms sit on-frame; leftover crop at the screen edge is viewmodel framing, not a new grip bake. Do not reopen the human Blender posing handoff.
- **LOD0 kit density.** Assault 36.2k / Phantom 32.9k vs ~22–25k / ~16–18k. Weight is kit tris; fold a cut into form polish if time allows.
- **Clay materials / Ironfall graybox hulls.** Play path uses V0.2 character/weapon GLBs on the V0.1 depot. Textures and a denser gate overlay are quality work, not a gameplay gate.

