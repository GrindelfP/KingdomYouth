extends RefCounted

const Canvas := preload("res://tools/art/pixel_canvas.gd")
const Palette := preload("res://tools/art/palette.gd")

const OUT_DIR := "res://assets/art/ui"
const BUILDINGS_DIR := "res://assets/art/buildings"
const THUMB := 32
const BUILDING_IDS: Array[String] = ["stockpile", "storage_barn", "house", "gatherers_hut", "hunting_cabin", "fishing_dock", "foresters_lodge", "quarry", "mine", "woodcutter", "blacksmith"]
const FIELD_COLUMNS: Dictionary = {"crop_field_4": [9, 9, 9, 9], "crop_field_6": [9, 11, 5, 9], "crop_field_8": [11, 11, 7, 11]}


static func generate() -> void:
	_panel("panel", false)
	_panel("panel_dark", true)
	_buttons()
	_note("toast")
	_tooltip()
	_bars()
	_slot()
	_icons()
	_thumbnails()


static func _chip(c: RefCounted, w: int, h: int) -> void:
	for p in [Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, h - 1), Vector2i(w - 1, h - 1)]:
		c.image.set_pixel(p.x, p.y, Palette.CLEAR)


static func _panel(name: String, dark: bool) -> void:
	var s := 32
	var c := Canvas.create(s, s, 11 if dark else 10)
	var W := Palette.WOOD
	if dark:
		c.rect(0, 0, s, s, W[1])
		for y in s:
			var m := y % 8
			var col: Color = W[1]
			if m == 0:
				col = W[0]
			elif m == 1:
				col = W[2]
			c.rect(0, y, s, 1, col)
		c.speckle(0, 0, s, s, W[2], 0.06, false)
		c.speckle(0, 0, s, s, W[0], 0.06, false)
		c.rect(0, 0, s, 1, W[0])
		c.rect(0, 1, s, 1, W[3])
		c.rect(0, 2, s, 1, W[2])
		c.rect(0, s - 2, s, 2, W[0])
		c.rect(0, s - 3, s, 1, W[1])
		c.rect(0, 0, 1, s, W[0])
		c.rect(s - 1, 0, 1, s, W[0])
		c.rect(1, 1, 1, s - 3, W[2])
		_chip(c, s, s)
		c.save("%s/%s.png" % [OUT_DIR, name])
		return
	c.rect(0, 0, s, s, W[0])
	c.rect(1, 1, s - 2, 3, W[3])
	c.rect(1, s - 4, s - 2, 3, W[2])
	c.rect(1, 1, 3, s - 2, W[3])
	c.rect(s - 4, 1, 3, s - 2, W[2])
	c.rect(1, 1, s - 2, 1, W[4])
	c.rect(1, 1, 1, s - 2, W[4])
	c.rect(1, s - 2, s - 2, 1, W[1])
	c.rect(s - 2, 1, 1, s - 2, W[1])
	c.rect(4, 4, s - 8, s - 8, Palette.CREAM[2])
	c.speckle(4, 4, s - 8, s - 8, Palette.CREAM[1], 0.07, false)
	c.speckle(4, 4, s - 8, s - 8, Palette.CREAM[3], 0.06, false)
	c.rect(4, 4, s - 8, 1, Palette.CREAM[0])
	c.rect(4, 4, 1, s - 8, Palette.CREAM[0])
	c.rect(s - 5, 5, 1, s - 9, Palette.CREAM[1])
	c.rect(5, s - 5, s - 9, 1, Palette.CREAM[1])
	for p in [Vector2i(2, 2), Vector2i(s - 3, 2), Vector2i(2, s - 3), Vector2i(s - 3, s - 3)]:
		c.px(p.x, p.y, Palette.STEEL[2])
		c.px(p.x + 1, p.y + 1, Palette.STEEL[0])
	_chip(c, s, s)
	c.save("%s/%s.png" % [OUT_DIR, name])


