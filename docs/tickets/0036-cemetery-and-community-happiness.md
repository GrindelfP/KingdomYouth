# 0036 — Cemeteries & bounded community happiness

- **Status:** ready
- **Milestone:** [M14 — Schools & Community Life](../roadmap.md#m14--schools--community-life)
- **Depends on:** 0035

## Goal
Give deaths and access to community services a readable, recoverable effect on town life.

## Context
Deaths and family links already exist. This is a small community model, not a disaster system or a hidden productivity-collapse mechanic.

## Scope
- Add a constructible cemetery with fixed grave capacity; actual deaths occupy graves when a reachable cemetery has space. Graves persist through this release; no corpse-hauling simulation.
- Apply time-limited bereavement to surviving partners/children; accessible cemetery service reduces its duration. Full/missing capacity has explicit UI feedback, not extra unexplained deaths.
- Add a bounded happiness score from active bereavement and accessible community services (school/cemetery), with a displayed breakdown and a small capped work-rate modifier.
- Document exact radius, capacity, durations, clamps, and removal behavior; demolished graves cease providing service and do not resurrect settlers.
- Persist grave records and active effects; include seasonal art, event hooks, and generational checks.

## Out of scope
- Hospitals, herbs, disease outbreaks, chapels, taverns, and grave reuse mechanics.

## Acceptance criteria
- [ ] Deaths fill cemetery capacity exactly once, including across save/load.
- [ ] Full/removed/unreachable service produces clear feedback and never blocks death cleanup or family replacement.
- [ ] Bereavement expires and the complete happiness/work-rate bounds match documented values.
- [ ] Multiple generations remain viable with and without cemetery coverage in controlled tests.
- [ ] New art/UI is reviewed; persistent effects and headless checks are error-free.

## Open questions
- None.
