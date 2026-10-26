extends RefCounted

const Canvas := preload("res://tools/art/pixel_canvas.gd")
const Palette := preload("res://tools/art/palette.gd")
const Util := preload("res://tools/art/art_util.gd")
const ShoreMask := preload("res://scripts/world/shore_mask.gd")

const OUT_DIR := "res://assets/art/terrain"
const T := 32
const SEASONS := 4
const GRASS_VARIANTS := 6
const FOREST_VARIANTS := 2
const ROCK_VARIANTS := 2
const WATER_VARIANTS := 2
const ROAD_MASKS := 16
const BLEED_VARIANTS := 4


static func generate() -> void:
	_ground_atlas()
	_shore_atlas()
	_bleed_atlas()
	_road_atlas()


static func _ground_atlas() -> void:
	var columns := GRASS_VARIANTS + FOREST_VARIANTS + ROCK_VARIANTS + WATER_VARIANTS
	var sheet := Canvas.create(columns * T, SEASONS * T, 1)
	for season in SEASONS:
		var column := 0
		for variant in GRASS_VARIANTS:
			sheet.blit(_grass(season, variant), column * T, season * T)
			column += 1
		for variant in FOREST_VARIANTS:
			sheet.blit(_forest_floor(season, variant), column * T, season * T)
			column += 1
		for variant in ROCK_VARIANTS:
			sheet.blit(_rock_ground(season, variant), column * T, season * T)
			column += 1
		for variant in WATER_VARIANTS:
			sheet.blit(_water(season, variant), column * T, season * T)
			column += 1
	sheet.save("%s/ground.png" % OUT_DIR)


static func _grain(c: RefCounted, ramp: Array, cuts: Array, seed_value: int, offset: Vector2i) -> void:
	for j in T:
		for i in T:
			var x := i + 0.5 + offset.x
			var y := j + 0.5 + offset.y
			var n := Util.pnoise(x, y, 16, T, seed_value) * 0.55 + Util.pnoise(x, y, 8, T, seed_value + 3) * 0.45
			var idx := 0
			while idx < cuts.size() and n >= cuts[idx]:
				idx += 1
			c.px(i, j, ramp[idx])


static func _grain_two(c: RefCounted, first: Array, second: Array, cuts: Array, seed_value: int, offset: Vector2i, split: float) -> void:
	for j in T:
		for i in T:
			var x := i + 0.5 + offset.x
			var y := j + 0.5 + offset.y
			var n := Util.pnoise(x, y, 16, T, seed_value) * 0.55 + Util.pnoise(x, y, 8, T, seed_value + 3) * 0.45
			var family := second if Util.pnoise(x, y, 6, T, seed_value + 9) > split else first
			var idx := 0
			while idx < cuts.size() and n >= cuts[idx]:
				idx += 1
			c.px(i, j, family[mini(idx, family.size() - 1)])


static func _clumps(c: RefCounted, count: int, dark: Color, mid: Color, light: Color) -> void:
	for k in count:
		var x: int = 3 + c.rng.randi() % (T - 7)
		var y: int = 4 + c.rng.randi() % (T - 8)
		c.px(x, y + 1, dark)
		c.px(x + 1, y + 1, dark)
		c.px(x + 2, y + 1, dark)
		c.px(x, y, mid)
		c.px(x + 1, y, light)
		c.px(x + 2, y, mid)
		c.px(x + 1, y - 1, light)


static func _blades(c: RefCounted, count: int, light: Color, dark: Color, tip: Color) -> void:
	for k in count:
		var x: int = 2 + c.rng.randi() % (T - 5)
		var y: int = 5 + c.rng.randi() % (T - 8)
		var lean: int = c.rng.randi() % 3 - 1
		c.px(x, y, dark)
		c.px(x, y - 1, light)
		c.px(x + lean, y - 2, tip)
		if c.rng.randf() < 0.55:
			c.px(x + 2, y, dark)
			c.px(x + 2, y - 1, light)
			c.px(x + 2 - lean, y - 2, light)
			c.px(x + 1, y + 1, dark)


