extends RefCounted

const Canvas := preload("res://tools/art/pixel_canvas.gd")
const Palette := preload("res://tools/art/palette.gd")

const OUT_DIR := "res://assets/art/settlers"
const CELL_W := 16
const CELL_H := 20
const OX := 2
const OY := 3
const FRAMES := 14
const PROFESSIONS: Array[String] = ["laborer", "builder", "farmer", "forester", "gatherer", "hunter", "fisher", "quarryman", "miner", "woodcutter", "blacksmith"]
const STAGES := 3
const HAIR_VARIANTS := 3
const DOWN := 0
const UP := 1
const SIDE := 2

static var _styles: Dictionary = {}


static func generate() -> void:
	_init_styles()
	var rows := HAIR_VARIANTS * STAGES * 2 * PROFESSIONS.size()
	var sheet := Canvas.create(CELL_W * FRAMES, CELL_H * rows, 1)
	for hair in HAIR_VARIANTS:
		for stage in STAGES:
			for sex in 2:
				for prof in PROFESSIONS.size():
					var row := ((hair * STAGES + stage) * 2 + sex) * PROFESSIONS.size() + prof
					for frame in FRAMES:
						sheet.blit(_cell(hair, stage, sex, prof, frame), frame * CELL_W, row * CELL_H)
	sheet.save("%s/settlers.png" % OUT_DIR)
	_carry_icons()


static func _init_styles() -> void:
	var W := Palette.WOOD
	var S := Palette.STRAW
	_styles = {
		"laborer": {"r": [W[0], W[1], W[2], W[3]], "pants": Palette.DIRT[1]},
		"builder": {"r": [Palette.FIRE[0], Palette.FIRE[0], Palette.FIRE[1], Palette.FIRE[2]], "pants": Palette.DIRT[1], "hat": "hardhat"},
		"farmer": {"r": [S[0], S[1], S[2], S[3]], "pants": Palette.DIRT[1], "hat": "straw"},
		"forester": {"r": [Palette.LEAF_DEEP[0], Palette.LEAF_DEEP[1], Palette.LEAF_DEEP[2], Palette.LEAF_DEEP[3]], "pants": Palette.DIRT[0]},
		"gatherer": {"r": [Palette.BERRY[0], Palette.BERRY[1], Palette.BERRY[2], Palette.BERRY[3]], "pants": Palette.DIRT[1], "kerchief": true},
		"hunter": {"r": [Palette.DIRT[1], Palette.DIRT[2], Palette.SAND[0], Palette.SAND[1]], "pants": Palette.DIRT[0], "hat": "cap"},
		"fisher": {"r": [Palette.FISH[0], Palette.FISH[0], Palette.FISH[1], Palette.FISH[2]], "pants": Palette.SLATE[0], "hat": "wool"},
		"quarryman": {"r": [Palette.STONE[0], Palette.STONE[1], Palette.STONE[2], Palette.STONE[3]], "pants": Palette.DIRT[1], "scarf": true},
		"miner": {"r": [Palette.STEEL[0], Palette.STEEL[0], Palette.STEEL[1], Palette.STEEL[2]], "pants": Palette.INK, "hat": "helmet"},
		"woodcutter": {"r": [Palette.ROOF_RED[0], Palette.ROOF_RED[0], Palette.ROOF_RED[1], Palette.ROOF_RED[2]], "pants": Palette.DIRT[0], "plaid": true},
		"blacksmith": {"r": [Palette.INK, Palette.SLATE[0], Palette.SLATE[0], Palette.SLATE[1]], "pants": Palette.STEEL[0], "apron": true, "bare_arms": true},
	}


static func _hair_ramp(hair: int, stage: int) -> Array:
	if stage == 2:
		return [Palette.STONE[3], Palette.STONE[4]]
	match hair:
		0:
			return [Palette.WOOD[0], Palette.WOOD[1]]
		1:
			return [Palette.WOOD[2], Palette.WOOD[3]]
	return [Palette.STRAW[1], Palette.STRAW[2]]


