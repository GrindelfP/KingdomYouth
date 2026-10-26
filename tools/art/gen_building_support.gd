extends RefCounted

const Canvas := preload("res://tools/art/pixel_canvas.gd")
const Palette := preload("res://tools/art/palette.gd")
const P := preload("res://tools/art/building_parts.gd")

const OUT_DIR := "res://assets/art/buildings"
const SITE_SIZES: Array[int] = [2, 3, 4]
const FENCE_SIZES: Array[int] = [4, 6, 8]
const FIELD_COLUMNS := 15
const PILE_W := 40
const PILE_H := 32
const PILE_GOODS: Array[String] = ["logs", "stone", "firewood", "iron", "tools"]
const PILE_STAGES := 4


static func generate() -> void:
	for n in SITE_SIZES:
		_site_sheet(n)
	for n in FENCE_SIZES:
		_fence_sheet(n)
	_field_tiles()
	_piles()
	_fx()


static func _site_sheet(n: int) -> void:
	var w := n * 32 + 16
	var ext := 14
	var h := n * 32 + ext + 6
	var sheet := Canvas.create(w * 3, h, 1)
	for stage in 3:
		sheet.blit(_site(n, stage, w, h), stage * w, 0)
	sheet.save("%s/site_%d.png" % [OUT_DIR, n])


static func _site(n: int, stage: int, w: int, h: int) -> RefCounted:
	var c := Canvas.create(w, h, 200 + n * 7 + stage)
	var W := Palette.WOOD
	var S := Palette.STONE
	var by := h - 6
	var x0 := 10
	var x1 := w - 10
	var depth := n * 32 - 18
	var y0 := by - depth
	c.noise_fill(x0, y0, x1 - x0, depth - 3, [S[1], S[2], S[2], S[3]], 3.0, 210 + n)
	c.speckle(x0, y0, x1 - x0, depth - 3, S[0], 0.06)
	c.rect(x0, by - 4, x1 - x0, 4, S[2])
	c.rect(x0, by - 4, x1 - x0, 1, S[4])
	c.rect(x0, by - 1, x1 - x0, 1, S[0])
	c.rect(x0, y0, x1 - x0, 3, W[2])
	c.rect(x0, y0, x1 - x0, 1, W[4])
	c.rect(x0, by - 7, x1 - x0, 3, W[2])
	c.rect(x0, by - 7, x1 - x0, 1, W[4])
	c.rect(x0, y0, 3, depth - 3, W[2])
	c.rect(x1 - 3, y0, 3, depth - 3, W[1])
	c.rect(x0, y0, 1, depth - 3, W[4])
	var post_h := 20 + n * 2
	if stage == 0:
		for corner in [Vector2(x0 + 1, y0 + 1), Vector2(x1 - 2, y0 + 1), Vector2(x0 + 1, by - 6), Vector2(x1 - 2, by - 6)]:
			c.rect(int(corner.x), int(corner.y) - 9, 2, 10, W[3])
			c.px(int(corner.x), int(corner.y) - 10, W[4])
		c.line(x0 + 1, by - 16, x1 - 2, by - 16, Palette.CREAM[1])
		c.line(x0 + 1, y0 - 9, x1 - 2, y0 - 9, Palette.CREAM[1])
		for k in 3:
			c.rect(x0 + 8 + k * 14, y0 + 10 + k * 5, 10, 2, W[3])
			c.rect(x0 + 8 + k * 14, y0 + 12 + k * 5, 10, 1, W[1])
	else:
		var front_xs: Array[int] = []
		var count := n * 2
		for k in count + 1:
			front_xs.append(x0 + 1 + k * (x1 - x0 - 4) / count)
		for px in [x0 + 1, x1 - 4]:
			c.rect(px, y0 - post_h + 6, 3, post_h, W[1])
			c.px(px, y0 - post_h + 6, W[3])
		c.line(x0 + 1, y0 - post_h + 6, x1 - 4, y0 - post_h + 6, W[2])
		c.line(x0 + 1, y0 - post_h + 7, x1 - 4, y0 - post_h + 7, W[1])
		for px in front_xs:
			c.rect(px, by - 7 - post_h, 3, post_h, W[2])
			c.rect(px, by - 7 - post_h, 1, post_h, W[4])
			c.rect(px + 2, by - 7 - post_h, 1, post_h, W[0])
		c.rect(x0, by - 9 - post_h, x1 - x0, 3, W[3])
		c.rect(x0, by - 9 - post_h, x1 - x0, 1, W[4])
		c.rect(x0, by - 7 - post_h, x1 - x0, 1, W[0])
		c.line(x0 + 2, by - 7 - post_h, x0 + 2, y0 - post_h + 6, W[2])
		c.line(x1 - 3, by - 7 - post_h, x1 - 3, y0 - post_h + 6, W[1])
		var braces := [x0 + 1, x1 - 4]
		for bx in braces:
			c.line(bx, by - 7 - 8, bx + (7 if bx == x0 + 1 else -7), by - 7 - 16, W[2])
	if stage == 2:
		var wall_h := 14 + n
		P.plank_wall(c, x0 + 3, by - 7 - wall_h, (x1 - x0) / 2, wall_h, W, 220 + n)
		for k in n * 2:
			var rx := x0 + 4 + k * (x1 - x0 - 8) / (n * 2)
			c.line(rx, by - 9 - post_h, (x0 + x1) / 2, by - 9 - post_h - 12, W[3])
			c.line(rx + 1, by - 9 - post_h, (x0 + x1) / 2 + 1, by - 9 - post_h - 12, W[1])
		c.rect((x0 + x1) / 2 - 1, by - 9 - post_h - 13, 3, 13, W[3])
	c.outline_dark()
	var shadow_y := by
	for j in range(shadow_y - 1, shadow_y + 3):
		for i in range(x0 + 2, x1 + 4):
			if not c.is_opaque(i, j):
				c.px(i, j, Palette.SHADOW)
	return c