static func _flower(c: RefCounted, x: int, y: int, petal: Color, heart: Color, big: bool) -> void:
	c.px(x, y + 1, Palette.GRASS[1])
	c.px(x, y + 2, Palette.GRASS[1])
	c.px(x, y, petal)
	if big:
		c.px(x - 1, y, petal)
		c.px(x + 1, y, petal)
		c.px(x, y - 1, petal)
		c.px(x, y, heart)


static func _flowers(c: RefCounted, count: int, colors: Array, heart: Color) -> void:
	for k in count:
		var x: int = 3 + c.rng.randi() % (T - 7)
		var y: int = 4 + c.rng.randi() % (T - 9)
		_flower(c, x, y, colors[c.rng.randi() % colors.size()], heart, k % 2 == 0)


static func _specks(c: RefCounted, count: int, colors: Array, wide: bool) -> void:
	for k in count:
		var x: int = 2 + c.rng.randi() % (T - 5)
		var y: int = 2 + c.rng.randi() % (T - 5)
		var color: Color = colors[c.rng.randi() % colors.size()]
		c.px(x, y, color)
		if wide:
			c.px(x + 1, y, color)


static func _pebble(c: RefCounted, x: int, y: int, ramp: Array) -> void:
	c.px(x, y, ramp[2])
	c.px(x + 1, y, ramp[3])
	c.px(x, y + 1, ramp[1])
	c.px(x + 1, y + 1, ramp[1])
	c.px(x + 2, y + 1, ramp[0])


static func _grass(season: int, variant: int) -> RefCounted:
	var c := Canvas.create(T, T, 100 + season * 17 + variant * 131)
	var G := Palette.GRASS
	var offset := Vector2i(variant * 7, variant * 11)
	var light: Color
	var dark: Color
	var tip: Color
	match season:
		Util.SPRING:
			_grain(c, [G[2], G[3], G[3], G[4]], [0.36, 0.62, 0.78], 11, offset)
			_clumps(c, 5, G[2], G[3], G[4])
			light = G[4]
			dark = G[2]
			tip = G[4]
		Util.SUMMER:
			_grain(c, [G[1], G[2], G[2], G[3]], [0.36, 0.62, 0.8], 12, offset)
			_clumps(c, 5, G[1], G[2], G[3])
			light = G[3]
			dark = G[1]
			tip = G[4]
		Util.AUTUMN:
			_grain_two(c, [G[2], G[2], G[3], G[3]], [Palette.STRAW[0], Palette.STRAW[1], Palette.STRAW[1], Palette.STRAW[2]], [0.36, 0.62, 0.8], 13, offset, 0.4)
			_clumps(c, 5, Palette.STRAW[0], Palette.STRAW[1], Palette.STRAW[2])
			light = Palette.STRAW[2]
			dark = Palette.STRAW[0]
			tip = Palette.STRAW[3]
		_:
			_grain(c, [Palette.SNOW[1], Palette.SNOW[2], Palette.SNOW[2], Palette.SNOW[3]], [0.4, 0.62, 0.84], 14, offset)
			_drifts(c, 3)
			light = Palette.SNOW[3]
			dark = Palette.SNOW[0]
			tip = Palette.SNOW[3]
	var blade_counts := [3, 5, 10, 4, 4, 4]
	if season == Util.WINTER:
		_blades(c, int(blade_counts[variant] * 0.5), G[1], G[0], Palette.SNOW[3])
		match variant:
			3:
				c.line(6, 22, 11, 20, Palette.WOOD[1])
				c.px(11, 19, Palette.WOOD[1])
				c.line(7, 21, 10, 19, Palette.SNOW[3])
				c.px(8, 24, Palette.WOOD[1])
			4:
				for step in 3:
					c.rect(7 + step * 6, 10 + step * 5, 2, 3, Palette.SNOW[0])
					c.rect(10 + step * 6, 13 + step * 5, 2, 3, Palette.SNOW[0])
					c.px(7 + step * 6, 10 + step * 5, Palette.SNOW[1])
			5:
				_pebble(c, 20, 20, Palette.STONE)
				_pebble(c, 9, 9, Palette.STONE)
				c.line(20, 20, 23, 20, Palette.SNOW[3])
				c.line(9, 9, 12, 9, Palette.SNOW[3])
		return c
	_blades(c, blade_counts[variant], light, dark, tip)
	var petals := [Palette.CREAM[3], Palette.STRAW[3], Palette.BERRY[3]]
	match season:
		Util.SPRING:
			match variant:
				3: _flowers(c, 8, [Palette.CREAM[3], Palette.STRAW[3]], Palette.STRAW[2])
				4: _flowers(c, 8, [Palette.BERRY[3], Palette.CREAM[3]], Palette.STRAW[3])
				5: _flowers(c, 5, petals, Palette.STRAW[2])
		Util.SUMMER:
			match variant:
				3: _flowers(c, 4, [Palette.STRAW[3], Palette.STRAW[2]], Palette.FIRE[1])
				4: _flowers(c, 4, [Palette.BERRY[2], Palette.BERRY[3]], Palette.STRAW[3])
				5:
					_pebble(c, 20, 20, Palette.STONE)
					_pebble(c, 8, 9, Palette.STONE)
		Util.AUTUMN:
			match variant:
				3: _specks(c, 9, [Palette.AUTUMN[1], Palette.AUTUMN[2], Palette.AUTUMN[3]], true)
				4: _specks(c, 6, [Palette.AUTUMN[0], Palette.AUTUMN[2]], true)
				5:
					_pebble(c, 20, 19, Palette.STONE)
					_specks(c, 4, [Palette.AUTUMN[2]], true)
	return c


