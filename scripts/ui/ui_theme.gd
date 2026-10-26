class_name UiTheme
extends RefCounted

const PATH := "res://resources/ui/theme.tres"

static var _theme: Theme


static func load_theme() -> Theme:
	if _theme == null and ResourceLoader.exists(PATH):
		_theme = load(PATH)
	return _theme