static func _cell(hair: int, stage: int, sex: int, prof: int, frame: int) -> RefCounted:
	var c := Canvas.create(CELL_W, CELL_H, 100 + frame)
	var facing := DOWN
	var phase := 1
	var work := -1
	if frame < 12:
		facing = frame / 4
		phase = frame % 4
	else:
		work = frame - 12
	var style: Dictionary = _styles[PROFESSIONS[prof]]
	_person(c, style, hair, stage, sex, facing, phase, work)
	c.outline_dark()
	c.drop_shadow(1, 1)
	return c


static func _p(c: RefCounted, x: int, y: int, color: Color) -> void:
	c.px(x + OX, y + OY, color)


static func _r(c: RefCounted, x: int, y: int, w: int, h: int, color: Color) -> void:
	c.rect(x + OX, y + OY, w, h, color)


static func _person(c: RefCounted, style: Dictionary, hair: int, stage: int, sex: int, facing: int, phase: int, work: int) -> void:
	var r: Array = style["r"]
	var hr := _hair_ramp(hair, stage)
	var hy := 1
	var ty := 6
	var th := 5
	if stage == 0:
		hy = 5
		ty = 10
		th = 3
	elif stage == 2:
		hy = 2
		ty = 7
		th = 4
	var bob := -1 if (phase == 1 or phase == 3) and work < 0 else 0
	if work == 1:
		bob = 1
	var ls := ty + th + bob
	hy += bob
	ty += bob
	_legs(c, style, sex, facing, phase, ls, work)
	_torso(c, style, r, sex, facing, ty, ls, stage, phase, work)
	_head(c, style, hr, sex, facing, hy, ty, stage)
	if work >= 0:
		_tool(c, ty, work)
	if stage == 2:
		_staff(c, facing, ty)


static func _legs(c: RefCounted, style: Dictionary, sex: int, facing: int, phase: int, ls: int, work: int) -> void:
	var pants: Color = style["pants"]
	var boot: Color = Palette.WOOD[0]
	var bottom := 14
	var lo := mini(ls + 2, bottom)
	if facing != SIDE:
		var left_end := bottom - 1 if phase == 0 else bottom
		var right_end := bottom - 1 if phase == 2 else bottom
		if sex == 0:
			_r(c, 4, ls, 2, left_end - ls + 1, pants)
			_r(c, 6, ls, 2, right_end - ls + 1, pants)
			_p(c, 5, ls + 1, Canvas.darken(pants, 0.25))
			_p(c, 7, ls + 1, Canvas.darken(pants, 0.25))
			_r(c, 4, left_end, 2, 1, boot)
			_r(c, 6, right_end, 2, 1, boot)
		else:
			if left_end >= lo:
				_r(c, 4, lo, 2, left_end - lo + 1, boot)
			if right_end >= lo:
				_r(c, 6, lo, 2, right_end - lo + 1, boot)
		return
	var near_x := 5
	var far_x := 5
	var near_end := bottom
	var far_end := bottom
	if phase == 0:
		near_x = 6
		far_x = 3
	elif phase == 2:
		near_x = 3
		far_x = 6
	elif phase == 1:
		far_end = bottom - 1
	elif phase == 3:
		near_end = bottom - 1
	var far_color: Color = Canvas.darken(pants, 0.3)
	if sex == 0:
		_r(c, far_x, ls, 2, far_end - ls + 1, far_color)
		_r(c, far_x, far_end, 2, 1, Canvas.darken(boot, 0.0))
		_r(c, near_x, ls, 2, near_end - ls + 1, pants)
		_r(c, near_x, near_end, 2, 1, boot)
		if phase == 0 or phase == 2:
			_p(c, near_x + (1 if near_x > 5 else -1), near_end, boot)
			_p(c, far_x + (-1 if far_x < 5 else 1), far_end, boot)
	else:
		if far_end >= lo:
			_r(c, far_x, lo, 2, far_end - lo + 1, boot)
		if near_end >= lo:
			_r(c, near_x, lo, 2, near_end - lo + 1, boot)


