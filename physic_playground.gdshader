shader_type spatial;

varying vec3 world_pos;

void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }

void fragment() {
	vec2 test = fract(world_pos.xz / 4.) * 2.;
	if ((test.x < 0.1) || (test.y < 0.1)) {
		ALBEDO = vec3(1., 0., 0.);
	} else {
		ALBEDO = vec3(1., 1., 1.);
	}
	ALPHA = 0.7;
}
