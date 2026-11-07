# 0034 — Food categories & long-term dietary health

- **Status:** ready
- **Milestone:** [M13 — Clothing & Food Diversity](../roadmap.md#m13--clothing--food-diversity)
- **Depends on:** 0033

## Goal
Make food variety understandable and beneficial without instantly punishing a single-food founding village.

## Context
v0.2 already uses household food-kind counts for health regeneration. Replace that crude modifier rather than stacking a second dietary bonus over it.

## Scope
- Classify existing foods into grain, vegetables, fruit, and protein; document mushrooms as vegetables and reserve the fruit category for orchard fruit alongside berries.
- Track each settler's recently eaten categories over a rolling game year, updated from actual meals rather than food merely sitting in storage.
- Use a bounded, documented long-term health recovery benefit for variety; single-food meals still relieve hunger and do not create an immediate health penalty.
- Bias restocking/meal selection toward available missing categories without refusing reachable basic food.
- Show settler diet and town category coverage; persist recent-meal history and accept future fruit/meat without special-case UI.

## Out of scope
- Infectious disease, food spoilage, new crops, and medical buildings.

## Acceptance criteria
- [ ] Controlled same-calorie single-food and varied-food tests show the documented long-term recovery difference.
- [ ] Single-food meals prevent starvation; an empty preferred category cannot block eating.
- [ ] Transfers between inventories do not count as eating or improve diet.
- [ ] Existing v0.2 diet modifiers are replaced, not double applied.
- [ ] Recent categories round-trip correctly; starter winter and headless regression checks pass.

## Open questions
- None; record the category mapping, history window, and bounded benefit in the balance tables.
