shader_type spatial;

uniform vec3 albedo1 : source_color = vec3(0., 0.321569, 0.431373);
uniform vec3 albedo2 : source_color = vec3(0., 0.47451, 0.764706);
uniform float metallic : hint_range(0.0, 1.0) = 0;
uniform float roughness : hint_range(0.0, 1.0) = 0.02;
uniform float fresnel_amount : hint_range(0.0, 20.0) = 5.0;
uniform sampler2D wave;
uniform sampler2D texture_normal1;
uniform sampler2D texture_normal2;
uniform vec2 wave_direction1 = vec2(2.0, 0.0);
uniform vec2 wave_direction2 = vec2(0.0, 1.0);
uniform float time_scale : hint_range(0.0, 0.2, 0.005) = 0.025;
uniform float noise_scale = 10;
uniform float height_scale = 0.15;
uniform float beers_law = 2.0;
uniform float depth_offset = -0.75;
uniform float wave_time = 0.0;
uniform float clamp_distance = 100.;
uniform vec3 clamp_center = vec3(0., 0., 0.);

group_uniforms depth;
uniform vec4 color_deep : source_color = vec4(0.105882, 0.294118, 0.329412, 1.);
uniform vec4 color_shallow : source_color = vec4(0, 0.552941, 0.65098, 1);
uniform sampler2D depth_texture : hint_depth_texture;
uniform float depth_factor : hint_range(1., 50, 0.1) = 9.;

group_uniforms wave1;
uniform float angle1 = 0.0;
uniform float stepness1 : hint_range(0.0, 1.0) = 0.3;
uniform float wavelength1 = 40.;

group_uniforms wave2;
uniform float angle2 = 1.81;
uniform float stepness2 : hint_range(0.0, 1.0) = 0.25;
uniform float wavelength2 = 20.;

group_uniforms wave3;
uniform float angle3 = 0.9;
uniform float stepness3 : hint_range(0.0, 1.0) = 0.15;
uniform float wavelength3 = 10.;

varying vec3 world_pos;

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)),
			   amount);
}

// from https://catlikecoding.com/unity/tutorials/flow/waves/
vec3 gerstnerWave(float angle, float stepness, float wavelength, vec2 p,
				  float time, inout vec3 tangent, inout vec3 binormal) {
	float k = TAU / wavelength;
	float c = sqrt(9.81 / k);
	vec2 d = vec2(cos(angle), sin(angle));
	float f = k * (dot(d, p) - c * time);
	float a = stepness / k;
	// Compute the normal
	tangent += vec3(1. - d.x * d.x * stepness * sin(f), stepness * cos(f),
					-d.x * d.y * stepness * sin(f));
	binormal += vec3(-d.x * d.y * stepness * sin(f), d.y * stepness * sin(f),
					 1. - d.y * d.y * stepness * sin(f));

	return vec3(d.x * a * cos(f), a * sin(f), d.y * a * cos(f));
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	float vertex_distance = distance(world_pos, clamp_center);
	vertex_distance = clamp(vertex_distance, 0, clamp_distance);
	float vertex_distance_clamped = vertex_distance / clamp_distance;

	vec3 tangent = vec3(1., 0., 0.);
	vec3 binormal = vec3(0., 0., 1.);
	vec3 offset = vec3(0.);
	offset += gerstnerWave(angle1, stepness1, wavelength1, world_pos.xz,
						   wave_time, tangent, binormal);
	offset += gerstnerWave(angle2, stepness2, wavelength2, world_pos.xz,
						   wave_time, tangent, binormal);
	offset += gerstnerWave(angle3, stepness3, wavelength3, world_pos.xz,
						   wave_time, tangent, binormal);

	offset.y +=
		texture(wave, world_pos.xz / noise_scale + TIME * time_scale).r *
			height_scale -
		height_scale / 2.;

	VERTEX += offset * (1. - vertex_distance_clamped);
	NORMAL = mix(NORMAL, normalize(cross(binormal, tangent)),
				 1. - vertex_distance_clamped);
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).x;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	depth = depth * 2. - 1.;
#endif
	depth = PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]);
	depth += VERTEX.z;
	depth = clamp(depth / depth_factor, 0., 1.);

	vec3 color = mix(color_shallow.rgb, color_deep.rgb, depth);

	vec2 time1 = (TIME * wave_direction1) * time_scale;
	vec2 time2 = (TIME * wave_direction2) * time_scale;
	vec3 normal_blend = mix(
		texture(texture_normal1, world_pos.xz / noise_scale + time1).rgb,
		texture(texture_normal2, world_pos.xz / noise_scale + time2).rgb, 0.5);

	float fresnel = fresnel(fresnel_amount, NORMAL, VIEW);
	vec3 surface_color = mix(albedo1, albedo2, fresnel);

	ALBEDO = mix(surface_color, color, 0.75);
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal_blend;
	ALPHA = mix(0.6, 0.95, depth);
}
