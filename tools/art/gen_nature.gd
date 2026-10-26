extends RefCounted

const Canvas := preload("res://tools/art/pixel_canvas.gd")
const Palette := preload("res://tools/art/palette.gd")
const Util := preload("res://tools/art/art_util.gd")

const OUT_DIR := "res://assets/art/terrain"
const TREE_W := 32
const TREE_H := 48
const BASE_X := 16
const BASE_Y := 44
const VARIANTS := 3
const STAGES := 3
const ROCK_W := 32
const ROCK_H := 32
const ROCK_VARIANTS := 3
const STAGE_SCALE := [0.0, 0.66, 1.0]


static func generate() -> void:
	_trees()
	_rocks()
	_particles()


static func _trees() -> void:
	var sheet := Canvas.create(VARIANTS * STAGES * TREE_W, 4 * TREE_H, 1)
	for season in 4:
		for variant in VARIANTS:
			for stage in STAGES:
				var tree := _tree(season, variant, stage)
				sheet.blit(tree, (variant * STAGES + stage) * TREE_W, season * TREE_H)
	sheet.save("%s/trees.png" % OUT_DIR)


static func _foliage_ramps(season: int, variant: int) -> Array:
	var L := Palette.LEAF_DEEP
	var G := Palette.GRASS
	var A := Palette.AUTUMN
	match season:
		Util.SPRING:
			if variant == 2:
				return [[L[1], L[2], L[3], G[3]]]
			return [[G[1], G[2], G[3], G[4]], [G[2], G[3], G[4], G[4]]]
		Util.SUMMER:
			if variant == 1:
				return [[L[1], L[2], L[3], G[3]]]
			return [[L[0], L[1], L[2], L[3]], [L[0], L[1], L[2], L[3]], [L[1], L[2], L[3], G[3]]]
		Util.AUTUMN:
			if variant == 2:
				return [[L[0], L[1], L[2], L[3]]]
			if variant == 1:
				return [[A[1], A[2], A[3], Palette.STRAW[3]], [A[2], A[3], Palette.STRAW[2], Palette.STRAW[3]]]
			return [[A[0], A[1], A[2], A[3]], [Palette.ROOF_RED[0], Palette.ROOF_RED[1], A[1], A[2]], [A[1], A[2], A[3], Palette.STRAW[3]]]
	return [[L[0], L[1], L[2], L[3]]]


static func _lobes(variant: int) -> Array:
	if variant == 0:
		return [
			Vector4(-1, -29, 8, 7), Vector4(-8, -21, 7, 6), Vector4(8, -21, 7, 6),
			Vector4(0, -21, 9, 8), Vector4(-6, -14, 6, 4.5), Vector4(6, -14, 6, 4.5),
		]
	return [
		Vector4(0, -33, 6, 7), Vector4(-4, -26, 7, 6.5), Vector4(4, -24, 7, 6.5),
		Vector4(0, -18, 8, 6), Vector4(-3, -13, 5, 4), Vector4(4, -12, 4.5, 3.5),
	]


static func _tree(season: int, variant: int, stage: int) -> RefCounted:
	var c := Canvas.create(TREE_W, TREE_H, 4000 + season * 101 + variant * 17 + stage * 3)
	var s: float = STAGE_SCALE[stage]
	if stage == 0:
		_sapling(c, season, variant)
	elif variant == 2:
		_conifer(c, season, stage, s)
	else:
		_broadleaf(c, season, variant, stage, s)
	c.outline_dark()
	var shadow_w := 4.0 + 7.0 * (s if stage > 0 else 0.3)
	for j in range(BASE_Y - 2, BASE_Y + 4):
		for i in range(BASE_X - 13, BASE_X + 14):
			var dx := (i + 0.5 - BASE_X - 2.0) / shadow_w
			var dy := (j + 0.5 - BASE_Y - 0.5) / 2.6
			if dx * dx + dy * dy <= 1.0 and not c.is_opaque(i, j):
				c.px(i, j, Palette.SHADOW)
	return c