static func _torso(c: RefCounted, style: Dictionary, r: Array, sex: int, facing: int, ty: int, ls: int, stage: int, phase: int, work: int) -> void:
	var x0 := 3
	var x1 := 8
	if facing == SIDE:
		x0 = 4
		x1 = 7
	var bottom := ls - 1
	var skirt_end := ls + 1
	if sex == 1:
		bottom = skirt_end
	var plaid: bool = style.get("plaid", false)
	for y in range(ty, bottom + 1):
		for x in range(x0, x1 + 1):
			var col: Color = r[2]
			if y == ty:
				col = r[3] if x < x1 else r[2]
			elif x == x1 and facing != SIDE:
				col = r[1]
			elif y >= ls and sex == 1:
				col = r[1]
			elif y == bottom:
				col = r[1]
			if plaid and (x + y) % 2 == 0 and y > ty:
				col = r[0]
			_p(c, x, y, col)
	if sex == 1:
		for y in range(ls, skirt_end + 1):
			var sx0 := x0 - 1 if y > ls else x0
			var sx1 := x1 + 1 if y > ls else x1
			for x in range(sx0, sx1 + 1):
				var col: Color = r[2] if y == ls else r[1]
				if y == skirt_end:
					col = r[0] if (x + y) % 2 == 0 else r[1]
				if plaid and (x + y) % 2 == 0:
					col = r[0]
				_p(c, x, y, col)
	var belt_y := ls - 1
	if sex == 1:
		belt_y = ty + (th_for(stage) - 2)
	if belt_y > ty and belt_y < ty + 6:
		for x in range(x0, x1 + 1):
			_p(c, x, belt_y, Palette.WOOD[1])
		if facing == DOWN:
			_p(c, 5, belt_y, Palette.STRAW[2])
	if style.get("apron", false) and facing != UP:
		var ax0 := 4 if facing == DOWN else 6
		var ax1 := 7
		for y in range(ty + 1, ls + 1 + (1 if sex == 1 else 0)):
			for x in range(ax0, ax1 + 1):
				_p(c, x, y, Palette.WOOD[2] if x < ax1 else Palette.WOOD[1])
		_p(c, ax0, ty + 1, Palette.WOOD[3])
	_arms(c, style, r, facing, ty, stage, phase, work)
	if style.get("scarf", false):
		var sy := ty
		for x in range(x0, x1 + 1):
			_p(c, x, sy, Palette.CREAM[1] if x < x1 else Palette.CREAM[0])
	if style.get("kerchief", false) and facing == DOWN:
		_p(c, 5, ty, Palette.CREAM[2])
		_p(c, 6, ty, Palette.CREAM[1])


static func th_for(stage: int) -> int:
	return [3, 5, 4][stage]


static func _arms(c: RefCounted, style: Dictionary, r: Array, facing: int, ty: int, stage: int, phase: int, work: int) -> void:
	var sleeve: Color = r[1]
	var hand: Color = Palette.SKIN[1]
	if style.get("bare_arms", false):
		sleeve = Palette.SKIN[1]
	var length := 3 if stage != 0 else 2
	var top := ty + 1
	if facing != SIDE:
		var left_len := length
		var right_len := length
		if phase == 0:
			left_len = length - 1
			right_len = length + 1
		elif phase == 2:
			left_len = length + 1
			right_len = length - 1
		if work >= 0:
			right_len = 1
		for y in range(top, top + left_len):
			_p(c, 2, y, sleeve if y < top + left_len - 1 else hand)
		for y in range(top, top + right_len):
			_p(c, 9, y, sleeve if y < top + right_len - 1 or work >= 0 else hand)
		if work >= 0:
			_p(c, 9, top + right_len - 1, hand)
		return
	var ax := 5
	if phase == 0:
		ax = 7
	elif phase == 2:
		ax = 3
	for y in range(top, top + length):
		_p(c, ax, y, r[3] if y == top else sleeve)
	_p(c, ax, top + length - 1, hand)
	_p(c, ax + 1 if ax < 7 else ax, top, r[2])