static func _button(state: String) -> void:
	var s := 16
	var c := Canvas.create(s, s, 20)
	var W := Palette.WOOD
	var face: Color = W[2]
	var hi: Color = W[3]
	var lo: Color = W[1]
	var grain: Color = W[1]
	match state:
		"hover":
			face = W[3]
			hi = W[4]
			lo = W[2]
			grain = W[2]
		"pressed":
			face = W[1]
			hi = W[0]
			lo = W[2]
			grain = W[0]
		"disabled":
			face = Palette.DIRT[1]
			hi = Palette.DIRT[2]
			lo = Palette.DIRT[0]
			grain = Palette.DIRT[0]
	c.rect(0, 0, s, s, W[0])
	c.rect(1, 1, s - 2, s - 2, face)
	for y in range(2, s - 2):
		if y % 5 == 3:
			c.rect(2, y, s - 4, 1, grain)
	c.rect(1, 1, s - 2, 1, hi)
	c.rect(1, 1, 1, s - 2, hi)
	c.rect(1, s - 2, s - 2, 1, lo)
	c.rect(s - 2, 1, 1, s - 2, lo)
	if state == "pressed":
		c.rect(2, 2, s - 4, 1, Palette.STRAW[0])
	_chip(c, s, s)
	c.save("%s/button_%s.png" % [OUT_DIR, state])


static func _buttons() -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		_button(state)


static func _note(name: String) -> void:
	var s := 24
	var c := Canvas.create(s, s, 30)
	var P := Palette.CREAM
	c.rect(0, 0, s - 2, s - 2, Palette.WOOD[2])
	c.rect(1, 1, s - 4, s - 4, P[3])
	c.speckle(1, 1, s - 4, s - 4, P[2], 0.08, false)
	c.speckle(1, 1, s - 4, s - 4, P[1], 0.03, false)
	c.rect(1, 1, s - 4, 1, Color.WHITE.lerp(P[3], 0.5))
	c.rect(1, s - 4, s - 4, 1, P[2])
	c.rect(s - 4, 1, 1, s - 4, P[2])
	c.polygon(PackedVector2Array([Vector2(s - 10, s - 2), Vector2(s - 2, s - 2), Vector2(s - 2, s - 10)]), P[1])
	c.polygon(PackedVector2Array([Vector2(s - 10, s - 2), Vector2(s - 2, s - 10), Vector2(s - 10, s - 10)]), P[2])
	c.line(s - 10, s - 10, s - 3, s - 3, Palette.WOOD[2])
	c.rect(3, 3, 3, 3, Palette.MEAT[1])
	c.rect(3, 3, 2, 2, Palette.MEAT[2])
	c.px(3, 3, Palette.MEAT[3])
	c.px(5, 5, Palette.MEAT[0])
	for x in range(s - 2, s):
		for y in range(2, s):
			c.px(x, y, Palette.SHADOW)
	for y in range(s - 2, s):
		for x in range(2, s):
			c.px(x, y, Palette.SHADOW)
	c.px(0, 0, Palette.CLEAR)
	c.px(s - 3, 0, Palette.CLEAR)
	c.px(0, s - 3, Palette.CLEAR)
	c.save("%s/%s.png" % [OUT_DIR, name])


static func _tooltip() -> void:
	var s := 16
	var c := Canvas.create(s, s, 40)
	c.rect(0, 0, s, s, Palette.WOOD[1])
	c.rect(1, 1, s - 2, s - 2, Palette.WOOD[3])
	c.rect(2, 2, s - 4, s - 4, Palette.CREAM[3])
	c.rect(2, 2, s - 4, 1, Color.WHITE)
	c.speckle(2, 2, s - 4, s - 4, Palette.CREAM[2], 0.1, false)
	_chip(c, s, s)
	c.save("%s/tooltip.png" % OUT_DIR)


