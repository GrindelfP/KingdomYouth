extends RefCounted

const MODULES: Array[String] = [
	"res://tools/art/gen_settlers.gd",
	"res://tools/art/gen_ui.gd",
]


static func generate() -> void:
	for path in MODULES:
		print("art: ", path)
		load(path).generate()
