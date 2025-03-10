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
uniform vec4 color_deep : source_color = vec4(0.105882, 0.294118, 0.329412, 1.);
uniform vec4 color_shallow : source_color = vec4(0, 0.552941, 0.65098, 1);
uniform float beers_law = 2.0;
uniform float depth_offset = -0.75;
uniform float wave_time = 0.0;
uniform float wave_amplitude : hint_range(0.0, 10.0) = 0.2;
uniform float wave_frequency : hint_range(0.0, 10.0) = 1.0;
uniform float wave_speed : hint_range(0.0, 10.0) = 1.0;
uniform float wave_angle = 0.0;
uniform float clamp_distance = 100.;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

varying float height;
varying vec3 world_pos;

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)),
			   amount);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	height = texture(wave, world_pos.xz / noise_scale + TIME * time_scale).r *
			 height_scale;

	vec2 wave_direction = vec2(cos(wave_angle), sin(wave_angle));
	vec2 pos = world_pos.xz;
	height += sin(dot(pos, wave_direction) * wave_frequency +
				  wave_time * wave_speed) *
			  wave_amplitude;
	float vertex_distance = distance(world_pos, vec3(0.));
	vertex_distance = clamp(vertex_distance, 0, clamp_distance);
	float vertex_distance_clamped = vertex_distance / clamp_distance;
	VERTEX.y = height * (1. - vertex_distance_clamped);
	// Calculate partial derivatives
	float dx = wave_amplitude * wave_frequency *
			   cos(dot(pos, wave_direction) * wave_frequency +
				   wave_time * wave_speed) *
			   wave_direction.x * (1. - vertex_distance_clamped);
	float dz = wave_amplitude * wave_frequency *
			   cos(dot(pos, wave_direction) * wave_frequency +
				   wave_time * wave_speed) *
			   wave_direction.y * (1. - vertex_distance_clamped);

	// Compute the normal
	NORMAL = normalize(vec3(-dx, 1.0, -dz));
}

void fragment() {
	float depth_texture = texture(DEPTH_TEXTURE, SCREEN_UV).r * 2.0 - 1.0;
	float depth =
		PROJECTION_MATRIX[3][2] / (depth_texture + PROJECTION_MATRIX[2][2]);
	float depth_blend = exp((depth + VERTEX.z + depth_offset) * -beers_law);
	depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
	float depth_blend_power = clamp(pow(depth_blend, 2.5), 0.0, 1.0);

	// Retrieving depth color and applying the deep and shallow colors
	vec3 screen_color =
		textureLod(SCREEN_TEXTURE, SCREEN_UV, depth_blend_power * 2.5).rgb;
	vec3 depth_color =
		mix(color_shallow.rgb, color_deep.rgb, depth_blend_power);
	vec3 color = mix(screen_color * depth_color, depth_color * 0.25,
					 depth_blend_power * 0.5);

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
}