static func _bars() -> void:
	var bg := Canvas.create(8, 8, 50)
	bg.rect(0, 0, 8, 8, Palette.INK)
	bg.rect(1, 1, 6, 6, Palette.WOOD[0])
	bg.rect(1, 6, 6, 1, Palette.WOOD[1])
	bg.rect(1, 1, 6, 1, Palette.INK)
	bg.save("%s/bar_bg.png" % OUT_DIR)
	var fill := Canvas.create(8, 8, 51)
	fill.rect(0, 0, 8, 8, Palette.GRASS[2])
	fill.rect(0, 0, 8, 2, Palette.GRASS[3])
	fill.rect(0, 0, 8, 1, Palette.GRASS[4])
	fill.rect(0, 6, 8, 2, Palette.GRASS[1])
	fill.save("%s/bar_fill.png" % OUT_DIR)


static func _slot() -> void:
	var s := 16
	var c := Canvas.create(s, s, 60)
	c.rect(0, 0, s, s, Palette.WOOD[0])
	c.rect(1, 1, s - 2, s - 2, Palette.WOOD[0])
	c.rect(1, 1, s - 2, 1, Palette.INK)
	c.rect(1, 1, 1, s - 2, Palette.INK)
	c.rect(2, 2, s - 4, s - 4, Color.html("#3a2417"))
	c.speckle(2, 2, s - 4, s - 4, Palette.WOOD[1], 0.06, false)
	c.rect(1, s - 1, s - 2, 1, Palette.WOOD[2])
	_chip(c, s, s)
	c.save("%s/slot.png" % OUT_DIR)


static func _icons() -> void:
	var makers: Dictionary = {
		"birth": _icon_birth,
		"death": _icon_death,
		"season": _icon_season,
		"warning": _icon_warning,
		"info": _icon_info,
		"build": _icon_build,
	}
	for id: String in makers:
		var c := Canvas.create(16, 16, hash(id))
		makers[id].call(c)
		c.outline_dark()
		c.save("%s/toast_%s.png" % [OUT_DIR, id])


static func _icon_birth(c: RefCounted) -> void:
	var M := Palette.MEAT
	c.shade_ellipse(5.0, 6.0, 4.0, 4.0, [M[1], M[2], M[2], M[3]])
	c.shade_ellipse(10.0, 6.0, 4.0, 4.0, [M[1], M[2], M[2], M[3]])
	c.polygon(PackedVector2Array([Vector2(1.5, 7.5), Vector2(14.5, 7.5), Vector2(8, 14.5)]), M[2])
	c.line(3, 8, 8, 13, M[1])
	c.line(12, 8, 8, 13, M[1])
	c.px(4, 4, M[3])
	c.px(5, 3, Palette.CREAM[3])
	c.px(4, 5, Palette.CREAM[2])


static func _icon_death(c: RefCounted) -> void:
	var S := Palette.STONE
	c.rect(3, 6, 10, 8, S[2])
	c.ellipse(8, 6, 5, 4, S[2])
	c.rect(3, 6, 2, 8, S[3])
	c.rect(11, 7, 2, 7, S[1])
	c.rect(3, 13, 10, 1, S[1])
	c.rect(7, 4, 2, 8, S[0])
	c.rect(5, 6, 6, 2, S[0])
	c.rect(7, 4, 1, 8, S[1])
	c.px(4, 8, S[4])
	c.px(3, 9, S[4])
	c.rect(2, 14, 12, 1, Palette.GRASS[2])
	c.px(4, 14, Palette.GRASS[3])
	c.px(10, 14, Palette.GRASS[3])


static func _icon_season(c: RefCounted) -> void:
	var F := Palette.FIRE
	for k in 8:
		var a := k * PI / 4.0
		c.px(int(round(8.0 + cos(a) * 6.0)), int(round(8.0 + sin(a) * 6.0)), F[2])
		c.px(int(round(8.0 + cos(a) * 5.0)), int(round(8.0 + sin(a) * 5.0)), F[1])
	c.shade_ellipse(8.0, 8.0, 3.6, 3.6, [F[1], F[2], F[2], F[3]])
	c.px(6, 6, Palette.CREAM[3])


