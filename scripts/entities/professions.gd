class_name Professions
extends RefCounted

const LABORER := &"laborer"
const BUILDER := &"builder"


static func display_name(profession: StringName) -> String:
	return String(profession).capitalize()