static func _drifts(c: RefCounted, count: int) -> void:
	for k in count:
		var x: int = 4 + c.rng.randi() % (T - 12)
		var y: int = 5 + c.rng.randi() % (T - 10)
		var length: int = 4 + c.rng.randi() % 4
		c.rect(x, y, length, 1, Palette.SNOW[3])
		c.rect(x + 1, y + 1, length, 1, Palette.SNOW[1])
		c.px(x + length + 1, y + 1, Palette.SNOW[0])
		c.px(x, y + 1, Palette.SNOW[2])


static func _forest_floor(season: int, variant: int) -> RefCounted:
	var c := Canvas.create(T, T, 300 + season * 17 + variant * 131)
	var G := Palette.GRASS
	var offset := Vector2i(variant * 9 + 3, variant * 5)
	match season:
		Util.SPRING: _grain(c, [G[1], G[2], G[2], G[3]], [0.38, 0.64, 0.82], 61, offset)
		Util.SUMMER: _grain(c, [G[0], G[1], G[1], G[2]], [0.38, 0.62, 0.84], 62, offset)
		Util.AUTUMN: _grain(c, [G[1], Palette.WOOD[1], G[1], Palette.WOOD[2]], [0.38, 0.62, 0.84], 63, offset)
		_: _grain(c, [Palette.SNOW[1], Palette.SNOW[1], Palette.SNOW[2], Palette.SNOW[2]], [0.4, 0.62, 0.84], 64, offset)
	match season:
		Util.SPRING:
			_blades(c, 6, G[3], G[1], G[3])
			_specks(c, 4, [Palette.WOOD[1]], true)
		Util.SUMMER:
			_blades(c, 5, G[2], G[0], G[3])
			_specks(c, 5, [Palette.WOOD[1], Palette.WOOD[0]], true)
		Util.AUTUMN:
			_specks(c, 12, [Palette.AUTUMN[0], Palette.AUTUMN[1], Palette.AUTUMN[2]], true)
		_:
			_specks(c, 5, [Palette.WOOD[1], Palette.SNOW[3]], true)
			_blades(c, 2, G[1], G[0], Palette.SNOW[3])
			_drifts(c, 2)
	if variant == 1 and season != Util.WINTER:
		c.line(9, 20, 14, 18, Palette.WOOD[1])
		c.px(14, 17, Palette.WOOD[2])
		c.px(10, 21, Palette.WOOD[0])
	return c


