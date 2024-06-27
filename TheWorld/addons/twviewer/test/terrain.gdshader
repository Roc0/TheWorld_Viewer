shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_toon;

global uniform sampler2D gu_terrain_quad_border_distance : source_color;

uniform sampler2D u_terrain_heightmap;
uniform sampler2D u_terrain_normalmap;
uniform bool u_use_globalmap = false;
uniform sampler2D u_terrain_globalmap : source_color;
uniform vec4 u_ground_uv_scale_per_texture = vec4(2.000000, 2.000000, 2.000000, 2.000000);
uniform float u_piece_size = 200;
uniform float u_scale_per_texture_factor = 1;
uniform uint u_piecing_threshold_factor = 4;
uniform float u_globalmap_blend_start = 0;
uniform float u_globalmap_blend_distance = 0;
uniform float u_editmode_selected = 0;
uniform vec2 u_mouse_hit = vec2(-1.000000, -1.000000);
uniform float u_mouse_hit_radius = 0.0010000000475;
uniform bool u_triplanar = false;
uniform vec4 u_tile_reduction_per_texture = vec4(0.000000, 0.000000, 0.000000, 0.000000);
uniform bool u_depth_blending = false;
global uniform sampler2DArray gu_ground_albedo_bump_array : source_color;
global uniform sampler2DArray gu_ground_normal_roughness_array;
uniform vec4 u_ground_layers = vec4(-1.000000, -1.000000, -1.000000, -1.000000);
uniform vec4 u_north_ground_layers = vec4(-1.000000, -1.000000, -1.000000, -1.000000);
uniform vec4 u_east_ground_layers = vec4(-1.000000, -1.000000, -1.000000, -1.000000);
uniform vec4 u_west_ground_layers = vec4(-1.000000, -1.000000, -1.000000, -1.000000);
uniform vec4 u_south_ground_layers = vec4(-1.000000, -1.000000, -1.000000, -1.000000);
global uniform float gu_texture_blending_size = 0.40000000596046;
uniform bool u_grid_on = false;
global uniform float gu_grid_step;
global uniform float gu_camera_altitude_from_terrain = -1;
global uniform bool gu_show_chunks = false;

// Varyings
varying vec4 v_vertex_world_pos;
varying vec2 v_vertex_cell_coords_in_textures;
varying float v_distance_from_camera;
varying vec4 v_splat;
varying vec3 v_tint0;
varying vec3 v_tint1;
varying vec3 v_tint2;
varying vec3 v_tint3;
varying float v_distance_from_camera_on_terrain;
varying float v_close_mask;
varying float v_middle_mask;
varying float v_lod;

uniform mat4 u_terrain_inverse_transform;
uniform float u_grid_step = 2;
uniform uint u_optimization_level = 0;
uniform uint u_num_vertices_per_chunk;
global uniform vec3 gu_camera_pos = vec3(0.000000, 0.000000, 0.000000);
uniform sampler2D u_terrain_splatmap;
uniform sampler2D u_terrain_colormap;
//uniform sampler2D tex_frg_62;

// GlobalExpression:0
#include "res://addons/twviewer/shaders/include/CommonFunctions.gdshaderinc"

uniform mat3 u_terrain_normal_basis;
uniform float u_terrain_height = 1.0;	// NOTSET
uniform float u_quad_border_line_thickness = 0.005;	// NOTSET
uniform bool u_force_height_0 = false;
global uniform int gu_force_height_0 = -1;
uniform sampler2D u_ground_albedo_bump_0 : source_color;
uniform sampler2D u_ground_albedo_bump_1 : source_color;
uniform sampler2D u_ground_albedo_bump_2 : source_color;
uniform sampler2D u_ground_albedo_bump_3 : source_color;
uniform sampler2D u_ground_normal_roughness_0;
uniform sampler2D u_ground_normal_roughness_1;
uniform sampler2D u_ground_normal_roughness_2;
uniform sampler2D u_ground_normal_roughness_3;
//uniform vec4 u_tile_reduction_per_texture = vec4(0.0, 0.0, 0.0, 0.0);	// Each component corresponds to a ground texture. Set greater than zero to enable.
//uniform float u_globalmap_blend_start = 0;		// 2000 ==> optimization: at 2000 WU from camera will be used global map instead of u_ground_albedo_bump_0/3 and u_ground_normal_roughness_0/3
//uniform float u_globalmap_blend_distance = 0;	// 1	==> 0 = disable use of global map
uniform vec4 u_colormap_opacity_per_texture = vec4(1.0, 1.0, 1.0, 1.0);	// NOTSET
const float ground_uv_scale_threshold = 15000.0;
const float altitude_uv_scale_threshold = 800.0;

const bool new = false;
//const bool new = true;
// NEW
const float close_distance = 30.0;
const float close_blend_amount = 5.0;
const float middle_distance_increment = 1200.0;
const float middle_blend_amount = 10.0;
const float middle_distance = close_distance + middle_distance_increment;
const float close_uv_scale = 50.0;
const float middle_uv_scale = 20.0;
const float far_uv_scale = 1.0;
// NEW

// GlobalExpression:1
/*float get_height(sampler2D tex, float terrain_height, vec2 uv)
{
	return texture(tex, uv).r * terrain_height;
}*/

// GlobalExpression:2
/*
const float close_distance = 20.0;
const float close_blend_amount = 5.0;
const float middle_distance = 60.0;
const float middle_blend_amount = 10.0;

const float close_uv_scale = 0.5;
const float middle_uv_scale = 0.1;
const float far_uv_scale = 0.01;

varying float close_mask;
varying float middle_mask;

vec4 distance_texture(sampler2D _tex, vec2 _uv) {
	vec4 final = texture(_tex, _uv * far_uv_scale);
	final = mix(final, texture(_tex, _uv * middle_uv_scale), middle_mask);
	final = mix(final, texture(_tex, _uv * close_uv_scale), close_mask);
	return final;
}

vertex

	float dis = lenght(CAMERA_POSITION_WOLRD - world_pos);
	close_mask = smoothstep(close_distance + close_blend_amount, close_distance, dis);		1 if dis < close_distance, 0 if dis > close_distance + close_blend_amount else an intermediate value
	middle_mask = smoothstep(middle_distance + middle_blend_amount, middle_distance, dis);

fragment

	tutte le fetch delle texture devono essere fatte con distance_texture invece che con texture
	*/

// GlobalExpression:3
/*vec3 get_normal(sampler2D tex, mat3 terrain_normal_basis, vec2 uv){
	// Need to use terrain_normal_basis to handle scaling.
	vec3 n = terrain_normal_basis * unpack_normal(texture(tex, uv));
	//vec3 n = unpack_normal(texture(tex, uv));
	return normalize(n);
}*/

// GlobalExpression:4
/*bool is_on_the_border(vec2 uv, float distance_from_border) {
	if (uv.x > distance_from_border && uv.x < (1.0 - distance_from_border) && uv.y > distance_from_border && uv.y < (1.0 - distance_from_border)) {
		return false;
	} else {
		return true;
	}
}

bool is_on_upper_border(vec2 uv, float distance_from_border) {
	if (uv.y >= 0.0 && uv.y < distance_from_border) {
		return true;
	} else {
		return false;
	}
}

bool is_on_lower_border(vec2 uv, float distance_from_border) {
	if (uv.y > (1.0 - distance_from_border) && uv.y <= 1.0) {
		return true;
	} else {
		return false;
	}
}

bool is_on_left_border(vec2 uv, float distance_from_border) {
	if (uv.x >= 0.0 && uv.x < distance_from_border) {
		return true;
	} else {
		return false;
	}
}

bool is_on_right_border(vec2 uv, float distance_from_border) {
	if (uv.x > (1.0 - distance_from_border) && uv.x <= 1.0) {
		return true;
	} else {
		return false;
	}
}*/

