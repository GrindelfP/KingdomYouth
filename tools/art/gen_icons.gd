extends RefCounted

const Canvas := preload("res://tools/art/pixel_canvas.gd")
const Palette := preload("res://tools/art/palette.gd")

const OUT_DIR := "res://assets/art/icons"
const SIZE := 16


static func generate() -> void:
	var makers: Dictionary = {
		"logs": _logs,
		"stone": _stone,
		"iron": _iron,
		"firewood": _firewood,
		"tools": _tools,
		"wheat": _wheat,
		"cabbage": _cabbage,
		"berries": _berries,
		"mushrooms": _mushrooms,
		"venison": _venison,
		"fish": _fish,
		"food": _bread,
	}
	var ids: Array = makers.keys()
	ids.sort()
	for id in ids:
		var canvas := Canvas.create(SIZE, SIZE, hash(id))
		makers[id].call(canvas)
		canvas.outline_dark()
		canvas.save("%s/%s.png" % [OUT_DIR, id])


static func _log_h(c: RefCounted, x: int, y: int, length: int) -> void:
	var rows := [Palette.WOOD[3], Palette.WOOD[3], Palette.WOOD[2], Palette.WOOD[2], Palette.WOOD[1]]
	for j in 5:
		c.rect(x, y + j, length, 1, rows[j])
	c.px(x + 4, y + 1, Palette.WOOD[4])
	c.px(x + 5, y + 1, Palette.WOOD[4])
	c.px(x + 8, y + 3, Palette.WOOD[1])
	c.px(x + 9, y + 3, Palette.WOOD[1])
	c.px(x + 6, y + 2, Palette.WOOD[1])
	c.ellipse(x + 1.5, y + 2.5, 2.0, 2.5, Palette.CREAM[1])
	c.px(x + 1, y + 2, Palette.STRAW[1])
	c.px(x + 1, y + 3, Palette.STRAW[1])
	c.px(x + 2, y + 1, Palette.CREAM[2])
	c.px(x, y + 2, Palette.STRAW[0])


static func _logs(c: RefCounted) -> void:
	_log_h(c, 3, 9, 11)
	_log_h(c, 4, 5, 10)
	_log_h(c, 2, 1, 11)


static func _block(c: RefCounted, x: int, y: int, w: int, h: int, seed_value: int) -> void:
	c.rect(x, y + 2, w, h - 2, Palette.STONE[2])
	c.rect(x, y + h - 2, w, 2, Palette.STONE[1])
	c.rect(x, y + 2, w, 1, Palette.STONE[3])
	c.rect(x + w - 1, y + 2, 1, h - 2, Palette.STONE[1])
	c.polygon(PackedVector2Array([Vector2(x + 2, y), Vector2(x + w + 1, y), Vector2(x + w, y + 2), Vector2(x, y + 2)]), Palette.STONE[4])
	c.line(x + 2, y, x + w, y, Palette.STONE[4])
	c.px(x + 1, y + 3, Palette.STONE[4])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for k in 3:
		c.px(x + 1 + rng.randi() % (w - 2), y + 3 + rng.randi() % (h - 4), Palette.STONE[1])


static func _stone(c: RefCounted) -> void:
	_block(c, 1, 8, 7, 6, 1)
	_block(c, 8, 8, 7, 6, 2)
	_block(c, 4, 2, 8, 6, 3)


static func _ingot(c: RefCounted, x: int, y: int, w: int) -> void:
	var inset := 2
	c.polygon(PackedVector2Array([Vector2(x, y + 6), Vector2(x + w, y + 6), Vector2(x + w - 1, y + 3), Vector2(x + 1, y + 3)]), Palette.STEEL[1])
	c.polygon(PackedVector2Array([Vector2(x + 1, y + 3), Vector2(x + w - 1, y + 3), Vector2(x + w - 1 - inset + 1, y), Vector2(x + inset, y)]), Palette.STEEL[2])
	c.line(x + 2, y + 1, x + w - 3, y + 1, Palette.STEEL[3])
	c.line(x + 1, y + 3, x + w - 2, y + 3, Palette.STEEL[3])
	c.rect(x, y + 5, w, 1, Palette.STEEL[0])
	c.px(x + 2, y + 4, Palette.STEEL[3])


static func _iron(c: RefCounted) -> void:
	_ingot(c, 3, 2, 9)
	_ingot(c, 0, 8, 9)
	_ingot(c, 6, 8, 9)


