class_name ResourceDef
extends Resource

enum Category { MATERIAL, FUEL, TOOL, FOOD }

@export var id: StringName
@export var display_name: String
@export var category := Category.MATERIAL
@export var color := Color.WHITE
@export var sort_order := 0
@export var starting_amount := 0
