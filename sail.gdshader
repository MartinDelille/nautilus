shader_type spatial;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,
								   filter_linear_mipmap,
								   repeat_enable;

uniform vec2 offset = vec2(0., 0.);
uniform vec2 scale = vec2(1., 1);

void vertex() {
	UV = vec2((offset.x + UV.x) * scale.x, 1. - (offset.y + UV.y) * scale.y);
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
}
