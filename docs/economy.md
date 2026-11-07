# Economy history and household shortages

Open **Economy / Inventory** for the physical food/firewood breakdown beside a seasonal, per-good flow table. Pick any retained season; the current season updates as goods are made and used. **Shortages** opens the same panel, including while paused. Its counter counts home/resource pairs, so one home without both food and fuel counts twice. **Go to next home** cycles affected homes, moves the camera, and selects the home's reserves/residents for inspection. Workplace selection explains current activity or its blocker.

## Accounting

- Keep 80 seasons (20 years including current-season progress). Seasons are absolute calendar indices, not wall-clock timestamps.
- **Made** records harvesting, raw production, crafting outputs and demolition material recovery. An output that cannot fit is also an explicit **Lost** amount; it is never available as inventory.
- **Used** records the actual good eaten, household firewood burned, crafting inputs, tools equipped (worn equipment is outside physical inventory), completed construction materials, and stone roads.
- Hauling, household/workshop restocking, construction delivery/reservations, cancellation refunds, and save restoration are transfers, not production/use. Construction materials are used at completion, not delivery.
- **Lost** records output overflow and discarded cargo/refunds/demolition contents when existing return-to-storage behavior cannot fit them. Returning goods does not manufacture replacements.
- **In / Out** are explicit future import/export hooks (`EconomyHistory.record("imported"/"exported", id, actual_amount)`). Nothing trades automatically yet.
- Starting supplies are an opening balance, not production. Standing crops are not goods until harvested, so frost notifications count destroyed crop cells, not inventory losses.
- Save version remains 10: history is an additive optional section. A v10 save without that section starts tracking at its loaded date with empty records, never an invented past. Pre-v10 saves retain their existing explicit rejection. History and active warning episodes round-trip with the town; loading does not replay goods events or emit warning-start signals.

## Shortage policy and tuning

`scripts/autoload/economy_history.gd` exposes `food_warning_threshold` (default **0** food), `fuel_warning_threshold` (default **0** firewood), and `warning_interval` (default **1 simulated second**). Adjust these script defaults when tuning; there is no player-facing threshold editor. A reserve at or below its threshold is low. Only occupied homes are included. Food is checked year-round; fuel only in winter, even if the last firewood is still heating the house. Distant storage never cancels a household warning.

There is one toast when a resource's affected-home list goes from empty to nonempty, not one toast per home or per tick. The list remains inspectable after the toast expires and while paused. It clears when no occupied homes meet that condition; a later new episode can notify again. Pausing does not advance polling or history. A persisted active episode does not re-notify on load. The panel lists the first three coordinates and navigation cycles **all** affected homes. Warnings never change inventory, staffing or survival rules.

Workplace feedback distinguishes zero desired workers (intentional stop), no assigned workers, personal-needs pauses, missing input, inaccessible input/destination/work, full storage/output buffers, off-season fields/production, and no work in radius. Ready/active states are not mislabeled as shortages. Production limits are not implemented by this ticket; personal-needs pauses and intentional stops are not reported as limits.

## Regression checks

```sh
G=/Applications/Godot.app/Contents/MacOS/Godot
$G --headless --path . res://tools/soak/economy_test.tscn
$G --headless --path . res://tools/soak/inventory_test.tscn
$G --headless --path . --fixed-fps 30 res://tools/soak/soak.tscn -- --mode=planned --years=3
$G --headless --path . res://tools/soak/roundtrip.tscn -- --phase=save
$G --headless --path . res://tools/soak/roundtrip.tscn -- --phase=load
```

The economy test uses isolated fixtures and `user://economy_test_save.json`, never the player's save. It verifies production/use/transfers, rolling retention, actual worker/crop/crafting/heating/tool/construction/road paths, overflow loss, idle reasons, paused inspection/navigation, warning recovery/deduplication, active-warning save restoration, and additive v10 compatibility. The two-process round-trip digest includes economy history and warning state. Do not run multiple economy tests concurrently: they share their test-only save path.

For a repeatable windowed fixture at 1280x720:

```sh
$G --path . --rendering-method gl_compatibility --resolution 1280x720 res://tools/soak/economy_test.tscn -- --visual
```

This runs the same assertions and captures the economy panel, navigated house, and blocked workplace as `user://economy-*-review.png` (full paths printed by the test). Fixture buildings deliberately bypass placement validation to isolate conditions; they are not a playable town or balance evidence.