static func _rock_ground(season: int, variant: int) -> RefCounted:
	var c := Canvas.create(T, T, 500 + season * 17 + variant * 131)
	var S := Palette.STONE
	var offset := Vector2i(variant * 13, variant * 3)
	if season == Util.WINTER:
		_grain(c, [Palette.SNOW[0], Palette.SNOW[1], Palette.SNOW[1], Palette.SNOW[2]], [0.34, 0.55, 0.78], 91, offset)
	else:
		_grain(c, [S[1], S[1], S[2], S[2]], [0.3, 0.6, 0.86], 92, offset)
	_clumps(c, 5, S[0], S[2], S[3])
	for k in 5:
		var x: int = 2 + c.rng.randi() % (T - 6)
		var y: int = 2 + c.rng.randi() % (T - 6)
		_pebble(c, x, y, S)
	for k in 2:
		var x: int = 4 + c.rng.randi() % (T - 12)
		var y: int = 5 + c.rng.randi() % (T - 12)
		c.line(x, y, x + 4, y + 2, S[0])
		c.line(x + 4, y + 2, x + 6, y + 1, S[0])
	if season == Util.SPRING or season == Util.SUMMER:
		_specks(c, 4, [Palette.GRASS[2], Palette.GRASS[1]], true)
	return c


static func _water(season: int, variant: int) -> RefCounted:
	var c := Canvas.create(T, T, 700 + season * 17 + variant * 131)
	var W := Palette.WATER
	if season == Util.WINTER:
		return _ice(c, variant)
	var ramp: Array
	match season:
		Util.SPRING: ramp = [W[1], W[2], W[2], W[3]]
		_: ramp = [W[1], W[1], W[2], W[2]]
	_grain(c, ramp, [0.4, 0.62, 0.85], 131 + variant * 17, Vector2i(variant * 5, variant * 9))
	for k in 5:
		var y: int = 3 + (k * 6 + variant * 3 + c.rng.randi() % 3) % (T - 6)
		var x: int = 2 + c.rng.randi() % (T - 12)
		var length: int = 3 + c.rng.randi() % 4
		c.rect(x, y, length, 1, W[3])
		c.px(x, y, W[4])
		c.rect(x + 1, y + 1, maxi(length - 2, 1), 1, W[0])
	for k in 3:
		c.px(3 + c.rng.randi() % (T - 6), 3 + c.rng.randi() % (T - 6), W[4])
	return c


static func _ice(c: RefCounted, variant: int) -> RefCounted:
	var W := Palette.WATER
	var S := Palette.SNOW
	var ramp: Array = [W[3], W[3], S[1], S[2]]
	_grain(c, ramp, [0.4, 0.62, 0.85], 171 + variant * 19, Vector2i(variant * 5, variant * 9))
	for k in 2:
		var x: int = 4 + c.rng.randi() % (T - 12)
		var y: int = 4 + c.rng.randi() % (T - 8)
		for step in 9:
			c.px(x, y, W[1])
			c.px(x, y + 1, S[3])
			x += 1 + c.rng.randi() % 2
			y += c.rng.randi() % 3 - 1
			if x > T - 3 or y < 2 or y > T - 4:
				break
	for k in 3:
		var x: int = 3 + c.rng.randi() % (T - 10)
		var y: int = 4 + c.rng.randi() % (T - 10)
		c.line(x, y + 3, x + 3, y, S[3])
		c.px(x + 4, y - 1, S[3])
	_specks(c, 6, [S[3], W[4]], false)
	return c


static func _bleed_atlas() -> void:
	var keys := ShoreMask.keys()
	var sheet := Canvas.create(keys.size() * T, SEASONS * 2 * BLEED_VARIANTS * T, 1)
	for season in SEASONS:
		for kind in 2:
			for variant in BLEED_VARIANTS:
				var source: RefCounted = _forest_floor(season, variant % FOREST_VARIANTS) if kind == 0 else _rock_ground(season, variant % ROCK_VARIANTS)
				var row := (season * 2 + kind) * BLEED_VARIANTS + variant
				for index in keys.size():
					sheet.blit(_bleed_tile(source, keys[index], season * 16 + kind * 4 + variant), index * T, row * T)
	sheet.save("%s/bleed.png" % OUT_DIR)


