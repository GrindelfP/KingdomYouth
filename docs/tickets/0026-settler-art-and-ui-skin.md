# 0026 — Settler art & UI skin

- **Status:** ready
- **Milestone:** M9 — Visual Overhaul
- **Depends on:** 0025

## Style
Follow `docs/art-style.md` and the pipeline notes in ticket 0023 (`tools/art/`).

## Goal
Settlers look like little people whose job you can read, and the UI looks like part of a medieval village game instead of default Godot widgets.

## Context
Settlers are currently beige dots; the UI uses the stock theme. Both make the game feel like a prototype.

## Scope
- Settler sprites (0023 pipeline), ~12x16 px: head, body, legs; 2–4 frame walk cycle per facing (down/up/side, side mirrored). Variants: male/female, child (smaller), elder (grey hair, slight stoop).
- Clothing color by profession (laborer brown, builder orange, farmer straw, forester green, gatherer purple, hunter leather, fisher blue, quarry/miner grey, woodcutter red, blacksmith dark); carried goods drawn with the good's icon above/in front of the settler.
- Work animation hint: small bob or tool swing while working at a target.
- Settler hover/selection: outline + name tooltip.
- **UI theme** (`resources/ui/theme.tres`, generated textures where needed): wood/parchment panels (StyleBoxTexture or StyleBoxFlat with borders), styled buttons with hover/pressed states, readable font size, icons in build menu buttons (small building thumbnails generated from the building sprites), resource bar with icons from 0023. Applied to every HUD control.
- Toasts styled as parchment notes with an icon per type (birth, death, season, warning).

## Out of scope
- Sound, music.

## Acceptance criteria
- [ ] Profession is readable from clothing color; children and elders are distinguishable.
- [ ] Settlers animate while walking and carrying.
- [ ] All HUD panels use the custom theme; build menu shows thumbnails.
- [ ] Implementer reviews screenshots (windowed run saving the viewport) before marking done.
- [ ] Headless run is free of script errors.

## Open questions
- None.
