# 0003 — Camera & input controls

- **Status:** done
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
- [x] Camera pans via keyboard and/or drag without leaving map bounds. (Verified headless with the `camera_pan_right` action; clamp checked against the expected edge.)
- [x] Camera zooms smoothly within defined min/max limits. (Verified headless: wheel-in clamps at max zoom 3.0.)
- [x] All camera inputs are defined in the Input Map, not hardcoded key checks.
- [x] A helper function returns the grid tile currently under the mouse cursor. (`CameraController.get_hovered_grid_pos()`; checked that it runs, not against a real cursor position.)

## Decisions
- Controls (all in the Input Map, `project.godot` `[input]`):
  - `camera_pan_left/right/up/down`: WASD and arrow keys.
  - `camera_zoom_in/out`: mouse wheel up/down.
  - `camera_drag`: middle mouse button held, drag to pan. Right-click stays free for later placement/cancel actions.
- Zoom: multiplicative steps of 1.15, range 0.5 to 3.0, eased toward the target zoom each frame.
- Keyboard pan speed is scaled by `1 / zoom`, so it feels the same at any zoom level.
- Clamping is done in code on the camera position, not with `Camera2D` limits. The limits clamp only the drawn view, so the stored position drifts past the edge and the camera lags when reversing. When the view is larger than the map, the camera centers on it.
- Edge-scroll is not implemented (optional in this ticket).

## Open questions
- Keyboard pan, drag pan, or both — default to both unless the user prefers one.
- Edge-scrolling (pan when cursor nears screen edge) — nice-to-have, not required for MVP; skip unless trivial.
