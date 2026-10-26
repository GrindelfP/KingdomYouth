extends RefCounted

const Canvas := preload("res://tools/art/pixel_canvas.gd")
const Palette := preload("res://tools/art/palette.gd")
const P := preload("res://tools/art/building_parts.gd")

const OUT_DIR := "res://assets/art/buildings"
const PAD_X := 8
const PAD_BOTTOM := 6

const SPECS := {
	"house": [2, 2, 16],
	"foresters_lodge": [2, 2, 26],
	"gatherers_hut": [2, 2, 8],
	"hunting_cabin": [2, 2, 16],
	"woodcutter": [2, 2, 10],
	"blacksmith": [2, 2, 22],
	"fishing_dock": [2, 2, 12],
	"storage_barn": [3, 3, 22],
	"mine": [3, 3, 16],
	"quarry": [3, 3, 8],
	"stockpile": [4, 4, 20],
}


static func generate() -> void:
	for id in SPECS:
		for winter in [false, true]:
			var c: RefCounted = _make(id, winter)
			c.save("%s/%s%s.png" % [OUT_DIR, id, "_winter" if winter else ""])


static func _make(id: String, winter: bool) -> RefCounted:
	match id:
		"house":
			return _house(winter)
		"foresters_lodge":
			return _foresters_lodge(winter)
		"gatherers_hut":
			return _gatherers_hut(winter)
		"hunting_cabin":
			return _hunting_cabin(winter)
		"woodcutter":
			return _woodcutter(winter)
		"blacksmith":
			return _blacksmith(winter)
		"fishing_dock":
			return _fishing_dock(winter)
		"storage_barn":
			return _storage_barn(winter)
		"mine":
			return _mine(winter)
		"quarry":
			return _quarry(winter)
	return _stockpile(winter)


static func _new(id: String, seed_value: int) -> RefCounted:
	var spec: Array = SPECS[id]
	return Canvas.create(spec[0] * 32 + PAD_X * 2, spec[1] * 32 + spec[2] + PAD_BOTTOM, seed_value)


static func _by(c: RefCounted) -> int:
	return int(c.height) - PAD_BOTTOM


static func _finish(c: RefCounted, winter: bool, x0: int, x1: int, shadow_depth: int = 3) -> void:
	c.outline_dark()
	var by := _by(c)
	for j in range(by - 2, by + shadow_depth):
		for i in range(x0 + 2, x1 + 5):
			var edge := minf(float(i - x0 - 2), float(x1 + 4 - i))
			if j >= by + shadow_depth - 1 and edge < 3.0:
				continue
			if not c.is_opaque(i, j):
				c.px(i, j, Palette.SHADOW)
	if winter:
		P.snow_ground(c, x0 + 2, x1 - 2, by + 1, 77)


static func _house(winter: bool) -> RefCounted:
	var c := _new("house", 11)
	var W := Palette.WOOD
	var S := Palette.STONE
	var by := _by(c)
	var wt := by - 25
	P.plank_wall(c, 14, wt, 52, 22, W, 11)
	c.rect(14, wt, 2, 22, W[1])
	c.rect(15, wt, 1, 22, W[3])
	c.rect(64, wt, 2, 22, W[0])
	c.rect(14, by - 4, 52, 3, S[2])
	c.noise_fill(14, by - 4, 52, 3, [S[1], S[2], S[2], S[3]], 3.0, 5)
	P.door(c, 35, wt + 7, 9, 15)
	P.window(c, 21, wt + 8)
	P.window(c, 53, wt + 8)
	var roof := P.pts([[7, wt + 4], [73, wt + 4], [55, 22], [25, 22]])
	P.roof(c, roof, Palette.STRAW, "thatch", 12)
	for k in 7:
		c.px(27 + k * 4, 21, Palette.STRAW[1])
		c.px(28 + k * 4, 20, Palette.STRAW[0])
	P.eave_shadow(c, 14, 66, wt + 5)
	P.chimney(c, 53, 16, 8, 28, 13)
	c.rect(53, 40, 8, 3, Palette.STONE[0])
	if winter:
		P.snow_roof(c, roof, 14)
		c.rect(52, 12, 10, 1, Palette.SNOW[3])
		c.rect(53, 13, 8, 1, Palette.SNOW[2])
	_finish(c, winter, 10, 70)
	return c


