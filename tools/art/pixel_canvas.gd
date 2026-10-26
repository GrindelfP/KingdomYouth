extends RefCounted

const Palette := preload("res://tools/art/palette.gd")
const SELF_PATH := "res://tools/art/pixel_canvas.gd"
const BAYER: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

var image: Image
var rng := RandomNumberGenerator.new()
var width := 0
var height := 0


static func create(w: int, h: int, seed_value: int = 1) -> RefCounted:
	var canvas: RefCounted = load(SELF_PATH).new()
	canvas.image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	canvas.width = w
	canvas.height = h
	canvas.rng.seed = seed_value
	return canvas


static func hash2(x: int, y: int, seed_value: int = 0) -> int:
	var h := (x * 374761393 + y * 668265263 + seed_value * 1274126177) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1103515245) & 0x7fffffff
	return h ^ (h >> 16)


static func hash01(x: int, y: int, seed_value: int = 0) -> float:
	return float(hash2(x, y, seed_value) & 0xffff) / 65535.0


static func darken(c: Color, amount: float) -> Color:
	return Color(c.r * (1.0 - amount), c.g * (1.0 - amount * 0.9), c.b * (1.0 - amount * 0.7), c.a)


static func lighten(c: Color, amount: float) -> Color:
	return Color(c.r + (1.0 - c.r) * amount, c.g + (1.0 - c.g) * amount, c.b + (1.0 - c.b) * amount * 0.8, c.a)


static func value_noise(fx: float, fy: float, seed_value: int) -> float:
	var ix := int(floor(fx))
	var iy := int(floor(fy))
	var tx := fx - ix
	var ty := fy - iy
	tx = tx * tx * (3.0 - 2.0 * tx)
	ty = ty * ty * (3.0 - 2.0 * ty)
	var a := hash01(ix, iy, seed_value)
	var b := hash01(ix + 1, iy, seed_value)
	var c := hash01(ix, iy + 1, seed_value)
	var d := hash01(ix + 1, iy + 1, seed_value)
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), ty)


func inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < width and y < height


func get_px(x: int, y: int) -> Color:
	if not inside(x, y):
		return Palette.CLEAR
	return image.get_pixel(x, y)


func px(x: int, y: int, c: Color) -> void:
	if not inside(x, y):
		return
	if c.a >= 0.999:
		image.set_pixel(x, y, c)
	elif c.a > 0.0:
		var under := image.get_pixel(x, y)
		var out_a := c.a + under.a * (1.0 - c.a)
		var mixed := (Color(c.r, c.g, c.b) * c.a + Color(under.r, under.g, under.b) * under.a * (1.0 - c.a)) / out_a
		image.set_pixel(x, y, Color(mixed.r, mixed.g, mixed.b, out_a))


func is_opaque(x: int, y: int) -> bool:
	return inside(x, y) and image.get_pixel(x, y).a > 0.5


func clear(c: Color = Color(0, 0, 0, 0)) -> void:
	image.fill(c)


func rect(x: int, y: int, w: int, h: int, c: Color) -> void:
	for j in range(y, y + h):
		for i in range(x, x + w):
			px(i, j, c)


func rect_outline(x: int, y: int, w: int, h: int, c: Color) -> void:
	for i in range(x, x + w):
		px(i, y, c)
		px(i, y + h - 1, c)
	for j in range(y, y + h):
		px(x, j, c)
		px(x + w - 1, j, c)