static func _head(c: RefCounted, style: Dictionary, hr: Array, sex: int, facing: int, hy: int, ty: int, stage: int) -> void:
	var skin := Palette.SKIN
	var hl: Color = hr[0]
	var hh: Color = hr[1]
	var shift := 0
	if stage == 2 and facing == SIDE:
		shift = 1
	if facing == SIDE:
		_r(c, 4 + shift, hy, 5, 5, skin[2])
		_r(c, 4 + shift, hy + 4, 5, 1, skin[1])
		_r(c, 8 + shift, hy + 2, 1, 3, skin[1])
		_r(c, 4 + shift, hy, 5, 2, hl)
		_r(c, 4 + shift, hy + 2, 2, 2, hl)
		_p(c, 4 + shift, hy, hh)
		_p(c, 5 + shift, hy, hh)
		_p(c, 6 + shift, hy, hh)
		_p(c, 7 + shift, hy + 2, Palette.INK)
		_p(c, 8 + shift, hy + 2, hl)
		_p(c, 9 + shift, hy + 3, skin[1])
		_p(c, 5 + shift, hy + 1, hh)
		if sex == 1:
			var end_y := ty + 2
			for y in range(hy + 2, end_y + 1):
				_r(c, 3 + shift, y, 2, 1, hl)
			_p(c, 3 + shift, end_y, hh)
		if stage == 2 and sex == 0:
			_r(c, 6 + shift, hy + 4, 3, 1, Palette.STONE[4])
		if stage == 2 and sex == 1:
			_r(c, 3 + shift, hy - 1, 3, 2, hh)
		_hat(c, style, facing, hy, shift)
		return
	_r(c, 3, hy, 6, 5, skin[2])
	_r(c, 3, hy + 4, 6, 1, skin[1])
	_r(c, 8, hy + 2, 1, 3, skin[1])
	if facing == UP:
		_r(c, 3, hy, 6, 4, hl)
		_r(c, 3, hy, 5, 1, hh)
		_p(c, 3, hy + 1, hh)
		_r(c, 4, hy + 4, 4, 1, skin[1])
		if sex == 1:
			for y in range(hy + 4, ty + 3):
				_r(c, 3, y, 6, 1, hl)
			_p(c, 4, ty + 1, hh)
		if stage == 2 and sex == 1:
			_r(c, 4, hy - 1, 4, 2, hh)
			_p(c, 4, hy - 1, Palette.STONE[3])
		_hat(c, style, facing, hy, 0)
		return
	_r(c, 3, hy, 6, 2, hl)
	_r(c, 3, hy, 5, 1, hh)
	_p(c, 3, hy + 1, hh)
	_p(c, 3, hy + 2, hl)
	_p(c, 8, hy + 2, hl)
	_p(c, 4, hy + 3, Palette.INK)
	_p(c, 7, hy + 3, Palette.INK)
	_p(c, 3, hy + 4, skin[2])
	if sex == 1:
		for y in range(hy + 3, ty + 3):
			_p(c, 2 if y > hy + 3 else 3, y, hl)
			_p(c, 9 if y > hy + 3 else 8, y, hl)
		_p(c, 3, hy + 3, hl)
		_p(c, 8, hy + 3, hl)
		_p(c, 3, hy + 3, hh)
	if stage == 2:
		if sex == 0:
			_r(c, 4, hy + 4, 4, 1, Palette.STONE[4])
			_p(c, 5, hy + 4, Palette.STONE[3])
		else:
			_r(c, 4, hy - 1, 4, 2, hh)
			_p(c, 4, hy - 1, Palette.STONE[3])
	if stage == 0 and sex == 1:
		_p(c, 3, hy - 1, Palette.FIRE[0])
		_p(c, 4, hy - 1, Palette.FIRE[1])
		_p(c, 3, hy, Palette.FIRE[1])
	_hat(c, style, facing, hy, 0)


