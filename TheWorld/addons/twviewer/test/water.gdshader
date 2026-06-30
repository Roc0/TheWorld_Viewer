shader_type spatial;
render_mode blend_mix, cull_back;

const vec3 c_apricot_color = vec3(1.0, 0.749, 0.0);
const vec3 c_orange_color = vec3(0.77, 0.53, 0.11);
const vec3 c_red_salmon_color = vec3(0.980, 0.502, 0.447);
const float c_ground_uv_scale_horiz_threshold = 5000.0;	//15000.0;
const float c_ground_uv_scale_vert_threshold = 100.0;
const float c_max_ground_uv_scale_per_texture = 80.0;
const float c_f_texture_lod_zero = 0.0;
const int c_i_texture_lod_zero = 0;

global uniform float gu_time = 0;
global uniform bool gu_show_chunks = false;
global uniform float gu_camera_altitude_from_terrain;
global uniform sampler2D gu_sea_wave;
global uniform sampler2D gu_sea_texture_normal;
global uniform sampler2D gu_sea_texture_normal2;
global uniform sampler2D gu_water_foam;
global uniform float gu_sea_flat_sea_height = 0;
global uniform float gu_sea_time_scale : hint_range(0.0, 0.2, 0.0005) = 0.0005; // *** Rate of movement multiplied by shader_time
global uniform float gu_sea_rough_factor : hint_range(0.0, 20.0, 1.0) = 10.0;	// ***
global uniform float gu_sea_noise_scale = 1000.0;		// ***
global uniform float gu_sea_height_scale = 4.0;		// *** -15 / +15
global uniform float gu_sea_end_camera_altitude_for_waves = 1000.0;
global uniform float gu_sea_start_camera_altitude_for_waves_attenuation = 200.0;
global uniform float gu_sea_start_terrain_depth_for_waves_attenuation = 50.0;
global uniform float gu_sea_scale_offset_threshold = 20.0;
global uniform bool gu_highlight_hit_quadrant = false;
global uniform bool gu_hold_blending = false;

global uniform int gu_force_height_0 = -1;

uniform float u_highlight_quadrant_smoothness : hint_range(0.1, 1.0) = 0.4;

uniform float u_terrain_height_scale = 1.0;	// NOTSET
uniform sampler2D u_terrain_heightmap;
uniform uint u_extra_vertices_on_heightmap = 0;
uniform uint u_optimization_level = 0;
uniform float u_grid_step_optlvl_zero = 2.0;
uniform float u_editmode_selected = 0;
uniform bool u_grid_on = false;
uniform float u_quad_border_line_thickness = 0.005;
uniform float u_mouse_hit_radius = 0.0010000000475;
uniform uint u_num_vertices_per_chunk;
uniform vec2 u_mouse_hit_uv_quadrant = vec2(-1.000000, -1.000000);
uniform mat4 u_terrain_inverse_transform;
uniform float u_quadrant_size = 4096.0;
uniform bool u_generate_global_map = false;
uniform bool u_force_height_0 = false;
uniform float u_max_altitude_for_time_scale_factor = 5000.0;	// NOTSET

uniform float u_sea_foam_max_test_distance_from_coast = 30.00000;	// NOTSET
uniform float u_sea_foam_min_test_distance_from_coast = 0.00000;	// NOTSET
uniform float u_sea_foam_max_camera_height = 1000.0;
uniform float u_sea_foam_camera_depth_threshold = 1.0;	// 0.4;
uniform float u_sea_foam_edge_pattern_scale = 1.0;

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
	vec3(0.0, 0.0, 0.0)			// GDN_TheWorld_Globals::g_color_black
};

//uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture;
//uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec3 u_sea_color : source_color = vec3(0.10, 0.19, 0.32);	// vec3(0.0, 0.03, 0.34);		// vec3(0.0, 0.19, 0.46);		// vec3(0.0, 0.32, 0.43);
uniform vec3 u_sea_color2 : source_color = vec3(0.25, 0.32, 0.43);	// vec3(0.25, 0.32, 0.43);	// vec3(1.0, 1.0, 1.0);
uniform float u_metallic : hint_range(0.0, 1.0) = 0.8;
uniform float u_roughness : hint_range(0.0, 1.0) = 0.02;
uniform vec2 u_wave_direction = vec2(2.0,0.0); // Direction of wave 1
uniform vec2 u_wave_direction2 = vec2(0.0,1.0); // Direction of wave 2

//uniform vec4 u_color_deep : source_color = vec4(0.10, 0.29, 0.32, 1.0); // Deep depth color
uniform vec4 u_color_shallow : source_color = vec4(1.0, 1.0, 1.0, 1.0);	// vec4(0.55, 0.55, 0.55, 1.0); // Shallow depth color

// Varying variables
varying vec3 v_world_pos;
varying float v_chunk_texture_lod;
varying float v_sea_depth;

#include "res://addons/twviewer/shaders/include/CommonFunctions.gdshaderinc"

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