static func _smin(a: float, b: float, k: float) -> float:
	var h := maxf(k - absf(a - b), 0.0) / k
	return minf(a, b) - h * h * k * 0.25


static func _stretch(n: float) -> float:
	return clampf((n - 0.5) * 2.4 + 0.5, 0.0, 1.0)


static func _bleed_field(x: float, y: float, k: int, seed_value: int, taper_x: float, taper_y: float) -> float:
	var sides := ShoreMask.sides_of(k)
	var corners := ShoreMask.corners_of(k)
	var f := 1000.0
	var common := _stretch(Util.pnoise(x, y, 2, T, 1500) * 0.5 + Util.pnoise(x, y, 4, T, 1505) * 0.35 + Util.pnoise(x, y, 8, T, 1509) * 0.15)
	var own := _stretch(Util.pnoise(x, y, 2, T, seed_value) * 0.5 + Util.pnoise(x, y, 4, T, seed_value + 5) * 0.35 + Util.pnoise(x, y, 8, T, seed_value + 9) * 0.15)
	var along := [taper_x, taper_y, taper_x, taper_y]
	var corner_taper := minf(taper_x, taper_y)
	var dists := [y, T - x, T - y, x]
	for bit in 4:
		if sides & (1 << bit):
			var wide := (lerpf(common, own, along[bit]) - 0.5) * 2.0
			var edge: float = 6.4 + wide * 6.4
			f = _smin(f, dists[bit] - edge, 4.0)
	var centers := [Vector2(T, 0), Vector2(T, T), Vector2(0, T), Vector2(0, 0)]
	for bit in 4:
		if corners & (1 << bit):
			f = _smin(f, Vector2(x, y).distance_to(centers[bit]) - (5.0 + (lerpf(common, own, corner_taper) - 0.5) * 2.0 * 4.0), 4.0)
	return f


static func _bleed_tile(source: RefCounted, k: int, seed_value: int) -> RefCounted:
	var c := Canvas.create(T, T, 1)
	for j in T:
		for i in T:
			var x := i + 0.5
			var y := j + 0.5
			var taper_x := smoothstep(0.0, 6.0, minf(x, T - x))
			var taper_y := smoothstep(0.0, 6.0, minf(y, T - y))
			var f := _bleed_field(x, y, k, 1500 + seed_value, taper_x, taper_y)
			var bayer: int = Canvas.BAYER[(j % 4) * 4 + (i % 4)]
			if f < 0.0 or (f < 1.4 and bayer < 6):
				c.px(i, j, source.get_px(i, j))
	return c


static func _shore_atlas() -> void:
	var keys := ShoreMask.keys()
	var sheet := Canvas.create(keys.size() * T, SEASONS * 2 * T, 1)
	for season in SEASONS:
		for index in keys.size():
			sheet.blit(_shore_tile(season, keys[index], false), index * T, season * 2 * T)
			sheet.blit(_shore_tile(season, keys[index], true), index * T, (season * 2 + 1) * T)
	sheet.save("%s/shore.png" % OUT_DIR)


static func _shore_distance(x: float, y: float, k: int) -> float:
	var sides := ShoreMask.sides_of(k)
	var corners := ShoreMask.corners_of(k)
	var d := 1000.0
	if sides & ShoreMask.N:
		d = minf(d, y)
	if sides & ShoreMask.E:
		d = minf(d, T - x)
	if sides & ShoreMask.S:
		d = minf(d, T - y)
	if sides & ShoreMask.W:
		d = minf(d, x)
	if corners & ShoreMask.NE:
		d = minf(d, Vector2(T - x, y).length())
	if corners & ShoreMask.SE:
		d = minf(d, Vector2(T - x, T - y).length())
	if corners & ShoreMask.SW:
		d = minf(d, Vector2(x, T - y).length())
	if corners & ShoreMask.NW:
		d = minf(d, Vector2(x, y).length())
	return d


