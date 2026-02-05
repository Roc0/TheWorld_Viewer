// TODO
// * set new uniforms
// * transform global uniforms in uniforms
// * update water.gdshader
// * update test_quadrant.gd

shader_type spatial;
//render_mode blend_mix, depth_draw_opaque, cull_back, /*diffuse_lambert,*/ diffuse_burley, /*specular_toon*/ specular_schlick_ggx, skip_vertex_transform;
//render_mode blend_mix, depth_draw_opaque, cull_back, /*diffuse_lambert,*/ diffuse_toon, specular_toon, skip_vertex_transform;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon, skip_vertex_transform;
//render_mode unshaded, skip_vertex_transform;		// DEBUG

#include "res://addons/twviewer/shaders/include/CommonFunctions.gdshaderinc"

// consts
const vec3 c_apricot_color = vec3(1.0, 0.749, 0.0);
const vec3 c_orange_color = vec3(0.77, 0.53, 0.11);
const vec3 c_red_salmon_color = vec3(0.980, 0.502, 0.447);
const float c_ground_uv_scale_horiz_threshold = 5000.0;	//15000.0;
const float c_ground_uv_scale_vert_threshold = 100.0;
const float c_max_ground_uv_scale_per_texture = 80.0;
const float c_f_texture_lod_zero = 0.0;
const int c_i_texture_lod_zero = 0;

// ***********
// Limitations
// ***********
// * max 64 ground texture
// * max 3 optimization level increments	es: if u_optlvl_increment=2 optimization level can be 0 (num_optlvl_inc=0), 2 (num_optlvl_inc=1), 4 (num_optlvl_inc=2), 6 (num_optlvl_inc=3)
// * max 625 quadrants (1 + 12 *2)

// ************
// new uniforms
// ************
// already set
// not set yet
//uniform vec2 u_grid_pos;					// pos of the left-most, top-most quadrant of the grid: the position of the verrtex with the less x and z coords
//uniform uint u_optlvl_increment = 2;		// increment value with which the optimization level can grow according to quadrant params
//uniform uint u_num_quadrants_per_grid_size;// num quadrant per size in the heightmap grid
//uniform sampler2D u_grid_control_1;		//texture FORMAT_RF, one texel for each quardant (row * column) with dim = u_num_quadrants_per_size * u_num_quadrants_per_size
											// * num_optlvl_inc					2 bit	range 0/3
											// * low-level texture	index		6 bit	range 0/63	(for a max of 64 ground texture)
											// * high-level texture index		6 bit	range 0/63	(for a max of 64 ground texture)
											// * dirt texture index				6 bit	range 0/63	(for a max of 64 ground texture)
											// * rock texture index			6 bit	range 0/63	(for a max of 64 ground texture)
											// * reserved						6 bit

//uniform sampler2D u_grid_control_2;		// texture FORMAT_RGBAF, one texel for each quardant (row * column) with dim = u_num_quadrants_per_size * u_num_quadrants_per_size
											// * high_elevation_factor	(R)		32 bits
											// * low_elevation_factor (G)		32 bits
											// * min_height (B)					32 bits
											// * max_height (A)					32 bits

//uniform sampler2D u_grid_control_3;		// texture FORMAT_RGBAF, one texel for each quardant (row * column) with dim = u_num_quadrants_per_size * u_num_quadrants_per_size
											// * slope_vertical_factor (R)		32 bits
											// * slope_flat_factor (G)			32 bits
											// * dirt_on_rocks_factor (B)		32 bits
											// * reserved (A)					22 bits
											// * heightmap_index (A)			10 bits		range 0/1023
//uniform sampler2D u_heightmap_array[841] : repeat_disable;
//uniform sampler2DArray u_heightmap_array_optlvl_inc_0 : repeat_disable;	// texture array FORMAT_RH, flat texture array (one texture for each quadrant - row * column) with dim = u_num_quadrants_per_size * u_num_quadrants_per_size, for each layer: one texel for each vertex (row * column), 16 bit	range -65504/+65504
//uniform sampler2DArray u_heightmap_array_optlvl_inc_1 : repeat_disable;	// texture array same as above
//uniform sampler2DArray u_heightmap_array_optlvl_inc_2 : repeat_disable;	// texture array same as above
//uniform sampler2DArray u_heightmap_array_optlvl_inc_3 : repeat_disable;	// texture array same as above
//uniform sampler2DArray u_vertex_control_array_optlvl_inc_0 : repeat_disable;	// texture array FORMAT_RF, flat texture array (one texture for each quadrant - row * column) with dim = u_num_quadrants_per_size * u_num_quadrants_per_size, for each layer: one texel for each vertex (row * column)
															// * hole						1 bit	range 0/1	false/true
															// * navigation				1 bit	range 0/1	false/true
															// * custom texture 1 valid	1 bit	range 0/1	false/true
															// * custom texture 2 valid	1 bit	range 0/1	false/true
															// * custom texture 3 valid	1 bit	range 0/1	false/true
															// * custom texture 4 valid	1 bit	range 0/1	false/true
															// * custom texture 1 index	6 bit	range 0/63	(per un massimo di 64 ground texture)
															// * custom texture 2 index	6 bit	range 0/63	(per un massimo di 64 ground texture)
															// * custom texture 3 index	6 bit	range 0/63	(per un massimo di 64 ground texture)
															// * custom texture 4 index	6 bit	range 0/63	(per un massimo di 64 ground texture)
															// * reserved					2 bit

//uniform sampler2DArray u_vertex_control_array_optlvl_inc_1 : repeat_disable;	// texture array same as above
//uniform sampler2DArray u_vertex_control_array_optlvl_inc_2 : repeat_disable;	// texture array same as above
//uniform sampler2DArray u_vertex_control_array_optlvl_inc_3 : repeat_disable;	// texture array same as above

//const vec3 vectors[3] = {
//	vec3(1.0, 0.0 ,0.0),
//	vec3(0.0, 1.0 ,0.0),
//	vec3(0.0, 0.0 ,1.0)
//};

// ************************
// only in test_quadrant.gd
// ************************
uniform bool u_test_quadrant = false;
uniform bool u_test_quadrant_show_wireframe = false;

// ***************
// not set in code
// ***************
//uniform float u_shine_speed : hint_range(0.1, 10) = 1.5;
uniform float u_highlight_quadrant_smoothness : hint_range(0.1, 1.0) = 0.2;

// ***************
// global uniforms
// ***************
global uniform sampler2D gu_terrain_quad_border_distance : source_color;
global uniform sampler2DArray gu_ground_albedo_displ_array : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
global uniform sampler2DArray gu_ground_normal_roughness_array : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
global uniform sampler2D gu_ground_base_values_array;
//global uniform sampler2DArray gu_ground_ao_array : hint_default_white, filter_linear_mipmap, repeat_enable;
global uniform vec4 gu_ground_albedo_modifier : source_color = vec4(1.0, 1.0, 1.0, 1.0);
global uniform float gu_ground_roughness_scale : hint_range(0.0, 1.0) = 1.0;
global uniform float gu_ground_normal_scale : hint_range(1.0, 16.0, 0.1) = 3.0;
global uniform float gu_ground_ao_light_affect : hint_range(0.0, 1.0, 0.01) = 0.0;
//global uniform float gu_ground_heightmap_displ : hint_range(0.0, 5.0, 0.001) = 0.0;	//=3.871;
global uniform float gu_texture_overflow_size = 0.3;
//global uniform bool gu_texture_new_overflow = false;
//global uniform float gu_grid_step;
global uniform float gu_camera_altitude_from_terrain = -1;
global uniform bool gu_show_chunks = false;
uniform bool u_show_wireframe = false;
global uniform bool gu_show_need_blending = false;
//global uniform vec3 gu_camera_pos = vec3(0.000000, 0.000000, 0.000000);
global uniform int gu_force_height_0 = -1;
global uniform bool gu_highlight_hit_quadrant = false;
global uniform bool gu_hold_blending = false;
global uniform float gu_piece_size = 200;
global uniform bool gu_debug_view_pieces = false;
//global uniform float gu_debug_float0 = 40.0;
//global uniform float gu_debug_float1 = 20.0;
//global uniform float gu_debug_float2 = 20.0;
//global uniform float gu_debug_float3 = 16.0;
//global uniform float gu_debug_float4 = 12.0;
//global uniform float gu_debug_float5 = 6.0;
global uniform bool gu_debug_texture_overflow = false;
global uniform bool gu_debug_uv_scale_per_texture = false;
//global uniform float gu_camera_altitude_uv_scale_threshold = 6000.0;
global uniform float gu_camera_distance_uv_scale_threshold = 10000.0;

// ********
// uniforms
// ********
uniform float u_grid_step_optlvl_zero = 2;	// step in WUs between vertices at optimization level zero that is at greater resolution of the chunk
uniform bool u_need_blending = false;
uniform bool u_need_blending_north = false;
uniform bool u_need_blending_south = false;
uniform bool u_need_blending_east = false;
uniform bool u_need_blending_west = false;

uniform vec4 u_wireframe_background_albedo : source_color = vec4(0.0, 1.0, 0.0, 1.0);	// green
uniform vec4 u_wireframe_lines_albedo : source_color = vec4(1.0, 0.0, 0.0, 1.0);	// red
uniform vec4 u_need_blending_albedo : source_color = vec4(0.0, 0.0, 1.0, 1.0);	// blue
uniform vec4 u_selected_albedo : source_color = vec4(0.0, 0.0, 1.0, 1.0);	// green
uniform vec4 u_wireframe_border_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);	// black
uniform vec4 u_need_blending_border_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);	// red
uniform float u_uv_wire_width = 0.003;
//uniform float u_wire_width : hint_range(0.0, 40.0) = 1.0;
//uniform float u_wire_smoothness : hint_range(0.0, 0.1) = 0.01;

uniform sampler2D u_terrain_heightmap;
uniform sampler2D u_terrain_heightmap_border_rows;	// row0 = north border of the heightmap (x growing), row1 = south border of the heightmap (x growing), row2 = west border of the heightmap (z growing), row3 = east border of the heightmap (z growing)
//const int c_north_quadrant_border_row = 0;	// North / Top Quadrant
//const int c_south_quadrant_border_row = 1;	// South / Bottom Quadrant
//const int c_west_quadrant_border_row = 2;		// West / Left Quadrant
//const int c_east_quadrant_border_row = 3;		// East / Right Quadrant

uniform sampler2D u_terrain_normalmap;

//uniform sampler2D u_terrain_globalmap : source_color;

uniform vec4 u_ground_uv_scale_per_texture = vec4(1.000000, 1.000000, 1.000000, 1.000000);	// actually used as float, only first coord is used assuming same scaling in all textures

//uniform float u_scale_per_texture_factor = 1;
//uniform uint u_piecing_threshold_factor = 4;
uniform float u_editmode_selected = 0;
uniform vec2 u_mouse_hit_uv_quadrant = vec2(-1.000000, -1.000000);
uniform float u_mouse_hit_radius = 0.0010000000475;
//uniform bool u_triplanar = false;
uniform vec4 u_tile_reduction_per_texture = vec4(0.000000, 0.000000, 0.000000, 0.000000);	// Each component corresponds to a ground texture. Set greater than zero to enable.
uniform bool u_depth_blending = false;
uniform bool u_grid_on = false;