static func _fence_sheet(n: int) -> void:
	var w := n * 32 + 16
	var h := n * 32 + 20
	var sheet := Canvas.create(w * 4, h, 1)
	for stage in 4:
		sheet.blit(_fence(n, stage, w, h), stage * w, 0)
	sheet.save("%s/fence_%d.png" % [OUT_DIR, n])


static func _fence(n: int, stage: int, w: int, h: int) -> RefCounted:
	var c := Canvas.create(w, h, 300 + n * 5 + stage)
	var W := Palette.WOOD
	var x0 := 9
	var x1 := w - 9
	var y0 := 13
	var y1 := h - 9
	var step := 16 if stage >= 2 else 32
	var xs: Array[int] = []
	for x in range(x0, x1 + 1, step):
		xs.append(x)
	if xs[xs.size() - 1] != x1:
		xs.append(x1)
	var ys: Array[int] = []
	for y in range(y0, y1 + 1, step):
		ys.append(y)
	if ys[ys.size() - 1] != y1:
		ys.append(y1)
	if stage == 0:
		for corner in [Vector2i(x0, y0), Vector2i(x1, y0), Vector2i(x0, y1), Vector2i(x1, y1)]:
			c.rect(corner.x - 1, corner.y - 7, 2, 8, W[3])
			c.px(corner.x - 1, corner.y - 8, W[4])
		c.line(x0, y0 - 6, x1, y0 - 6, Palette.CREAM[1])
		c.line(x0, y1 - 6, x1, y1 - 6, Palette.CREAM[1])
		c.line(x0 - 1, y0 - 5, x0 - 1, y1 - 5, Palette.CREAM[1])
		c.line(x1, y0 - 5, x1, y1 - 5, Palette.CREAM[1])
		c.outline_dark()
		return c
	if stage >= 2:
		var rail_end := x1 if stage == 3 else (x0 + x1) / 2
		for yy in [y0, y1]:
			for x in range(x0, rail_end):
				c.px(x, yy - 5, W[3] if x % 3 else W[4])
				c.px(x, yy - 4, W[1])
				if stage == 3:
					c.px(x, yy - 8, W[3] if x % 3 else W[4])
					c.px(x, yy - 7, W[1])
		var rail_bottom := y1 if stage == 3 else (y0 + y1) / 2
		for y in range(y0, rail_bottom):
			c.px(x0 - 1, y - 4, W[3])
			c.px(x0, y - 4, W[1])
			c.px(x1, y - 4, W[3])
			c.px(x1 + 1, y - 4, W[1])
	for yy in ys:
		for x in xs:
			if yy != y0 and yy != y1 and x != x0 and x != x1:
				continue
			if stage == 2 and x > (x0 + x1) / 2 and yy > (y0 + y1) / 2:
				continue
			_post(c, x, yy)
	c.outline_dark()
	return c


