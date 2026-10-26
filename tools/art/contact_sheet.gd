extends SceneTree

const Canvas := preload("res://tools/art/pixel_canvas.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var dir := args[0] if args.size() > 0 else "res://assets/art/icons"
	var out := args[1] if args.size() > 1 else "/tmp/contact_sheet.png"
	var scale := int(args[2]) if args.size() > 2 else 4
	var files: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".png"):
			files.append(f)
	files.sort()
	var images: Array[Image] = []
	var cell := 0
	for f in files:
		var img := Image.load_from_file("%s/%s" % [ProjectSettings.globalize_path(dir), f])
		img.convert(Image.FORMAT_RGBA8)
		images.append(img)
		cell = maxi(cell, maxi(img.get_width(), img.get_height()))
	var cols := mini(files.size(), 6)
	var rows := ceili(float(files.size()) / cols)
	var pad := 4
	var step := cell * scale + pad * 2
	var sheet := Canvas.create(cols * step, rows * step)
	sheet.clear(Color.html("#4a6a44"))
	for k in images.size():
		var holder := Canvas.create(images[k].get_width(), images[k].get_height())
		holder.image = images[k]
		var big: RefCounted = holder.scaled(scale)
		sheet.blit(big, (k % cols) * step + pad, (k / cols) * step + pad)
	sheet.save(out)
	quit()
