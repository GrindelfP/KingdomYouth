class_name ProfessionPanel
extends PanelContainer

const REFRESH_SECONDS := 0.25
const NAME_WIDTH := 110.0
const COUNT_WIDTH := 70.0

var _labor: LaborManager
var _rows: Dictionary = {}
var _refresh_left := 0.0


func setup(labor: LaborManager) -> void:
	_labor = labor
	visible = false
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	add_child(column)
	var title := Label.new()
	title.text = "Professions"
	title.theme_type_variation = &"TitleLabel"
	column.add_child(title)
	for profession in labor.profession_ids():
		column.add_child(_make_row(profession))
	_refresh()


func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		_refresh()


func _make_row(profession: StringName) -> HBoxContainer:
	var row := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = Professions.display_name(profession)
	name_label.custom_minimum_size = Vector2(NAME_WIDTH, 0)
	row.add_child(name_label)
	var count_label := Label.new()
	count_label.custom_minimum_size = Vector2(COUNT_WIDTH, 0)
	row.add_child(count_label)
	var minus := _make_button("-", func() -> void: _labor.decrease(profession))
	var plus := _make_button("+", func() -> void: _labor.increase(profession))
	row.add_child(minus)
	row.add_child(plus)
	_rows[profession] = {"count": count_label, "minus": minus, "plus": plus}
	return row


func _make_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.theme_type_variation = &"SmallButton"
	button.custom_minimum_size = Vector2(26, 22)
	button.pressed.connect(func() -> void:
		action.call()
		_refresh())
	return button


func _refresh() -> void:
	for profession in _rows:
		var row: Dictionary = _rows[profession]
		var maximum := _labor.get_max(profession)
		var count := _labor.get_count(profession)
		row["count"].text = "%d / %d" % [count, maximum] if maximum >= 0 else str(count)
		row["minus"].disabled = not _labor.can_decrease(profession)
		row["plus"].disabled = not _labor.can_increase(profession)
