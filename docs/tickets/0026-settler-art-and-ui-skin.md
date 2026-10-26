# 0026 — Settler art & UI skin

- **Status:** done
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
- [x] Profession is readable from clothing color; children and elders are distinguishable.
- [x] Settlers animate while walking and carrying.
- [x] All HUD panels use the custom theme; build menu shows thumbnails.
- [x] Implementer reviews screenshots (windowed run saving the viewport) before marking done.
- [x] Headless run is free of script errors.

## Open questions
- None.

## Implementation notes
- Settlers: `tools/art/gen_settlers.gd` generates sprite sheets (age stage x sex x hair variant x profession, 2-4 frame walk per facing, side mirrored); `scripts/entities/settler_art.gd` selects the row and animates; carried goods drawn with the good's icon, work bob, outline shader on hover and selection, name tooltip via `SettlerManager`.
- UI skin: `tools/art/gen_ui.gd` (registered in `gen_people_ui.gd`) generates panel/button/slot/bar/toast/tooltip textures, per-type toast icons and building thumbnails in `assets/art/ui/`. `resources/ui/theme.tres` defines parchment panels, wood bars, textured buttons with hover/pressed/disabled, label variations (Title, Section, Hint, Light, Note), progress bars, tooltip. `UiTheme.load_theme()` is applied at the HUD root so every control inherits it.
- Build menu: grouped buttons with thumbnails, toggle state mirrors the active tool (`BuildController.active_index/active_road/is_demolishing`), cost in tooltip.
- HUD: two-row wood top bar with resource slots and icons; toasts are fading parchment notes with icons (info, birth, death, season, warning, build); hint on a wood plate; info and profession panels skinned (title labels, taller bars, compact +/- buttons).
- Reviewed by capturing the full HUD with toasts, profession and info panels, and a zoomed capture of settlers of mixed professions, ages and carrying goods.
