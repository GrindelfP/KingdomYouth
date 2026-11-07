# 0041 — Wool coats & clothing replacement policy

- **Status:** ready
- **Milestone:** [M16 — Orchards & Pastures](../roadmap.md#m16--orchards--pastures)
- **Depends on:** 0033, 0040

## Goal
Complete the sheep-to-clothing chain with warmer coats and predictable use of existing leather clothing.

## Context
Extend the tailor and equipment/wear model from 0033. Wool remains a hauled material until a tailor consumes it; an animal is never directly converted into an equipped coat.

## Scope
- Add wool storage/catalog support and a selectable wool-coat recipe alongside leather coats; pending batches keep their original recipe when switched.
- Wool coats provide a documented stronger but bounded exposure reduction, with their own lifetime and generated icon/visual distinction.
- Settlers without a serviceable coat prefer available wool coats but accept leather; settlers finish wearing existing coats rather than discarding them solely to upgrade.
- Apply separate per-good limits and market supply support for both coat types; show clothing coverage/type/condition consistently.
- Include seasonal winter comparisons, recipe/input/output history, and mid-batch/mid-wear persistence checks.

## Out of scope
- Luxury clothing, textiles beyond wool/leather, stacking coats, and automatic forced upgrades.

## Acceptance criteria
- [ ] Sheep wool is hauled into the tailor, consumed by the selected recipe, and delivered as real wool coats.
- [ ] Recipe changes cannot convert an already-started leather batch into free wool clothing.
- [ ] Existing coats wear normally, replacements follow the stated preference, and unavailable wool never blocks leather use.
- [ ] Paired winter tests document leather/wool/no-coat differences without making home heating obsolete.
- [ ] Saved recipes, equipped types, wear, and shipments round-trip; UI/art and headless checks pass.

## Open questions
- None; record recipe, lifetime, and warmth values in `docs/balance.md`.