void vertex()
{
	vec3 vertex_modelspace_in = VERTEX;

	float shader_time = gu_time;	// TIME

	vec2 heightmapSize = vec2(textureSize(u_terrain_heightmap, c_i_texture_lod_zero));		// Power of 2 + 1 (f.i. 1025, 2049) + 2 * extra neighbour border on each side
	vec2 quadrantHeightmapSize = heightmapSize - vec2(float(u_extra_vertices_on_heightmap)) * 2.0;	// to have the size of the heightmap who map on the quadrant we have to subtract the extra neighbour border texel

	// VERTEX coords are local to the chunk (as the material is applied to the mesh which is tied to the chunk) so they start from the beginning of the chunk: we need
	// to trasform them in world coord to abstract from chunk
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	float flat_sea_height = gu_sea_flat_sea_height;
	VERTEX.y = flat_sea_height;

	// SETTING UV (mapping of the VERTEX in current quadrant)
	//vec4 vertex_world_pos = MODEL_MATRIX * vec4(VERTEX, 1);
	vec4 vertex_world_pos = vec4(v_world_pos, 1.0);
	// to calculate coords of the vertex local to the quadrant we use affine inverse matrix of the global trasform of the quadtree
	vec4 vertex_local_to_quadrant_pos = u_terrain_inverse_transform * vertex_world_pos;
	UV = vertex_local_to_quadrant_pos.xz / vec2(u_quadrant_size);		// mapping of vertex_local_to_quadrant_pos in current quadrant from 0.0 (start of the quadrant) to 1.0 (end of the quadrant)
	//UV = vertex_local_to_quadrant_pos.xz / quadrantHeightmapSize;		// mapping of vertex_local_to_quadrant_pos in current quadrant from 0.0 (start of the quadrant) to 1.0 (end of the quadrant)

	vec2 vertex_cell_coords_in_heightmap = vertex_local_to_quadrant_pos.xz / vec2(u_grid_step_optlvl_zero * pow(2.0, float(u_optimization_level))) + vec2(float(u_extra_vertices_on_heightmap));
	vertex_cell_coords_in_heightmap += vec2(0.5);	// IMPORTANT: now vertex_cell_coords_in_heightmap ranges from 0.5
													// to (heightmap size - 1) + 0.5 with increment of 1.0 between each coord
	vec2 terrain_uv = vertex_cell_coords_in_heightmap / heightmapSize;
	float terrain_vertex_hight = get_height(u_terrain_heightmap, u_terrain_height_scale, terrain_uv);		// Height displacement from heigthmap

	float end_camera_altitude_for_waves = gu_sea_end_camera_altitude_for_waves;
	float start_camera_altitude_for_waves_attenuation = gu_sea_start_camera_altitude_for_waves_attenuation;
	float start_terrain_depth_for_waves_attenuation = gu_sea_start_terrain_depth_for_waves_attenuation;

	// heigth of waves only if camera is below end_camera_altitude_for_waves
	if (CAMERA_POSITION_WORLD.y - flat_sea_height < end_camera_altitude_for_waves || u_generate_global_map) {
		// sea height in range 0.0 / 1.0 from noise texture moving uv with vertex global position and time
		float height = textureLod(gu_sea_wave, (v_world_pos.xz / gu_sea_noise_scale) + (shader_time * gu_sea_time_scale * gu_sea_rough_factor), 0).r;

		// Attenuation of waves height when camera is between start_camera_altitude_for_waves_attenuation (max waves height) and end_camera_altitude_for_waves (null waves height)
		float scale = gu_sea_height_scale * gu_sea_rough_factor;
		if (CAMERA_POSITION_WORLD.y > flat_sea_height + start_camera_altitude_for_waves_attenuation) {
			scale = scale - (scale * (CAMERA_POSITION_WORLD.y - start_camera_altitude_for_waves_attenuation) / (end_camera_altitude_for_waves - start_camera_altitude_for_waves_attenuation));
			//scale = 40.0;		// DEBUG
		}

		// Attenuation of height waves at lower depth (near the coast)
		if (terrain_vertex_hight > flat_sea_height - start_terrain_depth_for_waves_attenuation) {
			scale *= -clamp(terrain_vertex_hight, -start_terrain_depth_for_waves_attenuation, 0) / start_terrain_depth_for_waves_attenuation;
			//scale += 20.0;	// DEBUG
		}

		float scale_offset_threshold = gu_sea_scale_offset_threshold;
		if (terrain_vertex_hight >= flat_sea_height - scale_offset_threshold) {
			float scale_offset = clamp(scale_offset_threshold + terrain_vertex_hight, 0, scale_offset_threshold);
			scale += scale_offset;
		}

		float sea_vertex_height = VERTEX.y;

		bool force_height_0 = u_force_height_0;
		if (!force_height_0) {
			if (gu_force_height_0 > 0) {
				force_height_0 = true;
			}
		}
		//force_height_0 = true;		// DEBUG
		if (force_height_0) {
			sea_vertex_height = 0.0;
		} else {
			sea_vertex_height += (height * scale) - (scale / 3.0);
		}

		if (u_generate_global_map) {
			if (terrain_vertex_hight > sea_vertex_height) {
				VERTEX.y = flat_sea_height - 1.0;
				//VERTEX.y = 100.0;
			} else {
				VERTEX.y = flat_sea_height + 1.0;
			}
		} else {
			VERTEX.y = sea_vertex_height;
		}
	}

	v_sea_depth = VERTEX.y - terrain_vertex_hight;		// positive values for terrain under water, negative for terrain over water

	//VERTEX.y = 0.0;		// DEBUG
	//VERTEX.y = 1000.0;	// DEBUG

	vec2 chunk_uv = vec2(0.0, 0.0);
	float lod = -1.0;
	if (gu_show_chunks && !u_generate_global_map) {
		/*
		// SETTING UV2 (mapping of the VERTEX in current chunk) and lod of current chunk
		int vertex_col = int(floor(mod(float(VERTEX_ID), float(u_num_vertices_per_chunk))));		// vertex_col ranges from 0 to u_num_vertices_per_chunk - 1
		int vertex_row = int(floor(float(VERTEX_ID) / float(u_num_vertices_per_chunk)));			// vertex_row ranges from 0 to u_num_vertices_per_chunk - 1
		float step_between_vertices_in_current_mesh = -1.0;
		if ((vertex_col == 0 && vertex_row == 0) || (vertex_col == 0 && vertex_row == int(u_num_vertices_per_chunk - uint(1)))
			|| (vertex_col == int(u_num_vertices_per_chunk - uint(1)) && vertex_row == 0) || (vertex_col == int(u_num_vertices_per_chunk - uint(1)) && vertex_row == int(u_num_vertices_per_chunk - uint(1))))
		{
		}
		else
		{
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
			lod = log2(step_between_vertices_in_current_mesh) - 1.0;
		}
		*/
		int vertex_col = int(floor(mod(float(VERTEX_ID), float(u_num_vertices_per_chunk))));		// vertex_col ranges from 0 to u_num_vertices_per_chunk - 1
		int vertex_row = int(floor(float(VERTEX_ID) / float(u_num_vertices_per_chunk)));			// vertex_row ranges from 0 to u_num_vertices_per_chunk - 1
		float step_between_vertices_in_current_chunk = -1000000000.0;
		float chunk_size = -1000000000.0;
		{
			if (vertex_col == 0 && vertex_row == 0)
			{
				chunk_uv = vec2(0.0, 0.0);
			}
			else
			{
				if (vertex_col == 0) {	// vertex_row is > 0
					step_between_vertices_in_current_chunk = floor(vertex_modelspace_in.z / float(vertex_row));
				} else {	// vertex_col is > 0
					step_between_vertices_in_current_chunk = floor(vertex_modelspace_in.x / float(vertex_col));
				}
				chunk_size = step_between_vertices_in_current_chunk * float(u_num_vertices_per_chunk - uint(1));
				chunk_uv = vertex_modelspace_in.xz / vec2(chunk_size);
			}
		}

		if ((vertex_col == 0 && vertex_row == 0) || (vertex_col == 0 && vertex_row == int(u_num_vertices_per_chunk - uint(1)))
			|| (vertex_col == int(u_num_vertices_per_chunk - uint(1)) && vertex_row == 0) || (vertex_col == int(u_num_vertices_per_chunk - uint(1)) && vertex_row == int(u_num_vertices_per_chunk - uint(1))))
		{
			lod = 99.0;
		}
		else
		{
			lod = log2(step_between_vertices_in_current_chunk) - 1.0;
		}
	}

	UV2 = chunk_uv;
	v_chunk_texture_lod = lod;
}