static func _trunk(c: RefCounted, top: int, width: int, birch: bool) -> void:
	var W := Palette.WOOD
	var ramp: Array = [Palette.CREAM[1], Palette.CREAM[2], Palette.CREAM[3], Palette.CREAM[3]] if birch else [W[1], W[2], W[3], W[3]]
	var x0 := BASE_X - width / 2
	for j in range(top, BASE_Y):
		for i in width:
			var idx := 2 if i == 0 else (0 if i == width - 1 else 1)
			if width >= 4 and i == 1:
				idx = 2 if not birch else 3
			c.px(x0 + i, j, ramp[idx])
	if birch:
		for k in range(top + 2, BASE_Y - 1, 3):
			c.px(x0 + c.rng.randi() % width, k, Palette.INK)
			if c.rng.randf() < 0.5:
				c.px(x0 + 1 + c.rng.randi() % maxi(width - 1, 1), k + 1, Palette.STONE[1])
	else:
		for k in range(top + 3, BASE_Y - 2, 4):
			c.px(x0 + 1 + c.rng.randi() % maxi(width - 1, 1), k, W[0])
	c.px(x0 - 1, BASE_Y - 1, ramp[1])
	c.px(x0 + width, BASE_Y - 1, ramp[0])
	c.px(x0 - 1, BASE_Y - 2, ramp[2])
	c.px(x0 + width, BASE_Y - 2, ramp[0])


static func _clumps(c: RefCounted, light: Color, dark: Color, count: int) -> void:
	var tries := 0
	var placed := 0
	while placed < count and tries < count * 12:
		tries += 1
		var x: int = 4 + c.rng.randi() % (TREE_W - 8)
		var y: int = 4 + c.rng.randi() % (BASE_Y - 10)
		if not (c.is_opaque(x, y) and c.is_opaque(x + 2, y + 2) and c.is_opaque(x - 1, y + 1)):
			continue
		var upper_left := (x + y) < 50
		var top: Color = light if upper_left else dark
		c.px(x, y, top)
		c.px(x + 1, y, top)
		c.px(x - 1, y + 1, top)
		if not upper_left:
			c.px(x, y + 1, light)
		placed += 1


static func _broadleaf(c: RefCounted, season: int, variant: int, stage: int, s: float) -> void:
	var birch := variant == 1
	var trunk_w := 4 if (variant == 0 and stage == 2) else 3
	var trunk_top := int(BASE_Y - (13 if variant == 0 else 20) * s - 2)
	if season == Util.WINTER:
		_bare(c, variant, s, trunk_w, birch)
		return
	_trunk(c, trunk_top, trunk_w, birch)
	var canopy := Canvas.create(TREE_W, TREE_H, 99 + variant + stage)
	var ramps := _foliage_ramps(season, variant)
	var lobes := _lobes(variant)
	for index in lobes.size():
		var l: Vector4 = lobes[index]
		var rx := maxf(l.z * s, 2.0)
		var ry := maxf(l.w * s, 2.0)
		var cx := BASE_X + l.x * s
		var cy := BASE_Y + l.y * s
		canopy.shade_ellipse(cx, cy, rx, ry, ramps[index % ramps.size()])
	var ramp: Array = ramps[0]
	_clumps(canopy, ramp[3], ramp[0], int(18 * s * s) + 4)
	if season == Util.SPRING and variant == 1 and stage > 0:
		for k in 10:
			var x: int = 8 + canopy.rng.randi() % 16
			var y: int = 6 + canopy.rng.randi() % 20
			if canopy.is_opaque(x, y):
				canopy.px(x, y, Palette.BERRY[3] if k % 2 == 0 else Palette.CREAM[3])
	elif season == Util.SPRING and variant == 0 and stage > 1:
		for k in 5:
			var x: int = 8 + canopy.rng.randi() % 16
			var y: int = 8 + canopy.rng.randi() % 20
			if canopy.is_opaque(x, y):
				canopy.px(x, y, Palette.CREAM[3])
	c.blit(canopy, 0, 0)


static func _limb(c: RefCounted, x0: int, y0: int, x1: int, y1: int, color: Color, shade: Color, thick: bool) -> void:
	c.line(x0, y0, x1, y1, color)
	if thick:
		c.line(x0 + 1, y0, x1 + 1, y1, shade)
		c.line(x0 - 1, y0, x1 - 1, y1, color)


