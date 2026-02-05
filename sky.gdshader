shader_type sky;

uniform vec3 skyColor : source_color = vec3(0., 0., 1.);
uniform vec3 horizonColor : source_color = vec3(0.5, 0.5, 0.5);
uniform vec3 cloudColor : source_color = vec3(1., 1., 1.);
uniform sampler2D cloudNoise1;
uniform sampler2D cloudNoise2;
uniform float a = 1.;
uniform float b = 1.;
uniform float c = 1.;
uniform vec2 cloud_direction1 = vec2(0., 0.);
uniform vec2 cloud_direction2 = vec2(1., 2.);
uniform float cloud_speed = 1.;
uniform vec2 cloud_scale = vec2(1., 1.);
uniform float cloud_distance = 0.;

// Sun Stuff
uniform vec3 sun_color : source_color = vec3(1.0, 0.95, 0.85);
uniform float sun_size : hint_range(0.00001, 1.0) = 0.1;
// uniform float sun_blur : hint_range(0.01, 1.0) = 0.01;
uniform float sun_softness : hint_range(0.001, 1.0) = 0.15;

void sky() {
	float clamped_y = clamp(EYEDIR.y, 0., 1.);
	vec3 color = mix(horizonColor, skyColor, clamped_y);
	float cloudFactor = clamp(EYEDIR.y * a - b, 0., 1);
	vec3 cloud = texture(cloudNoise1, EYEDIR.xz / clamped_y * cloud_scale.x +
										  cloud_direction1 * TIME * cloud_speed)
					 .rgb -
				 texture(cloudNoise2, EYEDIR.xz / clamped_y * cloud_scale.y +
										  cloud_direction2 * TIME * cloud_speed)
					 .rgb;
	cloud = cloud - smoothstep(0., EYEDIR.y, cloud_distance);
	cloud = clamp(cloud, 0., 1.);
	// color += cloud;

	/* ---------- SUN 1---------- */
	// float sun_distance = distance(EYEDIR.xyz, LIGHT0_DIRECTION);
	// float sun_power = 1.0 - clamp(sun_distance / sun_size, 0.0, 1.0);
	// float sun_disc = clamp(sun_power / sun_blur, sun_power, 1.0);
	// vec3 sun = sun_color * sun_disc;

	//	color += sun;

	/* ---------- SUN 2---------- */
	float sun_dot = dot(EYEDIR, normalize(LIGHT0_DIRECTION));
	float sun_mask = smoothstep(1.0 - sun_size, 1.0, sun_dot);
	float sun_glow = smoothstep(1.0 - sun_size - sun_softness, 1.0, sun_dot);

	// color += sun_color * sun_glow * 1.5;
	// color = mix(color, sun_color, sun_mask);

	COLOR = color;
}