static func _post(c: RefCounted, x: int, y: int) -> void:
	var W := Palette.WOOD
	c.rect(x - 1, y - 11, 3, 11, W[2])
	c.rect(x - 1, y - 11, 1, 11, W[4])
	c.rect(x + 1, y - 11, 1, 11, W[0])
	c.px(x, y - 12, W[3])
	c.px(x - 1, y - 12, W[4])


static func _field_tiles() -> void:
	var sheet := Canvas.create(FIELD_COLUMNS * 32, 2 * 32, 1)
	for col in FIELD_COLUMNS:
		var tile := _field_tile(col)
		sheet.blit(tile, col * 32, 0)
		sheet.blit(_snowy(tile, col), col * 32, 32)
	sheet.save("%s/field_tiles.png" % OUT_DIR)


static func _soil(c: RefCounted, seed_value: int, furrows: bool) -> void:
	var D := Palette.DIRT
	if not furrows:
		c.noise_fill(0, 0, 32, 32, [D[1], D[2], D[2], D[3]], 4.0, seed_value)
		c.speckle(0, 0, 32, 32, D[0], 0.05, false)
		c.speckle(0, 0, 32, 32, D[3], 0.04, false)
		for k in 3:
			var x := 3 + int(Canvas.hash01(k, 1, seed_value) * 24)
			var y := 3 + int(Canvas.hash01(k, 2, seed_value) * 24)
			c.px(x, y, Palette.STONE[2])
			c.px(x + 1, y, Palette.STONE[1])
		return
	for j in 32:
		for i in 32:
			var wave := int(round(sin(i * 0.25 + seed_value) * 0.8))
			var r := (j + wave + 32) % 8
			var v := 0.5
			match r:
				0:
					v = 0.8
				1, 2:
					v = 0.6
				3:
					v = 0.4
				4, 5:
					v = 0.12
				_:
					v = 0.3
			v += (Canvas.hash01(i, j, seed_value) - 0.5) * 0.18
			c.px(i, j, D[P.qidx(v, 4, i, j)])


static func _wheat_row(c: RefCounted, y: int, height: int, ripe: bool, seed_value: int) -> void:
	var G := Palette.GRASS
	var S := Palette.STRAW
	for i in range(1, 31, 2):
		var jitter := int(Canvas.hash01(i, y, seed_value) * 3.0)
		var top := y - height + jitter
		var stalk: Color = S[1] if ripe else G[2]
		var head: Color = S[3] if ripe else G[3]
		c.line(i, y, i, top, stalk)
		c.px(i, top, head)
		c.px(i, top - 1 if ripe else top, head)
		if ripe and i % 4 == 1:
			c.px(i + 1, top + 1, S[2])
			c.px(i - 1, top + 2, S[2])
		if not ripe and i % 4 == 1:
			c.px(i + 1, top + 2, G[1])