func ellipse(cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for j in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for i in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			if _in_ellipse(i, j, cx, cy, rx, ry):
				px(i, j, c)


func ellipse_outline(cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for j in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for i in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			if not _in_ellipse(i, j, cx, cy, rx, ry):
				continue
			if not (_in_ellipse(i + 1, j, cx, cy, rx, ry) and _in_ellipse(i - 1, j, cx, cy, rx, ry) and _in_ellipse(i, j + 1, cx, cy, rx, ry) and _in_ellipse(i, j - 1, cx, cy, rx, ry)):
				px(i, j, c)


func _in_ellipse(i: int, j: int, cx: float, cy: float, rx: float, ry: float) -> bool:
	var dx := (i + 0.5 - cx) / rx
	var dy := (j + 0.5 - cy) / ry
	return dx * dx + dy * dy <= 1.0


func line(x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	var x := x0
	var y := y0
	while true:
		px(x, y, c)
		if x == x1 and y == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy


func polygon(points: PackedVector2Array, c: Color) -> void:
	for j in _scan_rows(points):
		for span in _spans(points, j):
			for i in range(span.x, span.y):
				px(i, j, c)


func _scan_rows(points: PackedVector2Array) -> Array[int]:
	var min_y := 1000000.0
	var max_y := -1000000.0
	for p in points:
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	var rows: Array[int] = []
	for j in range(int(floor(min_y)), int(ceil(max_y)) + 1):
		rows.append(j)
	return rows


func _spans(points: PackedVector2Array, j: int) -> Array[Vector2i]:
	var yy := j + 0.5
	var xs: Array[float] = []
	for k in points.size():
		var a := points[k]
		var b := points[(k + 1) % points.size()]
		if (a.y <= yy and b.y > yy) or (b.y <= yy and a.y > yy):
			xs.append(a.x + (yy - a.y) / (b.y - a.y) * (b.x - a.x))
	xs.sort()
	var out: Array[Vector2i] = []
	for k in range(0, xs.size() - 1, 2):
		out.append(Vector2i(int(round(xs[k])), int(round(xs[k + 1]))))
	return out


func gradient_v(x: int, y: int, w: int, h: int, ramp: Array) -> void:
	var steps := ramp.size()
	for j in h:
		var t := (float(j) + 0.5) / h * (steps - 1)
		var lo := int(floor(t))
		var frac := t - lo
		for i in w:
			var threshold := (BAYER[(j % 4) * 4 + (i % 4)] + 0.5) / 16.0
			var idx := lo + (1 if frac > threshold and lo + 1 < steps else 0)
			px(x + i, y + j, ramp[idx])


func noise_fill(x: int, y: int, w: int, h: int, ramp: Array, scale: float, seed_value: int = 0, only_opaque: bool = false) -> void:
	for j in h:
		for i in w:
			if only_opaque and not is_opaque(x + i, y + j):
				continue
			var fx := (x + i) / scale
			var fy := (y + j) / scale
			var n := value_noise(fx, fy, seed_value) * 0.7 + value_noise(fx * 2.0, fy * 2.0, seed_value + 7) * 0.3
			var idx := clampi(int(n * ramp.size()), 0, ramp.size() - 1)
			px(x + i, y + j, ramp[idx])


func speckle(x: int, y: int, w: int, h: int, c: Color, density: float, only_opaque: bool = true) -> void:
	for j in range(y, y + h):
		for i in range(x, x + w):
			if only_opaque and not is_opaque(i, j):
				continue
			if rng.randf() < density:
				px(i, j, c)


func shade_ellipse(cx: float, cy: float, rx: float, ry: float, ramp: Array) -> void:
	var last := ramp.size() - 1
	for j in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for i in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			if not _in_ellipse(i, j, cx, cy, rx, ry):
				continue
			var dx := (i + 0.5 - cx) / rx
			var dy := (j + 0.5 - cy) / ry
			var lit := clampf(0.55 - (dx * 0.55 + dy * 0.75) * 0.6, 0.0, 0.999)
			px(i, j, ramp[clampi(int(lit * ramp.size()), 0, last)])


func shade_rect(x: int, y: int, w: int, h: int, ramp: Array) -> void:
	var last := ramp.size() - 1
	rect(x, y, w, h, ramp[mini(1, last)])
	if last >= 2:
		for i in w:
			px(x + i, y, ramp[mini(2, last)])
			px(x + i, y + h - 1, ramp[0])
		for j in h:
			px(x, y + j, ramp[mini(2, last)])
			px(x + w - 1, y + j, ramp[0])
		px(x, y + h - 1, ramp[1])
		px(x + w - 1, y, ramp[1])
	if last >= 3:
		px(x, y, ramp[last])


func shade_polygon(points: PackedVector2Array, ramp: Array) -> void:
	var min_x := 1000000.0
	var max_x := -1000000.0
	var min_y := 1000000.0
	var max_y := -1000000.0
	for p in points:
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	var cx := (min_x + max_x) * 0.5
	var cy := (min_y + max_y) * 0.5
	var rx := maxf((max_x - min_x) * 0.5, 1.0)
	var ry := maxf((max_y - min_y) * 0.5, 1.0)
	for j in _scan_rows(points):
		for span in _spans(points, j):
			for i in range(span.x, span.y):
				var dx := (i + 0.5 - cx) / rx
				var dy := (j + 0.5 - cy) / ry
				var lit := clampf(0.55 - (dx * 0.5 + dy * 0.7) * 0.55, 0.0, 0.999)
				px(i, j, ramp[clampi(int(lit * ramp.size()), 0, ramp.size() - 1)])


func outline(c: Color) -> void:
	var src := image.duplicate() as Image
	for j in height:
		for i in width:
			if src.get_pixel(i, j).a > 0.5:
				continue
			if _src_opaque(src, i + 1, j) or _src_opaque(src, i - 1, j) or _src_opaque(src, i, j + 1) or _src_opaque(src, i, j - 1):
				image.set_pixel(i, j, c)


func outline_dark(amount: float = 0.62) -> void:
	var src := image.duplicate() as Image
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for j in height:
		for i in width:
			if src.get_pixel(i, j).a > 0.5:
				continue
			var best := Palette.CLEAR
			var best_lum := 2.0
			for d in dirs:
				var nx := i + d.x
				var ny := j + d.y
				if nx >= 0 and ny >= 0 and nx < width and ny < height:
					var n := src.get_pixel(nx, ny)
					if n.a > 0.5 and n.get_luminance() < best_lum:
						best_lum = n.get_luminance()
						best = n
			if best.a > 0.5:
				var dark := darken(best, amount)
				image.set_pixel(i, j, dark.lerp(Palette.INK, 0.25))


func _src_opaque(src: Image, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < width and y < height and src.get_pixel(x, y).a > 0.5


func drop_shadow(dx: int, dy: int, c: Color = Palette.SHADOW) -> void:
	var src := image.duplicate() as Image
	for j in height:
		for i in width:
			if src.get_pixel(i, j).a > 0.05:
				continue
			if _src_opaque(src, i - dx, j - dy):
				px(i, j, c)


func blit(other: RefCounted, x: int, y: int) -> void:
	for j in other.height:
		for i in other.width:
			var c: Color = other.image.get_pixel(i, j)
			if c.a > 0.0:
				px(x + i, y + j, c)


func flipped_h() -> RefCounted:
	var out: RefCounted = load(SELF_PATH).create(width, height)
	for j in height:
		for i in width:
			out.image.set_pixel(width - 1 - i, j, image.get_pixel(i, j))
	return out


func scaled(factor: int) -> RefCounted:
	var out: RefCounted = load(SELF_PATH).create(width * factor, height * factor)
	for j in out.height:
		for i in out.width:
			out.image.set_pixel(i, j, image.get_pixel(i / factor, j / factor))
	return out


func save(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
	var err := image.save_png(path)
	if err != OK:
		push_error("Could not save %s (%d)" % [path, err])
