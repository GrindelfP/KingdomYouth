# 0029 — Seasonal economy history & shortage feedback

- **Status:** done
- **Milestone:** [M11 — Readable Economy & Long-Run Baseline](../roadmap.md#m11--readable-economy--long-run-baseline)
- **Depends on:** 0028

## Goal
Let players explain shortages and idle workplaces from the UI rather than logs.

## Context
Transfers are not production or consumption. Seasonal records must follow actual creation/use of goods, while idle reasons come from current simulation state.

## Scope
- Record per-good seasonal production, consumption, imports/exports hooks, and explicit loss; retain the latest 20 years with current-season progress.
- Add an economy detail panel showing history beside 0028 inventory breakdowns.
- Expose workplace reasons for no workers, no input, no reachable work/destination, full storage, and off-season work; distinguish intentional pauses and later production limits.
- Add deduplicated food/fuel shortage warnings with affected homes and useful navigation. Document configurable thresholds; shortages must not create goods.
- Persist history and warning state; loading and pausing must not repeat consumption or flood toasts.

## Out of scope
- Full town overview/event archive (0045).
- New survival pressures or automated player decisions.

## Acceptance criteria
- [x] A controlled season's creation, use, and transfers produce correct separate history entries.
- [x] Each listed idle condition can be reproduced and explained in its workplace panel.
- [x] Empty household reserves trigger actionable warnings even when distant storage contains food/fuel.
- [x] History survives a round-trip and warnings remain inspectable while paused.
- [x] Headless checks are error-free; the panel and alerts are reviewed at 1280x720.

## Verification — 2026-11-08

- `economy_test.tscn`: `ECONOMY OK`. Exercises real creation/use paths, hauling exclusion, seasonal separation and 80-season retention, trade hooks, overflow loss, every listed reason through the actual workplace panel, past-season selection, household warnings despite stored supplies, navigation, paused inspection, active-warning persistence/recovery/deduplication, and v10 saves without history.
- `inventory_test.tscn`: `INVENTORY OK`.
- Documented planned three-year headless soak: month 36, population 15, no deaths, no frozen reports or script errors. This is not the twenty-year demographic baseline (0030).
- Documented separate-process round-trip save/load: `ROUNDTRIP OK`, 0 of 10 digest sections differ, including history/warnings and physical inventory locations. Strengthened the fixture to require an employed carrier. Fixed cargo restoration order after reproducing job assignment returning saved cargo to storage; the focused regression failed before the fix and passes afterward.
- Headless editor import and main-scene startup: no errors. `git diff --check`: clean.
- Windowed scripted fixture with OpenGL compatibility renderer: `ECONOMY OK`. Reviewed rendered 1280x720 captures of the economy/alerts, navigated home, off-season field and blocked woodcutter panels. No unscripted interactive playthrough or Forward+ visual review was performed. Capture paths and commands are documented in [economy.md](../economy.md).

## Implementation notes

- [Economy accounting, warning thresholds and test commands](../economy.md).
- Save version 10 gains an optional economy section; existing v10 saves start empty history at their loaded date. No past production/consumption is fabricated. Earlier-version rejection remains unchanged.
- Production limits and actual trading remain future dependent tickets; this ticket supplies clear intentional/needs pause labels and explicit import/export hooks without simulating those features.

## Open questions
- None; tune and document warning thresholds during implementation.