static func _firewood(c: RefCounted) -> void:
	var spots: Array[Vector2] = [Vector2(4.5, 11.5), Vector2(9.5, 11.5), Vector2(14.0, 11.5), Vector2(7.0, 6.5), Vector2(12.0, 6.5), Vector2(9.5, 2.0)]
	var picks: Array[Vector2] = [Vector2(4.5, 11.0), Vector2(9.5, 11.0), Vector2(7.0, 6.0), Vector2(12.0, 6.0), Vector2(9.5, 1.5)]
	picks = [Vector2(3.5, 11.0), Vector2(8.5, 11.0), Vector2(13.0, 11.0), Vector2(6.0, 6.5), Vector2(11.0, 6.5), Vector2(8.5, 2.5)]
	spots.clear()
	for p in picks:
		c.shade_ellipse(p.x, p.y, 2.6, 2.6, [Palette.WOOD[1], Palette.WOOD[2], Palette.WOOD[3]])
	for p in picks:
		c.ellipse(p.x - 0.3, p.y - 0.3, 1.7, 1.7, Palette.CREAM[1])
		c.px(int(p.x - 1), int(p.y - 1), Palette.CREAM[3])
		c.px(int(p.x), int(p.y), Palette.STRAW[1])
		c.px(int(p.x) - 1, int(p.y), Palette.STRAW[0])


static func _tools(c: RefCounted) -> void:
	c.line(3, 13, 11, 5, Palette.WOOD[3])
	c.line(4, 13, 12, 5, Palette.WOOD[2])
	c.line(12, 13, 4, 5, Palette.WOOD[3])
	c.line(11, 13, 3, 5, Palette.WOOD[2])
	c.rect(9, 1, 6, 5, Palette.STEEL[2])
	c.rect(9, 5, 6, 1, Palette.STEEL[1])
	c.rect(14, 1, 1, 5, Palette.STEEL[1])
	c.line(9, 1, 14, 1, Palette.STEEL[3])
	c.px(9, 2, Palette.STEEL[3])
	c.polygon(PackedVector2Array([Vector2(0, 1), Vector2(4, 1), Vector2(7, 4), Vector2(5, 7), Vector2(2, 7), Vector2(1, 5)]), Palette.STEEL[2])
	c.line(1, 6, 1, 2, Palette.STEEL[3])
	c.line(1, 2, 3, 2, Palette.STEEL[3])
	c.line(3, 6, 6, 4, Palette.STEEL[1])
	c.px(7, 6, Palette.WOOD[1])
	c.px(8, 8, Palette.STRAW[1])


static func _wheat(c: RefCounted) -> void:
	var tops: Array[Vector2i] = [Vector2i(3, 4), Vector2i(8, 2), Vector2i(13, 4), Vector2i(5, 3), Vector2i(11, 3)]
	for t in tops:
		c.line(8, 14, t.x, t.y + 3, Palette.STRAW[0])
	for t in tops:
		for k in 4:
			var yy := t.y + k * 1
			c.px(t.x - 1, yy + (k % 2), Palette.STRAW[2])
			c.px(t.x + 1, yy + ((k + 1) % 2), Palette.STRAW[1])
			c.px(t.x, yy, Palette.STRAW[3] if k < 2 else Palette.STRAW[2])
		c.px(t.x, t.y - 1, Palette.STRAW[2])
	c.rect(6, 11, 5, 2, Palette.ROOF_RED[2])
	c.rect(6, 12, 5, 1, Palette.ROOF_RED[1])
	c.line(7, 14, 7, 15, Palette.STRAW[0])
	c.line(9, 14, 9, 15, Palette.STRAW[0])


static func _cabbage(c: RefCounted) -> void:
	c.shade_ellipse(8, 8.5, 6.8, 6.3, Palette.CABBAGE)
	c.ellipse(8.5, 8.5, 4.2, 4.0, Palette.CABBAGE[2])
	c.shade_ellipse(8.5, 8.5, 3.6, 3.4, [Palette.CABBAGE[1], Palette.CABBAGE[2], Palette.CABBAGE[3], Palette.CREAM[2]])
	c.line(2, 9, 5, 5, Palette.CABBAGE[0])
	c.line(13, 6, 10, 12, Palette.CABBAGE[1])
	c.line(5, 12, 9, 13, Palette.CABBAGE[0])
	c.line(8, 3, 6, 6, Palette.CABBAGE[3])
	c.line(10, 3, 12, 5, Palette.CABBAGE[3])
	c.line(4, 10, 6, 13, Palette.CABBAGE[1])
	c.px(6, 5, Palette.CABBAGE[3])
	c.px(5, 4, Palette.CABBAGE[3])


static func _berries(c: RefCounted) -> void:
	c.line(8, 1, 8, 5, Palette.GRASS[1])
	c.polygon(PackedVector2Array([Vector2(8, 3), Vector2(13, 1), Vector2(14, 4), Vector2(10, 5)]), Palette.GRASS[3])
	c.line(9, 3, 13, 2, Palette.GRASS[4])
	c.polygon(PackedVector2Array([Vector2(8, 3), Vector2(3, 2), Vector2(2, 5), Vector2(6, 5)]), Palette.GRASS[2])
	c.line(3, 3, 6, 4, Palette.GRASS[3])
	var spots: Array[Vector2] = [Vector2(8.0, 6.5), Vector2(4.5, 10.5), Vector2(11.5, 10.5), Vector2(8.0, 12.0)]
	for p in spots:
		c.ellipse(p.x, p.y, 3.6, 3.6, Palette.BERRY[0])
		c.shade_ellipse(p.x, p.y, 2.9, 2.9, Palette.BERRY)
		c.px(int(p.x) - 1, int(p.y) - 1, Palette.BERRY[3])
		c.px(int(p.x) - 1, int(p.y) - 2, Palette.CREAM[3])