static func _icon_warning(c: RefCounted) -> void:
	var F := Palette.FIRE
	c.polygon(PackedVector2Array([Vector2(8, 1), Vector2(15, 14), Vector2(1, 14)]), F[2])
	c.polygon(PackedVector2Array([Vector2(8, 3), Vector2(13, 13), Vector2(3, 13)]), F[3])
	c.line(8, 2, 2, 13, F[3])
	c.line(8, 2, 14, 13, F[1])
	c.rect(2, 13, 13, 1, F[1])
	c.rect(7, 5, 2, 5, Palette.INK)
	c.rect(7, 11, 2, 2, Palette.INK)


static func _icon_info(c: RefCounted) -> void:
	var S := Palette.SLATE
	c.shade_ellipse(8.0, 8.0, 6.5, 6.5, [S[0], S[1], S[2], S[3]])
	c.rect(7, 7, 2, 5, Palette.CREAM[3])
	c.rect(7, 4, 2, 2, Palette.CREAM[3])
	c.px(7, 4, Color.WHITE)


static func _icon_build(c: RefCounted) -> void:
	var W := Palette.WOOD
	var T := Palette.STEEL
	c.line(3, 13, 11, 5, W[3])
	c.line(4, 13, 12, 5, W[2])
	c.line(3, 12, 11, 4, W[4])
	c.rect(8, 1, 7, 4, T[2])
	c.rect(8, 1, 7, 1, T[3])
	c.rect(8, 4, 7, 1, T[1])
	c.rect(8, 1, 1, 4, T[3])
	c.rect(14, 2, 1, 3, T[1])


static func _thumbnails() -> void:
	for id in BUILDING_IDS:
		var img := Image.load_from_file(ProjectSettings.globalize_path("%s/%s.png" % [BUILDINGS_DIR, id]))
		img.convert(Image.FORMAT_RGBA8)
		_thumb(img, id).save("%s/thumb_%s.png" % [OUT_DIR, id])
	for id: String in FIELD_COLUMNS:
		_field_thumb(id).save("%s/thumb_%s.png" % [OUT_DIR, id])
	_road_thumb(false).save("%s/thumb_road_dirt.png" % OUT_DIR)
	_road_thumb(true).save("%s/thumb_road_stone.png" % OUT_DIR)
	_demolish_thumb().save("%s/thumb_demolish.png" % OUT_DIR)


static func _bounds(img: Image) -> Rect2i:
	var x0 := img.get_width()
	var y0 := img.get_height()
	var x1 := -1
	var y1 := -1
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				x0 = mini(x0, x)
				y0 = mini(y0, y)
				x1 = maxi(x1, x)
				y1 = maxi(y1, y)
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)


static func _thumb(img: Image, id: String) -> RefCounted:
	var box := _bounds(img)
	var inner := THUMB - 2
	var factor := maxf(float(box.size.x), float(box.size.y)) / inner
	var out_w := maxi(int(round(box.size.x / factor)), 1)
	var out_h := maxi(int(round(box.size.y / factor)), 1)
	var c := Canvas.create(THUMB, THUMB, hash(id))
	var ox := (THUMB - out_w) / 2
	var oy := THUMB - 1 - out_h
	for j in out_h:
		for i in out_w:
			var color := _mode_color(img, box, i * factor, j * factor, factor)
			if color.a > 0.5:
				c.px(ox + i, oy + j, color)
	c.outline_dark()
	return c