static func _bare(c: RefCounted, variant: int, s: float, trunk_w: int, birch: bool) -> void:
	var W := Palette.WOOD
	var top := int(BASE_Y - (17 if variant == 0 else 22) * s)
	_trunk(c, top, trunk_w, birch)
	var branch: Color = Palette.STONE[3] if birch else W[2]
	var shade: Color = Palette.STONE[1] if birch else W[1]
	var limbs: Array = [
		[0, 0, -8, -9, 1], [0, 0, 7, -10, 1], [0, 0, 0, -14, 1],
		[-8, -9, -12, -13, 0], [-8, -9, -9, -18, 0], [7, -10, 11, -14, 0], [7, -10, 5, -19, 0],
		[0, -14, -3, -20, 0], [0, -14, 3, -21, 0], [-4, -5, -11, -6, 0], [4, -5, 10, -4, 0],
		[-9, -18, -12, -21, 0], [5, -19, 8, -22, 0],
	]
	var count := limbs.size() if s > 0.9 else 7
	var lift := 1.0 if variant == 0 else 1.15
	for index in count:
		var f: Array = limbs[index]
		var x0 := BASE_X + int(f[0] * s)
		var y0 := top + int(f[1] * s * lift)
		var x1 := BASE_X + int(f[2] * s)
		var y1 := top + int(f[3] * s * lift)
		_limb(c, x0, y0, x1, y1, branch, shade, f[4] == 1 and s > 0.9)
		c.px(x1, y1 - 1, Palette.SNOW[3])
		if absi(y1 - y0) < 8:
			c.px((x0 + x1) / 2, (y0 + y1) / 2 - 1, Palette.SNOW[3])
	for k in 3:
		c.px(BASE_X - 7 + c.rng.randi() % 14, top - 14 + c.rng.randi() % 10, Palette.AUTUMN[0])


static func _conifer(c: RefCounted, season: int, stage: int, s: float) -> void:
	var L := Palette.LEAF_DEEP
	var ramp: Array = [L[0], L[1], L[2], L[3]]
	if season == Util.SPRING:
		ramp = [L[1], L[2], L[3], Palette.GRASS[3]]
	elif season == Util.AUTUMN:
		ramp = [L[0], L[1], L[2], L[3]]
	var tiers := 3 if stage == 1 else 4
	var top_y := BASE_Y - 40.0 * s
	var bottom := BASE_Y - 8.0 * s
	_trunk(c, int(bottom) - 1, 3, false)
	var span := bottom - top_y
	var widths := [6.0, 9.5, 12.0, 14.0]
	var tops := [0.0, 0.17, 0.4, 0.6]
	var tier_h := span * (0.4 if tiers == 4 else 0.46)
	var snow_tiers: Array[PackedVector2Array] = []
	for t in tiers:
		var y0: float = top_y + span * (tops[t] if tiers == 4 else [0.0, 0.26, 0.52][t])
		var y1 := minf(y0 + tier_h + 2.0 * s, bottom)
		var half: float = (widths[t] if tiers == 4 else [7.0, 11.0, 14.0][t]) * s
		var points := PackedVector2Array([Vector2(BASE_X, y0), Vector2(BASE_X + half, y1), Vector2(BASE_X + half * 0.45, y1 - 1.5 * s), Vector2(BASE_X, y1 + 0.5), Vector2(BASE_X - half * 0.45, y1 - 1.5 * s), Vector2(BASE_X - half, y1)])
		c.shade_polygon(points, ramp)
		for k in int(half):
			var px := BASE_X - int(half) + 1 + k * 2
			c.px(px, int(y1) - 1, ramp[0])
			c.px(px + 1, int(y1) - 2, ramp[1])
		snow_tiers.append(PackedVector2Array([Vector2(BASE_X, y0 - 0.5), Vector2(BASE_X + half * 0.8, y0 + (y1 - y0) * 0.62), Vector2(BASE_X, y0 + (y1 - y0) * 0.5), Vector2(BASE_X - half * 0.8, y0 + (y1 - y0) * 0.62)]))
	_clumps(c, ramp[3], ramp[0], int(10 * s * s) + 2)
	if season == Util.WINTER:
		for tier in snow_tiers:
			c.shade_polygon(tier, [Palette.SNOW[0], Palette.SNOW[1], Palette.SNOW[2], Palette.SNOW[3]])
	if season == Util.SPRING and stage == 2:
		for k in 4:
			var x: int = 10 + c.rng.randi() % 12
			var y: int = 10 + c.rng.randi() % 20
			if c.is_opaque(x, y):
				c.px(x, y, Palette.GRASS[4])