static func _foresters_lodge(winter: bool) -> RefCounted:
	var c := _new("foresters_lodge", 21)
	var W := Palette.WOOD
	var L := Palette.LEAF_DEEP
	var G := Palette.GRASS
	var by := _by(c)
	var wt := by - 20
	P.plank_wall(c, 18, wt, 44, 17, W, 21)
	c.rect(18, wt, 2, 17, W[1])
	c.rect(60, wt, 2, 17, W[0])
	c.rect(18, by - 4, 44, 2, Palette.STONE[1])
	P.door(c, 34, wt + 4, 10, 13)
	var roof := P.pts([[11, wt + 3], [16, wt - 3], [23, wt - 14], [30, wt - 28], [36, wt - 42], [40, wt - 52], [44, wt - 42], [50, wt - 28], [57, wt - 14], [64, wt - 3], [69, wt + 3]])
	P.roof(c, roof, [L[0], L[1], L[2], G[2]], "tile", 22)
	c.line(40, wt - 53, 40, wt - 60, W[3])
	c.px(39, wt - 60, W[4])
	c.px(41, wt - 56, G[3])
	c.px(39, wt - 57, G[3])
	c.px(41, wt - 59, G[2])
	P.eave_shadow(c, 18, 62, wt + 4)
	c.rect(30, wt - 30, 11, 9, W[0])
	c.rect(32, wt - 29, 7, 7, Palette.FIRE[2])
	c.rect(32, wt - 29, 3, 3, Palette.FIRE[3])
	c.line(35, wt - 29, 35, wt - 23, W[1])
	c.line(32, wt - 26, 38, wt - 26, W[1])
	c.rect(63, by - 15, 14, 12, Palette.DIRT[1])
	c.noise_fill(63, by - 15, 14, 12, [Palette.DIRT[0], Palette.DIRT[1], Palette.DIRT[2]], 2.0, 8)
	for k in 3:
		_sapling(c, 66 + k * 4, by - 5 - (k % 2) * 3)
	c.rect(62, by - 16, 16, 1, W[3])
	c.rect(62, by - 3, 16, 1, W[2])
	c.rect(62, by - 16, 1, 14, W[3])
	c.rect(77, by - 16, 1, 14, W[1])
	_stump_axe(c, 4, by - 1)
	if winter:
		P.snow_roof(c, roof, 24, 4)
		c.rect(63, by - 16, 14, 2, Palette.SNOW[2])
	_finish(c, winter, 10, 70)
	return c


static func _sapling(c: RefCounted, x: int, by: int) -> void:
	var G := Palette.GRASS
	c.line(x, by, x, by - 5, Palette.WOOD[2])
	c.shade_ellipse(x, by - 7, 2.6, 2.6, [G[1], G[2], G[3], G[4]])
	c.px(x - 2, by - 4, G[3])
	c.px(x + 2, by - 5, G[2])


static func _stump_axe(c: RefCounted, x: int, by: int) -> void:
	var W := Palette.WOOD
	c.rect(x, by - 8, 9, 8, W[2])
	c.rect(x, by - 8, 1, 8, W[3])
	c.rect(x + 8, by - 8, 1, 8, W[1])
	c.rect(x, by - 1, 9, 1, W[0])
	c.ellipse(x + 4.5, by - 8, 4.5, 2.2, W[4])
	c.ellipse(x + 4.5, by - 8, 2.6, 1.2, W[3])
	c.px(x + 4, by - 8, W[2])
	c.line(x + 6, by - 10, x + 11, by - 17, W[3])
	c.line(x + 7, by - 10, x + 12, by - 17, W[2])
	c.rect(x + 10, by - 19, 5, 3, Palette.STEEL[2])
	c.rect(x + 10, by - 19, 5, 1, Palette.STEEL[3])
	c.px(x + 14, by - 17, Palette.STEEL[1])


static func _gatherers_hut(winter: bool) -> RefCounted:
	var c := _new("gatherers_hut", 31)
	var W := Palette.WOOD
	var C := Palette.CREAM
	var by := _by(c)
	var wt := by - 18
	c.noise_fill(22, wt, 36, 16, [C[0], C[1], C[1], C[2]], 2.5, 31)
	for k in 6:
		c.px(24 + k * 6, wt + 3 + (k % 3) * 3, C[0])
		c.px(25 + k * 6, wt + 4 + (k % 3) * 3, C[0])
	c.rect(22, wt, 3, 16, W[2])
	c.rect(55, wt, 3, 16, W[1])
	c.rect(22, wt, 1, 16, W[3])
	c.rect(22, by - 4, 36, 3, Palette.STONE[2])
	c.noise_fill(22, by - 4, 36, 3, [Palette.STONE[1], Palette.STONE[2], Palette.STONE[3]], 2.0, 3)
	P.door(c, 35, wt + 5, 10, 13)
	c.rect(35, wt + 3, 10, 2, W[2])
	var hut_roof := P.pts([[13, by - 16], [16, by - 22], [22, by - 32], [29, by - 41], [35, by - 48], [40, by - 54], [45, by - 48], [51, by - 41], [58, by - 32], [64, by - 22], [67, by - 16], [58, by - 13], [40, by - 12], [22, by - 13]])
	var ramp := [Palette.GRASS[1], Palette.STRAW[0], Palette.STRAW[1], Palette.STRAW[2]]
	P.roof(c, hut_roof, ramp, "thatch", 32)
	for k in 5:
		c.px(38 + k, by - 55 + (k % 2), Palette.STRAW[1])
	c.px(40, by - 56, Palette.STRAW[2])
	c.line(40, by - 55, 40, by - 59, W[2])
	c.px(39, by - 59, Palette.GRASS[3])
	c.px(41, by - 58, Palette.GRASS[3])
	P.eave_shadow(c, 24, 56, by - 11)
	P.basket(c, 14, by - 1, Palette.BERRY)
	P.basket(c, 66, by - 1, Palette.BREAD)
	c.px(11, by - 9, Palette.BERRY[3])
	if winter:
		P.snow_roof(c, hut_roof, 34, 3)
	_finish(c, winter, 10, 70)
	return c