void fragment() {
	float shader_time = gu_time;	// TIME

	float metallic = u_metallic;
	float roughness = u_roughness;

	// Time calculations for wave (normal map) movement
	//float time_scale_factor = clamp(abs(CAMERA_POSITION_WORLD.y), 0.0, u_max_altitude_for_time_scale_factor) / u_max_altitude_for_time_scale_factor;	// normalized 0 on the surface to 1 at max_altitude_for_time_scale_factor
	float time_scale_factor = 0.00;
	time_scale_factor = (time_scale_factor * 4.0) + 1.0;	// normalized 1 on the surface to 5 at max_altitude_for_time_scale_factor
	vec2 time = (shader_time * u_wave_direction) * gu_sea_time_scale * time_scale_factor * (gu_sea_rough_factor / 6.0) /*/ 0.5*/; // Movement rate of first wave
	vec2 time2 = (shader_time * u_wave_direction2) * gu_sea_time_scale * time_scale_factor * (gu_sea_rough_factor / 6.0) /*/ 0.5*/; // Movement rate of second wave

	// Blend normal maps into one
	vec3 normal_blend = mix(texture(gu_sea_texture_normal, (UV + time) * 10.0 ).rgb, texture(gu_sea_texture_normal2, (UV + time2) * 10.0).rgb, 0.5);

	vec3 surface_color = u_sea_color;
	float alpha = 1.0;

	// Calculate Fresnel
	{
		float fresnel = fresnel(1.0, NORMAL, VIEW);
		surface_color = mix(u_sea_color, u_sea_color2, fresnel / 5.0); // Interpolate albedo values by frensel
	}

	// Calculate Transparency
	{
		float start_transparent_sea_depth = 30.0;
		float transparent_sea_depth = clamp(v_sea_depth, 0, start_transparent_sea_depth);
		float shallow_sea_alpha = 0.4;
		float deep_sea_alpha = 0.9;
		// alpha ranges from shallow_sea_alpha to deep_sea_alpha: deep_sea_alpha when v_sea_depth is greater than start_transparent_sea_depth, shallow_sea_alpha when v_sea_depth is 0 or less (terrain above sea)
		alpha = shallow_sea_alpha + ((deep_sea_alpha - shallow_sea_alpha) / start_transparent_sea_depth) * transparent_sea_depth;
		//alpha = 1.0;														// DEBUG
		//metallic = 1.0;													// DEBUG
		//roughness = 0.0;													// DEBUG
		//if (v_sea_depth < start_transparent_sea_depth) alpha = 1.0;		// DEBUG
	}

	float __depth_tex = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	// NDC = normalized device coordinates
	vec4 __depth_world_pos_ndc = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, __depth_tex, 1.0);
	__depth_world_pos_ndc.xyz /= __depth_world_pos_ndc.w;
	float depth_positive_distance_from_camera = -(__depth_world_pos_ndc.z);

	// Foam
	float foam_max_camera_height = u_sea_foam_max_camera_height;
	//foam_max_camera_height = 1000.0;	// DEBUG
	if (CAMERA_POSITION_WORLD.y <= foam_max_camera_height)
	{
		float foam_max_test_distance_from_coast = u_sea_foam_max_test_distance_from_coast;
		float foam_min_test_distance_from_coast = u_sea_foam_min_test_distance_from_coast;
		//foam_min_test_distance_from_coast = 0.0;
		// related to camera heigth: foam_min_test_distance_from_coast at foam_max_camera_height, foam_max_test_distance_from_coast at 0
		float foam_test_distance_from_coast = foam_min_test_distance_from_coast + (foam_max_test_distance_from_coast - foam_min_test_distance_from_coast) * (1.0 - abs(CAMERA_POSITION_WORLD.y) / foam_max_camera_height);
		//foam_test_distance_from_coast = 30.0;	// DEBUG
		float camera_depth = clamp(1.0 - smoothstep(__depth_world_pos_ndc.z + foam_test_distance_from_coast, __depth_world_pos_ndc.z, VERTEX.z), 0.0, 1.0);

		//camera_depth = 1.0 - camera_depth;		// DEBUG
		float foam_camera_depth_threshold = u_sea_foam_camera_depth_threshold;
		//foam_camera_depth_threshold = 1.0;
		if (camera_depth < foam_camera_depth_threshold) {
			float foam_alpha = 0.9;
			//normal_blend = mix(texture(gu_sea_texture_normal, (UV + time) * 100.0 ).rgb, texture(gu_sea_texture_normal2, (UV + time2) * 100.0).rgb, 0.5);

			//float water_foam_mask = mix(texture(gu_water_foam, water_foam_uv).r, texture(gu_water_foam, water_foam_uv).b, 0.95);
			//surface_color = mix(surface_color, u_color_shallow.rgb, water_foam_mask);

			vec2 water_foam_uv = (UV + time / 3.0) * vec2(40);
			vec4 foam_tex = texture(gu_water_foam, water_foam_uv);
			float foam_fade_alpha = 1.0;
			foam_alpha = foam_alpha * foam_tex.a * foam_fade_alpha;
			vec3 foam_surface_color = mix(surface_color, foam_tex.rgb, foam_alpha);
			foam_alpha = foam_alpha;
			surface_color = mix(foam_surface_color, surface_color, camera_depth);
			alpha = mix(foam_alpha, alpha, camera_depth);
		}
	}

	{
		// comment render_mode unshaded

		//alpha = 1.0;
		//metallic = 0.0;
		//roughness = 1.0;

		//vec3 fragment_world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
		//float fragment_distance_from_camera = distance(CAMERA_POSITION_WORLD, fragment_world_pos);
		//float fragment_distance_mask = smoothstep(00000.0, 60000.0, fragment_distance_from_camera);
		////fragment_distance_mask = 0.08;
		//surface_color = vec3(fragment_distance_mask);
		//float depth_distance_mask = smoothstep(00000.0, 60000.0, depth_positive_distance_from_camera);
		////depth_distance_mask = 0.01;
		//surface_color = vec3(depth_distance_mask);
		/*if (abs(fragment_distance_mask - depth_distance_mask) < 0.03) {
			surface_color = vec3(1.0, 0.0, 0.0);
		} else {
			surface_color = vec3(0.0, 1.0, 0.0);
		}*/
	}

	// contrast z-fighting or z-clipping: at great distance we need to force sea in front of terrain in the z-buffer to avoid flickering when camera moves
	/*float z_fighting_max_camera_heigth = 100000.0;
	if (CAMERA_POSITION_WORLD.y <= z_fighting_max_camera_heigth) {
		// near terrain we assume not to have z-fighting
		DEPTH = FRAGCOORD.z;
	} else {
		//vec3 fragment_world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
		//float fragment_distance_from_camera = distance(CAMERA_POSITION_WORLD, fragment_world_pos);
		//float fragment_distance_mask = smoothstep(00000.0, 60000.0, fragment_distance_from_camera);
		//float depth_distance_mask = smoothstep(00000.0, 60000.0, depth_positive_distance_from_camera);
		//if(abs(fragment_distance_mask - depth_distance_mask) > 0.1) {
		//	DEPTH = FRAGCOORD.z;
		//} else
			if (v_sea_depth > 0.0) {
				// terrain under water
				DEPTH = FRAGCOORD.z - 0.1;
			} else {
				// terrain over water
				DEPTH = FRAGCOORD.z + 0.1;
			}
	}*/

	if (u_generate_global_map) {
		alpha = 1.0;
	}

	if (u_editmode_selected > 0.0 && is_on_the_border(UV, u_quad_border_line_thickness)) {
		if (gu_hold_blending)
			surface_color = c_red_salmon_color;		// GDN_TheWorld_Globals::g_color_yellow_apricot
		else
			surface_color = c_apricot_color;		// GDN_TheWorld_Globals::g_color_yellow_apricot
		alpha = 1.0; 
		metallic = 1.0;
		roughness = 1.0;
	} else {
		float lod = v_chunk_texture_lod;
		//lod = -1.0;		// DEBUG
		if (lod >= 0.0)
		{
			lod = round(lod);
			float chunk_border_line_thickness = 0.005;

			if (u_mouse_hit_uv_quadrant != vec2(-1) && distance(u_mouse_hit_uv_quadrant, UV) < u_mouse_hit_radius) {
				surface_color = c_apricot_color;		// GDN_TheWorld_Globals::g_color_yellow_apricot
			} else {
				if (is_on_the_border(UV, chunk_border_line_thickness) || is_on_the_border(UV2, chunk_border_line_thickness)) {
					//albedo_out = vec3(1.0, 1.0, 1.0);		// GDN_TheWorld_Globals::g_color_white
					surface_color = vec3(0.0, 0.0, 0.0);		// GDN_TheWorld_Globals::g_color_black
				} else {
					if (lod >= 0.0 && lod <= 8.0) {
						surface_color = lod_colors[int(lod)];
					} else {
						surface_color = lod_colors[9];
					}
				}
			}
			alpha = 1.0; 
			metallic = 1.0;
			roughness = 1.0;
		}
	}
	
	if (gu_highlight_hit_quadrant && u_mouse_hit_uv_quadrant != vec2(-1) && (u_mouse_hit_uv_quadrant.x >= 0.0 && u_mouse_hit_uv_quadrant.x <= 1.0 && u_mouse_hit_uv_quadrant.y >= 0.0 && u_mouse_hit_uv_quadrant.y <= 1.0))
	{
		surface_color = c_apricot_color;		// GDN_TheWorld_Globals::g_color_yellow_apricot
		surface_color = mix(surface_color, c_orange_color, u_highlight_quadrant_smoothness);
		alpha = 1.0; 
		metallic = 1.0;
		roughness = 1.0;
	}

	ALBEDO = surface_color;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal_blend;
	ALPHA = alpha;

	//if (u_editmode_selected > 0.0) ALPHA = 0.2;		// DEBUG
	//if (v_chunk_texture_lod >= 0.0) ALPHA = 0.2;		// DEBUG
	//if (u_generate_global_map) ALPHA = 0.2;		// DEBUG
	//if (gu_show_chunks) ALPHA = 1.0;		// DEBUG
}