static func _sapling(c: RefCounted, season: int, variant: int) -> void:
	var W := Palette.WOOD
	var L := Palette.LEAF_DEEP
	var G := Palette.GRASS
	var leaf: Array = [G[1], G[2], G[3], G[4]]
	match season:
		Util.SUMMER: leaf = [L[1], L[2], L[3], G[3]]
		Util.AUTUMN: leaf = [Palette.AUTUMN[1], Palette.AUTUMN[2], Palette.AUTUMN[3], Palette.STRAW[3]] if variant != 2 else [L[1], L[2], L[3], G[3]]
	if season == Util.WINTER:
		c.line(BASE_X, BASE_Y - 1, BASE_X, BASE_Y - 12, W[2])
		c.line(BASE_X, BASE_Y - 8, BASE_X - 4, BASE_Y - 13, W[2])
		c.line(BASE_X, BASE_Y - 6, BASE_X + 4, BASE_Y - 11, W[1])
		c.px(BASE_X, BASE_Y - 13, Palette.SNOW[3])
		c.px(BASE_X - 4, BASE_Y - 14, Palette.SNOW[3])
		c.px(BASE_X + 4, BASE_Y - 12, Palette.SNOW[3])
		c.px(BASE_X - 1, BASE_Y - 1, Palette.SNOW[2])
		c.px(BASE_X + 1, BASE_Y - 1, Palette.SNOW[2])
		return
	if variant == 2:
		c.shade_polygon(PackedVector2Array([Vector2(BASE_X, BASE_Y - 14), Vector2(BASE_X + 4, BASE_Y - 4), Vector2(BASE_X - 4, BASE_Y - 4)]), leaf)
		c.shade_polygon(PackedVector2Array([Vector2(BASE_X, BASE_Y - 9), Vector2(BASE_X + 5, BASE_Y - 1), Vector2(BASE_X - 5, BASE_Y - 1)]), leaf)
		c.px(BASE_X, BASE_Y, W[1])
		return
	c.line(BASE_X, BASE_Y - 1, BASE_X, BASE_Y - 8, W[3])
	c.px(BASE_X + 1, BASE_Y - 1, W[1])
	c.shade_ellipse(BASE_X - 3, BASE_Y - 8, 3.2, 2.4, leaf)
	c.shade_ellipse(BASE_X + 3, BASE_Y - 9, 3.2, 2.4, leaf)
	c.shade_ellipse(BASE_X, BASE_Y - 12, 3.4, 3.0, leaf)
	c.px(BASE_X - 2, BASE_Y - 13, leaf[3])
	c.px(BASE_X + 2, BASE_Y - 10, leaf[3])


static func _rocks() -> void:
	var sheet := Canvas.create(ROCK_VARIANTS * ROCK_W, 4 * ROCK_H, 1)
	for season in 4:
		for variant in ROCK_VARIANTS:
			sheet.blit(_rock_cluster(season, variant), variant * ROCK_W, season * ROCK_H)
	sheet.save("%s/rocks.png" % OUT_DIR)


