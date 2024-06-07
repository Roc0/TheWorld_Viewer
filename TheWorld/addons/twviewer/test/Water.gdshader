shader_type spatial;

global uniform bool gu_show_chunks = false;
global uniform float gu_camera_altitude_from_terrain;
global uniform sampler2D gu_sea_wave;
global uniform sampler2D gu_sea_texture_normal;
global uniform sampler2D gu_sea_texture_normal2;
global uniform sampler2D gu_water_foam;
global uniform sampler2D gu_water_foam_1;

uniform float u_terrain_height = 1.0;	// NOTSET
uniform sampler2D u_terrain_heightmap;
uniform uint u_optimization_level = 0;
uniform float u_grid_step = 2.0;
uniform float u_editmode_selected = 0;
uniform bool u_grid_on = false;
uniform float u_quad_border_line_thickness = 0.005;
uniform float u_mouse_hit_radius = 0.0010000000475;
uniform uint u_num_vertices_per_chunk;
uniform vec2 u_mouse_hit = vec2(-1.000000, -1.000000);
uniform mat4 u_terrain_inverse_transform;
uniform float u_quadrant_size = 4096.0;

uniform float u_max_altitude_for_time_scale_factor = 5000.0;	// NOTSET

uniform float u_foam_test_distance = 10.00000;	// NOTSET
uniform float u_foam_camera_depth_threshold = 1.0;	// 0.4;
uniform float u_foam_edge_pattern_scale = 1.0;

const vec3 lod_colors[10] = {
	vec3(1.0, 0.749, 0.0),		// GDN_TheWorld_Globals::g_color_yellow_apricot
	vec3(0.498, 1.0, 0.831),	// GDN_TheWorld_Globals::g_color_aquamarine_green
	vec3(0.0, 1.0, 0.0),		// GDN_TheWorld_Globals::g_color_green
	vec3(0.0, 1.0, 1.0),		// GDN_TheWorld_Globals::g_color_cyan
	vec3(0.980, 0.592, 0.447),	// GDN_TheWorld_Globals::g_color_red_salmon
	vec3(0.0, 0.0, 1.0),		// GDN_TheWorld_Globals::g_color_blue
	vec3(0.623, 0.168, 0.408),	// GDN_TheWorld_Globals::g_color_pink_amaranth
	vec3(0.561, 0.737, 0.561),	// GDN_TheWorld_Globals::g_color_darksea_green
	vec3(1.0, 0.0, 0.0),		// GDN_TheWorld_Globals::g_color_red
	vec3(0.0, 0.0, 0.0)		// GDN_TheWorld_Globals::g_color_black
};

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec3 sea_color : source_color = vec3(0.10, 0.19, 0.32);	// vec3(0.0, 0.03, 0.34);		// vec3(0.0, 0.19, 0.46);		// vec3(0.0, 0.32, 0.43);
uniform vec3 sea_color2 : source_color = vec3(0.25, 0.32, 0.43);	// vec3(0.25, 0.32, 0.43);	// vec3(1.0, 1.0, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.8;
uniform float roughness : hint_range(0.0, 1.0) = 0.02;
//uniform sampler2D wave;
//uniform sampler2D texture_normal;
//uniform sampler2D texture_normal2;
uniform vec2 wave_direction = vec2(2.0,0.0); // Direction of wave 1
uniform vec2 wave_direction2 = vec2(0.0,1.0); // Direction of wave 2
uniform float time_scale : hint_range(0.0, 0.2, 0.0005) = 0.0005; // *** Rate of movement multiplied by TIME
uniform float rough_sea_factor : hint_range(0.0, 20.0, 1.0) = 10.0;	// ***
uniform float noise_scale = 1000.0;		// ***
uniform float height_scale = 4.0;		// *** -15 / +15

//uniform vec4 color_deep : source_color = vec4(0.10, 0.29, 0.32, 1.0); // Deep depth color
uniform vec4 color_shallow : source_color = vec4(1.0, 1.0, 1.0, 1.0);	// vec4(0.55, 0.55, 0.55, 1.0); // Shallow depth color
//uniform float beers_law = 2.0; // Beer's law application
//uniform float depth_offset = -0.75; // Offset

