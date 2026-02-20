// NOTE: Shader automatically converted from Godot Engine 4.3.beta's StandardMaterial3D.

shader_type spatial;
render_mode unshaded;

//global uniform bool gu_camera_on_sea = false;
//global uniform float gu_camera_under_water = -1;

uniform bool u_camera_on_sea = false;
uniform float u_camera_under_water = -1;

uniform vec4 u_albedo : source_color = vec4(0.01, 0.01, 0.958, 1);
uniform float u_color_intensity = 3.0;
uniform vec3 u_uv1_scale = vec3(0, 0, 0);
uniform vec3 u_uv1_offset = vec3(0, 0, 0);

// Cattura lo schermo dietro la mesh
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D u_noise_distorsion : repeat_enable;
uniform vec2 u_distortion_speed = vec2(0.2, 0.1);
uniform float u_distortion_strength : hint_range(0.0, 0.1) = 0.16;
uniform float u_wave_strength = 3;

void vertex() {
}

void fragment() {
	
	bool under_water = false;

	bool camera_on_sea = u_camera_on_sea;
	float camera_under_water = u_camera_under_water;
	
	if (camera_on_sea && camera_under_water > 0.0) {
		under_water = true;
	}

	if (under_water) {
		vec2 noise_uv = UV + u_distortion_speed * TIME;
		vec2 noise = textureLod(u_noise_distorsion, noise_uv, 0).rg;
		noise -= 0.5;
		//float rad = TIME / 1000.0;
		//vec2 effect = vec2(sin(rad * u_distortion_speed.x), cos(rad * u_distortion_speed.y));
		float rad = (TIME * PI) / 30.0;
		vec2 effect = vec2(sin(rad), cos(rad));
		noise *= effect;
		vec4 screen_color = vec4(u_albedo.r, u_albedo.g, u_albedo.b, 1); // + vec4(noise.x * u_distortion_strength, noise.y * u_distortion_strength, noise.x * u_distortion_strength, 1);
		screen_color.rgb *= textureLod(screen_texture, SCREEN_UV + noise * (u_wave_strength / 80.0), 0).rgb;
		screen_color.rgb *= u_color_intensity;
		ALBEDO = screen_color.rgb;
		ALPHA = 0.8;
	} else {
		ALPHA = 0.0;
	}
}