static func _mushrooms(c: RefCounted) -> void:
	_mushroom(c, 4, 7, 7, 4)
	_mushroom(c, 12, 11, 5, 3)


static func _mushroom(c: RefCounted, cx: int, base: int, cap_w: int, cap_h: int) -> void:
	var stem_w := maxi(2, cap_w / 3 + 1)
	var stem_x := cx - stem_w / 2
	c.rect(stem_x, base - 2, stem_w, 6, Palette.CREAM[2])
	c.rect(stem_x + stem_w - 1, base - 2, 1, 6, Palette.CREAM[0])
	c.rect(stem_x, base - 2, 1, 6, Palette.CREAM[3])
	c.shade_ellipse(cx, base - 1.5, cap_w * 0.5 + 0.5, cap_h, [Palette.WOOD[1], Palette.WOOD[2], Palette.WOOD[3], Palette.WOOD[4]])
	c.rect(cx - cap_w, base - 1, cap_w * 2 + 1, 3, Palette.CLEAR)
	c.rect(stem_x, base - 2, stem_w, 5, Palette.CREAM[2])
	c.rect(stem_x + stem_w - 1, base - 2, 1, 5, Palette.CREAM[0])
	c.rect(cx - cap_w / 2 - 1, base - 3, cap_w + 3, 2, Palette.WOOD[2])
	c.rect(cx - cap_w / 2, base - 3, cap_w + 1, 1, Palette.WOOD[3])
	c.px(cx - cap_w / 2, base - 4, Palette.WOOD[4])
	c.px(cx - cap_w / 2 + 1, base - 4, Palette.WOOD[4])


static func _venison(c: RefCounted) -> void:
	c.line(9, 9, 13, 13, Palette.CREAM[2])
	c.line(10, 9, 14, 13, Palette.CREAM[1])
	c.ellipse(13.5, 13.5, 1.6, 1.6, Palette.CREAM[2])
	c.ellipse(11.5, 14.5, 1.3, 1.3, Palette.CREAM[1])
	c.px(14, 12, Palette.CREAM[3])
	c.shade_ellipse(6.5, 6.5, 5.6, 5.0, Palette.MEAT)
	c.polygon(PackedVector2Array([Vector2(8, 8), Vector2(11, 9), Vector2(10, 11), Vector2(7, 10)]), Palette.MEAT[1])
	c.line(3, 4, 7, 3, Palette.MEAT[3])
	c.line(4, 6, 5, 8, Palette.MEAT[3])
	c.line(8, 5, 10, 7, Palette.MEAT[0])
	c.px(5, 4, Palette.CREAM[3])


static func _fish(c: RefCounted) -> void:
	c.polygon(PackedVector2Array([Vector2(11, 8), Vector2(15, 3), Vector2(15, 13)]), Palette.FISH[1])
	c.line(12, 8, 14, 5, Palette.FISH[2])
	c.line(12, 8, 14, 11, Palette.FISH[0])
	c.polygon(PackedVector2Array([Vector2(5, 4), Vector2(9, 1), Vector2(10, 5)]), Palette.FISH[0])
	c.polygon(PackedVector2Array([Vector2(6, 11), Vector2(9, 14), Vector2(10, 11)]), Palette.FISH[0])
	c.shade_ellipse(7, 8, 6.5, 4.2, Palette.FISH)
	c.rect(3, 9, 8, 2, Palette.FISH[3])
	c.line(4, 6, 11, 5, Palette.FISH[1])
	c.line(5, 7, 10, 7, Palette.FISH[2])
	c.line(6, 6, 6, 9, Palette.FISH[0])
	c.px(3, 6, Palette.INK)
	c.px(3, 5, Palette.FISH[3])
	c.px(2, 8, Palette.FISH[0])


static func _bread(c: RefCounted) -> void:
	c.shade_ellipse(8, 9, 7, 4.8, Palette.BREAD)
	c.line(4, 7, 6, 10, Palette.BREAD[0])
	c.line(7, 6, 9, 9, Palette.BREAD[0])
	c.line(10, 7, 12, 10, Palette.BREAD[0])
	c.line(4, 6, 5, 6, Palette.BREAD[3])
	c.line(7, 5, 8, 5, Palette.BREAD[3])
	c.line(10, 6, 11, 6, Palette.BREAD[3])