//uniform float edge_scale = 0.1;
//uniform float near = 1.0;
//uniform float far = 20000.0;
//uniform vec3 edge_color : source_color = vec3(1.0, 1.0, 1.0);

// Varying variables
varying vec3 v_world_pos;
varying float v_lod;
varying float v_sea_depth;
//varying float v_fog_coord;

#include "res://addons/twviewer/shaders/include/CommonFunctions.gdshaderinc"

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

/*float edge(float depth)
{
	depth = 2.0 * depth - 1.0;
	return near * far / (far + depth * (near - far));
}*/

void vertex() {
	// VERTEX coords are local to the chunk (as the material is applied to the mesh which is tied to the chunk) so they start from the beginning of the chunk: we need
	// to trasform them in world coord to abstract from chunk
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	//v_fog_coord = length(CAMERA_POSITION_WORLD - v_world_pos);

	// SETTING UV (mapping of the VERTEX in current quadrant)
	//vec4 vertex_world_pos = MODEL_MATRIX * vec4(VERTEX, 1);
	vec4 vertex_world_pos = vec4(v_world_pos, 1.0);
	// to calculate coords of the vertex local to the quadrant we use affine inverse matrix of the global trasform of the quadtree
	vec4 vertex_local_to_quadrant_pos = u_terrain_inverse_transform * vertex_world_pos;
	UV = vertex_local_to_quadrant_pos.xz / vec2(u_quadrant_size);		// mapping of vertex_local_to_quadrant_pos in current quadrant from 0.0 (start of the quadrant) to 1.0 (end of the quadrant)

	vec2 vertex_cell_coords_in_textures = vertex_local_to_quadrant_pos.xz / vec2(u_grid_step * pow(2.0, float(u_optimization_level)));
	vertex_cell_coords_in_textures += vec2(0.5);	// IMPORTANT: now vertex_cell_coords_in_textures ranges from 0.5
													// to (heightmap size - 1) + 0.5 with increment of 1.0 between each coord
	vec2 terrain_uv = vertex_cell_coords_in_textures / vec2(textureSize(u_terrain_heightmap, 0));
	float terrain_hight = get_height(u_terrain_heightmap, u_terrain_height, terrain_uv);		// Height displacement from heigthmap

	float end_camera_altitude_for_waves = 500.0;
	float start_camera_altitude_for_waves_attenuation = 200.0;
	float start_terrain_depth_for_waves_attenuation = 50.0;

	// heigth of waves only if camera is below end_camera_altitude_for_waves
	if (CAMERA_POSITION_WORLD.y < end_camera_altitude_for_waves) {
		float height = texture(gu_sea_wave, v_world_pos.xz / noise_scale + TIME * time_scale * rough_sea_factor).r;

		// Attenuation of waves height when camera is between start_camera_altitude_for_waves_attenuation (max waves height) and end_camera_altitude_for_waves (null waves height)
		float scale = height_scale * rough_sea_factor;
		if (CAMERA_POSITION_WORLD.y > start_camera_altitude_for_waves_attenuation) {
			scale = scale - (scale * (CAMERA_POSITION_WORLD.y - start_camera_altitude_for_waves_attenuation) / (end_camera_altitude_for_waves - start_camera_altitude_for_waves_attenuation));
			//scale = 40.0;
		}

		// Attenuation of height waves at lower depth (near the coast)
		if (terrain_hight > -start_terrain_depth_for_waves_attenuation) {
			scale *= -clamp(terrain_hight, -start_terrain_depth_for_waves_attenuation, 0) / start_terrain_depth_for_waves_attenuation;
			//scale += 20.0;
		}

		float scale_offset_threshold = 20.0;
		if (terrain_hight >= -scale_offset_threshold) {
			float scale_offset = clamp(scale_offset_threshold + terrain_hight, 0, scale_offset_threshold);
			scale += scale_offset;
		}

		VERTEX.y += (height * scale) - (scale / 3.0);
	}

	v_sea_depth = VERTEX.y - terrain_hight;

	//VERTEX.y = 0.0;		// DEBUG
	//VERTEX.y = 1000.0;	// DEBUG

	float lod = -1.0;
	if (gu_show_chunks) {
		// SETTING UV2 (mapping of the VERTEX in current chunk) and lod of current chunk
		int vertex_col = int(floor(mod(float(VERTEX_ID), float(u_num_vertices_per_chunk))));		// vertex_col ranges from 0 to u_num_vertices_per_chunk - 1
		int vertex_row = int(floor(float(VERTEX_ID) / float(u_num_vertices_per_chunk)));			// vertex_row ranges from 0 to u_num_vertices_per_chunk - 1
		float step_between_vertices_in_current_mesh = -1.0;
		if ((vertex_col == 0 && vertex_row == 0) || (vertex_col == 0 && vertex_row == int(u_num_vertices_per_chunk - uint(1)))
			|| (vertex_col == int(u_num_vertices_per_chunk - uint(1)) && vertex_row == 0) || (vertex_col == int(u_num_vertices_per_chunk - uint(1)) && vertex_row == int(u_num_vertices_per_chunk - uint(1)))) {
		} else {
			// VERTEX coords are local to the chunk (as the material is applied to the mesh which is tied to the chunk) so they start from the beginning of the chunk
			if (vertex_col == 0) {	// vertex_row is > 0
				step_between_vertices_in_current_mesh = floor(VERTEX.z / float(vertex_row));	// in world units
			} else {
				step_between_vertices_in_current_mesh = floor(VERTEX.x / float(vertex_col));	// in world units
			}
		}
		if (abs(step_between_vertices_in_current_mesh + 1.0) < 0.0001) {
			UV2 = vec2(0.0, 0.0);
			lod = 99.0;
		} else {
			float chunk_size = step_between_vertices_in_current_mesh * float(u_num_vertices_per_chunk - uint(1));	// in world units
			UV2 = VERTEX.xz / vec2(chunk_size);		// mapping of the VERTEX in current chunk from 0.0 (start of the chunk) to 1.0 (end of the chunk)
			//UV2 = vec2(float(vertex_col) / float(u_num_vertices_per_chunk), float(vertex_row) / float(u_num_vertices_per_chunk));
			//lod = log2(step_between_vertices_in_current_mesh);
			lod = log2(step_between_vertices_in_current_mesh) - 1.0;
			//lod = float(step_between_vertices_in_current_mesh);
		}
	}
	v_lod = lod;
}