static func _field_tile(col: int) -> RefCounted:
	var c := Canvas.create(32, 32, 400 + col)
	var G := Palette.GRASS
	var S := Palette.STRAW
	var D := Palette.DIRT
	var K := Palette.CABBAGE
	var variant := col % 2
	match col:
		0, 1:
			_soil(c, 400 + variant, false)
			for k in 3:
				var x := 4 + int(Canvas.hash01(k, 3, col) * 22)
				var y := 4 + int(Canvas.hash01(k, 4, col) * 22)
				c.px(x, y, G[1])
				c.px(x, y - 1, G[2])
		2, 3:
			_soil(c, 410 + variant, true)
		4:
			_soil(c, 410, true)
			for row in 4:
				var y := row * 8 + 3
				for i in range(3, 31, 5):
					c.px(i, y, G[3])
					c.px(i, y - 1, G[4])
		5, 6:
			_soil(c, 410, true)
			for row in 4:
				var y := row * 8 + 3
				_wheat_row(c, y + 2, 4 if col == 5 else 7, false, col)
		7, 8:
			_soil(c, 410, true)
			for row in 4:
				var y := row * 8 + 3
				for i in [5, 16, 27]:
					var r := 1.6 if col == 7 else 3.0
					c.shade_ellipse(i, y, r, r * 0.8, [K[0], K[1], K[2], K[3]])
		9, 10:
			_soil(c, 410, true)
			for row in 4:
				_wheat_row(c, row * 8 + 6, 10, true, col)
		11, 12:
			_soil(c, 410, true)
			for row in 4:
				var y := row * 8 + 3
				for i in [6, 18, 29]:
					var cx: int = i + (4 if row % 2 == 1 and i < 29 else 0) - (2 if i == 29 else 0)
					c.shade_ellipse(cx, y, 5.2, 4.2, [Palette.GRASS[0], K[0], K[1], K[2]])
					c.shade_ellipse(cx - 1, y - 1, 3.0, 2.4, [K[1], K[2], K[3], K[3]])
					c.px(cx - 1, y - 2, Palette.CABBAGE[3])
		_:
			_soil(c, 420 + variant, false)
			c.noise_fill(0, 0, 32, 32, [S[0], S[1], S[1], D[3]], 3.0, 421 + variant)
			for k in 14:
				var x := 1 + int(Canvas.hash01(k, 7, col) * 30)
				var y := 2 + int(Canvas.hash01(k, 8, col) * 28)
				c.px(x, y, S[2])
				c.px(x, y - 1, S[3])
				c.px(x + 1, y + 1, D[0])
	return c


static func _snowy(tile: RefCounted, col: int) -> RefCounted:
	var c := Canvas.create(32, 32, 500 + col)
	c.blit(tile, 0, 0)
	var S := Palette.SNOW
	for j in 32:
		for i in 32:
			var n := Canvas.value_noise(i / 5.0, j / 5.0, 500 + col % 2)
			var furrow := col >= 2 and col <= 12 and ((j + 32) % 8) in [4, 5]
			if n > (0.5 if furrow else 0.14) - (0.1 if col in [0, 1, 13, 14] else 0.0):
				c.px(i, j, S[P.qidx(0.7 + (Canvas.hash01(i, j, 5) - 0.5) * 0.4 - n * 0.1, 4, i, j)])
	return c


static func _piles() -> void:
	var sheet := Canvas.create(PILE_W * PILE_GOODS.size() * PILE_STAGES, PILE_H * 2, 1)
	for g in PILE_GOODS.size():
		for stage in PILE_STAGES:
			var pile := _pile(PILE_GOODS[g], stage + 1)
			sheet.blit(pile, (g * PILE_STAGES + stage) * PILE_W, 0)
			sheet.blit(_snow_cap(pile), (g * PILE_STAGES + stage) * PILE_W, PILE_H)
	sheet.save("%s/piles.png" % OUT_DIR)


static func _snow_cap(pile: RefCounted) -> RefCounted:
	var c := Canvas.create(PILE_W, PILE_H, 1)
	c.blit(pile, 0, 0)
	var S := Palette.SNOW
	for i in PILE_W:
		for j in PILE_H:
			if pile.is_opaque(i, j):
				if Canvas.hash01(i, 1, 9) > 0.15:
					c.px(i, j, S[3])
					if Canvas.hash01(i, 2, 9) > 0.45 and pile.is_opaque(i, j + 2):
						c.px(i, j + 1, S[2])
				break
	return c