// GlobalExpression:5
vec3 get_triplanar_blend(vec3 world_normal) {
	vec3 blending = abs(world_normal);
	blending = normalize(max(blending, vec3(0.00001))); // Force weights to sum to 1.0
	float b = blending.x + blending.y + blending.z;
	return blending / vec3(b, b, b);
}

// GlobalExpression:6
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

// GlobalExpression:7
vec4 distance_texture(sampler2D _tex, vec2 _uv) {
	if (!new) {
		return texture(_tex, _uv);
	} else {
		vec4 final = texture(_tex, _uv * far_uv_scale);
		final = mix(final, texture(_tex, _uv * middle_uv_scale), v_middle_mask);
		final = mix(final, texture(_tex, _uv * close_uv_scale), v_close_mask);
		return final;
	}
}

vec4 distance_texture_layer(sampler2DArray _tex, vec3 _uv) {
	if (!new) {
		return texture(_tex, _uv);
	} else {
		vec4 final = texture(_tex, vec3(_uv.xy * far_uv_scale, _uv.z));
		final = mix(final, texture(_tex, vec3(_uv.xy * middle_uv_scale, _uv.z)), v_middle_mask);
		final = mix(final, texture(_tex, vec3(_uv.xy * close_uv_scale, _uv.z)), v_close_mask);
		return final;
	}
}

vec4 texture_albedo_bump(int type,
	bool north_border_pixel,
	bool south_border_pixel,
	bool west_border_pixel,
	bool east_border_pixel,
	vec2 uv)
{
	if (type == 0) {
		if (north_border_pixel && u_north_ground_layers.x >= 0.0) {
			return distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_north_ground_layers.x));
			//return texture(gu_ground_albedo_bump_array, vec3(uv, u_north_ground_layers.x));
		} else if (west_border_pixel && u_west_ground_layers.x >= 0.0) {
			return distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_west_ground_layers.x));
			//return texture(gu_ground_albedo_bump_array, vec3(uv, u_west_ground_layers.x));
		} else if (u_ground_layers.x >= 0.0) {
			return distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_ground_layers.x));
			//return texture(gu_ground_albedo_bump_array, vec3(uv, u_ground_layers.x));
		} else {
			return distance_texture(u_ground_albedo_bump_0, uv);
			//return texture(u_ground_albedo_bump_0, uv);
		}
	} else if (type == 1) {
		if (north_border_pixel && u_north_ground_layers.y >= 0.0) {
			return distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_north_ground_layers.y));
			//return texture(gu_ground_albedo_bump_array, vec3(uv, u_north_ground_layers.y));
		} else if (west_border_pixel && u_west_ground_layers.y >= 0.0) {
			return distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_west_ground_layers.y));
			//return texture(gu_ground_albedo_bump_array, vec3(uv, u_west_ground_layers.y));
		} else if (u_ground_layers.y >= 0.0) {
			return distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_ground_layers.y));
			//return texture(gu_ground_albedo_bump_array, vec3(uv, u_ground_layers.y));
		} else {
			return distance_texture(u_ground_albedo_bump_1, uv);
			//return texture(u_ground_albedo_bump_1, uv);
		}
	} else if (type == 2) {
		if (north_border_pixel && u_north_ground_layers.z >= 0.0) {
			return distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_north_ground_layers.z));
			//return texture(gu_ground_albedo_bump_array, vec3(uv, u_north_ground_layers.z));
		} else if (west_border_pixel && u_west_ground_layers.z >= 0.0) {
			return distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_west_ground_layers.z));
			//return texture(gu_ground_albedo_bump_array, vec3(uv, u_west_ground_layers.z));
		} else if (u_ground_layers.z >= 0.0) {
			return distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_ground_layers.z));
			//return texture(gu_ground_albedo_bump_array, vec3(uv, u_ground_layers.z));
		} else {
			return distance_texture(u_ground_albedo_bump_2, uv);
			//return texture(u_ground_albedo_bump_2, uv);
		}
	} else {
		if (north_border_pixel && u_north_ground_layers.a >= 0.0) {
			return distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_north_ground_layers.a));
			//return texture(gu_ground_albedo_bump_array, vec3(uv, u_north_ground_layers.a));
		} else if (west_border_pixel && u_west_ground_layers.a >= 0.0) {
			return distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_west_ground_layers.a));
			//return texture(gu_ground_albedo_bump_array, vec3(uv, u_west_ground_layers.a));
		} else if (u_ground_layers.a >= 0.0) {
			return distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_ground_layers.a));
			//return texture(gu_ground_albedo_bump_array, vec3(uv, u_ground_layers.a));
		} else {
			return distance_texture(u_ground_albedo_bump_3, uv);
			//return texture(u_ground_albedo_bump_3, uv);
		}
	}
}

vec4 texture_normal_roughness(int type,
	bool north_border_pixel,
	bool south_border_pixel,
	bool west_border_pixel,
	bool east_border_pixel,
	vec2 uv)
{
	if (type == 0) {
		if (north_border_pixel && u_north_ground_layers.x >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_north_ground_layers.x));
			//return texture(gu_ground_normal_roughness_array, vec3(uv, u_north_ground_layers.x));
		} else if (west_border_pixel && u_west_ground_layers.x >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_west_ground_layers.x));
			//return texture(gu_ground_normal_roughness_array, vec3(uv, u_west_ground_layers.x));
		} else if (u_ground_layers.x >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_ground_layers.x));
			//return texture(gu_ground_normal_roughness_array, vec3(uv, u_ground_layers.x));
		} else {
			return distance_texture(u_ground_normal_roughness_0, uv);
			//return texture(u_ground_normal_roughness_0, uv);
		}
	} else if (type == 1) {
		if (north_border_pixel && u_north_ground_layers.y >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_north_ground_layers.y));
			//return texture(gu_ground_normal_roughness_array, vec3(uv, u_north_ground_layers.y));
		} else if (west_border_pixel && u_west_ground_layers.y >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_west_ground_layers.y));
			//return texture(gu_ground_normal_roughness_array, vec3(uv, u_west_ground_layers.y));
		} else if (u_ground_layers.y >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_ground_layers.y));
			//return texture(gu_ground_normal_roughness_array, vec3(uv, u_ground_layers.y));
		} else {
			return distance_texture(u_ground_normal_roughness_1, uv);
			//return texture(u_ground_normal_roughness_1, uv);
		}
	} else if (type == 2) {
		if (north_border_pixel && u_north_ground_layers.z >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_north_ground_layers.z));
			//return texture(gu_ground_normal_roughness_array, vec3(uv, u_north_ground_layers.z));
		} else if (west_border_pixel && u_west_ground_layers.z >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_west_ground_layers.z));
			//return texture(gu_ground_normal_roughness_array, vec3(uv, u_west_ground_layers.z));
		} else if (u_ground_layers.z >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_ground_layers.z));
			//return texture(gu_ground_normal_roughness_array, vec3(uv, u_ground_layers.z));
		} else {
			return distance_texture(u_ground_normal_roughness_2, uv);
			//return texture(u_ground_normal_roughness_2, uv);
		}
	} else {
		if (north_border_pixel && u_north_ground_layers.a >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_north_ground_layers.a));
			//return texture(gu_ground_normal_roughness_array, vec3(uv, u_north_ground_layers.a));
		} else if (west_border_pixel && u_west_ground_layers.a >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_west_ground_layers.a));
			//return texture(gu_ground_normal_roughness_array, vec3(uv, u_west_ground_layers.a));
		} else if (u_ground_layers.a >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_ground_layers.a));
			//return texture(gu_ground_normal_roughness_array, vec3(uv, u_ground_layers.a));
		} else {
			return distance_texture(u_ground_normal_roughness_3, uv);
			//return texture(u_ground_normal_roughness_3, uv);
		}
	}
}

