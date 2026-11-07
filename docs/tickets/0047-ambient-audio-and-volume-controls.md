# 0047 — Restrained ambient audio & volume controls

- **Status:** ready
- **Milestone:** [M18 — Settlement Identity, Guidance & Presentation](../roadmap.md#m18--settlement-identity-guidance--presentation)
- **Depends on:** 0046

## Goal
Make the town feel alive without masking warnings or overwhelming the player.

## Context
v0.2 has no audio. Keep the existing generated-art direction and use reproducible generated sounds or clearly licensed assets with recorded attribution; do not introduce an external audio dependency silently.

## Scope
- Add subtle seasonal ambience, nearby active-production cues, and sparse UI/notification sounds; distance/zoom attenuates workplace sound.
- Use Master, Ambience, Effects, and UI buses with independent volume/mute controls in an accessible settings panel.
- Bound simultaneous voices and repeated cues; paused simulation stops production cues while UI controls remain responsive.
- Persist user audio preferences outside world saves so loading/restarting does not reset volume.
- Document asset generation/source/license and verify quiet/muted operation alongside visible alerts.

## Out of scope
- Music score, voiced settlers, disaster alarms, and a full audio-engine rewrite.

## Acceptance criteria
- [ ] Seasons and active production provide restrained audible cues without repeated alert spam.
- [ ] Each bus and master mute work immediately; all game sounds can be silenced.
- [ ] Preferences survive application restart independently of loaded world state.
- [ ] Pausing/loading/restarting does not leave orphaned looping sounds or accumulate voices.
- [ ] Interactive listening/volume checks and headless no-audio startup pass; asset provenance is documented.

## Open questions
- None; favor deterministic generated assets where suitable and record any licensed sources.