static func _hunting_cabin(winter: bool) -> RefCounted:
	var c := _new("hunting_cabin", 41)
	var W := Palette.WOOD
	var K := Palette.CREAM
	var by := _by(c)
	var wt := by - 20
	P.log_wall(c, 17, wt, 40, 17, W, 41)
	c.rect(17, by - 4, 40, 2, Palette.STONE[1])
	P.door(c, 31, wt + 5, 9, 12)
	P.window(c, 45, wt + 6, 5, 5, false)
	var border := [[11, wt + 3], [63, wt + 3]]
	var pelt := PackedVector2Array([Vector2(10, wt + 3), Vector2(64, wt + 3), Vector2(58, wt - 12), Vector2(48, wt - 22), Vector2(26, wt - 22), Vector2(16, wt - 12)])
	var fringe := PackedVector2Array()
	for x in range(64, 9, -6):
		fringe.append(Vector2(x, wt + 3))
		fringe.append(Vector2(x - 3, wt + 6))
	var roof := PackedVector2Array([Vector2(64, wt + 3), Vector2(58, wt - 12), Vector2(48, wt - 22), Vector2(26, wt - 22), Vector2(16, wt - 12), Vector2(10, wt + 3)])
	roof.append_array(PackedVector2Array(fringe))
	P.roof(c, roof, [Palette.DIRT[0], Palette.DIRT[1], Palette.DIRT[2], Palette.DIRT[3]], "hide", 42)
	c.line(37, wt - 22, 37, wt + 2, Palette.DIRT[0])
	c.line(36, wt - 20, 36, wt, Palette.DIRT[3])
	P.eave_shadow(c, 17, 57, wt + 7)
	c.line(37, wt - 22, 37, wt - 30, W[2])
	_skull(c, 37, wt - 24)
	_rack(c, 63, by)
	if winter:
		P.snow_roof(c, roof, 44, 4)
	_finish(c, winter, 10, 70)
	return c


static func _skull(c: RefCounted, cx: int, cy: int) -> void:
	var K := Palette.CREAM
	c.ellipse(cx, cy, 3.0, 2.5, K[2])
	c.rect(cx - 1, cy + 1, 3, 3, K[1])
	c.px(cx - 2, cy, Palette.INK)
	c.px(cx + 1, cy, Palette.INK)
	c.px(cx - 2, cy - 1, K[3])
	var left := [[cx - 2, cy - 2], [cx - 5, cy - 5], [cx - 7, cy - 10], [cx - 10, cy - 15]]
	var right := [[cx + 2, cy - 2], [cx + 5, cy - 5], [cx + 7, cy - 10], [cx + 10, cy - 15]]
	for side in [left, right]:
		for k in range(side.size() - 1):
			c.line(side[k][0], side[k][1], side[k + 1][0], side[k + 1][1], K[3] if side == left else K[2])
		var dir := -1 if side == left else 1
		c.line(side[1][0], side[1][1], side[1][0] + dir * 4, side[1][1] - 2, K[2])
		c.line(side[2][0], side[2][1], side[2][0] + dir * 3, side[2][1] - 4, K[2])
		c.line(side[3][0], side[3][1], side[3][0] + dir * -1, side[3][1] - 3, K[3])
	c.px(cx - 1, cy + 4, K[0])
	c.px(cx + 1, cy + 4, K[0])


static func _rack(c: RefCounted, x: int, by: int) -> void:
	var W := Palette.WOOD
	var M := Palette.MEAT
	c.line(x, by - 2, x, by - 24, W[2])
	c.line(x + 1, by - 2, x + 1, by - 24, W[1])
	c.line(x + 14, by - 2, x + 14, by - 24, W[2])
	c.line(x + 15, by - 2, x + 15, by - 24, W[1])
	c.rect(x - 1, by - 24, 18, 2, W[3])
	c.rect(x - 1, by - 24, 18, 1, W[4])
	c.rect(x + 3, by - 22, 7, 14, Palette.DIRT[2])
	c.noise_fill(x + 3, by - 22, 7, 14, [Palette.DIRT[1], Palette.DIRT[2], Palette.DIRT[3], Palette.CREAM[0]], 2.5, 45)
	c.rect(x + 3, by - 22, 7, 1, Palette.DIRT[0])
	for k in 3:
		c.px(x + 4 + k * 2, by - 8, Palette.DIRT[1])
	for k in 3:
		c.line(x + 11 + k, by - 22, x + 11 + k, by - 14 + k * 2, M[2 if k != 1 else 3])
		c.px(x + 11 + k, by - 14 + k * 2, M[1])
	c.rect(x - 1, by - 4, 3, 3, W[1])
	c.rect(x + 13, by - 4, 3, 3, W[1])


