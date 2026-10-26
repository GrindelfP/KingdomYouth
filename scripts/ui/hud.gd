class_name Hud
extends CanvasLayer

const TOAST_SECONDS := 6.0
const MAX_TOASTS := 5
const SEASON_MESSAGES := [
	"Spring has come. Farms are productive again.",
	"Summer. Farms are at their best.",
	"Autumn. Stock up before winter.",
	"Winter. Farms rest and unheated settlers grow cold.",
]
const SPEED_LABELS := ["||", ">", ">>", ">>>"]
const BAR_GOODS: Array[StringName] = [&"logs", &"stone", &"iron", &"firewood", &"tools"]
const FOOD_KEY := &"food"
const STORAGE_WARN_RATIO := 0.9
const STORAGE_CLEAR_RATIO := 0.8
const FOOD_ICON := preload("res://assets/art/icons/food.png")
const TOAST_ICONS := {
	&"info": preload("res://assets/art/ui/toast_info.png"),
	&"birth": preload("res://assets/art/ui/toast_birth.png"),
	&"death": preload("res://assets/art/ui/toast_death.png"),
	&"season": preload("res://assets/art/ui/toast_season.png"),
	&"warning": preload("res://assets/art/ui/toast_warning.png"),
	&"build": preload("res://assets/art/ui/toast_build.png"),
}
const TOAST_WIDTH := 300.0
const TOAST_FADE := 0.5

var _build: BuildController
var _jobs: JobController
var _settlers: SettlerManager
var _labor: LaborManager
var _professions: ProfessionPanel
var _resource_labels: Dictionary = {}
var _food_box: Control
var _storage_label: Label
var _storage_warned := false
var _time_label: Label
var _speed_buttons: Array[Button] = []
var _population_label: Label
var _hint_label: Label
var _hint_panel: PanelContainer
var _toasts: VBoxContainer


func _ready() -> void:
	_build = get_parent().get_node("Buildings")
	_jobs = get_parent().get_node("Jobs")
	_settlers = get_parent().get_node("Settlers")
	_labor = get_parent().get_node("Labor")

	var root := Control.new()
	root.theme = UiTheme.load_theme()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	root.add_child(_build_top_bar())
	_hint_panel = PanelContainer.new()
	_hint_panel.theme_type_variation = &"WoodBar"
	_hint_panel.position = Vector2(16, 92)
	_hint_panel.visible = false
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label = _make_label()
	_hint_label.theme_type_variation = &"LightLabel"
	_hint_panel.add_child(_hint_label)
	root.add_child(_hint_panel)

	_toasts = VBoxContainer.new()
	_toasts.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toasts.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toasts.offset_top = 92
	_toasts.add_theme_constant_override("separation", 4)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toasts)

	var menu := BuildingMenu.new()
	menu.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	menu.grow_vertical = Control.GROW_DIRECTION_BEGIN
	menu.offset_bottom = -12
	root.add_child(menu)
	menu.setup(_build)

	var info := InfoPanel.new()
	info.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	info.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	info.offset_top = 92
	info.offset_right = -12
	root.add_child(info)
	info.setup(_jobs, _settlers, _build, _labor)

	_professions = ProfessionPanel.new()
	_professions.position = Vector2(16, 140)
	root.add_child(_professions)
	_professions.setup(_labor)

	ResourceStockpile.resource_changed.connect(_on_resource_changed)
	for id in BAR_GOODS:
		_on_resource_changed(id, ResourceStockpile.get_amount(id))
	_refresh_food()
	_build.hint_changed.connect(_on_hint_changed)
	_build.construction_completed.connect(_on_construction_completed)
	_build.notice.connect(func(text: String) -> void: add_toast(text, &"warning" if text.begins_with("Not enough") else &"build"))
	_build.construction_cancelled.connect(func(def: BuildingDef) -> void: add_toast("Construction cancelled: %s. Delivered materials returned." % def.display_name, &"warning"))
	_build.crops_lost.connect(func(building: Building, count: int) -> void: add_toast("Frost destroyed crops at %s: %d cells lost." % [building.origin, count], &"warning"))
	_settlers.settler_born.connect(_on_settler_born)
	_settlers.settler_died.connect(_on_settler_died)
	_settlers.settler_grew_up.connect(func(settler: Settler) -> void: add_toast("%s came of age." % settler.given_name, &"birth"))
	TimeManager.season_changed.connect(_on_season_changed)
	TimeManager.speed_changed.connect(_on_speed_changed)
	_on_speed_changed(TimeManager.get_speed_index())


func _process(_delta: float) -> void:
	_time_label.text = "%s, Year %d" % [TimeManager.get_month_name(), TimeManager.get_year()]
	_update_storage()
	var stages := _settlers.count_by_stage()
	_population_label.text = "Pop %d (%dA %dC %dE) Work %d Build %d" % [
		_settlers.population(), stages[Settler.AgeStage.ADULT], stages[Settler.AgeStage.CHILD], stages[Settler.AgeStage.ELDER],
		_settlers.employed_count(), _labor.get_count(Professions.BUILDER)]


func _update_storage() -> void:
	var capacity := ResourceStockpile.get_capacity()
	var stored := ResourceStockpile.get_stored_total()
	_storage_label.text = "Store %d/%d" % [stored, capacity]
	var ratio := float(stored) / capacity if capacity > 0 else 1.0
	if not _storage_warned and ratio >= STORAGE_WARN_RATIO:
		_storage_warned = true
		add_toast("Storage is nearly full. Build more storage.", &"warning")
	elif _storage_warned and ratio < STORAGE_CLEAR_RATIO:
		_storage_warned = false


