class_name JobDef
extends Resource

enum TargetMode { ACCESS, FOREST_CELL, FORESTER, FIELD }
enum PlacementRule { NONE, NEAR_WATER, NEAR_ROCK }

@export var job_name: String
@export var slots := 1
@export var work_time := 4.0
@export var outputs: Array[Dictionary] = []
@export var inputs: Array[Dictionary] = []
@export var target_mode := TargetMode.ACCESS
@export var work_radius := 0.0
@export var density_cells := 0
@export var winter_factor := 1.0
@export var placement_rule := PlacementRule.NONE
@export var rule_radius := 3
@export var rule_min_cells := 4
@export var plant_time := 3.0
@export var plow_time := 2.5
@export var forest_density := 0.6


func profession_id() -> StringName:
	return StringName(job_name.to_lower().replace(" ", "_"))


func output_total() -> int:
	var total := 0
	for entry in outputs:
		total += int(entry["amount"])
	return total


func has_inputs() -> bool:
	return not inputs.is_empty()


func input_amount(id: StringName) -> int:
	for entry in inputs:
		if StringName(entry["id"]) == id:
			return int(entry["amount"])
	return 0


func primary_output() -> StringName:
	return StringName(outputs[0]["id"]) if not outputs.is_empty() else &""


func has_work_area() -> bool:
	return work_radius > 0.0