uniform vec4 u_ground_layers = vec4(-1.000000, -1.000000, -1.000000, -1.000000);
uniform vec4 u_north_ground_layers = vec4(-1.000000, -1.000000, -1.000000, -1.000000);
//uniform vec4 u_east_ground_layers = vec4(-1.000000, -1.000000, -1.000000, -1.000000);
uniform vec4 u_west_ground_layers = vec4(-1.000000, -1.000000, -1.000000, -1.000000);
//uniform vec4 u_south_ground_layers = vec4(-1.000000, -1.000000, -1.000000, -1.000000);
uniform vec4 u_north_west_ground_layers = vec4(-1.000000, -1.000000, -1.000000, -1.000000);
//uniform vec4 u_south_east_ground_layers = vec4(-1.000000, -1.000000, -1.000000, -1.000000);

uniform mat4 u_terrain_inverse_transform;
//uniform float u_grid_step = 2;		// replaced by u_grid_step_optlvl_zero
uniform uint u_optimization_level = 0;
uniform uint u_num_vertices_per_chunk;

uniform sampler2D u_terrain_splatmap;
uniform vec4 u_north_west_corner_splatmap_texel;
uniform sampler2D u_north_border_splatmap;
uniform sampler2D u_west_border_splatmap;

//uniform sampler2D u_terrain_colormap;

uniform mat3 u_terrain_normal_basis;
uniform float u_terrain_height = 1.0;	// NOTSET
uniform float u_quad_border_line_thickness = 0.005;	// NOTSET
uniform bool u_force_height_0 = false;

uniform vec4 u_colormap_opacity_per_texture = vec4(1.0, 1.0, 1.0, 1.0);	// NOTSET

uniform float u_override_camera_altitude_from_terrain = -2.0;

uniform float u_splat_slope_vertical_factor = 4.0;
uniform float u_splat_slope_flat_factor = 1.0;
uniform float u_splat_dirt_on_rocks_factor = 2.0;
uniform float u_splat_high_elevation_factor = 4.0;
uniform float u_splat_low_elevation_factor = 2.0;
uniform float u_splat_min_height = 0.0;
uniform float u_splat_max_height = 0.0;

//********************************************************************************************************************
//     Test PBR
//********************************************************************************************************************
/*uniform vec3 uv1_scale = vec3(1.0, 1.0, 1.0);
uniform vec3 uv1_offset = vec3(0.0, 0.0, 0.0);
uniform vec3 uv2_scale = vec3(1.0, 1.0, 1.0);
uniform vec3 uv2_offset = vec3(0.0, 0.0, 0.0);

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform ivec2 albedo_texture_size = ivec2(1024, 1024);
uniform float point_size : hint_range(0.1, 128.0, 0.1) = 1.0;

uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01) = 0.0;	//0.5;
uniform float metallic : hint_range(0.0, 1.0, 0.01) = 0.0;

uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0) = 1.0;

uniform sampler2D texture_ambient_occlusion : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 ao_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
uniform float ao_light_affect : hint_range(0.0, 1.0, 0.01) = 0.0;

uniform sampler2D texture_heightmap : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform float heightmap_scale : hint_range(-16.0, 16.0, 0.001) = 3.871;
uniform int heightmap_min_layers : hint_range(1, 64) = 8;
uniform int heightmap_max_layers : hint_range(1, 64) = 32;
uniform vec2 heightmap_flip = vec2(1.0, 1.0);

uniform sampler2D texture_displacement : hint_default_black, filter_linear_mipmap, repeat_enable;*/
//********************************************************************************************************************
//     Test PBR
//********************************************************************************************************************

// Varyings
varying vec4 v_vertex_worldspace;
varying vec2 v_vertex_cell_coords_in_heightmap;
varying vec4 v_splat;
varying vec3 v_tint0;
varying vec3 v_tint1;
varying vec3 v_tint2;
varying vec3 v_tint3;
varying float v_distance_from_camera;
varying float v_distance_from_vertical_of_camera_on_terrain;
varying float v_chunk_texture_lod;
//varying float v_grid_step;

vec3 get_triplanar_blend(vec3 world_normal) {
	vec3 blending = abs(world_normal);
	blending = normalize(max(blending, vec3(0.00001))); // Force weights to sum to 1.0
	float b = blending.x + blending.y + blending.z;
	return blending / vec3(b, b, b);
}

vec4 get_depth_blended_weights(vec4 splat, vec4 bumps) {
	float dh = 0.2;

	vec4 h = bumps + splat;

	// TODO Keep improving multilayer blending, there are still some edge cases...
	// Mitigation: nullify layers with near-zero splat
	h *= smoothstep(0, 0.05, splat);

	vec4 d = h + dh;
	d.r -= max(h.g, max(h.b, h.a));
	d.g -= max(h.r, max(h.b, h.a));
	d.b -= max(h.g, max(h.r, h.a));
	d.a -= max(h.g, max(h.b, h.r));

	return clamp(d, 0, 1);
}

vec4 texture_layer(sampler2DArray _tex, vec3 _uv) {
	//return texture(_tex, _uv);
	
	// 1. Calcola le derivate "pulite" prima di eventuali modifiche brusche
	// Se le derivate vengono calcolate su un salto (es. da 0.9 a 0.1), 
	// il valore di ddx/ddy sarà enorme, causando un campionamento del mipmap più basso (sfocato).
	vec2 uv_dx = dFdxCoarse(_uv.xy);
	vec2 uv_dy = dFdyCoarse(_uv.xy);
	// 2. Correzione manuale del salto (modulo o wrapping)
	// Se la differenza tra pixel è superiore a 0.5, assumiamo che ci sia stato un wrapping
	uv_dx -= round(uv_dx);
	uv_dy -= round(uv_dy);
	// 3. Campionamento della texture usando le derivate esplicite
	// Invece di texture(sampler, uv), usiamo le derivate calcolate per scegliere il MipMap corretto
	return textureGrad(_tex, _uv, uv_dx, uv_dy);
}

vec4 fetch_texture_albedo_displ(vec2 uv, float ground_texture_layer, float base_scale_uv, vec3 base_albedo, float base_scale_displ) {
	//base_scale_uv = 2.0;		// DEBUGUV
	//base_albedo = vec3(1.0);	// DEBUGUV
	//base_scale_ao = 1.0;		// DEBUGUV

	// DEBUGUV
	/*if (ground_texture_layer == 9.0) {
		if (abs(base_scale_uv - 2.0) < 0.01) {
			vec4 pixel;
			pixel.rgb = vec3(1.0, 0.0, 0.0);
			pixel.a = pixel.a * base_scale_ao;
			return pixel;
		}
	}*/
	// DEBUGUV

	vec3 uv_layer = vec3(uv * base_scale_uv, ground_texture_layer);
	//vec3 uv_layer = vec3(uv, ground_texture_layer);
	vec4 pixel = texture_layer(gu_ground_albedo_displ_array, uv_layer);
	pixel.rgb = pixel.rgb * base_albedo;
	pixel.a = pixel.a * base_scale_displ;
	return pixel;
}

vec4 fetch_texture_normal_roughness(vec2 uv, float ground_texture_layer, float base_scale_uv, float base_scale_roughness) {
	//base_scale_uv = 1.0;			// DEBUGUV
	//base_scale_roughness = 1.0;	// DEBUGUV
	vec3 uv_layer = vec3(uv * base_scale_uv, ground_texture_layer);
	//vec3 uv_layer = vec3(uv, ground_texture_layer);
	vec4 pixel;
	pixel = texture_layer(gu_ground_normal_roughness_array, uv_layer);
	//pixel.xyz = fma(pixel.xzy, vec3(2.0), vec3(-1.0));	// Boh!
	pixel.xyz = normalize(pixel.xyz);
	pixel.a = pixel.a * base_scale_roughness;
	return pixel;
}

void fetch_base_values0(float ground_texture_layer, out vec3 base_albedo, out float base_scale_displ)
{
	vec2 pixel_index = vec2(ground_texture_layer, 0.0);	// rangex from 0 to max texture-index (0-based) on the x side
	pixel_index += vec2(0.5);				// we need to center the pixel: rangex from 0.5 to max texture-index (0-based) + 0.5 on the x side
	vec2 pixel_uv = pixel_index / vec2(textureSize(gu_ground_base_values_array, c_i_texture_lod_zero));	// normalized UV to be in the range 0/1
	vec4 base_values0 = textureLod(gu_ground_base_values_array, pixel_uv, c_f_texture_lod_zero);
	//vec4 base_values0 = vec4(1.0, 1.0, 1.0, 1.0);		// DEBUG
	base_albedo = base_values0.rgb;
	base_scale_displ = base_values0.a * 255.0;
}

void fetch_base_values1(float ground_texture_layer, out float base_scale_ao, out float base_scale_normal, out float base_scale_roughness, out float base_scale_uv)
{
	vec2 pixel_index = vec2(ground_texture_layer, 1.0);	// rangex from 0 to max texture-index (0-based) on the x side
	pixel_index += vec2(0.5);				// we need to center the pixel: rangex from 0.5 to max texture-index (0-based) + 0.5 on the x side
	vec2 pixel_uv = pixel_index / vec2(textureSize(gu_ground_base_values_array, c_i_texture_lod_zero));	// normalized UV to be in the range 0/1
	//pixel_uv = vec2(0.65625, 0.75);		// DEBUG	10.5 / 16 e 1.5 / 2
	//pixel_uv = vec2(0.71875, 0.75);		// DEBUG	11.5 / 16 e 1.5 / 2
	vec4 base_values1 = textureLod(gu_ground_base_values_array, pixel_uv, c_f_texture_lod_zero);
	//vec4 base_values1 = vec4(1.0, 1.0, 1.0, 1.0);		// DEBUG
	//base_values1.g = gu_debug_float0;	// DEBUG
	base_scale_ao = base_values1.r * 255.0;
	base_scale_normal = base_values1.g * 255.0;
	base_scale_roughness = base_values1.b * 255.0;
	base_scale_uv = base_values1.a * 255.0;
}

