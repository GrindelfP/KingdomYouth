# 0048 — v3 save compatibility contract & full round-trip

- **Status:** ready
- **Milestone:** [M19 — v3 Integration & Release Gate](../roadmap.md#m19--v3-integration--release-gate)
- **Depends on:** 0047

## Goal
Finalize an explicit save contract and prove every v3 system survives a two-process round-trip.

## Context
v0.2 currently uses save version 10 and rejects older formats. Feature tickets already persist their own state; this ticket validates integration rather than deferring all save work until release.

## Scope
- Retain explicit rejection of v0.2/unsupported versions rather than silently reinterpreting them; document that policy and the final v3 version before freezing its format.
- Extend `tools/soak/roundtrip_test.gd` and its scenes/digests for accounting/history, markets/targets/reserves, diets/coats, students, graves/happiness, visits/trade stock/unlocks, orchard trees, animal breeding, map settings/actual terrain, bridges, goals, and goods in transit.
- Save during active merchant visits, schooling, recipe work, deliveries, orchard growth, and breeding; restore durable state and safely rebuild or release transient claims.
- Cover invalid/missing/newer/older saves with distinct feedback and validation before replacing the current world; failed load must leave the live settlement intact.
- Use isolated test save paths; verify a continued simulation after load, not just an equal serialized digest.

## Out of scope
- Implementing v0.2 migration, cloud saves, and adding new gameplay.

## Acceptance criteria
- [ ] Separate save/load processes match every documented persistent section, then continue without duplication or stuck commitments.
- [ ] Active visits, students, coats, animals, orchards, bridges, settings, and transit each have explicit assertions.
- [ ] Version-10, malformed, missing, and newer saves get documented feedback without corrupting the running world.
- [ ] Tests do not overwrite the player's save or reset user audio preferences.
- [ ] Compatibility policy, schema version, and repeatable commands are documented; headless checks are error-free.

## Open questions
- None; v0.2 migration is explicitly not required for this release.