static func _shore_tile(season: int, k: int, water_side: bool) -> RefCounted:
	var c := Canvas.create(T, T, 900 + k + season * 997)
	var winter := season == Util.WINTER
	var wet: Array = [Palette.SNOW[0], Palette.SNOW[1], Palette.SNOW[2]] if winter else Palette.SAND
	var W := Palette.WATER
	for j in T:
		for i in T:
			var x := i + 0.5
			var y := j + 0.5
			var d := _shore_distance(x, y, k)
			if d > 9.0:
				continue
			var wobble := Util.pnoise(x, y, 8, T, 77)
			var bayer: int = Canvas.BAYER[(j % 4) * 4 + (i % 4)]
			if water_side:
				var edge := 1.0 + (wobble - 0.5) * 2.6
				if d < edge:
					c.px(i, j, wet[0] if d < edge - 0.8 else wet[1])
				elif d < edge + 1.0:
					c.px(i, j, Palette.SNOW[3] if winter else W[4])
				elif d < edge + 2.2:
					if bayer < 9:
						c.px(i, j, Palette.SNOW[2] if winter else W[3])
				elif d < edge + 3.4:
					if bayer < 3:
						c.px(i, j, Palette.SNOW[1] if winter else W[3])
			else:
				var width := 5.2 + (wobble - 0.5) * 4.0
				if d >= width:
					continue
				var noise := Util.pnoise(x, y, 16, T, 41)
				if d < 1.2:
					c.px(i, j, wet[0])
				elif d < 2.4 + noise:
					c.px(i, j, wet[1] if noise > 0.35 else wet[0])
				elif d < width - 1.4:
					c.px(i, j, wet[1] if noise < 0.45 else wet[2])
				elif bayer < 8:
					c.px(i, j, wet[2] if noise > 0.5 else wet[1])
	if not water_side:
		for n in 6:
			var px: int = 2 + c.rng.randi() % (T - 4)
			var py: int = 2 + c.rng.randi() % (T - 4)
			if c.is_opaque(px, py):
				c.px(px, py, Palette.SNOW[3] if winter else Palette.SAND[0])
	return c


static func _road_atlas() -> void:
	var sheet := Canvas.create(ROAD_MASKS * T, SEASONS * 2 * T, 1)
	for season in SEASONS:
		for mask in ROAD_MASKS:
			sheet.blit(_road(season, mask, false), mask * T, season * 2 * T)
			sheet.blit(_road(season, mask, true), mask * T, (season * 2 + 1) * T)
	sheet.save("%s/roads.png" % OUT_DIR)


static func _half_width(t: float, side: int, stone: bool) -> float:
	var base := 8.5 if stone else 8.0
	var n := Canvas.value_noise(t / 2.5, side * 13.0, 55)
	return base + (n - 0.5) * (1.0 if stone else 3.2)


static func _is_road(i: int, j: int, mask: int, stone: bool) -> bool:
	var x := i + 0.5 - 16.0
	var y := j + 0.5 - 16.0
	var ax := absf(x)
	var ay := absf(y)
	var center := 8.5 if stone else 8.0
	if maxf(ax, ay) <= center and ax + ay <= center + 5.5:
		return true
	if mask & ShoreMask.N and y < 0.0 and ax <= _half_width(-y, 1 if x > 0.0 else 0, stone):
		return true
	if mask & ShoreMask.S and y > 0.0 and ax <= _half_width(y, 3 if x > 0.0 else 2, stone):
		return true
	if mask & ShoreMask.E and x > 0.0 and ay <= _half_width(x, 5 if y > 0.0 else 4, stone):
		return true
	if mask & ShoreMask.W and x < 0.0 and ay <= _half_width(-x, 7 if y > 0.0 else 6, stone):
		return true
	return false