static func _boulder(c: RefCounted, cx: float, cy: float, rx: float, ry: float, season: int) -> void:
	var S := Palette.STONE
	var points := PackedVector2Array()
	var count := 9
	for k in count:
		var a := TAU * k / count
		var jitter: float = 0.82 + c.rng.randf() * 0.3
		var flat := 1.0 if sin(a) < 0.5 else 0.8
		points.append(Vector2(cx + cos(a) * rx * jitter, cy + sin(a) * ry * jitter * flat))
	c.shade_polygon(points, [S[0], S[1], S[2], S[3], S[4]])
	for k in 3:
		var px: int = int(cx - rx * 0.4 + c.rng.randf() * rx * 0.9)
		var py: int = int(cy - ry * 0.2 + c.rng.randf() * ry * 0.7)
		if c.is_opaque(px, py):
			c.px(px, py, S[1])
			c.px(px + 1, py + 1, S[1])
	c.line(int(cx - rx * 0.2), int(cy - ry * 0.5), int(cx - rx * 0.4), int(cy + ry * 0.1), S[4])
	c.px(int(cx - rx * 0.5), int(cy - ry * 0.4), S[4])
	c.line(int(cx + rx * 0.2), int(cy - ry * 0.1), int(cx + rx * 0.3), int(cy + ry * 0.4), S[0])
	if season == Util.WINTER:
		var cap := PackedVector2Array()
		for k in count:
			var a := TAU * k / count
			var wob := 0.75 + 0.2 * sin(a * 3.0 + cx)
			if sin(a) < 0.1:
				cap.append(Vector2(cx + cos(a) * rx * 0.85, cy + sin(a) * ry * 0.75))
			else:
				cap.append(Vector2(cx + cos(a) * rx * 0.5, cy - ry * 0.05 * wob))
		c.shade_polygon(cap, [Palette.SNOW[0], Palette.SNOW[1], Palette.SNOW[2], Palette.SNOW[3]])
	elif season != Util.AUTUMN:
		for k in 4:
			var px: int = int(cx - rx * 0.6 + c.rng.randf() * rx * 1.2)
			var py: int = int(cy + ry * 0.35 + c.rng.randf() * ry * 0.4)
			if c.is_opaque(px, py):
				c.px(px, py, Palette.GRASS[1] if season == Util.SUMMER else Palette.GRASS[2])
				c.px(px + 1, py, Palette.GRASS[2] if season == Util.SUMMER else Palette.GRASS[3])


static func _rock_cluster(season: int, variant: int) -> RefCounted:
	var c := Canvas.create(ROCK_W, ROCK_H, 6000 + season * 13 + variant)
	var layouts: Array = [
		[Vector4(12, 20, 9, 7), Vector4(22, 22, 6, 5), Vector4(17, 14, 6, 5)],
		[Vector4(16, 20, 11, 8), Vector4(7, 24, 5, 4), Vector4(25, 24, 5, 4)],
		[Vector4(10, 22, 7, 5), Vector4(21, 19, 8, 7), Vector4(26, 25, 4, 3.5), Vector4(15, 14, 5, 4.5)],
	]
	var shadow := Canvas.create(ROCK_W, ROCK_H, 1)
	shadow.ellipse(17.0, 26.0, 13.0, 4.0, Palette.SHADOW)
	c.blit(shadow, 0, 0)
	var ordered: Array = layouts[variant].duplicate()
	ordered.sort_custom(func(a: Vector4, b: Vector4) -> bool: return a.y < b.y)
	for l in ordered:
		_boulder(c, l.x, l.y, l.z, l.w, season)
	c.outline_dark()
	return c


static func _particles() -> void:
	var leaf := Canvas.create(5, 4, 1)
	leaf.rect(1, 1, 3, 2, Palette.AUTUMN[2])
	leaf.px(0, 2, Palette.AUTUMN[1])
	leaf.px(4, 1, Palette.AUTUMN[3])
	leaf.px(2, 1, Palette.AUTUMN[3])
	leaf.px(1, 2, Palette.AUTUMN[1])
	leaf.px(3, 2, Palette.AUTUMN[0])
	leaf.save("%s/leaf.png" % OUT_DIR)
	var snow := Canvas.create(3, 3, 1)
	snow.px(1, 0, Palette.SNOW[2])
	snow.px(0, 1, Palette.SNOW[2])
	snow.px(1, 1, Palette.SNOW[3])
	snow.px(2, 1, Palette.SNOW[2])
	snow.px(1, 2, Palette.SNOW[2])
	snow.save("%s/snow.png" % OUT_DIR)
	var petal := Canvas.create(3, 3, 1)
	petal.px(1, 0, Palette.CREAM[3])
	petal.px(0, 1, Palette.BERRY[3])
	petal.px(1, 1, Palette.CREAM[3])
	petal.px(2, 1, Palette.BERRY[3])
	petal.save("%s/petal.png" % OUT_DIR)
