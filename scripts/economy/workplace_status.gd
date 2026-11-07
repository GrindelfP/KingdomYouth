class_name WorkplaceStatus
extends RefCounted


static func describe(building: Building) -> String:
	if building.desired_workers == 0:
		return "Intentionally paused: desired workers is zero."
	if building.workers.is_empty():
		return "No workers: assign this profession and desired workers."
	var reasons := PackedStringArray()
	for settler in building.workers:
		var reason := for_worker(building, settler)
		if not reasons.has(reason):
			reasons.append(reason)
	return "\n".join(reasons)


static func for_worker(building: Building, settler: Settler) -> String:
	var worker := settler.worker
	if worker.is_paused():
		return "Paused for personal needs (not a production limit)."
	if worker._state != Worker.State.IDLE:
		return "Active: %s (includes supply and delivery trips)." % worker.get_state_name().to_lower()
	var job := building.job_def()
	var hauler := Hauler.new(settler)
	if building.output.free_space() < job.output_total():
		var stores := ResourceStockpile.find_storages(building.get_output_id(), settler.get_grid_pos())
		if stores.is_empty():
			return "Full storage: no accepting space; build storage or free capacity."
		if not _any_access(stores, hauler):
			return "No reachable destination: reconnect storage access."
		return "Output buffer full: waiting for hauling."
	if not building.has_batch():
		var id := building.missing_input()
		var sources := ResourceStockpile.find_sources(id, settler.get_grid_pos())
		if sources.is_empty():
			return "No input: %s; produce it or release stored supplies." % ResourceCatalog.display_name(id)
		if not _any_access(sources, hauler):
			return "No reachable input source: reconnect storage access."
		return "Waiting for input delivery: %s." % ResourceCatalog.display_name(id)
	if TimeManager.is_cold() and job.winter_factor == 0.0:
		return "Off-season: this workplace cannot produce in winter."
	var candidates: Array[Vector2i] = []
	match job.target_mode:
		JobDef.TargetMode.FIELD:
			var pick := building.field.next_task(building.grid_to_field_cell(settler.get_grid_pos()), TimeManager.get_season() == TimeManager.Season.SPRING)
			if pick["task"] == CropField.Task.NONE:
				return "Off-season: wait for spring sowing or ripe crops." if TimeManager.get_season() != TimeManager.Season.SPRING else "No available field task: planted or claimed by another worker."
			candidates.append(building.field_cell_to_grid(pick["cell"]))
		JobDef.TargetMode.FOREST_CELL:
			for cell in settler.world.get_cells_in_radius(building.get_work_center(), job.work_radius):
				if settler.world.get_terrain_name(cell) == "forest":
					candidates.append(cell)
		JobDef.TargetMode.FORESTER:
			var mature: Array[Vector2i] = []
			var plantable: Array[Vector2i] = []
			var trees := 0
			for cell in settler.world.get_cells_in_radius(building.get_work_center(), job.work_radius):
				var stage := settler.world.get_tree_stage(cell)
				if stage != WorldGrid.NO_TREE:
					trees += 1
					if stage == WorldGrid.STAGE_MATURE:
						mature.append(cell)
				elif settler.world.can_plant(cell):
					plantable.append(cell)
			var density := float(trees) / maxf(trees + plantable.size(), 1.0)
			candidates = plantable if density < job.forest_density and not plantable.is_empty() else mature
		_:
			if building.work_efficiency() <= 0.0:
				return "No work in radius: restore nearby forest."
			candidates = building.get_access_cells()
			if candidates.is_empty():
				return "No reachable work: reconnect building access."
	if candidates.is_empty():
		return "No work in radius: wait for growth or choose another work area."
	for cell in candidates:
		if hauler.is_reachable(cell):
			return "Ready: waiting for the next work attempt."
	return "No reachable work: reconnect the work area or building access."


static func _any_access(buildings: Array[Building], hauler: Hauler) -> bool:
	for building in buildings:
		if hauler.reachable_access_cell(building) != Hauler.NO_TARGET:
			return true
	return false