static func _pile(good: String, stage: int) -> RefCounted:
	var c := Canvas.create(PILE_W, PILE_H, 600 + stage)
	var by := PILE_H - 3
	var cx := PILE_W / 2
	var T := Palette.STEEL
	match good:
		"logs":
			P.log_stack(c, cx, by, stage + 1, 2.8)
		"stone":
			var rows: Array = [[1], [2, 1], [3, 2], [3, 2, 1]][stage - 1]
			for r in rows.size():
				var count: int = rows[r]
				for k in count:
					P.stone_block(c, cx - count * 6 + k * 12, by - r * 8 + 1, 12, 9)
		"firewood":
			P.firewood_stack(c, cx - (2 + stage) * 2, by, 2 + stage, mini(stage, 3) + (1 if stage == 4 else 0), 2.0)
		"iron":
			var rows2: Array = [[1], [2, 1], [3, 2], [3, 2, 1]][stage - 1]
			for r in rows2.size():
				var count: int = rows2[r]
				for k in count:
					var bx := cx - count * 5 + k * 10
					var bt := by - r * 4
					c.rect(bx, bt - 4, 10, 4, T[1])
					c.rect(bx, bt - 4, 10, 1, T[3])
					c.rect(bx, bt - 4, 1, 4, T[2])
					c.rect(bx + 9, bt - 3, 1, 3, T[0])
					c.px(bx + 4, bt - 3, T[2])
		"tools":
			var positions: Array = [[0], [-6, 6], [-6, 6, 0], [-9, 0, 9]][stage - 1]
			for k in positions.size():
				var ox: int = positions[k]
				var level := 0 if k < 2 or stage == 4 else 1
				P.crate(c, cx + ox - 5, by - level * 9, 10, 9)
				if k == 0:
					var W := Palette.WOOD
					c.line(cx + ox - 2, by - level * 9 - 9, cx + ox - 4, by - level * 9 - 17, W[3])
					c.rect(cx + ox - 6, by - level * 9 - 19, 5, 3, T[2])
					c.line(cx + ox + 1, by - level * 9 - 9, cx + ox + 3, by - level * 9 - 16, W[2])
					c.rect(cx + ox + 1, by - level * 9 - 18, 5, 2, T[3])
	c.outline_dark()
	for j in range(by - 1, by + 3):
		for i in range(cx - 18, cx + 20):
			if not c.is_opaque(i, j) and j >= by:
				c.px(i, j, Palette.SHADOW)
	return c


static func _fx() -> void:
	var smoke := Canvas.create(8, 8, 700)
	smoke.ellipse(4, 4, 3.5, 3.2, Color(Palette.STONE[3].r, Palette.STONE[3].g, Palette.STONE[3].b, 0.9))
	smoke.ellipse(3, 3, 2.0, 1.8, Color(Palette.SNOW[2].r, Palette.SNOW[2].g, Palette.SNOW[2].b, 0.95))
	smoke.px(6, 5, Color(Palette.STONE[2].r, Palette.STONE[2].g, Palette.STONE[2].b, 0.9))
	smoke.px(1, 1, Color(0, 0, 0, 0))
	smoke.save("%s/smoke.png" % OUT_DIR)
	var glow := Canvas.create(24, 24, 701)
	for j in 24:
		for i in 24:
			var d := Vector2(i - 11.5, j - 11.5).length() / 11.5
			if d < 1.0:
				var a := (1.0 - d) * 0.75
				if Canvas.BAYER[(j % 4) * 4 + (i % 4)] / 16.0 > a * 1.2:
					continue
				glow.px(i, j, Color(Palette.FIRE[2].r, Palette.FIRE[2].g, Palette.FIRE[2].b, minf(a * 1.1, 0.9)))
	glow.save("%s/glow.png" % OUT_DIR)
