extends SceneTree

const MODULES: Array[String] = [
	"res://tools/art/gen_icons.gd",
]


func _init() -> void:
	for path in MODULES:
		print("art: ", path)
		load(path).generate()
	quit()