vec4 texture_ad_nr(int splatmap_layer,
	bool north_border_pixel,
	//bool south_border_pixel,
	bool west_border_pixel,
	//bool east_border_pixel,
	bool north_west_border_pixel,
	vec2 uv,
	out vec4 out_nr,
	out float normal_map_scale)
{
	float base_scale_ao;
	float base_scale_normal;
	float base_scale_roughness;
	float base_scale_uv;
	vec3 base_albedo;
	float base_scale_displ;

	if (splatmap_layer == 0) {
		if (north_border_pixel && west_border_pixel && u_north_west_ground_layers.x >= 0.0 && u_north_ground_layers.x >= 0.0) {
			if (north_west_border_pixel) {
				fetch_base_values0(u_north_west_ground_layers.x, base_albedo, base_scale_displ);
				fetch_base_values1(u_north_west_ground_layers.x, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

				vec4 north_west_ad = fetch_texture_albedo_displ(uv, u_north_west_ground_layers.x, base_scale_uv, base_albedo, base_scale_displ);
				vec4 north_west_nr = fetch_texture_normal_roughness(uv, u_north_west_ground_layers.x, base_scale_uv, base_scale_roughness);

				normal_map_scale = base_scale_normal;
				out_nr = north_west_nr;
				return north_west_ad;
			} else {
				fetch_base_values0(u_north_ground_layers.x, base_albedo, base_scale_displ);
				fetch_base_values1(u_north_ground_layers.x, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

				vec4 north_ad = fetch_texture_albedo_displ(uv, u_north_ground_layers.x, base_scale_uv, base_albedo, base_scale_displ);
				vec4 north_nr = fetch_texture_normal_roughness(uv, u_north_ground_layers.x, base_scale_uv, base_scale_roughness);

				normal_map_scale = base_scale_normal;
				out_nr = north_nr;
				return north_ad;
			}
		}

		if (north_border_pixel && u_north_ground_layers.x >= 0.0) {
			fetch_base_values0(u_north_ground_layers.x, base_albedo, base_scale_displ);
			fetch_base_values1(u_north_ground_layers.x, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

			vec4 north_ad = fetch_texture_albedo_displ(uv, u_north_ground_layers.x, base_scale_uv, base_albedo, base_scale_displ);
			vec4 north_nr = fetch_texture_normal_roughness(uv, u_north_ground_layers.x, base_scale_uv, base_scale_roughness);

			normal_map_scale = base_scale_normal;
			out_nr = north_nr;
			return north_ad;
		}

		if (west_border_pixel && u_west_ground_layers.x >= 0.0) {
			fetch_base_values0(u_west_ground_layers.x, base_albedo, base_scale_displ);
			fetch_base_values1(u_west_ground_layers.x, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

			vec4 west_ad = fetch_texture_albedo_displ(uv, u_west_ground_layers.x, base_scale_uv, base_albedo, base_scale_displ);
			vec4 west_nr = fetch_texture_normal_roughness(uv, u_west_ground_layers.x, base_scale_uv, base_scale_roughness);

			normal_map_scale = base_scale_normal;
			out_nr = west_nr;
			return west_ad;
		}

		if (u_ground_layers.x >= 0.0) {
			fetch_base_values0(u_ground_layers.x, base_albedo, base_scale_displ);
			fetch_base_values1(u_ground_layers.x, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

			normal_map_scale = base_scale_normal;
			out_nr = fetch_texture_normal_roughness(uv, u_ground_layers.x, base_scale_uv, base_scale_roughness);
			return fetch_texture_albedo_displ(uv, u_ground_layers.x, base_scale_uv, base_albedo, base_scale_displ);
		} else {
			normal_map_scale = 1.0;
			out_nr = vec4(1.0, 1.0, 1.0, 1.0);
			return vec4(1.0, 1.0, 1.0, 1.0);
		}
	} else if (splatmap_layer == 1) {
		if (north_border_pixel && west_border_pixel && u_north_west_ground_layers.y >= 0.0 && u_north_ground_layers.y >= 0.0) {
			if (north_west_border_pixel) {
				fetch_base_values0(u_north_west_ground_layers.y, base_albedo, base_scale_displ);
				fetch_base_values1(u_north_west_ground_layers.y, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

				vec4 north_west_ad = fetch_texture_albedo_displ(uv, u_north_west_ground_layers.y, base_scale_uv, base_albedo, base_scale_displ);
				vec4 north_west_nr = fetch_texture_normal_roughness(uv, u_north_west_ground_layers.y, base_scale_uv, base_scale_roughness);

				normal_map_scale = base_scale_normal;
				out_nr = north_west_nr;
				return north_west_ad;
			} else {
				fetch_base_values0(u_north_ground_layers.y, base_albedo, base_scale_displ);
				fetch_base_values1(u_north_ground_layers.y, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

				vec4 north_west_ad = fetch_texture_albedo_displ(uv, u_north_ground_layers.y, base_scale_uv, base_albedo, base_scale_displ);
				vec4 north_west_nr = fetch_texture_normal_roughness(uv, u_north_ground_layers.y, base_scale_uv, base_scale_roughness);

				normal_map_scale = base_scale_normal;
				out_nr = north_west_nr;
				return north_west_ad;
			}
		}

		if (north_border_pixel && u_north_ground_layers.y >= 0.0) {
			fetch_base_values0(u_north_ground_layers.y, base_albedo, base_scale_displ);
			fetch_base_values1(u_north_ground_layers.y, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

			vec4 north_ad = fetch_texture_albedo_displ(uv, u_north_ground_layers.y, base_scale_uv, base_albedo, base_scale_displ);
			vec4 north_nr = fetch_texture_normal_roughness(uv, u_north_ground_layers.y, base_scale_uv, base_scale_roughness);

			normal_map_scale = base_scale_normal;
			out_nr = north_nr;
			return north_ad;
		}

		if (west_border_pixel && u_west_ground_layers.y >= 0.0) {
			fetch_base_values0(u_west_ground_layers.y, base_albedo, base_scale_displ);
			fetch_base_values1(u_west_ground_layers.y, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

			vec4 west_ad = fetch_texture_albedo_displ(uv, u_west_ground_layers.y, base_scale_uv, base_albedo, base_scale_displ);
			vec4 west_nr = fetch_texture_normal_roughness(uv, u_west_ground_layers.y, base_scale_uv, base_scale_roughness);

			normal_map_scale = base_scale_normal;
			out_nr = west_nr;
			return west_ad;
		}

		if (u_ground_layers.y >= 0.0) {
			fetch_base_values0(u_ground_layers.y, base_albedo, base_scale_displ);
			fetch_base_values1(u_ground_layers.y, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

			normal_map_scale = base_scale_normal;
			out_nr = fetch_texture_normal_roughness(uv, u_ground_layers.y, base_scale_uv, base_scale_roughness);
			return fetch_texture_albedo_displ(uv, u_ground_layers.y, base_scale_uv, base_albedo, base_scale_displ);
		} else {
			normal_map_scale = 1.0;
			out_nr = vec4(1.0, 1.0, 1.0, 1.0);
			return vec4(1.0, 1.0, 1.0, 1.0);
		}
	} else if (splatmap_layer == 2) {
		if (north_border_pixel && west_border_pixel && u_north_west_ground_layers.z >= 0.0 && u_north_ground_layers.y >= 0.0) {
			if (north_west_border_pixel) {
				fetch_base_values0(u_north_west_ground_layers.z, base_albedo, base_scale_displ);
				fetch_base_values1(u_north_west_ground_layers.z, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

				vec4 north_west_ad = fetch_texture_albedo_displ(uv, u_north_west_ground_layers.z, base_scale_uv, base_albedo, base_scale_displ);
				vec4 north_west_nr = fetch_texture_normal_roughness(uv, u_north_west_ground_layers.z, base_scale_uv, base_scale_roughness);

				normal_map_scale = base_scale_normal;
				out_nr = north_west_nr;
				return north_west_ad;
			} else {
				fetch_base_values0(u_north_ground_layers.z, base_albedo, base_scale_displ);
				fetch_base_values1(u_north_ground_layers.z, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

				vec4 north_ad = fetch_texture_albedo_displ(uv, u_north_ground_layers.z, base_scale_uv, base_albedo, base_scale_displ);
				vec4 north_nr = fetch_texture_normal_roughness(uv, u_north_ground_layers.z, base_scale_uv, base_scale_roughness);

				normal_map_scale = base_scale_normal;
				out_nr = north_nr;
				return north_ad;
			}
		}

		if (north_border_pixel && u_north_ground_layers.z >= 0.0) {
			fetch_base_values0(u_north_ground_layers.z, base_albedo, base_scale_displ);
			fetch_base_values1(u_north_ground_layers.z, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

			vec4 north_ad = fetch_texture_albedo_displ(uv, u_north_ground_layers.z, base_scale_uv, base_albedo, base_scale_displ);
			vec4 north_nr = fetch_texture_normal_roughness(uv, u_north_ground_layers.z, base_scale_uv, base_scale_roughness);

			normal_map_scale = base_scale_normal;
			out_nr = north_nr;
			return north_ad;
		}

		if (west_border_pixel && u_west_ground_layers.z >= 0.0) {
			fetch_base_values0(u_west_ground_layers.z, base_albedo, base_scale_displ);
			fetch_base_values1(u_west_ground_layers.z, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

			vec4 west_ad = fetch_texture_albedo_displ(uv, u_west_ground_layers.z, base_scale_uv, base_albedo, base_scale_displ);
			vec4 west_nr = fetch_texture_normal_roughness(uv, u_west_ground_layers.z, base_scale_uv, base_scale_roughness);

			normal_map_scale = base_scale_normal;
			out_nr = west_nr;
			return west_ad;
		}

		if (u_ground_layers.z >= 0.0) {
			fetch_base_values0(u_ground_layers.z, base_albedo, base_scale_displ);
			fetch_base_values1(u_ground_layers.z, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

			normal_map_scale = base_scale_normal;
			out_nr = fetch_texture_normal_roughness(uv, u_ground_layers.z, base_scale_uv, base_scale_roughness);
			return fetch_texture_albedo_displ(uv, u_ground_layers.z, base_scale_uv, base_albedo, base_scale_displ);
		} else {
			normal_map_scale = 1.0;
			out_nr = vec4(1.0, 1.0, 1.0, 1.0);
			return vec4(1.0, 1.0, 1.0, 1.0);
		}
	} else {
		if (north_border_pixel && west_border_pixel && u_north_west_ground_layers.a >= 0.0 && u_north_ground_layers.y >= 0.0) {
			if (north_west_border_pixel) {
				fetch_base_values0(u_north_west_ground_layers.a, base_albedo, base_scale_displ);
				fetch_base_values1(u_north_west_ground_layers.a, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

				vec4 north_west_ad = fetch_texture_albedo_displ(uv, u_north_west_ground_layers.a, base_scale_uv, base_albedo, base_scale_displ);
				vec4 north_west_nr = fetch_texture_normal_roughness(uv, u_north_west_ground_layers.a, base_scale_uv, base_scale_roughness);

				normal_map_scale = base_scale_normal;
				out_nr = north_west_nr;
				return north_west_ad;
			} else {
				fetch_base_values0(u_north_ground_layers.a, base_albedo, base_scale_displ);
				fetch_base_values1(u_north_ground_layers.a, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

				vec4 north_ad = fetch_texture_albedo_displ(uv, u_north_ground_layers.a, base_scale_uv, base_albedo, base_scale_displ);
				vec4 north_nr = fetch_texture_normal_roughness(uv, u_north_ground_layers.a, base_scale_uv, base_scale_roughness);

				normal_map_scale = base_scale_normal;
				out_nr = north_nr;
				return north_ad;
			}
		}

		if (north_border_pixel && u_north_ground_layers.a >= 0.0) {
			fetch_base_values0(u_north_ground_layers.a, base_albedo, base_scale_displ);
			fetch_base_values1(u_north_ground_layers.a, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

			vec4 north_ad = fetch_texture_albedo_displ(uv, u_north_ground_layers.a, base_scale_uv, base_albedo, base_scale_displ);
			vec4 north_nr = fetch_texture_normal_roughness(uv, u_north_ground_layers.a, base_scale_uv, base_scale_roughness);

			normal_map_scale = base_scale_normal;
			out_nr = north_nr;
			return north_ad;
		}

		vec4 west_ad = vec4(0.0, 0.0, 0.0, 0.0);
		vec4 west_nr = vec4(0.0, 0.0, 0.0, 0.0);
		bool west_border_pixel_fetched = false;
		if (west_border_pixel && u_west_ground_layers.a >= 0.0) {
			fetch_base_values0(u_west_ground_layers.a, base_albedo, base_scale_displ);
			fetch_base_values1(u_west_ground_layers.a, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

			vec4 west_ad = fetch_texture_albedo_displ(uv, u_west_ground_layers.a, base_scale_uv, base_albedo, base_scale_displ);
			vec4 west_nr = fetch_texture_normal_roughness(uv, u_west_ground_layers.a, base_scale_uv, base_scale_roughness);

			normal_map_scale = base_scale_normal;
			out_nr = west_nr;
			return west_ad;
		}

		if (u_ground_layers.a >= 0.0) {
			fetch_base_values0(u_ground_layers.a, base_albedo, base_scale_displ);
			fetch_base_values1(u_ground_layers.a, base_scale_ao, base_scale_normal, base_scale_roughness, base_scale_uv);

			normal_map_scale = base_scale_normal;
			out_nr = fetch_texture_normal_roughness(uv, u_ground_layers.a, base_scale_uv, base_scale_roughness);
			return fetch_texture_albedo_displ(uv, u_ground_layers.a, base_scale_uv, base_albedo, base_scale_displ);
		} else {
			normal_map_scale = 1.0;
			out_nr = vec4(1.0, 1.0, 1.0, 1.0);
			return vec4(1.0, 1.0, 1.0, 1.0);
		}
	}
}

vec4 depth_blend2(vec4 a_value, float a_bump, vec4 b_value, float b_bump, float t) {
	// https://www.gamasutra.com
	// /blogs/AndreyMishkinis/20130716/196339/Advanced_Terrain_Texture_Splatting.php
	float d = 0.1;
	float ma = max(a_bump + (1.0 - t), b_bump + t) - d;
	float ba = max(a_bump + (1.0 - t) - ma, 0.0);
	float bb = max(b_bump + t - ma, 0.0);
	return (a_value * ba + b_value * bb) / (ba + bb);
}

vec2 rotate(vec2 v, float cosa, float sina) {
	return vec2(cosa * v.x - sina * v.y, sina * v.x + cosa * v.y);
}

vec4 texture_antitile_layers(int splatmap_layer,
	bool north_border_pixel,
	//bool south_border_pixel,
	bool west_border_pixel,
	//bool east_border_pixel,
	bool north_west_border_pixel,
	vec2 uv, out vec4 out_normal, out float normal_map_scale)
{
	float frequency = 2.0;
	float scale = 1.3;
	float sharpness = 0.7;

	// Rotate and scale UV
	float rot = 3.14 * 0.6;
	float cosa = cos(rot);
	float sina = sin(rot);
	vec2 uv2 = rotate(uv, cosa, sina) * scale;

	vec4 nrm0;
	vec4 col0 = texture_ad_nr(splatmap_layer, north_border_pixel, /*south_border_pixel,*/ west_border_pixel, /*east_border_pixel,*/ north_west_border_pixel, uv, nrm0, normal_map_scale);
	//col0 = vec4(0.0, 0.5, 0.5, 1.0); // Highlights variations

	float dummy;
	vec4 nrm1;
	vec4 col1 = texture_ad_nr(splatmap_layer, north_border_pixel, /*south_border_pixel,*/ west_border_pixel, /*east_border_pixel,*/ north_west_border_pixel, uv2, nrm1, dummy);

	// Normals have to be rotated too since we are rotating the texture...
	// TODO Probably not the most efficient but understandable for now
	vec3 n = unpack_normal(nrm1);
	// Had to negate the Y axis for some reason. I never remember the myriad of conventions around
	n.xz = rotate(n.xz, cosa, -sina);
	nrm1 = pack_normal(n, nrm1.a);

	// Periodically alternate between the two versions using a warped checker pattern
	float t = 1.2 +
		  sin(uv2.x * frequency + sin(uv.x) * 2.0)
		* cos(uv2.y * frequency + sin(uv.y) * 2.0); // Result in [0..2]
	t = smoothstep(sharpness, 2.0 - sharpness, t);

	// Using depth blend because classic alpha blending smoothes out details.
	out_normal = depth_blend2(nrm0, col0.a, nrm1, col1.a, t);
	return depth_blend2(col0, col0.a, col1, col1.a, t);
}

vec4 texture_triplanar_ad_nr_layers(int splatmap_layer,
	bool north_border_pixel,
	//bool south_border_pixel,
	bool west_border_pixel,
	//bool east_border_pixel,
	bool north_west_border_pixel,
	vec3 world_pos, vec3 blend,
	out vec4 out_nr, out float normal_map_scale)
{
	float dummy;
	vec4 xaxis_nr;
	vec4 xaxis_ad = texture_ad_nr(splatmap_layer, north_border_pixel, /*south_border_pixel,*/ west_border_pixel, /*east_border_pixel,*/ north_west_border_pixel, world_pos.yz, xaxis_nr, normal_map_scale);
	vec4 yaxis_nr;
	vec4 yaxis_ad = texture_ad_nr(splatmap_layer, north_border_pixel, /*south_border_pixel,*/ west_border_pixel, /*east_border_pixel,*/ north_west_border_pixel, world_pos.xz, yaxis_nr, dummy);
	vec4 zaxis_nr;
	vec4 zaxis_ad = texture_ad_nr(splatmap_layer, north_border_pixel, /*south_border_pixel,*/ west_border_pixel, /*east_border_pixel,*/ north_west_border_pixel, world_pos.xy, zaxis_nr, dummy);

	// blend the results of the 3 planar projections.
	vec4 out_ad = xaxis_ad * blend.x + yaxis_ad * blend.y + zaxis_ad * blend.z;
	out_nr = xaxis_nr * blend.x + yaxis_nr * blend.y + zaxis_nr * blend.z;

	return out_ad;
}

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

void remove_vertex(float f)
{
	f = 0.0 / 0.0;
}

vec3 compute_normal_1(sampler2D heightmap, vec2 vertex_cell_coords_in_textures, sampler2D heightmap_border_rows, vec2 vertex_cell_coords_in_heightmap_optlvl_zero, float grid_step, float terrain_height, bool use_external_borders)
{
	// vertex_cell_coords_in_textures is a 0-based index of the pixel in the heightmap and it ranges from 0 to heightmapSize - 1 (f.i. 1024 or 2048)
	int lod_zero = 0;
	vec2 heightmapSize = vec2(textureSize(heightmap, lod_zero));		// number of vertices per size of the texture f.i. 1025 or 2049 assuming each quadrant size 1024 or 2048
	ivec2 _index = ivec2(vertex_cell_coords_in_textures);
	ivec2 _index_optlvl_zero = ivec2(vertex_cell_coords_in_heightmap_optlvl_zero);
	float h;
	float right_h;
	float bottom_h;
	if (distance(vertex_cell_coords_in_textures.x, heightmapSize.x - 1.0) < 1.0) {
		// the pixel is in the right edge of the heightmap
		if (use_external_borders) {
			h = fetch_height(heightmap, terrain_height, _index);
			right_h = texelFetch(heightmap_border_rows, ivec2(_index_optlvl_zero.y, c_east_quadrant_border_row), lod_zero).r;
			if (distance(vertex_cell_coords_in_textures.y, heightmapSize.y - 1.0) < 1.0) {
				// the pixel is in the bottom/right corner of the heightmap
				bottom_h = texelFetch(heightmap_border_rows, ivec2(_index_optlvl_zero.x, c_south_quadrant_border_row), lod_zero).r;
			} else {
				bottom_h = fetch_height(heightmap, terrain_height, _index + ivec2(0, 1));
			}
		} else {
			h = fetch_height(heightmap, terrain_height, _index - ivec2(1, 0));
			right_h = fetch_height(heightmap, terrain_height, _index);
			bottom_h = fetch_height(heightmap, terrain_height, _index - ivec2(1, -1));
		}
	} else {
		if (distance(vertex_cell_coords_in_textures.y, heightmapSize.y - 1.0) < 1.0) {
			// the pixel is in the bottom edge of the heightmap but not in the bottom/right corner of the heightmap
			if (use_external_borders) {
				h = fetch_height(heightmap, terrain_height, _index);
				right_h = fetch_height(heightmap, terrain_height, _index + ivec2(1, 0));
				bottom_h = texelFetch(heightmap_border_rows, ivec2(_index_optlvl_zero.x, c_south_quadrant_border_row), lod_zero).r;
			} else {
				h = fetch_height(heightmap, terrain_height, _index - ivec2(0, 1));
				right_h = fetch_height(heightmap, terrain_height, _index - ivec2(-1, 1));
				bottom_h = fetch_height(heightmap, terrain_height, _index);
			}
		} else {
			h = fetch_height(heightmap, terrain_height, _index);
			right_h = fetch_height(heightmap, terrain_height, _index + ivec2(1, 0));
			bottom_h = fetch_height(heightmap, terrain_height, _index + ivec2(0, 1));
		}
	}
	return normalize(vec3(h - right_h, grid_step, h - bottom_h));
}

void vertex()
{
	//vec3 camera_pos = gu_camera_pos;
	vec3 camera_pos = MAIN_CAM_INV_VIEW_MATRIX[3].xyz;
	float camera_altitude_from_terrain = u_override_camera_altitude_from_terrain;
	if (camera_altitude_from_terrain < -1.0)
		camera_altitude_from_terrain = gu_camera_altitude_from_terrain;

	bool test_quadrant = u_test_quadrant;
	mat4 terrain_inverse_transform = u_terrain_inverse_transform;
	uint optimization_level = u_optimization_level;
	float grid_step = u_grid_step_optlvl_zero * pow(2.0, float(optimization_level));
	bool show_chunks = gu_show_chunks;
	uint num_vertices_per_chunk = u_num_vertices_per_chunk;

	vec2 heightmapSize = vec2(textureSize(u_terrain_heightmap, c_i_texture_lod_zero));		// Power of 2 + 1 (f.i. 1025, 2049)
	
	vec3 vertex_modelspace_in = VERTEX;

	// VERTEX coords are local to the chunk (because the material is applied to the mesh which is tied to the chunk) so they start from the beginning of the chunk: we need to trasform in world coord to abstract from chunk
	vec4 vertex_worldspace_in = MODEL_MATRIX * vec4(vertex_modelspace_in, 1);

	// to calculate coords of the vertex local to the quadrant we use affine inverse matrix of the global trasform of the quadtree
	vec4 vertex_local_to_quadrant_pos = terrain_inverse_transform * vertex_worldspace_in;		// vertex_local_to_quadrant_pos ranges from 0 to quadrant_size (f.i. 2048, 4096) and is a 0-based index of the vertex in the quadrant
	
	// to get correct value from the textures (in the range 0 / max size in local coord) we need to consider the step
	// (dividing by it): in the textures heights/normals are adjacent but in global/local coords are separated by the step
	// ***  after next line vertex_cell_coords_in_heightmap ranges from 0 to heightmapSize - 1 (heightmapSize vertices per
	// size of quadrant - f.i. 1025 or 2049) so it is a 0-based index of the pixel in heightmap/normalmap/splatmap etc. texture ***
	vec2 vertex_cell_coords_in_heightmap = vertex_local_to_quadrant_pos.xz / vec2(grid_step);	// vertex_cell_coords_in_heightmap ranges from 0 to heightmapSize - 1 (f.i. 1024 or 2048) 0-based index of the pixel in heightmap/normalmap/splatmap
	
	vec2 vertex_cell_coords_in_heightmap_optlvl_zero = vertex_local_to_quadrant_pos.xz / vec2(u_grid_step_optlvl_zero);
	
	// Moreover must add a half-offset so that we sample the center of pixels, otherwise bilinear filtering of the textures
	// will give us mixed results (#183): as we fetch pixels from textures with UV which is a percentage value ranging from
	// 0.0 to 1.0 we have to convert our index (vertex_cell_coords_in_heightmap) in percentage; without summing vec2(0.5)
	// first index 0 would be 0.0 and we could have next indices summing 1 / heightmap size with the second index being
	// 1 / heightmap size and the last index being (heightmap size - 1) / heightmap size. In this way transforming percentages
	// index we touch the exact point where our pixel start and where the previous texture pixel ends so the engine, not knowing
	// which value consider make an interpolation from the values of our texel and the previous but this is not what we want as we
	// want the exact value of the texel; to avoid this we have to sum half so the UV points in the exact medium of the texel
	// (remember tha UV is a percentage that approximate to a vertex index) avoiding linear interpolation.
	// look at https://gamedev.stackexchange.com/questions/46963/how-to-avoid-texture-bleeding-in-a-texture-atlas
	// and https://learn.microsoft.com/it-it/windows/win32/direct3d9/directly-mapping-texels-to-pixels?redirectedfrom=MSDN
	// Normalized UV to be in the range 0/1
	vec2 quadrant_uv = (vertex_cell_coords_in_heightmap + vec2(0.5)) / heightmapSize;	// IMPORTANT: to get correct we must range UV vertex_cell_coords_in_heightmap from 0.5 to (heightmap size - 1) + 0.5 
																						// with increment of 1.0 between each coord than we subdivide by the size of the heightmap 

	vec3 vertex_modelspace_with_h = vertex_modelspace_in;
	vec4 vertex_worldspace_with_h = vertex_worldspace_in;
	{
		float h = get_height(u_terrain_heightmap, u_terrain_height, quadrant_uv);		// Height displacement from heightmap
		bool force_height_0 = u_force_height_0;
		if (!force_height_0) {
			if (gu_force_height_0 > 0) {
				force_height_0 = true;
			}
		}
		//force_height_0 = true;		// DEBUG
		if (force_height_0) {													// Needed to bake globalmap
			vertex_modelspace_with_h.y = 0.0;
			vertex_worldspace_with_h.y = 0.0;
		} else {
			vertex_modelspace_with_h.y = h;
			vertex_worldspace_with_h.y = h;
		}
	}

	vec2 chunk_uv = UV;
	float chunk_texture_lod = -1.0;
	if (!test_quadrant)
	{
		int vertex_id = VERTEX_ID;
		int vertex_col = int(floor(mod(float(vertex_id), float(num_vertices_per_chunk))));		// from 0 to num_vertices_per_chunk - 1
		int vertex_row = int(floor(float(vertex_id) / float(num_vertices_per_chunk)));			// from 0 to num_vertices_per_chunk - 1

		float step_between_vertices_in_current_chunk = -1000000000.0;
		float chunk_size = -1000000000.0;
		chunk_uv = vec2(0.0, 0.0);
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
				chunk_size = step_between_vertices_in_current_chunk * float(num_vertices_per_chunk - uint(1));
				chunk_uv = vertex_modelspace_in.xz / vec2(chunk_size);
			}
		}

		if (show_chunks)
		{
			if ((vertex_col == 0 && vertex_row == 0) || (vertex_col == 0 && vertex_row == int(num_vertices_per_chunk - uint(1)))
				|| (vertex_col == int(num_vertices_per_chunk - uint(1)) && vertex_row == 0) || (vertex_col == int(num_vertices_per_chunk - uint(1)) && vertex_row == int(num_vertices_per_chunk - uint(1))))
			{
				chunk_texture_lod = 99.0;
			}
			else
			{
				chunk_texture_lod = log2(step_between_vertices_in_current_chunk) - 1.0;
			}
		}
	}

	float distance_from_camera = distance(vertex_worldspace_with_h.xyz, camera_pos);
	float distance_from_vertical_of_camera_on_terrain = distance(vertex_worldspace_with_h.xyz, vec3(camera_pos.x, camera_pos.y - camera_altitude_from_terrain, camera_pos.z));

	bool _compute_normal = false;
	bool _compute_splat = false;

	vec3 normal_computed;
	if (_compute_normal)
	{
		bool use_external_borders = true;
		normal_computed = compute_normal_1(u_terrain_heightmap, vertex_cell_coords_in_heightmap, u_terrain_heightmap_border_rows, vertex_cell_coords_in_heightmap_optlvl_zero, grid_step, u_terrain_height, use_external_borders);
	}
	else
	{
		normal_computed = get_normal(u_terrain_normalmap, u_terrain_normal_basis, quadrant_uv);
	}
	//normal_computed = normalize(vec3(1.0, 1.0, 1.0));		// DEBUG

	vec4 splat;
	if (_compute_splat)
	{
		float splat_slope_vertical_factor = u_splat_slope_vertical_factor;
		float splat_slope_flat_factor = u_splat_slope_flat_factor;
		float splat_dirt_on_rocks_factor = u_splat_dirt_on_rocks_factor;
		float splat_high_elevation_factor = u_splat_high_elevation_factor;
		float splat_low_elevation_factor = u_splat_low_elevation_factor;
		float splat_min_height = u_splat_min_height;
		float splat_max_height = u_splat_max_height;
		//splat_slope_vertical_factor = 4.0;	// DEBUG
		//splat_slope_flat_factor = 1.0;		// DEBUG
		//splat_dirt_on_rocks_factor = 2.0;		// DEBUG
		//splat_high_elevation_factor = 4.0;	// DEBUG
		//splat_low_elevation_factor = 2.0;		// DEBUG
		//splat_min_height = 0.0;				// DEBUG
		//splat_max_height = 0.0;				// DEBUG
		splat = compute_splat(u_terrain_heightmap, vertex_cell_coords_in_heightmap, grid_step, u_terrain_height, normal_computed, splat_slope_vertical_factor, splat_slope_flat_factor, splat_dirt_on_rocks_factor, splat_high_elevation_factor, splat_low_elevation_factor, splat_min_height, splat_max_height);
	}
	else
	{
		splat = textureLod(u_terrain_splatmap, quadrant_uv, c_f_texture_lod_zero);
	}
	//splat = vec4(1.0);	// DEBUG

	vec3 tint0 = vec3(1.0, 1.0, 1.0);
	vec3 tint1 = vec3(1.0, 1.0, 1.0);
	vec3 tint2 = vec3(1.0, 1.0, 1.0);
	vec3 tint3 = vec3(1.0, 1.0, 1.0);
	/*{
		vec4 tint = textureLod(u_terrain_colormap, quadrant_uv, c_f_texture_lod_zero);
		tint0 = mix(vec3(1.0), tint.rgb, u_colormap_opacity_per_texture.x);	// decreasing u_colormap_opacity_per_texture dimensions approximates vector tint (u_terrain_colormap texel) to white: each dimnesion (1-4) acts
		tint1 = mix(vec3(1.0), tint.rgb, u_colormap_opacity_per_texture.y);	// on the corresponding bump_map (1-4). More precisely u_colormap_opacity_per_texture.(x-w) must be in the interval 0-1, if 0 the function returns
		tint2 = mix(vec3(1.0), tint.rgb, u_colormap_opacity_per_texture.z);	// vec3(1.0) if 1 (default value) the function returns tint.rgb
		tint3 = mix(vec3(1.0), tint.rgb, u_colormap_opacity_per_texture.w);
	}*/

	//********************************************************************************************************************
	//     Test PBR
	//********************************************************************************************************************
	/*vec2 uv_texture = quadrant_uv * uv1_scale.xy + uv1_offset.xy;
	vertex_modelspace_with_h.y += texture(texture_displacement, uv_texture).r * heightmap_scale;*/
	//********************************************************************************************************************
	//     Test PBR
	//********************************************************************************************************************

// Output
	VERTEX = vertex_modelspace_with_h;
	NORMAL = normal_computed;
	UV = chunk_uv;
	UV2 = quadrant_uv;

	// Using skip_vertex_transform we need to manually transform VERTEX, NORMAL, BINORMAL and TANGENT form model space to view (camera) space
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	BINORMAL = normalize((MODELVIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz);
	TANGENT = normalize((MODELVIEW_MATRIX * vec4(TANGENT, 0.0)).xyz);

// Varyings
	v_vertex_cell_coords_in_heightmap = vertex_cell_coords_in_heightmap;		// vertex_cell_coords_in_heightmap ranges from 0 to heightmapSize - 1 ((f.i. 1024 or 2048) counting heightmap size vertices (f.i. 1025, 2049) ==> 0-based index of the pixel in the heightmap etc.
	v_vertex_worldspace = vertex_worldspace_with_h;
	//v_grid_step = grid_step;
	v_splat = splat;
	v_tint0 = tint0;
	v_tint1 = tint1;
	v_tint2 = tint2;
	v_tint3 = tint3;
	v_distance_from_camera = distance_from_camera;
	v_distance_from_vertical_of_camera_on_terrain = distance_from_vertical_of_camera_on_terrain;
	v_chunk_texture_lod = chunk_texture_lod;
}

void fragment()
{

// Uniforms
	bool test_quadrant = u_test_quadrant;
	uint num_vertices_per_chunk = u_num_vertices_per_chunk;
	float editmode_selected = u_editmode_selected;
	//bool triplanar = u_triplanar;
	bool triplanar = false;		// fortemente buggato: da verificare
	//uint piecing_threshold_factor = u_piecing_threshold_factor;
	float piece_size = gu_piece_size;
	//float scale_per_texture_factor = u_scale_per_texture_factor;
	float camera_altitude_from_terrain = u_override_camera_altitude_from_terrain;
	if (camera_altitude_from_terrain < -1.0)
		camera_altitude_from_terrain = gu_camera_altitude_from_terrain;
	//float camera_altitude_uv_scale_threshold = gu_camera_altitude_uv_scale_threshold;
	bool need_blending = u_need_blending;
	bool grid_on = u_grid_on;
	vec2 mouse_hit_in_quadrant_uv = u_mouse_hit_uv_quadrant;
	float mouse_hit_radius = u_mouse_hit_radius;
	bool force_height_0 = u_force_height_0;
	if (!force_height_0) {
		if (gu_force_height_0 > 0) {
			force_height_0 = true;
		}
	}
	
	vec2 heightmapSize = vec2(textureSize(u_terrain_heightmap, c_i_texture_lod_zero));

// Input from Vertex
	vec3 vertex_in = VERTEX;
	vec2 chunk_uv = UV;
	vec2 quadrant_uv = UV2;

	//float grid_step = floor(v_grid_step);

// Varyings
	//vec2 vertex_cell_coords_in_heightmap = floor(v_vertex_cell_coords_in_heightmap);
	vec4 vertex_worldspace = v_vertex_worldspace;
	float distance_from_camera = v_distance_from_camera;
	float distance_from_vertical_of_camera_on_terrain = v_distance_from_vertical_of_camera_on_terrain;
	vec4 splat_pixel_in = v_splat;
	float quadrant_texture_lod = v_chunk_texture_lod;

	float quad_line_thickness = 0.05;

	vec3 albedo_computed = vec3(0.0, 0.0, 0.0);
	float ground_normal_scale = gu_ground_normal_scale;
	float ao_computed = 0.0;
	float ao_light_affect_computed = 0.0;
	float roughness_computed = 1.0;

	// Terrain normals, tangents and binormals
	vec3 normal_computed, tanget_computed, binormal_computed, ground_normal_computed;
	{
		/*		// DEBUG
		{
			// 1. Calcola la dimensione del pixel per campionare i vicini
			vec2 texel_size = 1.0 / heightmapSize;
			texel_size *= 0.001;
			float height_scale = 1.0;
			
			// 2. Campionamento manuale (Central Difference)
			// Usiamo textureLod(..., 0.0) per evitare artefatti da mipmap ai bordi
			float h_l = textureLod(u_terrain_heightmap, quadrant_uv + vec2(-texel_size.x, 0.0), 0.0).r;
			float h_r = textureLod(u_terrain_heightmap, quadrant_uv + vec2(texel_size.x, 0.0), 0.0).r;
			float h_u = textureLod(u_terrain_heightmap, quadrant_uv + vec2(0.0, -texel_size.y), 0.0).r;
			float h_d = textureLod(u_terrain_heightmap, quadrant_uv + vec2(0.0, texel_size.y), 0.0).r;
	
			// 3. Ricostruzione della Normale
			// Il fattore 2.0 serve per bilanciare il campionamento centrale
			vec3 normal;
			normal.x = (h_l - h_r) * height_scale;
			normal.z = (h_u - h_d) * height_scale;
			normal.y = 2.0 * texel_size.x; // Regola l'intensità in base alla scala del mondo
			
			NORMAL = normalize(normal);
		}
		*/		// DEBUG
		normal_computed = NORMAL;
		tanget_computed = normalize(cross(normal_computed, vec3(0.0, 0.0, 1.0)));
		binormal_computed = normalize(cross(normal_computed, tanget_computed));
	}

	//
	// Pixel type assignment
	//
	const int texture_pixel = 0;
	const int editmode_border_pixel = 1;
	const int wireframe_pixel = 2;
	const int show_chunk_pixel = 3;
	int pixel_type = texture_pixel;
	{
		if (editmode_selected > 0.0 && is_on_the_border(quadrant_uv, u_quad_border_line_thickness)) {
			pixel_type = editmode_border_pixel;
		} else {
			// Show wireframe and need blending management
			if (!gu_show_need_blending)
				need_blending = false;

			bool wireframe = false;
			if (test_quadrant) {
				wireframe = u_test_quadrant_show_wireframe;
			} else {
				wireframe = need_blending;
				if (!wireframe)
					wireframe = u_show_wireframe;
			}

			if (wireframe)
				pixel_type = wireframe_pixel;
			else if (quadrant_texture_lod >= 0.0)
				pixel_type = show_chunk_pixel;
		}
	}

	//
	// Changing resolution (UV management)
	//
	//float ground_uv_scale_per_texture = 1.0;
	float ground_uv_scale_per_texture = u_ground_uv_scale_per_texture.r;
	vec3 ground_texture_uv = vec3(0.0);
	int pieces_from_camera_piece = 0;
	if (pixel_type == texture_pixel)
	{
		float max_distance_for_uv_scale = gu_camera_distance_uv_scale_threshold;
		if (distance_from_camera < max_distance_for_uv_scale)
		{
			pieces_from_camera_piece = -1;

			if (distance_from_vertical_of_camera_on_terrain < c_ground_uv_scale_horiz_threshold)
			{
				if (camera_altitude_from_terrain >= 0.0 && camera_altitude_from_terrain < c_ground_uv_scale_vert_threshold)
				{
					vec3 fragment_world_pos = (INV_VIEW_MATRIX * vec4(vertex_in, 1.0)).xyz;
					int camera_piece_x = int(floor(CAMERA_POSITION_WORLD.x / piece_size));
					int camera_piece_z = int(floor(CAMERA_POSITION_WORLD.z / piece_size));
					int frag_piece_x = int(floor(fragment_world_pos.x / piece_size));
					int frag_piece_z = int(floor(fragment_world_pos.z / piece_size));
					pieces_from_camera_piece = max(int(abs(camera_piece_x - frag_piece_x)), int(abs(camera_piece_z - frag_piece_z)));
					if (pieces_from_camera_piece <= 1)
					{
						float uv0 = 15.0;
						if (distance_from_camera < 50.0 && camera_altitude_from_terrain < 10.0)		// 15-30
							uv0 = c_max_ground_uv_scale_per_texture;		//120.0;
						else if (camera_altitude_from_terrain < 100.0)
							uv0 = 20.0;		//40.0;
						//uv0 = gu_debug_float0;		// DEBUG

						ground_uv_scale_per_texture *= uv0;
					}
					else if (pieces_from_camera_piece <= 3)
					{
						float uv1 = 5.0;
						if (camera_altitude_from_terrain < 100.0)		// 5-10
							uv1 = 10.0;
						//uv1 = gu_debug_float1;		// DEBUG

						ground_uv_scale_per_texture *= uv1;
					}
					else if (pieces_from_camera_piece <= 5)
					{
						float uv2 = 4.0;
						if (camera_altitude_from_terrain < 100.0)
							uv2 = 10.0;
						//uv2 = gu_debug_float2;		// DEBUG

						ground_uv_scale_per_texture *= uv2;
					}
					else if (pieces_from_camera_piece <= 7)
					{
						float uv3 = 3.0;
						if (camera_altitude_from_terrain < 100.0)
							uv3 = 5.0;
						//uv3 = gu_debug_float3;		// DEBUG

						ground_uv_scale_per_texture *= uv3;
					}
					else if (pieces_from_camera_piece <= 9)
					{
						float uv4 = 2.0;
						if (camera_altitude_from_terrain < 100.0)
							uv4 = 5.0;
						//uv4 = gu_debug_float4;		// DEBUG

						ground_uv_scale_per_texture *= uv4;
					}
					else if (pieces_from_camera_piece <= 11)
					{
						float uv5 = 1.0;
						if (camera_altitude_from_terrain < 100.0)
							uv5 = 1.0;
						//uv5 = gu_debug_float5;		// DEBUG

						ground_uv_scale_per_texture *= uv5;
					}
				}
				else if (camera_altitude_from_terrain <= c_ground_uv_scale_vert_threshold * 2.0)
				{
					if (distance_from_vertical_of_camera_on_terrain < (c_ground_uv_scale_horiz_threshold / 2.0))
					{
						ground_uv_scale_per_texture = 5.0;
					}
					else
					{
						ground_uv_scale_per_texture = 3.0;
					}
				}
				else if (camera_altitude_from_terrain <= c_ground_uv_scale_vert_threshold * 3.0)
				{
					ground_uv_scale_per_texture = 3.0;
				}
				else if (camera_altitude_from_terrain <= c_ground_uv_scale_vert_threshold * 4.0)
				{
					ground_uv_scale_per_texture = 2.0;
				}
			}
		}

		//ground_uv_scale_per_texture = 1.0;		// DEBUGUV	UV not modified
		//ground_uv_scale_per_texture = 30.0;		// DEBUGUV

		vec3 base_ground_texture_uv = vec3(quadrant_uv.x, vertex_worldspace.y * MODEL_MATRIX[1][1], quadrant_uv.y);
		//vec3 base_ground_texture_uv = vec3(quadrant_uv.x, vertex_worldspace.y, quadrant_uv.y);
		vec3 modified_ground_texture_uv = base_ground_texture_uv * ground_uv_scale_per_texture;
		ground_texture_uv = modified_ground_texture_uv;
	}

	//
	// Quadrant border pixels management
	//
	bool north_border_pixel = false;
	//bool south_border_pixel = false;
	bool west_border_pixel = false;
	//bool east_border_pixel = false;
	bool north_west_border_pixel = false;
	if (pixel_type == texture_pixel)
	{
		float distance_texel = texture(gu_terrain_quad_border_distance, quadrant_uv).x;
		float distance_from_border = distance_texel * gu_texture_overflow_size;

		if (is_on_upper_border(quadrant_uv, distance_from_border)) {
			north_border_pixel = true;
		}
		if (is_on_left_border(quadrant_uv, distance_from_border)) {
			west_border_pixel = true;
		}
		//if (is_on_lower_border(quadrant_uv, distance_from_border)) {
		//	south_border_pixel = true;
		//}
		//if (is_on_right_border(quadrant_uv, distance_from_border)) {
		//	east_border_pixel = true;
		//}

		if (north_border_pixel && west_border_pixel)
		{
			if (quadrant_uv.x > (quadrant_uv.y - distance_from_border / 6.0)) {
				//west_border_pixel = false;
			} else {
				//north_border_pixel = false;
				//west_border_pixel = false;
				north_west_border_pixel = true;
			}
		}
	}

	// If west_border_pixel or north_border_pixel we will use neighbours texture layers so we have to use splatmap values accordingly
	vec4 splat_pixel_computed = splat_pixel_in;
	if (north_border_pixel || west_border_pixel) {
		if (north_border_pixel) {
			if (north_west_border_pixel) {
				//vec2 pixel_uv = vec2(quadrant_uv.y, 0.5);
				//splat_pixel_computed = texture(u_west_border_splatmap, pixel_uv);
				splat_pixel_computed = u_north_west_corner_splatmap_texel;
			} else {
				vec2 pixel_uv = vec2(quadrant_uv.x, 0.5);
				splat_pixel_computed = texture(u_north_border_splatmap, pixel_uv);
			}
		}
		else {
			vec2 pixel_uv = vec2(quadrant_uv.y, 0.5);
			splat_pixel_computed = texture(u_west_border_splatmap, pixel_uv);
		}
	}


	//
	// Quadrant textures management (mixing them according to splatmap etc.)
	//
	if (pixel_type == texture_pixel)
	{
		vec4 tile_reduction_per_texture = u_tile_reduction_per_texture;

		vec4 ab0 = vec4(0.0, 0.0, 0.0, 0.0);
		vec4 ab1 = vec4(0.0, 0.0, 0.0, 0.0);
		vec4 ab2 = vec4(0.0, 0.0, 0.0, 0.0);
		vec4 ab3 = vec4(0.0, 0.0, 0.0, 0.0);
		vec4 nr0 = vec4(0.0, 0.0, 0.0, 0.0);
		vec4 nr1 = vec4(0.0, 0.0, 0.0, 0.0);
		vec4 nr2 = vec4(0.0, 0.0, 0.0, 0.0);
		vec4 nr3 = vec4(0.0, 0.0, 0.0, 0.0);
		float normal_map_scale0 = 1.0;
		float normal_map_scale1 = 1.0;
		float normal_map_scale2 = 1.0;
		float normal_map_scale3 = 1.0;
		vec4 ao0 = vec4(0.0, 0.0, 0.0, 0.0);
		vec4 ao1 = vec4(0.0, 0.0, 0.0, 0.0);
		vec4 ao2 = vec4(0.0, 0.0, 0.0, 0.0);
		vec4 ao3 = vec4(0.0, 0.0, 0.0, 0.0);
		{
			int splatmap_layer = 3;
			//splatmap_layer = 2;	// DEBUG
			if (triplanar) {
				vec3 blending = get_triplanar_blend(normal_computed);
				ab3 = texture_triplanar_ad_nr_layers(splatmap_layer, north_border_pixel, /*south_border_pixel,*/ west_border_pixel, /*east_border_pixel,*/ north_west_border_pixel, ground_texture_uv, blending, nr3, normal_map_scale3);

			} else {
				if (tile_reduction_per_texture[splatmap_layer] > 0.0) {
					ab3 = texture_antitile_layers(splatmap_layer, north_border_pixel, /*south_border_pixel,*/ west_border_pixel, /*east_border_pixel,*/ north_west_border_pixel, ground_texture_uv.xz, nr3, normal_map_scale3);
				} else {
					ab3 = texture_ad_nr(splatmap_layer, north_border_pixel, /*south_border_pixel,*/ west_border_pixel, /*east_border_pixel,*/ north_west_border_pixel, ground_texture_uv.xz, nr3, normal_map_scale3);
				}
			}
			ao3 = vec4(ab3.a);

			splatmap_layer = 0;
			//splatmap_layer = 2;	// DEBUG
			if (tile_reduction_per_texture[splatmap_layer] > 0.0) {
				ab0 = texture_antitile_layers(splatmap_layer, north_border_pixel, /*south_border_pixel,*/ west_border_pixel, /*east_border_pixel,*/ north_west_border_pixel, ground_texture_uv.xz, nr0, normal_map_scale0);
			} else {
				ab0 = texture_ad_nr(splatmap_layer, north_border_pixel, /*south_border_pixel,*/ west_border_pixel, /*east_border_pixel,*/ north_west_border_pixel, ground_texture_uv.xz, nr0, normal_map_scale0);
			}
			ao0 = vec4(ab0.a);

			splatmap_layer = 1;
			//splatmap_layer = 2;	// DEBUG
			if (tile_reduction_per_texture[splatmap_layer] > 0.0) {
				ab1 = texture_antitile_layers(splatmap_layer, north_border_pixel, /*south_border_pixel,*/ west_border_pixel, /*east_border_pixel,*/ north_west_border_pixel, ground_texture_uv.xz, nr1, normal_map_scale1);
			} else {
				ab1 = texture_ad_nr(splatmap_layer, north_border_pixel, /*south_border_pixel,*/ west_border_pixel, /*east_border_pixel,*/ north_west_border_pixel, ground_texture_uv.xz, nr1, normal_map_scale1);
			}
			ao1 = vec4(ab1.a);

			splatmap_layer = 2;
			if (tile_reduction_per_texture[splatmap_layer] > 0.0) {
				ab2 = texture_antitile_layers(splatmap_layer, north_border_pixel, /*south_border_pixel,*/ west_border_pixel, /*east_border_pixel,*/ north_west_border_pixel, ground_texture_uv.xz, nr2, normal_map_scale2);
			} else {
				ab2 = texture_ad_nr(splatmap_layer, north_border_pixel, /*south_border_pixel,*/ west_border_pixel, /*east_border_pixel,*/ north_west_border_pixel, ground_texture_uv.xz, nr2, normal_map_scale2);
			}
			ao2 = vec4(ab2.a);

			// DEBUG
			/*vec3 red = vec3(1.0, 0.0, 0.0);
			vec3 green = vec3(0.0, 1.0, 0.0);
			vec3 blue = vec3(0.0, 0.0, 1.0);
			vec3 yellow = c_apricot_color;
			if (north_border_pixel)	{
				ab0.rgb = red;
				ab1.rgb = red;
				ab2.rgb = red;
				ab3.rgb = red;
			}
			if (south_border_pixel)	{
				ab0.rgb = green;
				ab1.rgb = green;
				ab2.rgb = green;
				ab3.rgb = green;
			}
			if (west_border_pixel)	{
				ab0.rgb = blue;
				ab1.rgb = blue;
				ab2.rgb = blue;
				ab3.rgb = blue;
			}
			if (east_border_pixel)	{
				ab0.rgb = yellow;
				ab1.rgb = yellow;
				ab2.rgb = yellow;
				ab3.rgb = yellow;
			}*/
			// DEBUG
		}

		vec3 tint0 = v_tint0;
		vec3 tint1 = v_tint1;
		vec3 tint2 = v_tint2;
		vec3 tint3 = v_tint3;

		bool depth_blending = u_depth_blending;

		{
			vec3 col0 = ab0.rgb * tint0;
			vec3 col1 = ab1.rgb * tint1;
			vec3 col2 = ab2.rgb * tint2;
			vec3 col3 = ab3.rgb * tint3;

			vec4 rough = vec4(nr0.a, nr1.a, nr2.a, nr3.a);
			vec4 ao = vec4(ao0.r, ao1.r, ao2.r, ao3.r);

			vec3 normal0 = nr0.rgb;
			vec3 normal1 = nr1.rgb;
			vec3 normal2 = nr2.rgb;
			vec3 normal3 = nr3.rgb;

			vec4 w;
			if (depth_blending) {
				//float ground_heightmap_displ = gu_ground_heightmap_displ;
				vec4 bumps = vec4(ab0.a, ab1.a, ab2.a, ab3.a) /*+ ground_heightmap_displ*/;
				w = get_depth_blended_weights(splat_pixel_computed, bumps);
			} else {
				w = splat_pixel_computed.rgba;
			}

			float w_sum = (w.r + w.g + w.b + w.a);

			albedo_computed = (w.r * col0.rgb + w.g * col1.rgb + w.b * col2.rgb + w.a * col3.rgb) / w_sum;
			//albedo_computed = col0.rgb;		// DEBUG
			albedo_computed = gu_ground_albedo_modifier.rgb * albedo_computed;

			float ground_roughness_scale = gu_ground_roughness_scale;
			roughness_computed = (w.r * rough.r + w.g * rough.g + w.b * rough.b + w.a * rough.a) / w_sum;
			//roughness_computed = rough.r;	// DEBUG
			roughness_computed = roughness_computed * ground_roughness_scale;

			vec3 ground_normal = (w.r * normal0 + w.g * normal1 + w.b * normal2 + w.a * normal3) / w_sum;
			//ground_normal = normal0;		// DEBUG
			ground_normal_computed = normalize(ground_normal);

			const float max_distance_for_normal_scale = 10000.0;
			if (distance_from_camera > max_distance_for_normal_scale)
			{
				ground_normal_scale = 1.0;
			}
			else
			{
				ground_normal_scale = ground_normal_scale * ((w.r * normal_map_scale0 + w.g * normal_map_scale1 + w.b * normal_map_scale2 + w.a * normal_map_scale3) / w_sum);
				float normal_scale_increment = abs(ground_normal_scale - 1.0);
				ground_normal_scale = 1.0 + normal_scale_increment * smoothstep(max_distance_for_normal_scale, 0.0, distance_from_camera);		// smoothstep = 0 if distance_from_camera >= max_distance_for_normal_scale, grows to 1.0 if distance_from_camera decreases to zero
			}
			//ground_normal_scale = 1.0;	// DEBUG

			ao_computed = (w.r * ao.r + w.g * ao.g + w.b * ao.b + w.a * ao.a) / w_sum;;
			//ao_computed = ao.r;		// DEBUG
			float ground_ao_light_affect = gu_ground_ao_light_affect;
			if (ground_ao_light_affect == 0.0)
				ground_ao_light_affect = 0.000001;
			float max_view_distance = 40000.0 * ground_ao_light_affect;
			//ao_light_affect_computed = clamp(0.0, 1.0, max_view_distance / distance_from_camera);
			ao_light_affect_computed = smoothstep(0.0, max_view_distance, distance_from_camera);
			//ao_light_affect_computed = 0.0;		// DEBUG
		}

		/*{
			const float line_thickness = 0.3;
			if ((ground_texture_uv.x >= 0.0 && ground_texture_uv.x < line_thickness) || (ground_texture_uv.x <= 1.0 && ground_texture_uv.x > 1.0 - line_thickness)
				|| (ground_texture_uv.z >= 0.0 && ground_texture_uv.z < line_thickness) || (ground_texture_uv.z <= 1.0 && ground_texture_uv.z > 1.0 - line_thickness))
				albedo_computed = vec3(1.0, 0.0, 0.0);
		}*/
	}

	//
	// Highlight grid inside grid radius
	//
	if (pixel_type == texture_pixel)
	{
		// DEBUG: wisualize pieces
		if (gu_debug_view_pieces && pieces_from_camera_piece >= 0)
		{
			if (pieces_from_camera_piece <= 1) {
				albedo_computed = vec3(1.0, 0.0, 0.0);
			} else if (pieces_from_camera_piece <= 3) {
				albedo_computed = vec3(0.0, 1.0, 0.0);
			} else if (pieces_from_camera_piece <= 5) {
				albedo_computed = vec3(0.0, 0.0, 1.0);
			} else if (pieces_from_camera_piece <= 7) {
				albedo_computed = vec3(1.0, 0.0, 1.0);
			} else if (pieces_from_camera_piece <= 9) {
				albedo_computed = vec3(1.0, 1.0, 1.0);
			} else if (pieces_from_camera_piece <= 11) {
				albedo_computed = vec3(0.0, 0.0, 0.0);
			}
		}
		// DEBUG: wisualize pieces

		// Highlight grid inside grid radius
		if (mouse_hit_in_quadrant_uv != vec2(-1)) {
			float half_texel_size = 0.5 / heightmapSize.x;
			vec2 uv_begin_texel = quadrant_uv - vec2(half_texel_size);
			vec2 distance_from_vertex =	fract(vec2(uv_begin_texel.x / (half_texel_size * 2.0), uv_begin_texel.y / (half_texel_size * 2.0)));
			float grid_radius = mouse_hit_radius * 5.0;
			if (grid_radius != 0.0 && distance(mouse_hit_in_quadrant_uv, quadrant_uv) < grid_radius)
			{
				if (distance_from_vertex.x < quad_line_thickness || (1.0 - distance_from_vertex.x) < quad_line_thickness
					|| distance_from_vertex.y < quad_line_thickness || (1.0 - distance_from_vertex.y) < quad_line_thickness) {
					if ((distance_from_vertex.x < quad_line_thickness || (1.0 - distance_from_vertex.x) < quad_line_thickness)
						&& (distance_from_vertex.y < quad_line_thickness || (1.0 - distance_from_vertex.y) < quad_line_thickness)) {
						albedo_computed = vec3(1.0, 0.0, 0.0);	// GDN_TheWorld_Globals::g_color_yellow_red
					} else {
						albedo_computed = c_apricot_color;	// GDN_TheWorld_Globals::g_color_yellow_apricot
					}
				}
			}

			if (mouse_hit_radius != 0.0 && distance(mouse_hit_in_quadrant_uv, quadrant_uv) < mouse_hit_radius) {
				vec3 mouse_hit_albedo = c_apricot_color;		// GDN_TheWorld_Globals::g_color_yellow_apricot
				albedo_computed = mix(albedo_computed, mouse_hit_albedo, 0.3);
			}
		}

		// Show grid management
		if (grid_on) {
			float half_texel_size_in_uv_coords = 0.5 / heightmapSize.x;
			vec2 uv_begin_texel = quadrant_uv - vec2(half_texel_size_in_uv_coords);	// assuming uv is in the center of a texel for each fragment
			vec2 distance_of_current_fragment_from_grid_vertex = fract(vec2(uv_begin_texel.x / (half_texel_size_in_uv_coords * 2.0), uv_begin_texel.y / (half_texel_size_in_uv_coords * 2.0)));
			if (distance_of_current_fragment_from_grid_vertex.x < quad_line_thickness || (1.0 - distance_of_current_fragment_from_grid_vertex.x) < quad_line_thickness
				|| distance_of_current_fragment_from_grid_vertex.y < quad_line_thickness || (1.0 - distance_of_current_fragment_from_grid_vertex.y) < quad_line_thickness) {
				if ((distance_of_current_fragment_from_grid_vertex.x < quad_line_thickness || (1.0 - distance_of_current_fragment_from_grid_vertex.x) < quad_line_thickness)
					&& (distance_of_current_fragment_from_grid_vertex.y < quad_line_thickness || (1.0 - distance_of_current_fragment_from_grid_vertex.y) < quad_line_thickness)) {
					albedo_computed = vec3(1.0, 0.0, 0.0);	// GDN_TheWorld_Globals::g_color_yellow_red
				} else {
					albedo_computed = c_apricot_color;	// GDN_TheWorld_Globals::g_color_yellow_apricot
				}
			}
			vec2 g_uv0 = fract(ground_texture_uv.xz);
			float uv_line_thickness = quad_line_thickness / 10.0;
			if (g_uv0.x < uv_line_thickness || (1.0 - g_uv0.x) < uv_line_thickness
				|| g_uv0.y < uv_line_thickness || (1.0 - g_uv0.y) < uv_line_thickness) {
				albedo_computed = mix(albedo_computed, vec3(0.0, 0.0, 1.0), 0.3);		// GDN_TheWorld_Globals::g_color_blue;
			}
		}

	}

	//
	// Editmode border pixel color management
	//
	if (pixel_type == editmode_border_pixel) {
		if (gu_hold_blending)
			albedo_computed = c_red_salmon_color;		// GDN_TheWorld_Globals::g_color_yellow_apricot
		else
			albedo_computed = c_apricot_color;		// GDN_TheWorld_Globals::g_color_yellow_apricot
	}

	//
	// Show chunk management
	//
	if (pixel_type == show_chunk_pixel)
	{
		//quadrant_texture_lod = floor(quadrant_texture_lod);
		float f = floor(quadrant_texture_lod);
		float c = ceil(quadrant_texture_lod);
		if ((quadrant_texture_lod - f) > (c - quadrant_texture_lod) ) {
			quadrant_texture_lod = c;
		} else {
			quadrant_texture_lod = f;
		}

		float chunk_border_line_thickness = 0.005;

		if (editmode_selected > 0.0 && is_on_the_border(quadrant_uv, quad_line_thickness)) {
			albedo_computed = c_apricot_color;		// GDN_TheWorld_Globals::g_color_yellow_apricot
		} else {
			if (mouse_hit_in_quadrant_uv != vec2(-1) && distance(mouse_hit_in_quadrant_uv, quadrant_uv) < mouse_hit_radius) {
				albedo_computed = c_apricot_color;		// GDN_TheWorld_Globals::g_color_yellow_apricot
			} else {
				if (is_on_the_border(quadrant_uv, chunk_border_line_thickness) || is_on_the_border(chunk_uv, chunk_border_line_thickness)) {
					albedo_computed = vec3(0.0, 0.0, 0.0);		// GDN_TheWorld_Globals::g_color_black
				} else {
					if (quadrant_texture_lod >= 0.0 && quadrant_texture_lod <= 8.0) {
						albedo_computed = lod_colors[int(quadrant_texture_lod)];
					} else {
						albedo_computed = lod_colors[9];
					}
				}
			}
		}
	}

	//
	// Wireframe management
	//
	if (pixel_type == wireframe_pixel)
	{
		bool need_blending_north = u_need_blending_north;
		bool need_blending_south = u_need_blending_south;
		bool need_blending_east = u_need_blending_east;
		bool need_blending_west = u_need_blending_west;
		//need_blending_north = false;		// DEBUG
		//need_blending_south = false;		// DEBUG
		//need_blending_east = true;		// DEBUG
		//need_blending_west = false;		// DEBUG
		float uv_wire_width = u_uv_wire_width;
		float uv_border_wire_width = uv_wire_width * 3.0;
		float half_texel_size_in_uv_coords = 0.5 / heightmapSize.x;
		//uv_border_wire_width = 0.0;

		if (quadrant_uv.x < (half_texel_size_in_uv_coords + uv_border_wire_width))					// check left border of quadrant
		{
			// pixel on left border of quadrant
			if (need_blending_west) {
				albedo_computed = u_need_blending_border_color.rgb;
			}
			else {
				albedo_computed = u_wireframe_border_color.rgb;
			}
		}
		else if (quadrant_uv.y < (half_texel_size_in_uv_coords + uv_border_wire_width))				// check top border of quadrant
		{
			// pixel on top border of quadrant
			if (need_blending_north) {
				albedo_computed = u_need_blending_border_color.rgb;
			}
			else {
				albedo_computed = u_wireframe_border_color.rgb;
			}
		}
		else if ((1.0 - quadrant_uv.x) < (half_texel_size_in_uv_coords + uv_border_wire_width))		// check right border of quadrant
		{
			// pixel on right border of quadrant
			if (need_blending_east) {
				albedo_computed = u_need_blending_border_color.rgb;
			}
			else {
				albedo_computed = u_wireframe_border_color.rgb;
			}
		}
		else if  ((1.0 - quadrant_uv.y) < (half_texel_size_in_uv_coords + uv_border_wire_width))	// check bottom border of quadrant
		{
			// pixel on bottom border of quadrant
			if (need_blending_south) {
				albedo_computed = u_need_blending_border_color.rgb;
			}
			else {
				albedo_computed = u_wireframe_border_color.rgb;
			}
		}
		else
		{
			float uv_distance_from_vertices = 1.0 / float(num_vertices_per_chunk - uint(1));
			vec2 uv_distance_from_previous_vertex = fract(chunk_uv / vec2(uv_distance_from_vertices)) * vec2(uv_distance_from_vertices);
			vec2 uv_distance_from_next_vertex = vec2(uv_distance_from_vertices) - uv_distance_from_previous_vertex;
			if ((uv_distance_from_previous_vertex.x < (half_texel_size_in_uv_coords + uv_wire_width)) || (uv_distance_from_previous_vertex.y < (half_texel_size_in_uv_coords + uv_wire_width))
				|| (uv_distance_from_next_vertex.x < (half_texel_size_in_uv_coords + uv_wire_width)) || (uv_distance_from_next_vertex.y < (half_texel_size_in_uv_coords + uv_wire_width)))
			{
				// pixel on a line between vertices
				albedo_computed = u_wireframe_lines_albedo.rgb;
			}
			else
			{
				// pixel between vertices
				if (need_blending) {
					if (editmode_selected > 0.0) {
						albedo_computed = u_selected_albedo.rgb;
					} else {
						albedo_computed = u_need_blending_albedo.rgb;
					}
				} else {
					albedo_computed = u_wireframe_background_albedo.rgb;
				}
			}
		}
		/*if (chunk_uv.x >= 0.1 && chunk_uv.x <= 0.2) {			// DEBUG
			albedo_computed = vec3(0.0, 1.0, 0.0);				// DEBUG
		} else {												// DEBUG
			albedo_computed = vec3(0.0, 0.0, 1.0);				// DEBUG
		}														// DEBUG*/
		/*if (quadrant_uv.x >= 0.1 && quadrant_uv.x <= 0.2) {	// DEBUG
			albedo_computed = vec3(0.0, 1.0, 0.0);				// DEBUG
		} else {												// DEBUG
			albedo_computed = vec3(0.0, 0.0, 1.0);				// DEBUG
		}														// DEBUG*/
	}

	//
	// Highlight quadrant if requested
	//
	if (gu_highlight_hit_quadrant && mouse_hit_in_quadrant_uv != vec2(-1) && (mouse_hit_in_quadrant_uv.x >= 0.0 && mouse_hit_in_quadrant_uv.x <= 1.0 && mouse_hit_in_quadrant_uv.y >= 0.0 && mouse_hit_in_quadrant_uv.y <= 1.0))
	{
		/*float shine = abs(sin(TIME * u_shine_speed));
		float start_smoothness = 0.05;
		float smooth_shine = mix(start_smoothness, u_highlight_quadrant_smoothness, shine);
		vec3 shine_color = c_apricot_color;
		if (gu_hold_blending)
			shine_color = c_red_salmon_color;
		albedo_computed = mix(albedo_computed, shine_color.rgb, smooth_shine);*/
		albedo_computed = mix(albedo_computed, c_orange_color, u_highlight_quadrant_smoothness);
		//METALLIC = 1.0; // 0.0 (no metallic) to 1.0 (full metallic)
	}

	if (gu_debug_texture_overflow)
	{
		if (north_border_pixel && west_border_pixel)
		{
			if (north_west_border_pixel) {
				albedo_computed = vec3(1.0, 0.0, 0.0);
			} else {
				albedo_computed = vec3(0.0, 1.0, 0.0);
			}
		}
		else if (north_border_pixel)
		{
			//albedo_computed = vec3(0.0, 1.0, 0.0);
			albedo_computed = vec3(0.0, 0.0, 1.0);
		}
		else if (west_border_pixel)
		{
			albedo_computed = vec3(0.0, 0.0, 1.0);
		}
	}

	if (gu_debug_uv_scale_per_texture && ground_uv_scale_per_texture != 1.0)
	{
		albedo_computed = vec3(ground_uv_scale_per_texture / c_max_ground_uv_scale_per_texture, 0.0, 0.0);
	}

	//
	// Output
	//
	ALBEDO = albedo_computed;
	if (pixel_type == texture_pixel)
	{
		//force_height_0 = true;		// DEBUG
		if (force_height_0) {
			NORMAL = normalize(cross(dFdyCoarse(VERTEX), dFdxCoarse(VERTEX)));
			TANGENT = normalize(cross(NORMAL, VIEW_MATRIX[2].xyz));
			BINORMAL = normalize(cross(NORMAL, TANGENT));
		} else {
			NORMAL = mat3(VIEW_MATRIX) * normal_computed;
			TANGENT = mat3(VIEW_MATRIX) * tanget_computed;
			BINORMAL = mat3(VIEW_MATRIX) * binormal_computed;
		}

		ROUGHNESS = roughness_computed;
		AO = ao_computed;
		AO_LIGHT_AFFECT = ao_light_affect_computed;
		NORMAL_MAP = ground_normal_computed;
		NORMAL_MAP_DEPTH = ground_normal_scale;
	}

	//********************************************************************************************************************
	//     Test PBR
	//********************************************************************************************************************
	/*{
		vec2 base_uv = quadrant_uv;

		//{
		//	// Height: Enabled
		//	vec3 view_dir = normalize(normalize(-VERTEX + EYE_OFFSET) * mat3(TANGENT * heightmap_flip.x, -BINORMAL * heightmap_flip.y, NORMAL));
		//
		//	// Height Deep Parallax: Enabled
		//	float num_layers = mix(float(heightmap_max_layers), float(heightmap_min_layers), abs(dot(vec3(0.0, 0.0, 1.0), view_dir)));
		//	float layer_depth = 1.0 / num_layers;
		//	float current_layer_depth = 0.0;
		//	vec2 p = view_dir.xy * heightmap_scale * 0.01;
		//	vec2 delta = p / num_layers;
		//	vec2 ofs = base_uv;
		//	float depth = 1.0 - texture(texture_heightmap, ofs).r;
		//
		//	float current_depth = 0.0;
		//	while (current_depth < depth) {
		//		ofs -= delta;
		//		depth = 1.0 - texture(texture_heightmap, ofs).r;
		//
		//		current_depth += layer_depth;
		//	}
		//
		//	vec2 prev_ofs = ofs + delta;
		//	float after_depth = depth - current_depth;
		//	float before_depth = (1.0 - texture(texture_heightmap, prev_ofs).r) - current_depth + layer_depth;
		//
		//	float weight = after_depth / (after_depth - before_depth);
		//	ofs = mix(ofs, prev_ofs, weight);
		//	base_uv = ofs;
		//}

		vec4 albedo_tex = texture(texture_albedo, base_uv);
		ALBEDO = albedo.rgb * albedo_tex.rgb;

		float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
		METALLIC = metallic_tex * metallic;
		SPECULAR = specular;

		vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
		float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
		ROUGHNESS = roughness_tex * roughness;

		// Normal Map: Enabled
		NORMAL_MAP = texture(texture_normal, base_uv).rgb;
		NORMAL_MAP_DEPTH = normal_scale;

		// Ambient Occlusion: Enabled
		AO = dot(texture(texture_ambient_occlusion, base_uv), ao_texture_channel);
		AO_LIGHT_AFFECT = ao_light_affect;
	}*/
	//********************************************************************************************************************
	//     Test PBR
	//********************************************************************************************************************
}

/*void light() {
    DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR / PI;
}*/