static func _woodcutter(winter: bool) -> RefCounted:
	var c := _new("woodcutter", 51)
	var W := Palette.WOOD
	var by := _by(c)
	var back := by - 33
	P.plank_wall(c, 10, back, 56, 29, [W[0], W[0], W[1], W[1]], 51)
	c.rect(10, by - 5, 56, 3, Palette.DIRT[1])
	P.firewood_stack(c, 14, by - 4, 6, 5, 2.3)
	P.log_stack(c, 54, by - 4, 3, 3.0)
	var roof := P.pts([[4, back + 2], [72, back + 2], [66, back - 18], [10, back - 18]])
	P.roof(c, roof, [W[1], W[2], W[3], W[4]], "shake", 52)
	c.rect(10, back - 19, 56, 2, W[4])
	c.rect(10, back - 19, 56, 1, W[4])
	P.eave_shadow(c, 10, 66, back + 3)
	for x in [8, 63]:
		c.rect(x, back + 3, 4, 30, W[2])
		c.rect(x, back + 3, 1, 30, W[4])
		c.rect(x + 3, back + 3, 1, 30, W[0])
	c.rect(7, by - 3, 6, 2, Palette.STONE[1])
	c.rect(62, by - 3, 6, 2, Palette.STONE[1])
	_stump_axe(c, 34, by + 1)
	for k in 6:
		c.px(26 + k * 3, by - 1 + (k % 2), W[4])
		c.px(27 + k * 3, by, W[3])
	if winter:
		P.snow_roof(c, roof, 54, 3)
		c.rect(10, back - 20, 56, 1, Palette.SNOW[3])
	_finish(c, winter, 8, 68)
	return c


static func _blacksmith(winter: bool) -> RefCounted:
	var c := _new("blacksmith", 61)
	var W := Palette.WOOD
	var S := Palette.STONE
	var F := Palette.FIRE
	var by := _by(c)
	var wt := by - 25
	P.stone_wall(c, 12, wt, 56, 22, S, 61)
	c.rect(12, wt, 1, 22, S[3])
	c.rect(67, wt, 1, 22, S[0])
	var roof := P.pts([[6, wt + 4], [74, wt + 4], [62, wt - 17], [18, wt - 17]])
	P.roof(c, roof, Palette.SLATE, "slate", 62)
	P.eave_shadow(c, 12, 68, wt + 5)
	P.chimney(c, 13, 14, 14, 30, 63)
	c.rect(13, 40, 14, 4, S[0])
	c.rect(17, 10, 6, 2, F[1])
	c.px(19, 8, F[3])
	c.px(21, 9, F[2])
	c.px(18, 7, F[2])
	for j in range(by - 21, by - 3):
		for i in range(20, 36):
			var arch := absf(i - 27.5) < 8.0 - (0.9 if j < by - 19 else 0.0) * 3.0
			if not arch:
				continue
			var t := float(j - (by - 21)) / 17.0
			var v := t * 1.1 - 0.15 + (Canvas.hash01(i, j, 3) - 0.5) * 0.15
			if t < 0.2:
				c.px(i, j, Palette.INK)
			else:
				c.px(i, j, F[P.qidx(v, 4, i, j)] if v > 0.3 else Palette.MEAT[0])
	for k in 5:
		c.px(22 + k * 3, by - 5 - (k % 2), F[3])
	c.rect(18, by - 22, 20, 2, S[4])
	c.rect(18, by - 22, 2, 19, S[3])
	c.rect(36, by - 22, 2, 19, S[1])
	P.door(c, 54, wt + 8, 9, 14)
	P.window(c, 43, wt + 6, 5, 5, false)
	_anvil(c, 40, by + 1)
	P.barrel(c, 4, by, 8, 9)
	c.rect(4, by - 10, 8, 2, Palette.WATER[2])
	c.rect(5, by - 10, 3, 1, Palette.WATER[4])
	if winter:
		P.snow_roof(c, roof, 64, 3)
		c.rect(12, 13, 16, 1, Palette.SNOW[3])
	_finish(c, winter, 8, 70)
	return c


static func _anvil(c: RefCounted, x: int, by: int) -> void:
	var T := Palette.STEEL
	var W := Palette.WOOD
	c.rect(x + 2, by - 8, 8, 8, W[2])
	c.rect(x + 2, by - 8, 1, 8, W[3])
	c.rect(x + 9, by - 8, 1, 8, W[1])
	c.rect(x + 2, by - 1, 8, 1, W[0])
	c.polygon(P.pts([[x - 3, by - 14], [x + 14, by - 14], [x + 11, by - 11], [x + 9, by - 9], [x + 3, by - 9], [x + 1, by - 11]]), T[2])
	c.rect(x - 3, by - 14, 17, 2, T[3])
	c.rect(x + 1, by - 11, 10, 1, T[1])
	c.px(x - 3, by - 14, Palette.CREAM[3])
	c.rect(x + 4, by - 9, 4, 2, T[1])
	c.px(x + 16, by - 12, T[1])
	c.line(x + 6, by - 15, x + 12, by - 20, W[3])
	c.rect(x + 11, by - 23, 5, 3, T[2])
	c.rect(x + 11, by - 23, 5, 1, T[3])