func add_toast(text: String, kind: StringName = &"info") -> void:
	var note := PanelContainer.new()
	note.theme_type_variation = &"Toast"
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.add_child(row)
	var icon := TextureRect.new()
	icon.texture = TOAST_ICONS.get(kind, TOAST_ICONS[&"info"])
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(16, 16)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var label := _make_label()
	label.text = text
	label.theme_type_variation = &"NoteLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.custom_minimum_size = Vector2(TOAST_WIDTH, 0)
	row.add_child(label)
	_toasts.add_child(note)
	while _toasts.get_child_count() > MAX_TOASTS:
		var oldest := _toasts.get_child(0)
		_toasts.remove_child(oldest)
		oldest.queue_free()
	note.modulate.a = 0.0
	var tween := note.create_tween().set_ignore_time_scale(true)
	tween.tween_property(note, "modulate:a", 1.0, 0.2)
	tween.tween_interval(TOAST_SECONDS - 0.2 - TOAST_FADE)
	tween.tween_property(note, "modulate:a", 0.0, TOAST_FADE)
	tween.tween_callback(note.queue_free)


func _on_hint_changed(text: String) -> void:
	_hint_label.text = text
	_hint_panel.visible = text != ""


func _build_top_bar() -> PanelContainer:
	var bar := PanelContainer.new()
	bar.theme_type_variation = &"WoodBar"
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 4)
	bar.add_child(rows)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	rows.add_child(row)
	for id in BAR_GOODS:
		row.add_child(_make_resource_entry(id, ResourceCatalog.display_name(id), ResourceCatalog.get_def(id).icon))
	_food_box = _make_resource_entry(FOOD_KEY, "Food", FOOD_ICON)
	row.add_child(_food_box)
	_storage_label = _make_label(true)
	row.add_child(_storage_label)
	_population_label = _make_label(true)
	row.add_child(_population_label)
	row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	rows.add_child(row)
	_time_label = _make_label(true)
	row.add_child(_time_label)
	for index in TimeManager.SPEEDS.size():
		var button := _make_button(SPEED_LABELS[index], TimeManager.set_speed.bind(index))
		button.toggle_mode = true
		_speed_buttons.append(button)
		row.add_child(button)
	row.add_child(_make_button("Professions (P)", func() -> void: _professions.visible = not _professions.visible))
	row.add_child(_make_button("Save", _save_game))
	row.add_child(_make_button("Load", _load_game))
	row.add_child(_make_button("New game", SaveManager.start_new_game))
	return bar


func _make_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("professions_toggle"):
		_professions.visible = not _professions.visible
	elif event.is_action_pressed("toggle_pause"):
		TimeManager.toggle_pause()
	elif event.is_action_pressed("speed_1"):
		TimeManager.set_speed(1)
	elif event.is_action_pressed("speed_2"):
		TimeManager.set_speed(2)
	elif event.is_action_pressed("speed_3"):
		TimeManager.set_speed(3)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_game"):
		_save_game()
	elif event.is_action_pressed("load_game"):
		_load_game()


func _save_game() -> void:
	add_toast("Game saved." if SaveManager.save_game() else "Could not save the game.", &"info")


func _load_game() -> void:
	if not SaveManager.has_save():
		add_toast("No saved game yet.")
		return
	add_toast("Game loaded." if SaveManager.load_game() else "Could not load the save.")


func _make_label(light := false) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if light:
		label.theme_type_variation = &"LightLabel"
	return label


func _make_resource_entry(key: StringName, title: String, texture: Texture2D) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.theme_type_variation = &"Slot"
	slot.mouse_filter = Control.MOUSE_FILTER_PASS
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(box)
	var icon := TextureRect.new()
	icon.texture = texture
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(16, 16)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	var label := _make_label(true)
	label.text = "%s: 0" % title
	label.set_meta("title", title)
	_resource_labels[key] = label
	box.add_child(label)
	return slot


func _set_entry(key: StringName, amount: int) -> void:
	var label: Label = _resource_labels[key]
	label.text = "%s: %d" % [label.get_meta("title"), amount]


func _refresh_food() -> void:
	_set_entry(FOOD_KEY, ResourceStockpile.get_food_total())
	var lines := PackedStringArray()
	for id in ResourceCatalog.ids_in_category(ResourceDef.Category.FOOD):
		lines.append("%s: %d" % [ResourceCatalog.display_name(id), ResourceStockpile.get_amount(id)])
	_food_box.tooltip_text = "\n".join(lines)


func _on_resource_changed(id: StringName, new_amount: int) -> void:
	if _resource_labels.has(id):
		_set_entry(id, new_amount)
	elif ResourceCatalog.get_def(id).category == ResourceDef.Category.FOOD:
		_refresh_food()


func _on_construction_completed(building: Building) -> void:
	add_toast("Construction complete: %s." % building.def.display_name, &"build")


func _on_settler_born(settler: Settler) -> void:
	add_toast("%s was born." % settler.given_name, &"birth")


func _on_settler_died(settler: Settler, old_age: bool) -> void:
	add_toast("%s died of old age." % settler.given_name if old_age else "%s has died." % settler.given_name, &"death")


func _on_season_changed(season: int) -> void:
	add_toast("%s. %s" % [TimeManager.SEASON_NAMES[season], SEASON_MESSAGES[season]], &"season")


func _on_speed_changed(index: int) -> void:
	for button_index in _speed_buttons.size():
		_speed_buttons[button_index].button_pressed = button_index == index