// GlobalExpression:8
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

vec4 texture_antitile_dismiss(sampler2D albedo_tex, sampler2D normal_tex, vec2 uv, out vec4 out_normal) {
	float frequency = 2.0;
	float scale = 1.3;
	float sharpness = 0.7;

	// Rotate and scale UV
	float rot = 3.14 * 0.6;
	float cosa = cos(rot);
	float sina = sin(rot);
	vec2 uv2 = rotate(uv, cosa, sina) * scale;

	vec4 col0 = texture(albedo_tex, uv);
	vec4 col1 = texture(albedo_tex, uv2);
	vec4 nrm0 = texture(normal_tex, uv);
	vec4 nrm1 = texture(normal_tex, uv2);
	//col0 = vec4(0.0, 0.5, 0.5, 1.0); // Highlights variations

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

vec4 texture_antitile_layers(int type,
	bool north_border_pixel,
	bool south_border_pixel,
	bool west_border_pixel,
	bool east_border_pixel,
	vec2 uv, out vec4 out_normal)
{
	float frequency = 2.0;
	float scale = 1.3;
	float sharpness = 0.7;

	// Rotate and scale UV
	float rot = 3.14 * 0.6;
	float cosa = cos(rot);
	float sina = sin(rot);
	vec2 uv2 = rotate(uv, cosa, sina) * scale;

	vec4 col0 = texture_albedo_bump(type, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, uv);
	vec4 col1 = texture_albedo_bump(type, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, uv2);
	vec4 nrm0 = texture_normal_roughness(type, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, uv);
	vec4 nrm1 = texture_normal_roughness(type, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, uv2);
	//col0 = vec4(0.0, 0.5, 0.5, 1.0); // Highlights variations

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

// GlobalExpression:9
vec4 texture_triplanar_dismiss(sampler2D tex, vec3 world_pos, vec3 blend) {
	vec4 xaxis = texture(tex, world_pos.yz);
	vec4 yaxis = texture(tex, world_pos.xz);
	vec4 zaxis = texture(tex, world_pos.xy);
	// blend the results of the 3 planar projections.
	return xaxis * blend.x + yaxis * blend.y + zaxis * blend.z;
}

vec4 texture_triplanar_ab_layers(int type,
	bool north_border_pixel,
	bool south_border_pixel,
	bool west_border_pixel,
	bool east_border_pixel,
	vec3 world_pos, vec3 blend)
{
	vec4 xaxis = texture_albedo_bump(type, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, world_pos.yz);
	vec4 yaxis = texture_albedo_bump(type, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, world_pos.xz);
	vec4 zaxis = texture_albedo_bump(type, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, world_pos.xy);
	// blend the results of the 3 planar projections.
	return xaxis * blend.x + yaxis * blend.y + zaxis * blend.z;
}

vec4 texture_triplanar_nr_layers(int type,
	bool north_border_pixel,
	bool south_border_pixel,
	bool west_border_pixel,
	bool east_border_pixel,
	vec3 world_pos, vec3 blend)
{
	vec4 xaxis = texture_normal_roughness(type, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, world_pos.yz);
	vec4 yaxis = texture_normal_roughness(type, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, world_pos.xz);
	vec4 zaxis = texture_normal_roughness(type, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, world_pos.xy);
	// blend the results of the 3 planar projections.
	return xaxis * blend.x + yaxis * blend.y + zaxis * blend.z;
}

// GlobalExpression:10
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

void vertex() {
// Input:15
	vec3 vertex_in = VERTEX;


	vec4 vertex_world_pos;
// Expression:11
	vertex_world_pos = vec4(0.0, 0.0, 0.0, 0.0);
	{
		// VERTEX coords are local to the chunk (as the material is applied to the mesh which is tied to the chunk) so they start from the beginning of the chunk: we need to trasform in world coord to abstract from chunk
		vertex_world_pos = MODEL_MATRIX * vec4(vertex_in, 1);
	}


// TransformParameter:35
	mat4 terrain_inverse_transform = u_terrain_inverse_transform;


// FloatParameter:37
	float grid_step = u_grid_step;


// UIntParameter:36
	uint optimization_level = u_optimization_level;


	vec2 vertex_cell_coords_in_textures;
	vec2 uv_quadrant;
// Expression:12
	vertex_cell_coords_in_textures = vec2(0.0, 0.0);
	uv_quadrant = vec2(0.0, 0.0);
	{
		// to calculate coords of the vertex local to the quadrant we use affine inverse matrix of the global trasform of the quadtree
		vec4 vertex_local_to_quadrant_pos = terrain_inverse_transform * vertex_world_pos;
		// to get correct value from the textures (in the range 0 / max size in local coord) we need to consider the step
		// (dividing by it): in the textures heigths/normals are adjacent but in global/local coords are separated by the step
		// ***  after next line vertex_cell_coords_in_textures ranges from 0 to heightmap size - 1 (heightmap size vertices per
		// size of quadrant - f.i. 2049) so it is an index of the pixel in heightmap/normalmap/splatmap etc. texture ***
		vertex_cell_coords_in_textures = vertex_local_to_quadrant_pos.xz / vec2(grid_step * pow(2.0, float(optimization_level)));
		// Moreover must add a half-offset so that we sample the center of pixels, otherwise bilinear filtering of the textures
		// will give us mixed results (#183): as we fetch pixels from textures with UV which is a percentage value ranging from
		// 0.0 to 1.0 we have to convert our index (vertex_cell_coords_in_textures) in percentage; without summing vec2(0.5)
		// first index 0 would be 0.0 and we qould have next indices summing 1 / heightmap size with the second index being
		// 1 / heightmap size and the last index being (heightmap size - 1) / heightmap size. In this way transforming percentages
		// index we touch the exact point where our pixel start and where the previous texture pixel ends so the engine, not knowing
		// which value consider make an interpolation from the values of our texel and the previous but this is not what we want as we
		// want the exact value of the texel; to avoid this we have to sum half so the UV points in the exact medium of the texel
		// (remember tha UV is a percentage that approximate to a vertex index) avoiding linear interpolation.
		// look at https://gamedev.stackexchange.com/questions/46963/how-to-avoid-texture-bleeding-in-a-texture-atlas
		// and https://learn.microsoft.com/it-it/windows/win32/direct3d9/directly-mapping-texels-to-pixels?redirectedfrom=MSDN
		vertex_cell_coords_in_textures += vec2(0.5);	// IMPORTANT: now vertex_cell_coords_in_textures ranges from 0.5
														// to (heightmap size - 1) + 0.5 with increment of 1.0 between each coord
		// Normalized UV to be in the range 0/1
		uv_quadrant = vertex_cell_coords_in_textures / vec2(textureSize(u_terrain_heightmap, 0));
	}


	vec3 vertex_with_h;
	vec4 vertex_world_pos_with_h;
// Expression:13
	vertex_with_h = vec3(0.0, 0.0, 0.0);
	vertex_world_pos_with_h = vec4(0.0, 0.0, 0.0, 0.0);
	{
		vertex_with_h = vertex_in;
		vertex_world_pos_with_h = vertex_world_pos;
		float h = get_height(u_terrain_heightmap, u_terrain_height, uv_quadrant);		// Height displacement from heigthmap
		bool force_height_0 = u_force_height_0;
		if (!force_height_0) {
			if (gu_force_height_0 > 0) {
				force_height_0 = true;
			}
		}
		//force_height_0 = true;		// DEBUG
		if (force_height_0) {													// Needed to bake globalmap
			vertex_with_h.y = 0.0;
			vertex_world_pos_with_h.y = 0.0;
		} else {
			vertex_with_h.y = h;
			vertex_world_pos_with_h.y = h;
		}
	}


	vec3 normal;
// Expression:20
	normal = vec3(0.0, 0.0, 0.0);
	{
		// WARN
		normal = get_normal(u_terrain_normalmap, u_terrain_normal_basis, uv_quadrant);
	}


// BooleanParameter:72
	bool show_chunks = gu_show_chunks;


// UIntParameter:75
	uint num_vertices_per_chunk = u_num_vertices_per_chunk;


// Input:74
	int v_id = VERTEX_ID;


	float lod;
	vec2 uv2_computed;
// Expression:76
	lod = 0.0;
	uv2_computed = vec2(0.0, 0.0);
	{
		lod = -1.0;
		if (show_chunks) {
			int vertex_col = int(floor(mod(float(v_id), float(num_vertices_per_chunk))));		// from 0 to num_vertices_per_chunk - 1
			int vertex_row = int(floor(float(v_id) / float(num_vertices_per_chunk)));	// from 0 to num_vertices_per_chunk - 1
			float step_between_vertices_in_current_mesh = -1.0;
			if ((vertex_col == 0 && vertex_row == 0) || (vertex_col == 0 && vertex_row == int(num_vertices_per_chunk - uint(1)))
				|| (vertex_col == int(num_vertices_per_chunk - uint(1)) && vertex_row == 0) || (vertex_col == int(num_vertices_per_chunk - uint(1)) && vertex_row == int(num_vertices_per_chunk - uint(1)))) {
			} else {
				if (vertex_col == 0) {	// vertex_row is > 0
					step_between_vertices_in_current_mesh = floor(vertex_in.z / float(vertex_row));
				} else {
					step_between_vertices_in_current_mesh = floor(vertex_in.x / float(vertex_col));
				}
			}
			if (step_between_vertices_in_current_mesh == -1.0) {
				uv2_computed = vec2(0.0, 0.0);
				lod = 99.0;
			} else {
				float chunk_size = step_between_vertices_in_current_mesh * float(num_vertices_per_chunk - uint(1));
				uv2_computed = vertex_in.xz / vec2(chunk_size);
				//uv2_computed = vec2(float(vertex_col) / float(num_vertices_per_chunk), float(vertex_row) / float(num_vertices_per_chunk));
				//lod = log2(step_between_vertices_in_current_mesh);
				lod = log2(step_between_vertices_in_current_mesh) - 1.0;
				//lod = float(step_between_vertices_in_current_mesh);
			}
		}
	}


// Output:0
	VERTEX = vertex_with_h;
	NORMAL = normal;
	UV = uv_quadrant;
	UV2 = uv2_computed;


// VaryingSetter:14
	v_vertex_world_pos = vertex_world_pos_with_h;


// VaryingSetter:16
	v_vertex_cell_coords_in_textures = vertex_cell_coords_in_textures;


// Vector3Parameter:71
	vec3 camera_pos = gu_camera_pos;


	float distance_from_camera;
	float distance_from_camera_on_terrain;
	float close_mask;
	float middle_mask;
// Expression:18
	distance_from_camera = 0.0;
	distance_from_camera_on_terrain = 0.0;
	close_mask = 0.0;
	middle_mask = 0.0;
	{
		//camera_pos = INV_VIEW_MATRIX[3].xyz;
		distance_from_camera = distance(vertex_world_pos_with_h.xyz, camera_pos);
		distance_from_camera_on_terrain = distance(vertex_world_pos_with_h.xyz, vec3(camera_pos.x, camera_pos.y - gu_camera_altitude_from_terrain, camera_pos.z));
		if (new) {
			close_mask = smoothstep(close_distance + close_blend_amount, close_distance, distance_from_camera);
			middle_mask = smoothstep(middle_distance + middle_blend_amount, middle_distance, distance_from_camera);
		}
	}


// VaryingSetter:19
	v_distance_from_camera = distance_from_camera;


// BooleanParameter:38
	bool use_globalmap = u_use_globalmap;


	vec4 splat;
// Expression:23
	splat = vec4(0.0, 0.0, 0.0, 0.0);
	{
		if (!use_globalmap) {
				splat = texture(u_terrain_splatmap, uv_quadrant);
		}
	}


// VaryingSetter:24
	v_splat = splat;


	vec3 tint0;
	vec3 tint1;
	vec3 tint2;
	vec3 tint3;
// Expression:25
	tint0 = vec3(0.0, 0.0, 0.0);
	tint1 = vec3(0.0, 0.0, 0.0);
	tint2 = vec3(0.0, 0.0, 0.0);
	tint3 = vec3(0.0, 0.0, 0.0);
	{
		vec4 tint = texture(u_terrain_colormap, uv_quadrant);
		tint0 = mix(vec3(1.0), tint.rgb, u_colormap_opacity_per_texture.x);	// decreasing u_colormap_opacity_per_texture dimensions approximates vector tint (u_terrain_colormap texel) to white: each dimnesion (1-4) acts
		tint1 = mix(vec3(1.0), tint.rgb, u_colormap_opacity_per_texture.y);	// on the corresponding bump_map (1-4). More precisely u_colormap_opacity_per_texture.(x-w) must be in the interval 0-1, if 0 the function returns
		tint2 = mix(vec3(1.0), tint.rgb, u_colormap_opacity_per_texture.z);	// vec3(1.0) if 1 (default value) the function returns tint.rgb
		tint3 = mix(vec3(1.0), tint.rgb, u_colormap_opacity_per_texture.w);
	}


// VaryingSetter:26
	v_tint0 = tint0;


// VaryingSetter:27
	v_tint1 = tint1;


// VaryingSetter:28
	v_tint2 = tint2;


// VaryingSetter:29
	v_tint3 = tint3;


// VaryingSetter:68
	v_distance_from_camera_on_terrain = distance_from_camera_on_terrain;


// VaryingSetter:69
	v_close_mask = close_mask;


// VaryingSetter:70
	v_middle_mask = middle_mask;


// VaryingSetter:77
	v_lod = lod;


}

void fragment() {
// VaryingGetter:3
	float distance_from_camera = v_distance_from_camera;


// ParameterRef:23
	float globalmap_blend_start = u_globalmap_blend_start;


// ParameterRef:24
	float globalmap_blend_distance = u_globalmap_blend_distance;


// Input:13
	vec2 uv_in = UV;


// ParameterRef:26
	float editmode_selected = u_editmode_selected;


// ParameterRef:21
	bool use_globalmap = u_use_globalmap;


	bool editmode_pixel;
	bool globalmap_pixel;
// Expression:25
	editmode_pixel = false;
	globalmap_pixel = false;
	{
		if (editmode_selected > 0.0 && is_on_the_border(uv_in, u_quad_border_line_thickness)) {
			editmode_pixel = true;
		} else {
			editmode_pixel = false;
		}
		if (use_globalmap) {
			globalmap_pixel = true;
		} else {
			globalmap_pixel = false;
		}
	}


	vec3 n_out33p0;
	float n_out33p1;
	float n_out33p2;
// Expression:33
	n_out33p0 = vec3(0.0, 0.0, 0.0);
	n_out33p1 = 0.0;
	n_out33p2 = 0.0;
	{
		n_out33p2 = 1.0;
		n_out33p1 = 1.0;
		if (editmode_pixel) {
			n_out33p0 = vec3(1.0, 0.749, 0.0);		// GDN_TheWorld_Globals::g_color_yellow_apricot
		} else {
			n_out33p0 = texture(u_terrain_globalmap, uv_in).rgb;
			if (globalmap_pixel) {
				n_out33p1 = 0.5;
			} else {
				n_out33p2 = clamp((distance_from_camera - globalmap_blend_start) * globalmap_blend_distance, 0.0, 1.0);
				n_out33p2 *= n_out33p2; // slower start, faster transition but far away
			}
		}
	}


// ParameterRef:34
	bool n_out34p0 = u_triplanar;


	vec3 n_out14p0;
	vec3 n_out14p1;
// Expression:14
	n_out14p0 = vec3(0.0, 0.0, 0.0);
	n_out14p1 = vec3(0.0, 0.0, 0.0);
	{
		n_out14p0 = get_normal(u_terrain_normalmap, u_terrain_normal_basis, uv_in);
		//n_out14p1 = n_out14p0;
	}


// VaryingGetter:11
	vec2 n_out11p0 = v_vertex_cell_coords_in_textures;


// VaryingGetter:12
	vec4 n_out12p0 = v_vertex_world_pos;


// VaryingGetter:84
	float n_out84p0 = v_distance_from_camera_on_terrain;


// Input:8
	vec3 n_out8p0 = VERTEX;


// ParameterRef:17
	vec4 ground_uv_scale_per_texture_in = u_ground_uv_scale_per_texture;


// ParameterRef:18
	uint n_out18p0 = u_piecing_threshold_factor;


// ParameterRef:19
	float n_out19p0 = u_piece_size;


// ParameterRef:20
	float n_out20p0 = u_scale_per_texture_factor;


// ParameterRef:82
	float n_out82p0 = gu_camera_altitude_from_terrain;


	vec4 ground_uv_scale_per_texture_computed;
	int n_out4p1;
// Expression:4
	ground_uv_scale_per_texture_computed = vec4(0.0, 0.0, 0.0, 0.0);
	n_out4p1 = 0;
	{
		//ground_uv_scale_per_texture_in = vec4(200.0, 200.0, 200.0, 200.0);
		ground_uv_scale_per_texture_computed = ground_uv_scale_per_texture_in;
		n_out4p1 = -1;

		int alt_piece = int(floor(n_out82p0 / n_out19p0));
		/*if (alt_piece < 4) {
			n_out20p0 *= pow(2.0, float(alt_piece));
		} else {
			n_out82p0 = -1.0;
		}*/
		if (n_out82p0 < altitude_uv_scale_threshold) {
			n_out20p0 *= pow(2.0, float(alt_piece));
		} else {
			n_out82p0 = -1.0;
		}

		if (n_out84p0 < ground_uv_scale_threshold) {
			if (n_out82p0 > 0.0) {
				vec3 fragment_world_pos = (INV_VIEW_MATRIX * vec4(n_out8p0, 1.0)).xyz;
				int camera_piece_x = int(floor(CAMERA_POSITION_WORLD.x / n_out19p0));
				int camera_piece_z = int(floor(CAMERA_POSITION_WORLD.z / n_out19p0));
				int frag_piece_x = int(floor(fragment_world_pos.x / n_out19p0));
				int frag_piece_z = int(floor(fragment_world_pos.z / n_out19p0));
				n_out4p1 = max(int(abs(camera_piece_x - frag_piece_x)), int(abs(camera_piece_z - frag_piece_z)));
				if (n_out4p1 <= 1)
				{
					ground_uv_scale_per_texture_computed /= (n_out20p0 / 20.0);
					//ground_uv_scale_per_texture_computed = vec4(40.0);
				}
				else if (n_out4p1 <= 3)
				{
					ground_uv_scale_per_texture_computed /= (n_out20p0 / 10.0);
					//ground_uv_scale_per_texture_computed = vec4(20.0);
				}
				else if (n_out4p1 <= 5)
				{
					ground_uv_scale_per_texture_computed /= (n_out20p0 / 10.0);
					//ground_uv_scale_per_texture_computed = vec4(20.0);
				}
				else if (n_out4p1 <= 7)
				{
					ground_uv_scale_per_texture_computed /= (n_out20p0 / 8.0);
					//ground_uv_scale_per_texture_computed = vec4(16.0);
					//ground_uv_scale_per_texture_computed = ground_uv_scale_per_texture_in;
				}
				else if (n_out4p1 <= 9)
				{
					ground_uv_scale_per_texture_computed /= (n_out20p0 / 4.0);
				}
				else if (n_out4p1 <= 11)
				{
					ground_uv_scale_per_texture_computed /= (n_out20p0 / 2.0);
					//ground_uv_scale_per_texture_computed = vec4(6.0);
				}
			}
		}
		else
		{
			float forced_scale_value_beyond_threshold = 1.0;
			ground_uv_scale_per_texture_computed = vec4(forced_scale_value_beyond_threshold);
		}

	}


// VaryingGetter:37
	vec4 n_out37p0 = v_splat;


// Texture2D:62
	vec4 distance_texel = texture(gu_terrain_quad_border_distance, UV);


// FloatConstant:75
	float distance_threshold = 0.000000;


// ParameterRef:74
	float texture_blending_size = gu_texture_blending_size;


	vec3 n_out76p0;
// If:76
	float distance_value = 0.00000;
	float tolerance = 0.00001;
	if(abs(distance_threshold - distance_value) < tolerance)
	{
		n_out76p0 = vec3(texture_blending_size);
	}
	else if(distance_threshold < distance_value)
	{
		n_out76p0 = vec3(distance_threshold);
	}
	else
	{
		n_out76p0 = vec3(distance_threshold);
	}


// VectorOp:69
	vec3 n_out69p0 = vec3(distance_texel.xyz) * n_out76p0;

	float distance_from_border = n_out69p0.x;

	bool n_out73p0;
	bool n_out73p1;
	bool n_out73p2;
	bool n_out73p3;
	vec4 n_out73p4;
// Expression:73
	n_out73p0 = false;
	n_out73p1 = false;
	n_out73p2 = false;
	n_out73p3 = false;
	n_out73p4 = vec4(0.0, 0.0, 0.0, 0.0);
	{
		n_out73p0 = false;
		n_out73p1 = false;
		n_out73p2 = false;
		n_out73p3 = false;
		n_out73p4 = n_out37p0;

		if (!editmode_pixel && !globalmap_pixel) {
			if (is_on_upper_border(uv_in, distance_from_border)) {
				n_out73p0 = true;
				//n_out73p4 = n_out73p4 + ;
			}
			if (is_on_lower_border(uv_in, distance_from_border)) {
				n_out73p1 = true;
				//n_out73p4 = n_out73p4 + ;
			}
			if (is_on_left_border(uv_in, distance_from_border)) {
				n_out73p2 = true;
				//n_out73p4 = n_out73p4 + ;
			}
			if (is_on_right_border(uv_in, distance_from_border)) {
				n_out73p3 = true;
				//n_out73p4 = n_out73p4 + ;
			}
		}
		//n_out73p4 = n_out37p0;
	}


	vec2 n_out10p0;
	vec2 n_out10p1;
	vec2 n_out10p2;
	vec3 n_out10p3;
// Expression:10
	n_out10p0 = vec2(0.0, 0.0);
	n_out10p1 = vec2(0.0, 0.0);
	n_out10p2 = vec2(0.0, 0.0);
	n_out10p3 = vec3(0.0, 0.0, 0.0);
	{
		vec3 base_ground_uv;

		//ground_uv_scale_per_texture_computed = vec4(2.0);
		if (new) {
			ground_uv_scale_per_texture_computed = vec4(1.0, 1.0, 1.0, 1.0);
		}
		base_ground_uv = vec3(uv_in.x, n_out12p0.y * MODEL_MATRIX[1][1], uv_in.y);
		n_out10p0 = base_ground_uv.xz * ground_uv_scale_per_texture_computed.x;
		n_out10p1 = base_ground_uv.xz * ground_uv_scale_per_texture_computed.y;
		n_out10p2 = base_ground_uv.xz * ground_uv_scale_per_texture_computed.z;
		n_out10p3 = base_ground_uv * ground_uv_scale_per_texture_computed.w;

	}


// ParameterRef:35
	vec4 n_out35p0 = u_tile_reduction_per_texture;


	vec3 n_out30p0;
	float n_out30p1;
	vec3 n_out30p2;
	vec4 n_out30p3;
	vec4 n_out30p4;
	vec4 n_out30p5;
	vec4 n_out30p6;
	vec4 n_out30p7;
	vec4 n_out30p8;
	vec4 n_out30p9;
	vec4 n_out30p10;
// Expression:30
	n_out30p0 = vec3(0.0, 0.0, 0.0);
	n_out30p1 = 0.0;
	n_out30p2 = vec3(0.0, 0.0, 0.0);
	n_out30p3 = vec4(0.0, 0.0, 0.0, 0.0);
	n_out30p4 = vec4(0.0, 0.0, 0.0, 0.0);
	n_out30p5 = vec4(0.0, 0.0, 0.0, 0.0);
	n_out30p6 = vec4(0.0, 0.0, 0.0, 0.0);
	n_out30p7 = vec4(0.0, 0.0, 0.0, 0.0);
	n_out30p8 = vec4(0.0, 0.0, 0.0, 0.0);
	n_out30p9 = vec4(0.0, 0.0, 0.0, 0.0);
	n_out30p10 = vec4(0.0, 0.0, 0.0, 0.0);
	{
		n_out30p1 = n_out33p1;
		n_out30p0 = n_out33p0;
		n_out30p2 = n_out14p0;

		if (!editmode_pixel && !globalmap_pixel) {
			if (n_out34p0) {
				// Only do n_out34p0 on one texture slot,
				// because otherwise it would be very expensive and cost many more ifs.
				// I chose the last slot because first slot is the default on new splatmaps,
				// and that's a feature used for cliffs, which are usually designed later.

				vec3 blending = get_triplanar_blend(n_out14p0);

				//n_out30p6 = texture_triplanar(u_ground_albedo_bump_3, n_out10p3, blending);
				//n_out30p10 = texture_triplanar(u_ground_normal_roughness_3, n_out10p3, blending);
				n_out30p6 = texture_triplanar_ab_layers(3, n_out73p0, n_out73p1, n_out73p2, n_out73p3, n_out10p3, blending);
				n_out30p10 = texture_triplanar_nr_layers(3, n_out73p0, n_out73p1, n_out73p2, n_out73p3, n_out10p3, blending);

			} else {
				if (n_out35p0[3] > 0.0) {
					//n_out30p6 = texture_antitile(u_ground_albedo_bump_3, u_ground_normal_roughness_3, n_out10p3.xz, n_out30p10);
					n_out30p6 = texture_antitile_layers(3, n_out73p0, n_out73p1, n_out73p2, n_out73p3, n_out10p3.xz, n_out30p10);
				} else {
					//n_out30p6 = texture(u_ground_albedo_bump_3, n_out10p3.xz);
					//n_out30p10 = texture(u_ground_normal_roughness_3, n_out10p3.xz);
					n_out30p6 = texture_albedo_bump(3, n_out73p0, n_out73p1, n_out73p2, n_out73p3, n_out10p3.xz);
					n_out30p10 = texture_normal_roughness(3, n_out73p0, n_out73p1, n_out73p2, n_out73p3, n_out10p3.xz);
				}
			}

			if (n_out35p0[0] > 0.0) {
				//n_out30p3 = texture_antitile(u_ground_albedo_bump_0, u_ground_normal_roughness_0, n_out10p0, n_out30p7);
				n_out30p3 = texture_antitile_layers(0, n_out73p0, n_out73p1, n_out73p2, n_out73p3, n_out10p0, n_out30p7);
			} else {
				//n_out30p3 = texture(u_ground_albedo_bump_0, n_out10p0);
				//n_out30p7 = texture(u_ground_normal_roughness_0, n_out10p0);
				n_out30p3 = texture_albedo_bump(0, n_out73p0, n_out73p1, n_out73p2, n_out73p3, n_out10p0);
				n_out30p7 = texture_normal_roughness(0, n_out73p0, n_out73p1, n_out73p2, n_out73p3, n_out10p0);
			}
			if (n_out35p0[1] > 0.0) {
				//n_out30p4 = texture_antitile(u_ground_albedo_bump_1, u_ground_normal_roughness_1, n_out10p1, n_out30p8);
				n_out30p4 = texture_antitile_layers(1, n_out73p0, n_out73p1, n_out73p2, n_out73p3, n_out10p1, n_out30p8);
			} else {
				//n_out30p4 = texture(u_ground_albedo_bump_1, n_out10p1);
				//n_out30p8 = texture(u_ground_normal_roughness_1, n_out10p1);
				n_out30p4 = texture_albedo_bump(1, n_out73p0, n_out73p1, n_out73p2, n_out73p3, n_out10p1);
				n_out30p8 = texture_normal_roughness(1, n_out73p0, n_out73p1, n_out73p2, n_out73p3, n_out10p1);
			}
			if (n_out35p0[2] > 0.0) {
				//n_out30p5 = texture_antitile(u_ground_albedo_bump_2, u_ground_normal_roughness_2, n_out10p2, n_out30p9);
				n_out30p5 = texture_antitile_layers(2, n_out73p0, n_out73p1, n_out73p2, n_out73p3, n_out10p2, n_out30p9);
			} else {
				//n_out30p5 = texture(u_ground_albedo_bump_2, n_out10p2);
				//n_out30p9 = texture(u_ground_normal_roughness_2, n_out10p2);
				n_out30p5 = texture_albedo_bump(2, n_out73p0, n_out73p1, n_out73p2, n_out73p3, n_out10p2);
				n_out30p9 = texture_normal_roughness(2, n_out73p0, n_out73p1, n_out73p2, n_out73p3, n_out10p2);
			}

			/*if (n_out73p0 || n_out73p1 || n_out73p2 || n_out73p3) {
				vec4 _ab0 = mix(n_out30p3, n_out30p4, 0.5);
				vec4 _ab1 = mix(n_out30p4, n_out30p3, 0.5);
				n_out30p3 = _ab0;
				n_out30p4 = _ab1;
			}*/

			/*vec3 red = vec3(1.0, 0.0, 0.0);
			vec3 green = vec3(0.0, 1.0, 0.0);
			vec3 blue = vec3(0.0, 0.0, 1.0);
			vec3 yellow = vec3(1.0, 0.749, 0.0);
			if (n_out73p0)	{
				n_out30p3.rgb = red;
				n_out30p4.rgb = red;
				n_out30p5.rgb = red;
				n_out30p6.rgb = red;
			}
			if (n_out73p1)	{
				n_out30p3.rgb = green;
				n_out30p4.rgb = green;
				n_out30p5.rgb = green;
				n_out30p6.rgb = green;
			}
			if (n_out73p2)	{
				n_out30p3.rgb = blue;
				n_out30p4.rgb = blue;
				n_out30p5.rgb = blue;
				n_out30p6.rgb = blue;
			}
			if (n_out73p3)	{
				n_out30p3.rgb = yellow;
				n_out30p4.rgb = yellow;
				n_out30p5.rgb = yellow;
				n_out30p6.rgb = yellow;
			}*/
		}
	}


// VaryingGetter:38
	vec3 n_out38p0 = v_tint0;


// VaryingGetter:39
	vec3 n_out39p0 = v_tint1;


// VaryingGetter:40
	vec3 n_out40p0 = v_tint2;


// VaryingGetter:41
	vec3 n_out41p0 = v_tint3;


// ParameterRef:36
	bool n_out36p0 = u_depth_blending;


	vec3 n_out56p0;
	float n_out56p1;
	vec3 n_out56p2;
	float n_out56p3;
	float n_out56p4;
// Expression:56
	n_out56p0 = vec3(0.0, 0.0, 0.0);
	n_out56p1 = 0.0;
	n_out56p2 = vec3(0.0, 0.0, 0.0);
	n_out56p3 = 0.0;
	n_out56p4 = 0.0;
	{
		if (editmode_pixel || globalmap_pixel) {
			n_out56p1 = n_out30p1;
			n_out56p0 = n_out30p0;
			n_out56p2 = n_out30p2;
		} else {
			// col(0-3) is the result of the pixel fetched from u_ground_albedo_bump_(0-3) modified
			// by the value fetched from u_terrain_colormap and relative to the vertex corresponding
			// to current pixel
			// the value fetched from u_terrain_colormap if modified to the white according to the
			// vector u_colormap_opacity_per_texture (default value don't modify the color)
			vec3 col0 = n_out30p3.rgb * n_out38p0;
			vec3 col1 = n_out30p4.rgb * n_out39p0;
			vec3 col2 = n_out30p5.rgb * n_out40p0;
			vec3 col3 = n_out30p6.rgb * n_out41p0;
			//col0 = n_out30p3.rgb;
			//col1 = n_out30p4.rgb;
			//col2 = n_out30p5.rgb;
			//col3 = n_out30p6.rgb;

			vec4 rough = vec4(n_out30p7.a, n_out30p8.a, n_out30p9.a, n_out30p10.a);

			//vec3 normal0 = unpack_normal(n_out30p7);
			//vec3 normal1 = unpack_normal(n_out30p8);
			//vec3 normal2 = unpack_normal(n_out30p9);
			//vec3 normal3 = unpack_normal(n_out30p10);
			vec3 normal0 = n_out30p7.rgb;
			vec3 normal1 = n_out30p8.rgb;
			vec3 normal2 = n_out30p9.rgb;
			vec3 normal3 = n_out30p10.rgb;

			vec4 w;
			// TODO An #ifdef macro would be nice! Or copy/paste everything in a different shader...
			if (n_out36p0) {
				w = get_depth_blended_weights(n_out73p4, vec4(n_out30p3.a, n_out30p4.a, n_out30p5.a, n_out30p6.a));
			} else {
				w = n_out73p4.rgba;
			}

			float w_sum = (w.r + w.g + w.b + w.a);

			n_out56p0 = (
				w.r * col0.rgb +
				w.g * col1.rgb +
				w.b * col2.rgb +
				w.a * col3.rgb) / w_sum;

			n_out56p1 = (
				w.r * rough.r +
				w.g * rough.g +
				w.b * rough.b +
				w.a * rough.a) / w_sum;

			vec3 ground_normal = /*u_terrain_normal_basis **/ (
				w.r * normal0 +
				w.g * normal1 +
				w.b * normal2 +
				w.a * normal3) / w_sum;
			// If no n_out73p4 textures are defined, normal vectors will default to (1,1,1),
			// which is incorrect, and causes the terrain to be shaded wrongly in some directions.
			// However, this should not be a problem to fix in the shader,
			// because there MUST be at least one n_out73p4 texture set.
			//ground_normal = normalize(ground_normal);
			// TODO Make the plugin insert a default normalmap if it's empty

			// Combine terrain normals with detail normals (not sure if correct but looks ok)
			n_out56p2 = normalize(vec3(n_out30p2.x + ground_normal.x, n_out30p2.y, n_out30p2.z + ground_normal.z));
			n_out56p2 = mix(n_out56p2, n_out30p2, n_out33p2);
			n_out56p0 = mix(n_out56p0, n_out30p0, n_out33p2);
			n_out56p1 = mix(n_out56p1, 1.0, n_out33p2);
			n_out56p3 = (w.r * n_out30p3.a +	w.g * n_out30p4.a + w.b * n_out30p5.a +	w.a * n_out30p6.a) / w_sum;
			n_out56p4 = 0.1;
			//METALLIC = (w.r * n_out30p3.a +	w.g * n_out30p4.a + w.b * n_out30p5.a +	w.a * n_out30p6.a) / w_sum;
			//SPECULAR = 0.5;

			/*vec3 red = vec3(1.0, 0.0, 0.0);
			vec3 green = vec3(0.0, 1.0, 0.0);
			vec3 blue = vec3(0.0, 0.0, 1.0);
			vec3 yellow = vec3(1.0, 0.749, 0.0);
			if (n_out73p4.x < 0.0)	{
				n_out56p0 = red;
			}
			if (n_out73p4.y < 0.0)	{
				n_out56p0 = green;
			}
			if (n_out73p4.z < 0.0)	{
				n_out56p0 = blue;
			}
			if (n_out73p4.a < 0.0)	{
				n_out56p0 = yellow;
			}*/
		}
	}


// ParameterRef:27
	vec2 n_out27p0 = u_mouse_hit;


// ParameterRef:28
	float n_out28p0 = u_mouse_hit_radius;


// ParameterRef:81
	bool n_out81p0 = u_grid_on;


	vec3 n_out31p0;
	float n_out31p1;
	vec3 n_out31p2;
	float n_out31p3;
// Expression:31
	n_out31p0 = vec3(0.0, 0.0, 0.0);
	n_out31p1 = 0.0;
	n_out31p2 = vec3(0.0, 0.0, 0.0);
	n_out31p3 = 0.0;
	{
		n_out31p0 = n_out56p0;
		n_out31p2 = (VIEW_MATRIX * (vec4(n_out56p2, 0.0))).xyz;
		n_out31p1 = n_out56p1;

		n_out31p3 = 0.05;

		// DEBUG: wisualize pieces
		/*if (n_out4p1 == 0) {
			n_out31p0 = vec3(1.0, 0.0, 0.0);
		} else if (n_out4p1 == 1) {
			n_out31p0 = vec3(0.0, 1.0, 0.0);
		} else if (n_out4p1 == 2) {
			n_out31p0 = vec3(0.0, 0.0, 1.0);
		} else if (n_out4p1 == 3) {
			n_out31p0 = vec3(1.0, 0.0, 1.0);
		}*/
		// DEBUG: wisualize pieces
		//n_out31p0 = vec3(v_close_mask);	// DEBUG
		//n_out31p0 = vec3(v_middle_mask);	// DEBUG

		//bool n_out81p0 = !(n_out27p0 == vec2(-1));
		/*if (n_out81p0) {
			float half_texel_size = 0.5 / vec2(textureSize(u_terrain_heightmap, 0)).x;
			vec2 uv_begin_texel = uv_in - vec2(half_texel_size);
			vec2 distance_from_vertex =
				fract(vec2(uv_begin_texel.x / (half_texel_size * 2.0), uv_begin_texel.y / (half_texel_size * 2.0)));
			if (distance_from_vertex.x < n_out31p3 || (1.0 - distance_from_vertex.x) < n_out31p3
				|| distance_from_vertex.y < n_out31p3 || (1.0 - distance_from_vertex.y) < n_out31p3) {
				if ((distance_from_vertex.x < n_out31p3 || (1.0 - distance_from_vertex.x) < n_out31p3)
					&& (distance_from_vertex.y < n_out31p3 || (1.0 - distance_from_vertex.y) < n_out31p3)) {
					//n_out31p0 = mix(n_out31p0, vec3(1.0, 0.0, 0.0), 0.3);	// GDN_TheWorld_Globals::g_color_yellow_red
					n_out31p0 = vec3(1.0, 0.0, 0.0);	// GDN_TheWorld_Globals::g_color_yellow_red
				} else {
					//n_out31p0 = mix(n_out31p0, vec3(1.0, 0.749, 0.0), 0.3);	// GDN_TheWorld_Globals::g_color_yellow_apricot
					n_out31p0 = vec3(1.0, 0.749, 0.0);	// GDN_TheWorld_Globals::g_color_yellow_apricot
				}
			}
			vec2 g_uv0 = fract(n_out10p0);
			float uv_line_thickness = n_out31p3 / 10.0;
			if (g_uv0.x < uv_line_thickness || (1.0 - g_uv0.x) < uv_line_thickness
				|| g_uv0.y < uv_line_thickness || (1.0 - g_uv0.y) < uv_line_thickness) {
				n_out31p0 = mix(n_out31p0, vec3(0.0, 0.0, 1.0), 0.3);		// GDN_TheWorld_Globals::g_color_blue;
			}
		}*/

		if (n_out27p0 != vec2(-1)) {
			float half_texel_size = 0.5 / vec2(textureSize(u_terrain_heightmap, 0)).x;
			vec2 uv_begin_texel = uv_in - vec2(half_texel_size);
			vec2 distance_from_vertex =
				fract(vec2(uv_begin_texel.x / (half_texel_size * 2.0), uv_begin_texel.y / (half_texel_size * 2.0)));
			float grid_radius = n_out28p0 * 5.0;
			if (grid_radius != 0.0 && distance(n_out27p0, uv_in) < grid_radius)
			{
				if (distance_from_vertex.x < n_out31p3 || (1.0 - distance_from_vertex.x) < n_out31p3
					|| distance_from_vertex.y < n_out31p3 || (1.0 - distance_from_vertex.y) < n_out31p3) {
					if ((distance_from_vertex.x < n_out31p3 || (1.0 - distance_from_vertex.x) < n_out31p3)
						&& (distance_from_vertex.y < n_out31p3 || (1.0 - distance_from_vertex.y) < n_out31p3)) {
						//n_out31p0 = mix(n_out31p0, vec3(1.0, 0.0, 0.0), 0.3);	// GDN_TheWorld_Globals::g_color_yellow_red
						n_out31p0 = vec3(1.0, 0.0, 0.0);	// GDN_TheWorld_Globals::g_color_yellow_red
					} else {
						//n_out31p0 = mix(n_out31p0, vec3(1.0, 0.749, 0.0), 0.3);	// GDN_TheWorld_Globals::g_color_yellow_apricot
						n_out31p0 = vec3(1.0, 0.749, 0.0);	// GDN_TheWorld_Globals::g_color_yellow_apricot
					}
				}
			}

			if (n_out28p0 != 0.0 && distance(n_out27p0, uv_in) < n_out28p0) {
				vec3 mouse_hit_albedo = vec3(1.0, 0.749, 0.0);		// GDN_TheWorld_Globals::g_color_yellow_apricot
				n_out31p0 = mix(n_out31p0, mouse_hit_albedo, 0.3);
			}
		}
	}


// VaryingGetter:88
	float n_out88p0 = v_lod;


	vec3 n_out89p0;
	float n_out89p1;
	vec3 n_out89p2;
// Expression:89
	n_out89p0 = vec3(0.0, 0.0, 0.0);
	n_out89p1 = 0.0;
	n_out89p2 = vec3(0.0, 0.0, 0.0);
	{
		n_out89p0 = n_out31p0;
		n_out89p2 = n_out31p2;
		n_out89p1 = n_out31p1;
		if (n_out88p0 >= 0.0) {
			//n_out88p0 = floor(n_out88p0);
			float f = floor(n_out88p0);
			float c = ceil(n_out88p0);
			if ((n_out88p0 - f) > (c - n_out88p0) ) {
				n_out88p0 = c;
			} else {
				n_out88p0 = f;
			}

			float chunk_border_line_thickness = 0.005;

			if (u_editmode_selected > 0.0 && is_on_the_border(UV, n_out31p3)) {
				n_out89p0 = vec3(1.0, 0.749, 0.0);		// GDN_TheWorld_Globals::g_color_yellow_apricot
			} else {
				if (u_mouse_hit != vec2(-1) && distance(u_mouse_hit, UV) < u_mouse_hit_radius) {
					n_out89p0 = vec3(1.0, 0.749, 0.0);		// GDN_TheWorld_Globals::g_color_yellow_apricot
				} else {
					if (is_on_the_border(UV, chunk_border_line_thickness) || is_on_the_border(UV2, chunk_border_line_thickness)) {
						//n_out89p0 = vec3(1.0, 1.0, 1.0);		// GDN_TheWorld_Globals::g_color_white
						n_out89p0 = vec3(0.0, 0.0, 0.0);		// GDN_TheWorld_Globals::g_color_black
					} else {
						if (n_out88p0 >= 0.0 && n_out88p0 <= 8.0) {
							n_out89p0 = lod_colors[int(n_out88p0)];
						} else {
							n_out89p0 = lod_colors[9];
						}
					}
				}
			}
		}

		//bool n_out81p0 = !(mouse_hit == vec2(-1));
		if (n_out81p0) {
			float half_texel_size = 0.5 / vec2(textureSize(u_terrain_heightmap, 0)).x;
			vec2 uv_begin_texel = uv_in - vec2(half_texel_size);
			vec2 distance_from_vertex =
				fract(vec2(uv_begin_texel.x / (half_texel_size * 2.0), uv_begin_texel.y / (half_texel_size * 2.0)));
			if (distance_from_vertex.x < n_out31p3 || (1.0 - distance_from_vertex.x) < n_out31p3
				|| distance_from_vertex.y < n_out31p3 || (1.0 - distance_from_vertex.y) < n_out31p3) {
				if ((distance_from_vertex.x < n_out31p3 || (1.0 - distance_from_vertex.x) < n_out31p3)
					&& (distance_from_vertex.y < n_out31p3 || (1.0 - distance_from_vertex.y) < n_out31p3)) {
					//n_out89p0 = mix(n_out89p0, vec3(1.0, 0.0, 0.0), 0.3);	// GDN_TheWorld_Globals::g_color_yellow_red
					n_out89p0 = vec3(1.0, 0.0, 0.0);	// GDN_TheWorld_Globals::g_color_yellow_red
				} else {
					//n_out89p0 = mix(n_out89p0, vec3(1.0, 0.749, 0.0), 0.3);	// GDN_TheWorld_Globals::g_color_yellow_apricot
					n_out89p0 = vec3(1.0, 0.749, 0.0);	// GDN_TheWorld_Globals::g_color_yellow_apricot
				}
			}
			vec2 g_uv0 = fract(n_out10p0);
			float uv_line_thickness = n_out31p3 / 10.0;
			if (g_uv0.x < uv_line_thickness || (1.0 - g_uv0.x) < uv_line_thickness
				|| g_uv0.y < uv_line_thickness || (1.0 - g_uv0.y) < uv_line_thickness) {
				n_out89p0 = mix(n_out89p0, vec3(0.0, 0.0, 1.0), 0.3);		// GDN_TheWorld_Globals::g_color_blue;
			}
		}

		/*if (n_out88p0 >= 0.0 && n_out88p0 <= 511.0) {
			n_out89p0 = vec3(1.0);	// white
		} else {
			n_out89p0 = vec3(0.0);	// black
		}*/
		/*if (UV2.x >= 0.0 && UV2.x <= 1.0 && UV2.y >= 0.0 && UV2.y <= 1.0) {
			n_out89p0 = vec3(1.0);	// white
		}*/
		//n_out89p0 = vec3(UV2.x, UV2.y, 1.0);
	}


// Output:0
	ALBEDO = n_out89p0;
	ROUGHNESS = n_out89p1;
	AO = n_out56p3;
	AO_LIGHT_AFFECT = n_out56p4;
	NORMAL = n_out89p2;


}
