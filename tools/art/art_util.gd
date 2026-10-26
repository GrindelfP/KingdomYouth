extends RefCounted

const Canvas := preload("res://tools/art/pixel_canvas.gd")

const SPRING := 0
const SUMMER := 1
const AUTUMN := 2
const WINTER := 3


static func pnoise(x: float, y: float, cells: int, size: int, seed_value: int) -> float:
	var fx := x / size * cells
	var fy := y / size * cells
	var ix := int(floor(fx))
	var iy := int(floor(fy))
	var tx := fx - ix
	var ty := fy - iy
	tx = tx * tx * (3.0 - 2.0 * tx)
	ty = ty * ty * (3.0 - 2.0 * ty)
	var x0 := posmod(ix, cells)
	var x1 := posmod(ix + 1, cells)
	var y0 := posmod(iy, cells)
	var y1 := posmod(iy + 1, cells)
	var a := Canvas.hash01(x0, y0, seed_value)
	var b := Canvas.hash01(x1, y0, seed_value)
	var c := Canvas.hash01(x0, y1, seed_value)
	var d := Canvas.hash01(x1, y1, seed_value)
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), ty)


static func fbm(x: float, y: float, size: int, seed_value: int, big: int = 3, small: int = 8) -> float:
	return pnoise(x, y, big, size, seed_value) * 0.6 + pnoise(x, y, small, size, seed_value + 5) * 0.4


static func dither_index(n: float, steps: int, i: int, j: int, sharp: bool = true) -> int:
	var t := clampf(n, 0.0, 0.999) * (steps - 1)
	var lo := int(floor(t))
	var frac := t - lo
	if sharp:
		frac = smoothstep(0.3, 0.7, frac)
	var threshold := (Canvas.BAYER[(j % 4) * 4 + (i % 4)] + 0.5) / 16.0
	return lo + (1 if frac > threshold else 0)


static func edge_calm(i: int, j: int, size: int, margin: float, floor_value: float) -> float:
	var d := minf(minf(i, j), minf(size - 1 - i, size - 1 - j))
	return lerpf(floor_value, 1.0, clampf(d / margin, 0.0, 1.0))