static func _fishing_dock(winter: bool) -> RefCounted:
	var c := _new("fishing_dock", 71)
	var W := Palette.WOOD
	var by := _by(c)
	var top := by - 46
	for j in range(top, by - 8):
		for i in range(10, 70):
			var row := (j - top) / 4
			var r := (j - top) % 4
			var v := 0.58 + (Canvas.hash01(row, 2, 71) - 0.5) * 0.18
			if r == 0:
				v += 0.16
			elif r == 3:
				v -= 0.24
			if (i + row * 17) % 23 == 0:
				v -= 0.22
			c.px(i, j, W[P.qidx(v, 5, i, j)])
	for row in 10:
		var yy := top + row * 4 + 1
		for k in 3:
			c.px(13 + (row * 11 + k * 21) % 52, yy, W[0])
	c.rect(10, by - 8, 60, 6, W[1])
	c.rect(10, by - 8, 60, 1, W[3])
	for x in range(12, 70, 12):
		c.rect(x, by - 8, 3, 8, W[0])
		c.rect(x, by - 8, 1, 8, W[2])
	for x in [10, 66]:
		c.rect(x, top - 4, 4, 12, W[2])
		c.rect(x, top - 4, 1, 12, W[4])
		c.rect(x + 3, top - 4, 1, 12, W[0])
		c.rect(x, top - 5, 4, 2, W[4])
	c.line(12, top - 2, 36, top + 4, Palette.CREAM[1])
	c.line(36, top + 4, 66, top - 2, Palette.CREAM[1])
	var T := Palette.FISH
	c.line(18, by - 14, 18, by - 38, W[2])
	c.line(19, by - 14, 19, by - 38, W[1])
	c.line(46, by - 14, 46, by - 38, W[2])
	c.line(47, by - 14, 47, by - 38, W[1])
	c.rect(17, by - 38, 31, 2, W[3])
	c.rect(17, by - 38, 31, 1, W[4])
	for k in 5:
		var fx := 21 + k * 5
		var fy := by - 36
		c.line(fx, fy, fx, fy + 2, W[0])
		c.ellipse(fx, fy + 6, 1.8, 4.5, T[2])
		c.ellipse(fx, fy + 6, 1.0, 3.0, T[3])
		c.px(fx, fy + 3, T[1])
		c.px(fx, fy + 10, T[0])
		c.px(fx - 1, fy + 11, T[1])
		c.px(fx + 1, fy + 11, T[1])
	P.barrel(c, 52, by - 8, 8, 10)
	P.crate(c, 61, by - 8, 8, 7)
	c.rect(22, by - 12, 18, 7, Palette.WATER[1])
	for j in 7:
		for i in 18:
			if (i + j) % 3 == 0:
				c.px(22 + i, by - 12 + j, Palette.WATER[3] if (i + j) % 2 == 0 else Palette.WATER[0])
	c.rect(22, by - 12, 18, 1, Palette.WATER[4])
	if winter:
		c.rect(10, top - 5, 60, 1, Palette.SNOW[2])
		for k in 10:
			c.rect(12 + k * 6, top + (k % 3) * 9 + 2, 4, 2, Palette.SNOW[3])
		c.rect(17, by - 40, 31, 1, Palette.SNOW[3])
		c.rect(52, by - 19, 8, 1, Palette.SNOW[3])
	_finish(c, winter, 8, 70)
	return c


