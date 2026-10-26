extends RefCounted

const Canvas := preload("res://tools/art/pixel_canvas.gd")
const Palette := preload("res://tools/art/palette.gd")


static func qidx(v: float, n: int, i: int, j: int) -> int:
	var threshold := (Canvas.BAYER[(j % 4) * 4 + (i % 4)] + 0.5) / 16.0 - 0.5
	return clampi(int(floor((v + threshold * 0.14) * n)), 0, n - 1)


static func pts(list: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in list:
		out.append(Vector2(p[0], p[1]))
	return out


static func plank_wall(c: RefCounted, x: int, y: int, w: int, h: int, ramp: Array, seed_value: int, plank: int = 4) -> void:
	for j in h:
		for i in w:
			var col := i / plank
			var ci := i % plank
			var v := 0.56 + (0.07 if col % 2 == 0 else -0.05) + Canvas.hash01(col, 0, seed_value) * 0.09
			if ci == 0:
				v += 0.14
			elif ci == plank - 1:
				v -= 0.22
			if j < 2:
				v -= 0.26
			if j >= h - 2:
				v -= 0.14
			if (j + col * 5 + seed_value) % 13 == 0:
				v -= 0.2
			c.px(x + i, y + j, ramp[qidx(v, ramp.size(), x + i, y + j)])
	for k in maxi(w / 14, 1):
		var kx := x + 3 + int(Canvas.hash01(k, 3, seed_value) * (w - 6))
		var ky := y + 5 + int(Canvas.hash01(k, 4, seed_value) * maxf(h - 9, 1))
		c.px(kx, ky, ramp[0])
		c.px(kx + 1, ky, ramp[1])


static func log_wall(c: RefCounted, x: int, y: int, w: int, h: int, ramp: Array, seed_value: int) -> void:
	var band := 5
	for j in h:
		var r := j % band
		var row := j / band
		for i in w:
			var v := 0.55
			match r:
				0:
					v = 0.86
				1:
					v = 0.64
				2:
					v = 0.5
				3:
					v = 0.32
				4:
					v = 0.1
			if Canvas.hash01(i / 6, row, seed_value) > 0.82 and r in [1, 2]:
				v -= 0.12
			c.px(x + i, y + j, ramp[qidx(v, ramp.size(), x + i, y + j)])
	for row in range(0, (h + band - 1) / band):
		var yy := y + row * band
		var off := 0 if row % 2 == 0 else 2
		for k in 4:
			c.px(x - 2 + off + (k % 2), yy + 1 + k / 2, ramp[3 if k == 0 else 4])
			c.px(x + w + off - 2 + (k % 2), yy + 1 + k / 2, ramp[1 if k > 1 else 2])
		c.rect(x - 2 + off, yy, 3, 4, ramp[2])
		c.px(x - 2 + off, yy, ramp[4])
		c.px(x - 1 + off, yy + 1, ramp[4])
		c.px(x - 1 + off, yy + 2, ramp[0])
		c.rect(x + w - 1 + off, yy, 3, 4, ramp[2])
		c.px(x + w - 1 + off, yy, ramp[4])
		c.px(x + w + off, yy + 1, ramp[3])
		c.px(x + w + off, yy + 2, ramp[0])


static func stone_wall(c: RefCounted, x: int, y: int, w: int, h: int, ramp: Array, seed_value: int) -> void:
	var course := 6
	for j in h:
		var row := j / course
		var r := j % course
		var off := (row % 2) * 5
		for i in w:
			var cell := (i + off) / 9
			var ci := (i + off) % 9
			var tone := Canvas.hash01(cell, row, seed_value)
			var v := 0.5 + tone * 0.22
			if r == course - 1 or ci == 0:
				v = 0.18
			elif r == 0:
				v += 0.2
			elif r == course - 2:
				v -= 0.14
			if ci == 1 and r < course - 1:
				v += 0.1
			if j < 2:
				v -= 0.2
			c.px(x + i, y + j, ramp[qidx(v, ramp.size(), x + i, y + j)])


static func roof(c: RefCounted, points: PackedVector2Array, ramp: Array, style: String, seed_value: int) -> void:
	var rows: Array[int] = c._scan_rows(points)
	var top := rows[0]
	var bottom := rows[rows.size() - 1]
	var left := 1000000.0
	var right := -1000000.0
	for p in points:
		left = minf(left, p.x)
		right = maxf(right, p.x)
	var n := ramp.size()
	for j in rows:
		var t := float(j - top) / maxf(bottom - top, 1.0)
		for span in c._spans(points, j):
			for i in range(span.x, span.y):
				var u := float(i - left) / maxf(right - left, 1.0)
				var v := 0.72 - u * 0.24 - t * 0.12
				var rj := j - top
				match style:
					"thatch":
						var band := rj / 4
						var r := rj % 4
						if r == 0:
							v += 0.16
						elif r == 3:
							v -= 0.24
						if (i + band * 3) % 5 == 0 and r in [1, 2]:
							v -= 0.15
					"tile":
						var band2 := rj / 5
						var r2 := rj % 5
						if r2 == 0:
							v += 0.14
						elif r2 == 4:
							v -= 0.26
						if (i + (band2 % 2) * 3) % 6 == 0 and r2 >= 2:
							v -= 0.2
					"slate":
						var band3 := rj / 4
						var r3 := rj % 4
						if r3 == 0:
							v += 0.1
						elif r3 == 3:
							v -= 0.24
						if (i + (band3 % 2) * 3) % 6 == 0 and r3 < 3:
							v -= 0.16
					"shake":
						if i % 4 == 0:
							v -= 0.2
						elif i % 4 == 1:
							v += 0.1
						if (rj + (i / 4) * 3) % 9 == 0:
							v -= 0.22
					"hide":
						var n1 := Canvas.value_noise(i / 7.0, j / 6.0, seed_value)
						if n1 > 0.58:
							v -= 0.2
						elif n1 < 0.3:
							v += 0.12
						if absf(n1 - 0.58) < 0.025 or absf(n1 - 0.3) < 0.02:
							v -= 0.3
						if (i + j) % 7 == 0 and absf(n1 - 0.58) < 0.07:
							v += 0.25
				v += (Canvas.hash01(i, j, seed_value) - 0.5) * 0.08
				if i == span.x:
					v += 0.18
				elif i == span.y - 1:
					v -= 0.12
				if j >= bottom - 1:
					v -= 0.3
				c.px(i, j, ramp[qidx(v, n, i, j)])


static func snow_roof(c: RefCounted, points: PackedVector2Array, seed_value: int, depth: int = 3) -> void:
	var rows: Array[int] = c._scan_rows(points)
	var top := rows[0]
	var bottom := rows[rows.size() - 1]
	var col_top := {}
	var col_bottom := {}
	var left := 1000000.0
	var right := -1000000.0
	for p in points:
		left = minf(left, p.x)
		right = maxf(right, p.x)
	for j in rows:
		for span in c._spans(points, j):
			for i in range(span.x, span.y):
				if not col_top.has(i):
					col_top[i] = j
				col_bottom[i] = j
	var S := Palette.SNOW
	for j in rows:
		for span in c._spans(points, j):
			for i in range(span.x, span.y):
				var limit: int = int(col_bottom[i]) - depth + 1 - int(Canvas.hash01(i / 2, 0, seed_value) * 3.0)
				if j > limit:
					continue
				if Canvas.hash01(i, j, seed_value + 3) < 0.02 and j > int(col_top[i]) + 1:
					continue
				var u := (i - left) / maxf(right - left, 1.0)
				var rel := float(j - int(col_top[i])) / maxf(limit - int(col_top[i]), 1.0)
				var v := 0.9 - u * 0.2 - rel * 0.28
				if j >= limit - 1:
					v -= 0.18
				if (j - top) % 6 == 5:
					v -= 0.12
				c.px(i, j, S[qidx(v, S.size(), i, j)])
	for i in col_bottom:
		if Canvas.hash01(int(i), 7, seed_value) > 0.84:
			var jb: int = int(col_bottom[i]) + 1
			c.px(int(i), jb, S[1])
			if Canvas.hash01(int(i), 8, seed_value) > 0.5:
				c.px(int(i), jb + 1, S[0])


static func eave_shadow(c: RefCounted, x0: int, x1: int, y: int) -> void:
	for i in range(x0, x1):
		c.px(i, y, Color(0.05, 0.03, 0.08, 0.4))
		c.px(i, y + 1, Color(0.05, 0.03, 0.08, 0.22))


static func door(c: RefCounted, x: int, y: int, w: int, h: int, seed_value: int = 1) -> void:
	var W := Palette.WOOD
	c.rect(x - 1, y - 1, w + 2, h + 1, W[0])
	for i in w:
		for j in h:
			var v := 0.5 + (0.16 if i == 0 else 0.0) - (0.18 if i == w - 1 else 0.0)
			if i % 3 == 2:
				v -= 0.14
			if j < 2:
				v -= 0.2
			c.px(x + i, y + j, W[qidx(v * 0.75, 4, x + i, y + j)])
	c.px(x + w - 3, y + h / 2, Palette.STEEL[3])
	c.px(x + w - 3, y + h / 2 + 1, Palette.STEEL[1])
	c.px(x - 1, y - 1, W[3])


static func opening(c: RefCounted, x: int, y: int, w: int, h: int) -> void:
	c.rect(x, y, w, h, Palette.INK)
	for i in w:
		for j in range(h - 3, h):
			if (i + j) % 3 == 0:
				c.px(x + i, y + j, Palette.WOOD[0])


static func window(c: RefCounted, x: int, y: int, w: int = 6, h: int = 6, shutters: bool = true) -> void:
	var W := Palette.WOOD
	var F := Palette.FIRE
	c.rect(x - 1, y - 1, w + 2, h + 2, W[0])
	for j in h:
		for i in w:
			var v := 0.55 + (0.2 if (i < 2 and j < 2) else 0.0) - j * 0.05
			c.px(x + i, y + j, F[qidx(v, 4, x + i, y + j)])
	c.line(x + w / 2, y, x + w / 2, y + h - 1, W[1])
	c.line(x, y + h / 2, x + w - 1, y + h / 2, W[1])
	c.rect(x - 2, y + h + 1, w + 4, 1, W[3])
	if shutters:
		c.rect(x - 3, y - 1, 2, h + 2, W[2])
		c.rect(x + w + 1, y - 1, 2, h + 2, W[1])
		c.px(x - 3, y - 1, W[4])


static func chimney(c: RefCounted, x: int, y: int, w: int, h: int, seed_value: int) -> void:
	var S := Palette.STONE
	stone_wall(c, x, y, w, h, S, seed_value)
	c.rect(x - 1, y - 2, w + 2, 3, S[1])
	c.rect(x - 1, y - 2, w + 2, 1, S[3])
	c.rect(x + 1, y - 3, w - 2, 1, S[0])
	c.px(x - 1, y - 2, S[4])


static func sack(c: RefCounted, cx: int, by: int, size: int = 7) -> void:
	var C := Palette.CREAM
	c.shade_ellipse(cx, by - size * 0.5, size * 0.5 + 0.5, size * 0.5, [C[0], C[1], C[2], C[3]])
	c.rect(cx - 1, by - size - 1, 3, 2, C[1])
	c.px(cx, by - size, Palette.WOOD[1])
	c.px(cx - 1, by - size - 2, C[2])
	c.px(cx + 1, by - size - 2, C[1])
	c.px(cx - 1, by - 3, C[0])


static func barrel(c: RefCounted, x: int, by: int, w: int = 8, h: int = 9) -> void:
	var W := Palette.WOOD
	for j in h:
		var bulge := 1 if (j > 1 and j < h - 2) else 0
		for i in range(-bulge, w + bulge):
			var v := 0.55 - float(i) / w * 0.4 + (0.2 if i == 0 else 0.0)
			c.px(x + i, by - h + j, W[qidx(v, 5, x + i, by - h + j)])
	c.rect(x - 1, by - h + 2, w + 2, 1, Palette.STEEL[1])
	c.rect(x - 1, by - 3, w + 2, 1, Palette.STEEL[1])
	c.rect(x, by - h, w, 1, W[4])
	c.px(x + 1, by - h + 2, Palette.STEEL[3])


static func crate(c: RefCounted, x: int, by: int, w: int = 9, h: int = 8) -> void:
	var W := Palette.WOOD
	c.rect(x, by - h, w, h, W[2])
	c.rect(x, by - h, w, 2, W[4])
	c.rect(x, by - h + 2, 1, h - 2, W[3])
	c.rect(x + w - 1, by - h + 1, 1, h - 1, W[1])
	c.rect(x, by - 1, w, 1, W[0])
	c.line(x + 1, by - h + 2, x + w - 2, by - 2, W[1])
	c.line(x + 1, by - 2, x + w - 2, by - h + 2, W[1])


static func log_end(c: RefCounted, cx: float, cy: float, r: float) -> void:
	var W := Palette.WOOD
	c.shade_ellipse(cx, cy, r, r, [W[1], W[2], W[3], W[3]])
	c.ellipse(cx, cy, maxf(r - 1.0, 0.8), maxf(r - 1.0, 0.8), W[4])
	if r >= 2.5:
		c.ellipse(cx, cy, r * 0.45, r * 0.45, W[3])
		c.px(int(cx), int(cy), W[2])
	c.ellipse_outline(cx, cy, r, r, W[0])


static func log_stack(c: RefCounted, cx: int, by: int, rows: int, r: float = 2.6) -> void:
	var W := Palette.WOOD
	var d := r * 2.0
	for row in rows:
		var count := rows - row
		var y := by - r - row * (d - 0.6)
		var start := cx - (count - 1) * d * 0.5
		for k in count:
			var x := start + k * d
			c.rect(int(x), int(y - r), 3, int(d), W[2])
			c.rect(int(x) + 1, int(y - r) - 1, 3, 1, W[1])
		for k in count:
			log_end(c, start + k * d, y, r)
	c.rect(cx - int(rows * r), by - 1, int(rows * d), 1, W[0])


static func firewood_stack(c: RefCounted, x: int, by: int, cols: int, rows: int, r: float = 2.0) -> void:
	var W := Palette.WOOD
	var d := r * 2.0
	c.rect(x - 1, by - int(rows * d) - 1, int(cols * d) + 2, int(rows * d) + 1, W[0])
	for row in rows:
		for k in cols:
			var cx := x + r + k * d
			var cy := by - r - row * d
			var tone := Canvas.hash01(k, row, 33)
			c.ellipse(cx, cy, r, r, W[3] if tone > 0.4 else W[2])
			c.px(int(cx), int(cy), W[4] if tone > 0.6 else W[1])
			c.px(int(cx - 1), int(cy - 1), W[4])
	c.rect(x, by - 1, int(cols * d), 1, W[0])


static func stone_block(c: RefCounted, x: int, by: int, w: int, h: int) -> void:
	var S := Palette.STONE
	var top := maxi(h / 3, 2)
	c.rect(x, by - h, w, h, S[2])
	c.rect(x, by - h, w, top, S[3])
	c.rect(x, by - h, w, 1, S[4])
	c.rect(x + w - 2, by - h + top, 2, h - top, S[1])
	c.rect(x, by - 1, w, 1, S[1])
	c.rect(x, by - h, 1, h, S[3])
	c.px(x + 2, by - h + top + 1, S[1])
	c.rect(x, by - h, w, 1, S[4])
	c.px(x + w - 1, by - h, S[2])


static func basket(c: RefCounted, cx: int, by: int, fill: Array) -> void:
	var W := Palette.WOOD
	var S := Palette.STRAW
	c.rect(cx - 4, by - 5, 9, 5, S[1])
	c.rect(cx - 5, by - 5, 11, 1, S[2])
	for k in 5:
		c.px(cx - 3 + k * 2, by - 3, S[0])
		c.px(cx - 4 + k * 2, by - 2, S[2])
	c.rect(cx - 4, by - 1, 9, 1, S[0])
	for k in 5:
		var dx := cx - 3 + (k % 3) * 2
		var dy := by - 7 + (k / 3)
		c.shade_ellipse(dx, dy, 1.6, 1.6, fill)
	c.px(cx - 5, by - 4, W[0])


static func shadow_under(c: RefCounted, x0: int, x1: int, by: int, depth: int = 3) -> void:
	for j in range(by - 1, by + depth):
		for i in range(x0, x1 + 4):
			if not c.is_opaque(i, j):
				c.px(i, j, Palette.SHADOW)


static func snow_ground(c: RefCounted, x0: int, x1: int, by: int, seed_value: int) -> void:
	var S := Palette.SNOW
	for i in range(x0, x1):
		var h := Canvas.hash01(i / 3, 1, seed_value)
		if h > 0.45:
			var j := by + 1 + (1 if h > 0.8 else 0)
			if not c.is_opaque(i, j):
				c.px(i, j, S[2] if h < 0.7 else S[3])
