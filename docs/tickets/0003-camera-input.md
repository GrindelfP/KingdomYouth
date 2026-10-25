# 0003 — Camera & input controls

- **Status:** ready
- **Milestone:** M1 — World Foundation
- **Depends on:** 0002

## Goal
The player can look at the whole map: pan, zoom, and (optionally) edge-scroll, clamped to map bounds.

## Context
2D top-down game (per roadmap decision). A `Camera2D` with scripted pan/zoom is sufficient; no 3D camera rig needed.

## Scope
- `Camera2D` with:
  - Pan via keyboard (WASD/arrow keys) and/or mouse drag (middle-click or right-click drag — pick one convention and document it).
  - Zoom via mouse wheel, with min/max zoom limits.
  - Clamping so the camera cannot pan past the map edges defined in 0002.
- Centralized input map entries in `project.godot` (not hardcoded scancodes scattered in scripts) for pan directions, zoom in/out, and drag-pan.
- Basic mouse-to-world and mouse-to-grid-tile conversion exposed (building on 0002's `world_to_grid`), since building placement (0005) and job assignment (0008) will need "what tile is the cursor over."

## Out of scope
- Building placement UI/ghost preview (0005).
- Settler/unit selection (not planned for MVP — the player doesn't directly control settlers, per the game's premise).
- Minimap.

## Acceptance criteria
- [ ] Camera pans via keyboard and/or drag without leaving map bounds.
- [ ] Camera zooms smoothly within defined min/max limits.
- [ ] All camera inputs are defined in the Input Map, not hardcoded key checks.
- [ ] A helper function returns the grid tile currently under the mouse cursor.

## Open questions
- Keyboard pan, drag pan, or both — default to both unless the user prefers one.
- Edge-scrolling (pan when cursor nears screen edge) — nice-to-have, not required for MVP; skip unless trivial.