static func _storage_barn(winter: bool) -> RefCounted:
	var c := _new("storage_barn", 81)
	var W := Palette.WOOD
	var R := Palette.ROOF_RED
	var K := Palette.CREAM
	var by := _by(c)
	var wt := by - 36
	P.plank_wall(c, 12, wt, 88, 32, [W[0], W[1], W[2], W[3]], 81, 5)
	c.rect(12, by - 4, 88, 3, Palette.STONE[1])
	c.noise_fill(12, by - 4, 88, 3, [Palette.STONE[1], Palette.STONE[2]], 3.0, 4)
	for x in [12, 97]:
		c.rect(x, wt, 3, 32, W[1])
	c.rect(39, wt + 6, 34, 26, Palette.INK)
	c.rect(39, wt + 6, 34, 3, W[0])
	for j in range(by - 12, by - 3):
		for i in range(41, 71):
			var v := 0.5 + (Canvas.hash01(i, j, 5) - 0.5) * 0.4 + float(j - (by - 12)) * 0.02
			c.px(i, j, Palette.STRAW[P.qidx(v, 3, i, j)])
	for k in 5:
		c.line(44 + k * 6, by - 12, 47 + k * 6, by - 6, Palette.STRAW[0])
	for side in [0, 1]:
		var lx := 36 if side == 0 else 73
		var dx := -1 if side == 0 else 1
		var leaf := PackedVector2Array([Vector2(lx, wt + 6), Vector2(lx + dx * 8, wt + 4), Vector2(lx + dx * 8, wt + 30), Vector2(lx, wt + 32)])
		c.polygon(leaf, W[2])
		c.line(lx + dx * 7, wt + 5, lx + dx * 7, wt + 29, W[3] if side == 0 else W[1])
		c.line(lx, wt + 6, lx + dx * 8, wt + 29, K[1])
		c.line(lx + dx * 8, wt + 5, lx, wt + 31, K[1])
		c.line(lx, wt + 6, lx, wt + 31, W[0])
	c.rect(37, wt + 4, 38, 2, K[2])
	c.rect(37, wt + 4, 38, 1, K[3])
	var roof := P.pts([[3, wt + 4], [109, wt + 4], [103, wt - 18], [86, wt - 42], [26, wt - 42], [9, wt - 18]])
	P.roof(c, roof, [R[0], R[1], R[2], R[3]], "tile", 82)
	c.line(9, wt - 18, 26, wt - 42, K[2])
	c.line(103, wt - 18, 86, wt - 42, K[1])
	c.line(26, wt - 42, 86, wt - 42, K[3])
	c.line(3, wt + 3, 9, wt - 18, K[2])
	c.line(109, wt + 3, 103, wt - 18, K[1])
	P.eave_shadow(c, 12, 100, wt + 5)
	c.rect(47, wt - 34, 18, 16, W[0])
	c.rect(47, wt - 34, 18, 2, K[2])
	c.rect(48, wt - 32, 16, 14, Palette.INK)
	for j in range(wt - 25, wt - 18):
		for i in range(49, 63):
			c.px(i, j, Palette.STRAW[P.qidx(0.35 + (Canvas.hash01(i, j, 9) - 0.5) * 0.5, 3, i, j)])
	c.line(56, wt - 42, 56, wt - 50, W[2])
	c.line(50, wt - 50, 62, wt - 50, W[3])
	c.px(62, wt - 49, K[2])
	P.sack(c, 82, by, 8)
	P.sack(c, 91, by - 1, 8)
	P.sack(c, 86, by - 8, 7)
	c.rect(98, by - 6, 3, 2, K[1])
	P.crate(c, 16, by, 10, 9)
	P.crate(c, 22, by - 9, 9, 8)
	P.sack(c, 33, by, 7)
	if winter:
		P.snow_roof(c, roof, 84, 4)
		c.rect(26, wt - 43, 60, 1, Palette.SNOW[3])
		c.rect(47, wt - 35, 18, 1, Palette.SNOW[3])
	_finish(c, winter, 8, 104)
	return c


static func _mine(winter: bool) -> RefCounted:
	var c := _new("mine", 91)
	var S := Palette.STONE
	var W := Palette.WOOD
	var T := Palette.STEEL
	var by := _by(c)
	var base := by - 12
	var hill := P.pts([[6, base], [9, base - 18], [18, base - 38], [32, base - 54], [50, base - 64], [68, base - 62], [84, base - 50], [96, base - 32], [103, base - 14], [106, base]])
	c.shade_polygon(hill, [S[0], S[1], S[1], S[2], S[3]])
	c.noise_fill(6, base - 66, 100, 68, [S[0], S[1], S[1], S[2], S[2], S[3]], 5.0, 91, true)
	for k in 26:
		var x := 12 + int(Canvas.hash01(k, 1, 91) * 86)
		var y := base - 60 + int(Canvas.hash01(k, 2, 91) * 56)
		if c.is_opaque(x, y) and c.is_opaque(x + 3, y):
			c.line(x, y, x + 2 + k % 3, y + (k % 2), S[0] if k % 3 else S[4])
	for k in 8:
		var x := 16 + int(Canvas.hash01(k, 5, 91) * 76)
		var y := base - 52 + int(Canvas.hash01(k, 6, 91) * 40)
		if c.is_opaque(x, y) and c.is_opaque(x + 2, y + 2) and (x < 44 or x > 70 or y < base - 40):
			c.rect(x, y, 3, 2, T[2])
			c.px(x, y, T[3])
	c.rect(40, base - 26, 4, 26, W[2])
	c.rect(40, base - 26, 1, 26, W[4])
	c.rect(68, base - 26, 4, 26, W[1])
	c.rect(40, base - 30, 32, 5, W[3])
	c.rect(40, base - 30, 32, 1, W[4])
	c.rect(40, base - 26, 32, 1, W[0])
	c.rect(44, base - 25, 24, 25, Palette.INK)
	for j in range(base - 8, base):
		for i in range(44, 68):
			if (i + j) % 4 == 0:
				c.px(i, j, S[0])
	c.line(48, base - 25, 48, base - 20, W[1])
	c.line(64, base - 25, 64, base - 20, W[1])
	c.rect(55, base - 25, 2, 4, W[2])
	c.px(55, base - 20, Palette.FIRE[2])
	c.px(55, base - 21, Palette.FIRE[3])
	c.px(54, base - 20, Palette.FIRE[0])
	for k in 5:
		var yy := base + k * 3
		c.rect(47 - k, yy, 3, 1, T[1])
		c.rect(61 + k, yy, 3, 1, T[1])
		c.rect(45 - k, yy + 1, 22 + k * 2, 1, W[1])
	c.line(50, base, 46, base + 12, T[2])
	c.line(61, base, 65, base + 12, T[2])
	_cart(c, 74, by)
	var pick_x := 14
	c.line(pick_x, by - 2, pick_x + 6, by - 20, W[3])
	c.line(pick_x + 1, by - 2, pick_x + 7, by - 20, W[2])
	c.polygon(P.pts([[pick_x + 1, by - 22], [pick_x + 10, by - 22], [pick_x + 12, by - 19], [pick_x + 8, by - 20], [pick_x + 4, by - 20], [pick_x + 1, by - 19]]), T[2])
	c.rect(pick_x + 1, by - 22, 10, 1, T[3])
	if winter:
		var cap := P.pts([[10, base - 18], [18, base - 38], [32, base - 54], [50, base - 64], [68, base - 62], [84, base - 50], [96, base - 32], [88, base - 30], [80, base - 40], [68, base - 48], [50, base - 50], [36, base - 38], [24, base - 28], [14, base - 14]])
		P.snow_roof(c, cap, 94, 6)
		c.rect(40, base - 31, 32, 1, Palette.SNOW[3])
	_finish(c, winter, 8, 104)
	return c


