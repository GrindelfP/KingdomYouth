shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE;
	float near = 0.0;
	for (int i = -2; i <= 2; i++) {
		for (int j = -2; j <= 2; j++) {
			if (abs(i) + abs(j) <= 2 && (i != 0 || j != 0)) {
				near = max(near, texture(TEXTURE, UV + vec2(float(i), float(j)) * px).a);
			}
		}
	}
	if (base.a < 0.5 && near > 0.5) {
		COLOR = outline_color;
	} else {
		COLOR = base;
	}
}