static func _road(season: int, mask: int, stone: bool) -> RefCounted:
	var c := Canvas.create(T, T, 1300 + season * 31 + mask * 7 + (1 if stone else 0))
	var D := Palette.DIRT
	var S := Palette.STONE
	var winter := season == Util.WINTER
	var ramp: Array
	if winter:
		ramp = [Palette.SNOW[0], Palette.SNOW[1], Palette.SNOW[1], Palette.SNOW[2]]
	elif stone:
		ramp = [S[1], S[2], S[2], S[3]]
	else:
		ramp = [D[1], D[2], D[2], D[3]]
	for j in T:
		for i in T:
			if not _is_road(i, j, mask, stone):
				continue
			var rim := not (_is_road(i + 1, j, mask, stone) and _is_road(i - 1, j, mask, stone) and _is_road(i, j + 1, mask, stone) and _is_road(i, j - 1, mask, stone))
			var color: Color
			if rim:
				color = S[0] if stone and not winter else (Palette.SNOW[0] if winter else D[0])
				if winter:
					color = D[1] if not stone else S[1]
			elif stone:
				color = _cobble(i, j, winter)
			else:
				var n := Util.pnoise(i + 0.5, j + 0.5, 16, T, 211) * 0.55 + Util.pnoise(i + 0.5, j + 0.5, 8, T, 214) * 0.45
				var idx := 0
				for cut in [0.4, 0.62, 0.82]:
					if n >= cut:
						idx += 1
				color = ramp[idx]
				if winter and n > 0.56:
					color = D[2] if n < 0.7 else D[1]
			c.px(i, j, color)
	for j in T:
		for i in T:
			if c.is_opaque(i, j) or _is_road(i, j, mask, stone):
				continue
			if (_is_road(i + 1, j, mask, stone) or _is_road(i, j + 1, mask, stone) or _is_road(i - 1, j, mask, stone) or _is_road(i, j - 1, mask, stone)) and c.rng.randf() < 0.1:
				c.px(i, j, Palette.SNOW[1] if winter else D[2])
	if not stone:
		for n in 14:
			var px: int = c.rng.randi() % T
			var py: int = c.rng.randi() % T
			if c.is_opaque(px, py):
				c.px(px, py, (D[2] if winter else (S[2] if n % 3 == 0 else D[3])) if n % 2 == 0 else (Palette.SNOW[3] if winter else D[0]))
		if season == Util.AUTUMN:
			for n in 5:
				var px: int = c.rng.randi() % T
				var py: int = c.rng.randi() % T
				if c.is_opaque(px, py):
					c.px(px, py, Palette.AUTUMN[1 + n % 3])
					c.px(px + 1, py, Palette.AUTUMN[0])
	return c


static func _cobble(i: int, j: int, winter: bool) -> Color:
	var S := Palette.STONE
	var cells := 5
	var size := float(T) / cells
	var x := i + 0.5
	var y := j + 0.5
	var gx := int(floor(x / size))
	var gy := int(floor(y / size))
	var d1 := 1000.0
	var d2 := 1000.0
	var best := Vector2.ZERO
	var best_cell := Vector2i.ZERO
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			var cx := gx + ox
			var cy := gy + oy
			var wx := posmod(cx, cells)
			var wy := posmod(cy, cells)
			var point := Vector2((cx + 0.5 + (Canvas.hash01(wx, wy, 21) - 0.5) * 0.6) * size, (cy + 0.5 + (Canvas.hash01(wx, wy, 22) - 0.5) * 0.6) * size)
			var d := point.distance_to(Vector2(x, y))
			if d < d1:
				d2 = d1
				d1 = d
				best = point
				best_cell = Vector2i(wx, wy)
			elif d < d2:
				d2 = d
	if d2 - d1 < 1.0:
		return Palette.SNOW[1] if winter and Canvas.hash2(i, j, 5) % 3 != 0 else S[0]
	var tone := Canvas.hash2(best_cell.x, best_cell.y, 5) % 3
	var rel := Vector2(x, y) - best
	var lit := rel.x + rel.y
	if winter and lit < 1.5 and Canvas.hash2(best_cell.x, best_cell.y, 9) % 4 != 0:
		return Palette.SNOW[3] if lit < -1.5 else Palette.SNOW[2]
	if lit < -2.2:
		return S[3] if tone != 0 else S[2]
	if lit > 2.4:
		return S[1]
	return S[2] if tone != 1 else S[1]
