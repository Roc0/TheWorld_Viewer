shader_type spatial;
render_mode unshaded;

global uniform bool gu_camera_on_sea = false;
global uniform float gu_camera_under_water = -1;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D NORMAL_ROUGHNESS_TEXTURE : hint_normal_roughness_texture, filter_linear_mipmap;

uniform vec3 u_under_water_albedo : source_color = vec3(0.056, 0.119, 0.48);	// vec3(0.119, 0.109, 0.48);

varying vec3 v_world_camera;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);	// Setting POSITION we tell godot to use coord as is and avoid automatic transformation to clip space before passing to the GPU. VERTEX coord are in local space.
	v_world_camera = CAMERA_POSITION_WORLD;
}

void fragment() {
	bool under_water = false;

	if (gu_camera_on_sea) {
		if (gu_camera_under_water < 0.0) {
			if (v_world_camera.y < 0.0) {
				under_water = true;
			}
		} else {
			if (gu_camera_under_water > 0.0) {
				under_water = true;
			}
		}
	}

	if (under_water) {
		//ALBEDO = vec3(0.188, 0.172, 0.758);
		ALBEDO = u_under_water_albedo;
		ALPHA = 0.8;
	} else {
		vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
		ALBEDO = screen_color.rgb;
		ALPHA = screen_color.a;
		vec4 normal_roughness = texture(NORMAL_ROUGHNESS_TEXTURE, SCREEN_UV);
		NORMAL_MAP = normal_roughness.rgb;
		ROUGHNESS = normal_roughness.a;
	}

	/*if (gu_camera_on_sea) {
		ALBEDO = vec3(1.0, 0.0, 0.0);
	} else {
		ALBEDO = vec3(0.0, 1.0, 0.0);
	}
	if (gu_camera_under_water > 0.0) {
		ALBEDO = vec3(1.0, 0.0, 0.0);
	} else {
		ALBEDO = vec3(0.0, 1.0, 0.0);
	}
	if (under_water) {
		ALBEDO = vec3(0.0, 0.0, 1.0);
	} else {
		ALBEDO = vec3(1.0, 0.0, 0.0);
	}
	ALPHA = 0.8;*/
}