static func _hat(c: RefCounted, style: Dictionary, facing: int, hy: int, dx: int) -> void:
	var kind: String = style.get("hat", "")
	if kind == "":
		return
	var side := facing == SIDE
	match kind:
		"straw":
			_r(c, 2 + dx, hy, 8, 1, Palette.STRAW[2])
			_r(c, 4 + dx, hy - 1, 4, 1, Palette.STRAW[3])
			_r(c, 4 + dx, hy, 4, 1, Palette.STRAW[1])
			_r(c, 2 + dx, hy + 1, 8, 1, Palette.STRAW[1])
			_p(c, 2 + dx, hy, Palette.STRAW[3])
			_p(c, 9 + dx, hy + 1, Palette.STRAW[0])
		"hardhat":
			_r(c, 3 + dx, hy - 1, 6, 2, Palette.CREAM[2])
			_r(c, 2 + dx, hy + 1, 8, 1, Palette.CREAM[1])
			_r(c, 3 + dx, hy - 1, 3, 1, Palette.CREAM[3])
			_p(c, 8 + dx, hy, Palette.CREAM[1])
		"cap":
			_r(c, 3 + dx, hy - 1, 6, 2, Palette.GRASS[1])
			_r(c, 3 + dx, hy - 1, 3, 1, Palette.GRASS[2])
			_r(c, 3 + dx, hy + 1, 6, 1, Palette.GRASS[0])
			_p(c, 8 + dx, hy - 2, Palette.MEAT[2])
			_p(c, 9 + dx, hy - 3, Palette.MEAT[3])
			_p(c, 9 + dx, hy - 2, Palette.MEAT[1])
		"wool":
			_r(c, 3 + dx, hy - 1, 6, 2, Palette.FISH[1])
			_r(c, 3 + dx, hy - 1, 3, 1, Palette.FISH[2])
			_r(c, 3 + dx, hy + 1, 6, 1, Palette.CREAM[1])
			_p(c, 5 + dx, hy - 2, Palette.FISH[2])
			_p(c, 6 + dx, hy - 2, Palette.FISH[1])
		"helmet":
			_r(c, 3 + dx, hy - 1, 6, 2, Palette.STEEL[2])
			_r(c, 3 + dx, hy - 1, 3, 1, Palette.STEEL[3])
			_r(c, 2 + dx, hy + 1, 8, 1, Palette.STEEL[1])
			if facing == DOWN:
				_p(c, 5 + dx, hy - 1, Palette.FIRE[3])
				_p(c, 6 + dx, hy - 1, Palette.FIRE[2])
			elif side:
				_p(c, 8 + dx, hy - 1, Palette.FIRE[3])


static func _staff(c: RefCounted, facing: int, ty: int) -> void:
	var x := 10 if facing != SIDE else 9
	for y in range(ty + 2, 15):
		_p(c, x, y, Palette.WOOD[3])
	_p(c, x, ty + 1, Palette.WOOD[4])
	_p(c, x, 14, Palette.WOOD[1])


static func _tool(c: RefCounted, ty: int, work: int) -> void:
	if work == 0:
		for y in range(ty - 3, ty + 2):
			_p(c, 10, y, Palette.WOOD[3])
		_p(c, 10, ty - 4, Palette.STEEL[3])
		_p(c, 11, ty - 4, Palette.STEEL[2])
		_p(c, 11, ty - 3, Palette.STEEL[1])
		_p(c, 9, ty - 4, Palette.STEEL[2])
	else:
		for k in 5:
			_p(c, 10 if k < 3 else 11, ty + k, Palette.WOOD[3])
		_p(c, 10, ty + 5, Palette.STEEL[3])
		_p(c, 11, ty + 5, Palette.STEEL[2])
		_p(c, 11, ty + 6, Palette.STEEL[1])
		_p(c, 10, ty + 6, Palette.STEEL[2])


static func _carry_icons() -> void:
	var dir := ProjectSettings.globalize_path("res://assets/art/icons")
	for file in DirAccess.get_files_at(dir):
		if not file.ends_with(".png"):
			continue
		var id := file.get_basename()
		if id == "food":
			continue
		var src := Image.load_from_file("%s/%s" % [dir, file])
		src.convert(Image.FORMAT_RGBA8)
		var mini := Canvas.create(10, 10, hash(id))
		for j in 8:
			for i in 8:
				mini.px(i + 1, j + 1, _block_color(src, i * 2, j * 2))
		mini.outline_dark()
		mini.save("%s/carry_%s.png" % [OUT_DIR, id])


static func _block_color(src: Image, x: int, y: int) -> Color:
	var best := Palette.CLEAR
	var best_score := -1.0
	var opaque := 0
	for dy in 2:
		for dx in 2:
			var c := src.get_pixel(x + dx, y + dy)
			if c.a > 0.5:
				opaque += 1
	if opaque < 2:
		return best
	for dy in 2:
		for dx in 2:
			var c := src.get_pixel(x + dx, y + dy)
			if c.a < 0.5:
				continue
			var score := c.get_luminance() + c.s * 0.6
			if score > best_score:
				best_score = score
				best = c
	return best