static func _cart(c: RefCounted, x: int, by: int) -> void:
	var W := Palette.WOOD
	var T := Palette.STEEL
	c.polygon(P.pts([[x, by - 15], [x + 24, by - 15], [x + 21, by - 4], [x + 3, by - 4]]), W[2])
	c.rect(x, by - 15, 24, 2, W[4])
	c.rect(x + 3, by - 6, 18, 2, W[0])
	c.rect(x, by - 15, 2, 10, W[3])
	c.rect(x + 22, by - 15, 2, 10, W[1])
	c.line(x + 2, by - 11, x + 22, by - 11, W[1])
	for k in 7:
		var ox := x + 3 + (k * 7) % 17
		var oy := by - 19 - (k * 3) % 4
		c.shade_ellipse(ox + 1.5, oy + 1.5, 2.6, 2.2, [T[0], T[1], T[2], T[3]])
	c.px(x + 8, by - 21, T[3])
	c.px(x + 15, by - 20, T[3])
	c.ellipse(x + 6, by - 2, 3.2, 3.2, T[1])
	c.ellipse(x + 6, by - 2, 1.4, 1.4, T[3])
	c.ellipse(x + 18, by - 2, 3.2, 3.2, T[1])
	c.ellipse(x + 18, by - 2, 1.4, 1.4, T[3])


static func _quarry(winter: bool) -> RefCounted:
	var c := _new("quarry", 101)
	var S := Palette.STONE
	var W := Palette.WOOD
	var by := _by(c)
	var x0 := 8
	var x1: int = c.width - 8
	var y0 := by - 92
	var levels: Array = [
		[0, 0, [S[2], S[3], S[3], S[4]]],
		[9, 12, [S[1], S[2], S[2], S[3]]],
		[18, 24, [S[0], S[1], S[1], S[2]]],
		[27, 36, [S[0], S[0], S[1], S[1]]],
	]
	for index in levels.size():
		var inset: int = levels[index][0]
		var wall: int = levels[index][1]
		var ramp: Array = levels[index][2]
		var lx := x0 + inset
		var rx := x1 - inset
		var ty := y0 + (wall if index > 0 else 0)
		var by2 := by - 8 - (inset if index > 0 else 0) / 2
		var shape := P.pts([[lx + 4, ty], [rx - 4, ty], [rx, ty + 4], [rx, by2 - 4], [rx - 4, by2], [lx + 4, by2], [lx, by2 - 4], [lx, ty + 4]])
		c.shade_polygon(shape, ramp)
		c.noise_fill(lx, ty, rx - lx, by2 - ty, ramp, 3.0, 100 + index, true)
		if index > 0:
			var face_top: int = ty - 9
			for j in range(face_top, ty):
				for i in range(lx + 2, rx - 1):
					var t := float(j - face_top) / 9.0
					c.px(i, j, (levels[index - 1][2] as Array)[P.qidx(0.65 - t * 0.55, 4, i, j)])
			c.rect(lx + 1, face_top, rx - lx - 1, 1, S[4] if index == 1 else S[3])
			for k in 6:
				var gx := lx + 6 + k * ((rx - lx - 12) / 5)
				c.line(gx, face_top + 1, gx + (k % 2) * 2 - 1, ty - 1, S[0])
	for k in 9:
		var rx2 := 38 + int(Canvas.hash01(k, 1, 7) * 32)
		var ry2 := by - 38 + int(Canvas.hash01(k, 2, 7) * 18)
		c.shade_ellipse(rx2, ry2, 3.2, 2.4, [S[0], S[1], S[2], S[3]])
	for k in 3:
		c.rect(40 + k * 14, by - 60, 10, 3, S[3])
	P.stone_block(c, 76, by - 2, 14, 10)
	P.stone_block(c, 91, by - 2, 14, 10)
	P.stone_block(c, 82, by - 12, 14, 10)
	c.rect(10, by - 10, 3, 10, W[2])
	c.line(12, by - 10, 28, by - 52, W[3])
	c.line(13, by - 10, 29, by - 52, W[2])
	c.line(28, by - 52, 56, by - 50, W[3])
	c.line(28, by - 51, 56, by - 49, W[1])
	c.line(54, by - 50, 54, by - 34, Palette.CREAM[1])
	c.rect(51, by - 34, 7, 7, S[3])
	c.rect(51, by - 34, 7, 2, S[4])
	c.rect(57, by - 32, 1, 5, S[1])
	c.rect(14, by - 4, 3, 4, W[1])
	if winter:
		for j in range(y0, by - 6):
			for i in range(x0, x1):
				if c.is_opaque(i, j) and (j - y0) < 3 + int(Canvas.hash01(i / 4, j / 8, 5) * 5.0) and Canvas.hash01(i, j, 6) > 0.35:
					c.px(i, j, Palette.SNOW[P.qidx(0.8 - float(j - y0) * 0.05, 4, i, j)])
		c.rect(51, by - 35, 7, 2, Palette.SNOW[3])
		for k in 3:
			c.rect(76 + k * 7, by - 13 + k * 2, 8, 2, Palette.SNOW[3])
	_finish(c, winter, 10, 104, 3)
	return c