void fragment() {
	// Time calculations for wave (normal map) movement
	float time_scale_factor = clamp(abs(CAMERA_POSITION_WORLD.y), 0.0, u_max_altitude_for_time_scale_factor) / u_max_altitude_for_time_scale_factor;	// normalized 0 on the surface to 1 at max_altitude_for_time_scale_factor
	time_scale_factor = (time_scale_factor * 4.0) + 1.0;	// normalized 1 on the surface to 5 at max_altitude_for_time_scale_factor
	vec2 time = (TIME * wave_direction) * time_scale * time_scale_factor * (rough_sea_factor / 6.0) /*/ 0.5*/; // Movement rate of first wave
	vec2 time2 = (TIME * wave_direction2) * time_scale * time_scale_factor * (rough_sea_factor / 6.0) /*/ 0.5*/; // Movement rate of second wave

	// Blend normal maps into one
	vec3 normal_blend = mix(texture(gu_sea_texture_normal, (UV + time) * 10.0 ).rgb, texture(gu_sea_texture_normal2, (UV + time2) * 10.0).rgb, 0.5);

	vec3 surface_color = sea_color;
	float alpha = 1.0;
	
	// Calculate Fresnel
	{
		float fresnel = fresnel(1.0, NORMAL, VIEW);
		surface_color = mix(sea_color, sea_color2, fresnel / 5.0); // Interpolate albedo values by frensel
	}

	// Calculate Transparency
	{
		float start_transparent_sea_depth = 30.0;
		float transparent_sea_depth = clamp(v_sea_depth, 0, start_transparent_sea_depth);
		float shallow_sea_alpha = 0.4;
		float deep_sea_alpha = 0.9;
		// alpha runs from shallow_sea_alpha to deep_sea_alpha: deep_sea_alpha when v_sea_depth is greater than start_transparent_sea_depth, shallow_sea_alpha when v_sea_depth is 0 or less (terrain above sea)
		alpha = shallow_sea_alpha + ((deep_sea_alpha - shallow_sea_alpha) / start_transparent_sea_depth) * transparent_sea_depth;
	}

	// Foam
	float camera_depth;
	{
		float foam_test_distance = u_foam_test_distance;
		foam_test_distance = 20.00000;
		float __depth_tex = texture(DEPTH_TEXTURE, SCREEN_UV).r;
		// NDC = normalized device coordinates
		vec4 __depth_world_pos_ndc = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, __depth_tex, 1.0);
		__depth_world_pos_ndc.xyz /= __depth_world_pos_ndc.w;
		camera_depth = clamp(1.0 - smoothstep(__depth_world_pos_ndc.z + foam_test_distance, __depth_world_pos_ndc.z, VERTEX.z), 0.0, 1.0);

		//camera_depth = 1.0 - camera_depth;		// DEBUG
		float foam_camera_depth_threshold = u_foam_camera_depth_threshold;
		//foam_camera_depth_threshold = 1.0;
		if (camera_depth < foam_camera_depth_threshold) {
			float foam_alpha = 0.9;
			//normal_blend = mix(texture(gu_sea_texture_normal, (UV + time) * 100.0 ).rgb, texture(gu_sea_texture_normal2, (UV + time2) * 100.0).rgb, 0.5);

			//float water_foam_mask = mix(texture(gu_water_foam, water_foam_uv).r, texture(gu_water_foam, water_foam_uv).b, 0.95);
			//surface_color = mix(surface_color, color_shallow.rgb, water_foam_mask);

			vec2 water_foam_uv = (UV + time / 5.0) * vec2(100);
			vec4 foam_tex = texture(gu_water_foam, water_foam_uv);
			float foam_fade_alpha = 1.0;
			foam_alpha = foam_alpha * foam_tex.a * foam_fade_alpha;
			vec3 foam_surface_color = mix(surface_color, foam_tex.rgb, foam_alpha);
			//foam_surface_color = foam_tex.rgb;
			//surface_color = foam_surface_color;
			foam_alpha = alpha + foam_alpha;
			//alpha = foam_alpha;
			surface_color = mix(foam_surface_color, surface_color, camera_depth);
			alpha = mix(foam_alpha, alpha, camera_depth);
		}
	}

	ALBEDO = surface_color;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal_blend;
	ALPHA = alpha;

	float lod = v_lod;
	if (lod >= 0.0) {
		float f = floor(lod);
		float c = ceil(lod);
		if ((lod - f) > (c - lod) ) {
			lod = c;
		} else {
			lod = f;
		}

		float chunk_border_line_thickness = 0.005;

		if (u_editmode_selected > 0.0 && is_on_the_border(UV, u_quad_border_line_thickness)) {
			ALBEDO = vec3(1.0, 0.749, 0.0);		// GDN_TheWorld_Globals::g_color_yellow_apricot
		} else {
			if (u_mouse_hit != vec2(-1) && distance(u_mouse_hit, UV) < u_mouse_hit_radius) {
				ALBEDO = vec3(1.0, 0.749, 0.0);		// GDN_TheWorld_Globals::g_color_yellow_apricot
			} else {
				if (is_on_the_border(UV, chunk_border_line_thickness) || is_on_the_border(UV2, chunk_border_line_thickness)) {
					//albedo_out = vec3(1.0, 1.0, 1.0);		// GDN_TheWorld_Globals::g_color_white
					ALBEDO = vec3(0.0, 0.0, 0.0);		// GDN_TheWorld_Globals::g_color_black
				} else {
					if (lod >= 0.0 && lod <= 8.0) {
						ALBEDO = lod_colors[int(lod)];
					} else {
						ALBEDO = lod_colors[9];
					}
				}
			}
		}
	}
}