static func _mode_color(img: Image, box: Rect2i, fx: float, fy: float, factor: float) -> Color:
	var counts: Dictionary = {}
	var total := 0
	var opaque := 0
	var x0 := box.position.x + int(floor(fx))
	var y0 := box.position.y + int(floor(fy))
	var x1 := box.position.x + int(ceil(fx + factor))
	var y1 := box.position.y + int(ceil(fy + factor))
	for y in range(y0, mini(y1, img.get_height())):
		for x in range(x0, mini(x1, img.get_width())):
			total += 1
			var col := img.get_pixel(x, y)
			if col.a > 0.5:
				opaque += 1
				var key := col.to_html()
				counts[key] = counts.get(key, 0) + 1
	if total == 0 or opaque * 2 < total:
		return Palette.CLEAR
	var best := ""
	var best_count := 0
	var keys: Array = counts.keys()
	keys.sort()
	for key: String in keys:
		if counts[key] > best_count:
			best_count = counts[key]
			best = key
	return Color.html(best)


static func _field_thumb(id: String) -> RefCounted:
	var tiles := Image.load_from_file(ProjectSettings.globalize_path("%s/field_tiles.png" % BUILDINGS_DIR))
	tiles.convert(Image.FORMAT_RGBA8)
	var big := Canvas.create(64, 64, 1)
	var columns: Array = FIELD_COLUMNS[id]
	for k in 4:
		for j in 32:
			for i in 32:
				big.image.set_pixel((k % 2) * 32 + i, (k / 2) * 32 + j, tiles.get_pixel(int(columns[k]) * 32 + i, j))
	var c := Canvas.create(THUMB, THUMB, hash(id))
	for j in 28:
		for i in 28:
			var color := _mode_color(big.image, Rect2i(0, 0, 64, 64), i * 2.0 + 4.0, j * 2.0 + 4.0, 2.0)
			c.px(2 + i, 4 + j, color)
	var W := Palette.WOOD
	c.rect_outline(2, 4, 28, 28, W[2])
	for x in range(2, 30, 4):
		c.rect(x, 2, 1, 4, W[3])
		c.rect(x, 30, 1, 3, W[3])
		c.px(x, 2, W[4])
	c.outline_dark()
	return c


static func _road_thumb(stone: bool) -> RefCounted:
	var c := Canvas.create(THUMB, THUMB, 70 if stone else 71)
	c.polygon(PackedVector2Array([Vector2(2, 20), Vector2(2, 12), Vector2(30, 12), Vector2(30, 24), Vector2(2, 24)]), Palette.DIRT[2])
	if stone:
		var S := Palette.STONE
		for row in 3:
			for col in 8:
				var x := 2 + col * 4 + (2 if row % 2 == 1 else 0)
				var y := 11 + row * 4
				if x + 4 <= 30:
					c.shade_rect(x, y, 4, 4, [S[1], S[2], S[2], S[3]])
		c.speckle(2, 11, 28, 12, S[4], 0.04, true)
	else:
		c.noise_fill(2, 12, 28, 12, [Palette.DIRT[1], Palette.DIRT[2], Palette.DIRT[2], Palette.DIRT[3]], 3.0, 5, true)
		c.speckle(2, 12, 28, 12, Palette.DIRT[0], 0.08, true)
		c.speckle(2, 12, 28, 12, Palette.SAND[0], 0.05, true)
		for k in 5:
			c.px(2 + k * 7, 11, Palette.GRASS[2])
			c.px(4 + k * 6, 25, Palette.GRASS[2])
	c.outline_dark()
	return c


static func _demolish_thumb() -> RefCounted:
	var c := Canvas.create(THUMB, THUMB, 80)
	var W := Palette.WOOD
	var T := Palette.STEEL
	c.line(6, 27, 24, 9, W[3])
	c.line(7, 27, 25, 9, W[2])
	c.line(6, 26, 24, 8, W[4])
	c.polygon(PackedVector2Array([Vector2(14, 5), Vector2(28, 6), Vector2(27, 20), Vector2(24, 11), Vector2(17, 8)]), T[2])
	c.line(14, 5, 28, 6, T[3])
	c.line(28, 6, 27, 20, T[1])
	c.line(17, 8, 24, 11, T[1])
	c.outline_dark()
	return c