static func _stockpile(winter: bool) -> RefCounted:
	var c := _new("stockpile", 111)
	var W := Palette.WOOD
	var D := Palette.DIRT
	var by := _by(c)
	var x0 := PAD_X + 1
	var x1: int = c.width - PAD_X - 1
	var y0 := by - 126
	var yard := Canvas.create(c.width, c.height, 112)
	yard.noise_fill(x0, y0, x1 - x0, 126, [D[1], D[1], D[2], D[2], D[3]], 5.0, 111)
	yard.speckle(x0, y0, x1 - x0, 126, D[0], 0.05, false)
	yard.speckle(x0, y0, x1 - x0, 126, D[3], 0.03, false)
	for k in 14:
		var px := x0 + 6 + int(Canvas.hash01(k, 1, 3) * (x1 - x0 - 12))
		var py := y0 + 8 + int(Canvas.hash01(k, 2, 3) * 108)
		yard.rect(px, py, 2, 1, Palette.STONE[2])
		yard.px(px, py, Palette.STONE[3])
	for j in range(y0, by):
		for i in range(x0, x1):
			var edge := minf(minf(i - x0, x1 - 1 - i), minf(j - y0, by - 1 - j))
			if edge < 3.0 and yard.is_opaque(i, j) and (i + j) % 2 == 0:
				yard.px(i, j, D[0])
	c.blit(yard, 0, 0)
	if winter:
		for j in range(y0, by - 1):
			for i in range(x0, x1):
				if Canvas.value_noise(i / 7.0, j / 7.0, 12) > 0.2:
					c.px(i, j, Palette.SNOW[P.qidx(0.62 + (Canvas.hash01(i, j, 13) - 0.5) * 0.3, 4, i, j)])
	var fence := Canvas.create(c.width, c.height, 113)
	var gate_l := 52
	var gate_r := 92
	for y in [y0 + 1, by - 3]:
		for x in range(x0, x1 + 1):
			if y > by - 10 and x > gate_l and x < gate_r:
				continue
			fence.px(x, y - 5, W[3] if x % 2 == 0 else W[2])
			fence.px(x, y - 4, W[1])
			fence.px(x, y - 9, W[3])
			fence.px(x, y - 8, W[1])
	for y in range(y0 + 1, by - 3):
		for x in [x0, x1]:
			if y % 8 < 2:
				continue
			fence.px(x, y, W[2] if x == x0 else W[1])
			fence.px(x + (1 if x == x0 else -1), y, W[3] if x == x0 else W[0])
	var post_xs: Array[int] = []
	for x in range(x0, x1 + 1, 16):
		post_xs.append(x)
	post_xs.append(x1)
	for y in [y0 + 1, by - 3]:
		for x in post_xs:
			if y > by - 10 and x > gate_l and x < gate_r:
				continue
			_post(fence, x, y)
	for y in range(y0 + 17, by - 3, 16):
		_post(fence, x0, y)
		_post(fence, x1, y)
	_post(fence, gate_l, by - 3, 4)
	_post(fence, gate_r, by - 3, 4)
	fence.outline_dark()
	c.blit(fence, 0, 0)
	for i in range(x0, x1):
		if Canvas.hash01(i, 5, 4) > 0.85:
			c.px(i, by - 1, Palette.SHADOW)
	return c


static func _post(c: RefCounted, x: int, y: int, extra: int = 0) -> void:
	var W := Palette.WOOD
	var h := 12 + extra
	c.rect(x - 1, y - h, 3, h, W[2])
	c.rect(x - 1, y - h, 1, h, W[3])
	c.rect(x + 1, y - h, 1, h, W[1])
	c.rect(x - 1, y - h - 1, 3, 1, W[4])
	c.px(x, y - h - 2, W[3])
