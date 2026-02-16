// NOTE: Shader automatically converted from Godot Engine 4.3.beta's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

//global uniform bool gu_camera_on_sea = false;
//global uniform float gu_camera_under_water = -1;

uniform bool u_camera_on_sea = false;
uniform float u_camera_under_water = -1;

uniform vec4 u_albedo : source_color = vec4(0.11, 0.07, 0.25, 1.0);	// vec4(0.056, 0.119, 0.48, 1.0);
uniform sampler2D u_texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float u_point_size : hint_range(0.1, 128.0, 0.1);

uniform float u_roughness : hint_range(0.0, 1.0);
uniform sampler2D u_texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 u_metallic_texture_channel;
uniform sampler2D u_texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float u_specular : hint_range(0.0, 1.0, 0.01);
uniform float u_metallic : hint_range(0.0, 1.0, 0.01);

uniform vec3 u_uv1_scale;
uniform vec3 u_uv1_offset;
uniform vec3 u_uv2_scale;
uniform vec3 u_uv2_offset;

// Cattura lo schermo dietro la mesh
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float u_speed : hint_range(0.0, 10.0) = 2.0;
uniform float u_distortion_strength : hint_range(0.0, 0.1) = 0.02;

varying vec3 v_world_camera;

void vertex() {
	UV = UV * u_uv1_scale.xy + u_uv1_offset.xy;
	//v_world_camera = MAIN_CAM_INV_VIEW_MATRIX[3].xyz;
	v_world_camera = CAMERA_POSITION_WORLD;
}

void fragment() {
	
	bool under_water = false;

	bool camera_on_sea = u_camera_on_sea;
	float camera_under_water = u_camera_under_water;
	
	if (camera_on_sea) {
		if (camera_under_water < 0.0) {
			if (v_world_camera.y < 0.0) {
				under_water = true;
			}
		} else {
			if (camera_under_water > 0.0) {
				under_water = true;
			}
		}
	}

	if (under_water) {
		vec2 base_uv = UV + u_speed * TIME;

		vec4 albedo_tex = texture(u_texture_albedo, base_uv);
		ALBEDO = u_albedo.rgb * albedo_tex.rgb;

		float metallic_tex = dot(texture(u_texture_metallic, base_uv), u_metallic_texture_channel);
		METALLIC = metallic_tex * u_metallic;
		SPECULAR = u_specular;

		vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
		float roughness_tex = dot(texture(u_texture_roughness, base_uv), roughness_texture_channel);
		ROUGHNESS = roughness_tex * u_roughness;

		ALPHA = 0.8;
	} else {
		ALPHA = 0.0;
		/*vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
		ALBEDO = screen_color.rgb;
		ALPHA = screen_color.a;
		vec4 normal_roughness = texture(NORMAL_ROUGHNESS_TEXTURE, SCREEN_UV);
		NORMAL_MAP = normal_roughness.rgb;
		ROUGHNESS = normal_roughness.a;*/
	}
}
