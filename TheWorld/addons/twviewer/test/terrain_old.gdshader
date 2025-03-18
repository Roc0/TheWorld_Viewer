shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_toon;

#include "res://addons/twviewer/shaders/include/CommonFunctions.gdshaderinc"

// consts
const vec3 apricot_color = vec3(1.0, 0.749, 0.0);
const vec3 red_salmon_color = vec3(0.980, 0.502, 0.447);
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

const vec3 vectors[3] = {
	vec3(1.0, 0.0 ,0.0),
	vec3(0.0, 1.0 ,0.0),
	vec3(0.0, 0.0 ,1.0)
};

// global uniforms
global uniform sampler2D gu_terrain_quad_border_distance : source_color;
global uniform sampler2DArray gu_ground_albedo_bump_array : source_color;
global uniform sampler2DArray gu_ground_normal_roughness_array;
global uniform float gu_texture_blending_size = 0.40000000596046;
global uniform bool gu_texture_new_blending = false;
global uniform float gu_grid_step;
global uniform float gu_camera_altitude_from_terrain = -1;
global uniform bool gu_show_chunks = false;
global uniform bool gu_show_wireframe = false;
global uniform bool gu_show_need_blending = false;
global uniform vec3 gu_camera_pos = vec3(0.000000, 0.000000, 0.000000);
global uniform int gu_force_height_0 = -1;
global uniform bool gu_highlight_hit_quadrant = false;
global uniform bool gu_hold_blending = false;

// uniforms
//uniform vec4 u_shine_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
//uniform vec4 u_shine_color : source_color = vec4(1.0, 0.749, 0.0, 1.0);
uniform float u_shine_speed : hint_range(0.1, 10) = 1.5;
uniform float u_smoothness : hint_range(0.1, 1.0) = 0.2;

uniform bool u_barycentric_wireframe = false;
uniform bool u_need_blending = false;
uniform bool u_need_blending_north = false;
uniform bool u_need_blending_south = false;
uniform bool u_need_blending_east = false;
uniform bool u_need_blending_west = false;

uniform vec4 u_wire_albedo : source_color = vec4(0.0, 1.0, 0.0, 1.0);	// green
uniform vec4 u_need_blending_albedo : source_color = vec4(0.0, 0.0, 1.0, 1.0);	// blue
uniform vec4 u_selected_albedo : source_color = vec4(0.0, 0.0, 1.0, 1.0);	// green
uniform vec4 u_wire_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);	// black
uniform vec4 u_wire_color_border_blending : source_color = vec4(1.0, 0.0, 0.0, 1.0);	// red
uniform float u_uv_wire_width = 0.003;
uniform float u_wire_width : hint_range(0.0, 40.0) = 1.0;
uniform float u_wire_smoothness : hint_range(0.0, 0.1) = 0.01;

//uniform bool filtered = false;
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
uniform vec2 u_mouse_hit_uv_quadrant = vec2(-1.000000, -1.000000);
uniform float u_mouse_hit_radius = 0.0010000000475;
uniform bool u_triplanar = false;
uniform vec4 u_tile_reduction_per_texture = vec4(0.000000, 0.000000, 0.000000, 0.000000);
uniform bool u_depth_blending = false;
uniform vec4 u_ground_layers = vec4(-1.000000, -1.000000, -1.000000, -1.000000);
uniform vec4 u_north_ground_layers = vec4(-1.000000, -1.000000, -1.000000, -1.000000);
uniform vec4 u_east_ground_layers = vec4(-1.000000, -1.000000, -1.000000, -1.000000);
uniform vec4 u_west_ground_layers = vec4(-1.000000, -1.000000, -1.000000, -1.000000);
uniform vec4 u_south_ground_layers = vec4(-1.000000, -1.000000, -1.000000, -1.000000);
uniform bool u_grid_on = false;

uniform mat4 u_terrain_inverse_transform;
uniform float u_grid_step = 2;
uniform uint u_optimization_level = 0;
uniform uint u_num_vertices_per_chunk;
uniform sampler2D u_terrain_splatmap;
uniform sampler2D u_terrain_colormap;
//uniform sampler2D tex_frg_62;

uniform mat3 u_terrain_normal_basis;
uniform float u_terrain_height = 1.0;	// NOTSET
uniform float u_quad_border_line_thickness = 0.005;	// NOTSET
uniform bool u_force_height_0 = false;
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

varying vec3 barycentrics;

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
	bool _newBlendig = new;
	//newBlendig = true;
	if (!_newBlendig) {
		return texture(_tex, _uv);
	} else {
		vec4 final = texture(_tex, _uv * far_uv_scale);
		final = mix(final, texture(_tex, _uv * middle_uv_scale), v_middle_mask);
		final = mix(final, texture(_tex, _uv * close_uv_scale), v_close_mask);
		return final;
	}
}

vec4 distance_texture_layer(sampler2DArray _tex, vec3 _uv) {
	bool _newBlendig = new;
	if (!_newBlendig) {
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
		vec4 north = vec4(0.0, 0.0, 0.0, 0.0);
		bool north_border_pixel_fetched = false;
		if (north_border_pixel && u_north_ground_layers.x >= 0.0) {
			north = distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_north_ground_layers.x));
			north_border_pixel_fetched = true;
			//return north;
		}

		vec4 west = vec4(0.0, 0.0, 0.0, 0.0);
		bool west_border_pixel_fetched = false;
		if (west_border_pixel && u_west_ground_layers.x >= 0.0) {
			west = distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_west_ground_layers.x));
			west_border_pixel_fetched = true;
			//return west;
		}

		if (north_border_pixel_fetched && west_border_pixel_fetched) {
			if (!gu_texture_new_blending) {
				return mix(west, north, 0.5);
			}
		} else if (north_border_pixel_fetched) {
			return north;
		} else if (west_border_pixel_fetched) {
			return west;
		}

		if (u_ground_layers.x >= 0.0) {
			return distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_ground_layers.x));
		} else {
			return distance_texture(u_ground_albedo_bump_0, uv);
		}
	} else if (type == 1) {
		vec4 north = vec4(0.0, 0.0, 0.0, 0.0);
		bool north_border_pixel_fetched = false;
		if (north_border_pixel && u_north_ground_layers.y >= 0.0) {
			north = distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_north_ground_layers.y));
			north_border_pixel_fetched = true;
			//return north;
		}

		vec4 west = vec4(0.0, 0.0, 0.0, 0.0);
		bool west_border_pixel_fetched = false;
		if (west_border_pixel && u_west_ground_layers.y >= 0.0) {
			west = distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_west_ground_layers.y));
			west_border_pixel_fetched = true;
			//return west;
		}

		if (north_border_pixel_fetched && west_border_pixel_fetched) {
			if (!gu_texture_new_blending) {
				return mix(west, north, 0.5);
			}
		} else if (north_border_pixel_fetched) {
			return north;
		} else if (west_border_pixel_fetched) {
			return west;
		}

		if (u_ground_layers.y >= 0.0) {
			return distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_ground_layers.y));
		} else {
			return distance_texture(u_ground_albedo_bump_1, uv);
		}
	} else if (type == 2) {
		vec4 north = vec4(0.0, 0.0, 0.0, 0.0);
		bool north_border_pixel_fetched = false;
		if (north_border_pixel && u_north_ground_layers.z >= 0.0) {
			north = distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_north_ground_layers.z));
			north_border_pixel_fetched = true;
			//return north;
		}

		vec4 west = vec4(0.0, 0.0, 0.0, 0.0);
		bool west_border_pixel_fetched = false;
		if (west_border_pixel && u_west_ground_layers.z >= 0.0) {
			west = distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_west_ground_layers.z));
			west_border_pixel_fetched = true;
			//return west;
		}

		if (north_border_pixel_fetched && west_border_pixel_fetched) {
			if (!gu_texture_new_blending) {
				return mix(west, north, 0.5);
			}
		} else if (north_border_pixel_fetched) {
			return north;
		} else if (west_border_pixel_fetched) {
			return west;
		}

		if (u_ground_layers.z >= 0.0) {
			return distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_ground_layers.z));
		} else {
			return distance_texture(u_ground_albedo_bump_2, uv);
		}
	} else {
		vec4 north = vec4(0.0, 0.0, 0.0, 0.0);
		bool north_border_pixel_fetched = false;
		if (north_border_pixel && u_north_ground_layers.a >= 0.0) {
			north = distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_north_ground_layers.a));
			north_border_pixel_fetched = true;
			//return north;
		}

		vec4 west = vec4(0.0, 0.0, 0.0, 0.0);
		bool west_border_pixel_fetched = false;
		if (west_border_pixel && u_west_ground_layers.a >= 0.0) {
			west = distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_west_ground_layers.a));
			west_border_pixel_fetched = true;
			//return west;
		}

		if (north_border_pixel_fetched && west_border_pixel_fetched) {
			if (!gu_texture_new_blending) {
				return mix(west, north, 0.5);
			}
		} else if (north_border_pixel_fetched) {
			return north;
		} else if (west_border_pixel_fetched) {
			return west;
		}

		if (u_ground_layers.a >= 0.0) {
			return distance_texture_layer(gu_ground_albedo_bump_array, vec3(uv, u_ground_layers.a));
		} else {
			return distance_texture(u_ground_albedo_bump_3, uv);
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
		} else if (west_border_pixel && u_west_ground_layers.x >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_west_ground_layers.x));
		} else if (u_ground_layers.x >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_ground_layers.x));
		} else {
			return distance_texture(u_ground_normal_roughness_0, uv);
		}
	} else if (type == 1) {
		if (north_border_pixel && u_north_ground_layers.y >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_north_ground_layers.y));
		} else if (west_border_pixel && u_west_ground_layers.y >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_west_ground_layers.y));
		} else if (u_ground_layers.y >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_ground_layers.y));
		} else {
			return distance_texture(u_ground_normal_roughness_1, uv);
		}
	} else if (type == 2) {
		if (north_border_pixel && u_north_ground_layers.z >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_north_ground_layers.z));
		} else if (west_border_pixel && u_west_ground_layers.z >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_west_ground_layers.z));
		} else if (u_ground_layers.z >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_ground_layers.z));
		} else {
			return distance_texture(u_ground_normal_roughness_2, uv);
		}
	} else {
		if (north_border_pixel && u_north_ground_layers.a >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_north_ground_layers.a));
		} else if (west_border_pixel && u_west_ground_layers.a >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_west_ground_layers.a));
		} else if (u_ground_layers.a >= 0.0) {
			return distance_texture_layer(gu_ground_normal_roughness_array, vec3(uv, u_ground_layers.a));
		} else {
			return distance_texture(u_ground_normal_roughness_3, uv);
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

	barycentrics = vectors[VERTEX_ID % 3];

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


	vec3 normal_computed;
// Expression:20
	normal_computed = vec3(0.0, 0.0, 0.0);
	{
		// WARN
		normal_computed = get_normal(u_terrain_normalmap, u_terrain_normal_basis, uv_quadrant);
	}


// BooleanParameter:72
	bool show_chunks = gu_show_chunks;


	uint num_vertices_per_chunk = u_num_vertices_per_chunk;
	int vertex_id = VERTEX_ID;
	int vertex_col = int(floor(mod(float(vertex_id), float(num_vertices_per_chunk))));		// from 0 to num_vertices_per_chunk - 1
	int vertex_row = int(floor(float(vertex_id) / float(num_vertices_per_chunk)));			// from 0 to num_vertices_per_chunk - 1

	float step_between_vertices_in_current_chunk = -1000000000.0;
	float chunk_size = -1000000000.0;
	vec2 uv_chunk = vec2(0.0, 0.0);
	{
		if (vertex_col == 0 && vertex_row == 0)
		{
			uv_chunk = vec2(0.0, 0.0);
		}
		else
		{
			if (vertex_col == 0) {	// vertex_row is > 0
				step_between_vertices_in_current_chunk = floor(vertex_in.z / float(vertex_row));
			} else {	// vertex_col is > 0
				step_between_vertices_in_current_chunk = floor(vertex_in.x / float(vertex_col));
			}
			chunk_size = step_between_vertices_in_current_chunk * float(num_vertices_per_chunk - uint(1));
			uv_chunk = vertex_in.xz / vec2(chunk_size);
		}
	}
	
	
	float lod = 0.0;;
	{
		lod = -1.0;
		if (show_chunks)
		{
			if ((vertex_col == 0 && vertex_row == 0) || (vertex_col == 0 && vertex_row == int(num_vertices_per_chunk - uint(1)))
				|| (vertex_col == int(num_vertices_per_chunk - uint(1)) && vertex_row == 0) || (vertex_col == int(num_vertices_per_chunk - uint(1)) && vertex_row == int(num_vertices_per_chunk - uint(1))))
			{
				//uv_chunk = vec2(0.0, 0.0);
				lod = 99.0;
			}
			else
			{
				//uv_chunk = vertex_in.xz / vec2(chunk_size);
				//uv_chunk = vec2(float(vertex_col) / float(num_vertices_per_chunk), float(vertex_row) / float(num_vertices_per_chunk));
				//lod = log2(step_between_vertices_in_current_chunk);
				lod = log2(step_between_vertices_in_current_chunk) - 1.0;
				//lod = float(step_between_vertices_in_current_chunk);
			}
		}
	}


// Output:0
	VERTEX = vertex_with_h;
	NORMAL = normal_computed;
	UV = uv_quadrant;
	UV2 = uv_chunk;


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

	float alpha = 1.0;
	float distance_from_camera = v_distance_from_camera;
	float globalmap_blend_start = u_globalmap_blend_start;
	float globalmap_blend_distance = u_globalmap_blend_distance;
	vec2 uv_quadrant = UV;
	vec2 uv_chunk = UV2;
	float editmode_selected = u_editmode_selected;
	bool use_globalmap = u_use_globalmap;

	bool editmode_pixel = false;
	bool globalmap_pixel = false;
	{
		if (editmode_selected > 0.0 && is_on_the_border(uv_quadrant, u_quad_border_line_thickness)) {
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


	vec3 albedo_computed_1;
	float roughness_computed_1;
	float globalmap_factor;
// Expression:33
	albedo_computed_1 = vec3(0.0, 0.0, 0.0);
	roughness_computed_1 = 0.0;
	globalmap_factor = 0.0;
	{
		globalmap_factor = 1.0;
		roughness_computed_1 = 1.0;
		if (editmode_pixel) {
			if (gu_hold_blending)
				albedo_computed_1 = red_salmon_color;		// GDN_TheWorld_Globals::g_color_yellow_apricot
			else
				albedo_computed_1 = apricot_color;		// GDN_TheWorld_Globals::g_color_yellow_apricot
		} else {
			albedo_computed_1 = texture(u_terrain_globalmap, uv_quadrant).rgb;
			if (globalmap_pixel) {
				roughness_computed_1 = 0.5;
			} else {
				globalmap_factor = clamp((distance_from_camera - globalmap_blend_start) * globalmap_blend_distance, 0.0, 1.0);
				globalmap_factor *= globalmap_factor; // slower start, faster transition but far away
			}
		}
	}


// ParameterRef:34
	bool triplanar = u_triplanar;


	vec3 normal_computed_1;
// Expression:14
	normal_computed_1 = vec3(0.0, 0.0, 0.0);
	{
		normal_computed_1 = get_normal(u_terrain_normalmap, u_terrain_normal_basis, uv_quadrant);
	}


// VaryingGetter:11
	vec2 vertex_cell_coords_in_textures = v_vertex_cell_coords_in_textures;


// VaryingGetter:12
	vec4 vertex_world_pos = v_vertex_world_pos;


// VaryingGetter:84
	float distance_from_camera_on_terrain = v_distance_from_camera_on_terrain;


// Input:8
	vec3 vertex_in = VERTEX;


// ParameterRef:17
	vec4 ground_uv_scale_per_texture_in = u_ground_uv_scale_per_texture;


// ParameterRef:18
	uint piecing_threshold_factor = u_piecing_threshold_factor;


// ParameterRef:19
	float piece_size = u_piece_size;


// ParameterRef:20
	float scale_per_texture_factor = u_scale_per_texture_factor;


// ParameterRef:82
	float camera_altitude_from_terrain = gu_camera_altitude_from_terrain;


	vec4 ground_uv_scale_per_texture_computed;
	int pieces_from_camera_piece;
// Expression:4
	ground_uv_scale_per_texture_computed = vec4(0.0, 0.0, 0.0, 0.0);
	pieces_from_camera_piece = 0;
	{
		//ground_uv_scale_per_texture_in = vec4(200.0, 200.0, 200.0, 200.0);
		ground_uv_scale_per_texture_computed = ground_uv_scale_per_texture_in;
		pieces_from_camera_piece = -1;

		int alt_piece = int(floor(camera_altitude_from_terrain / piece_size));
		/*if (alt_piece < 4) {
			scale_per_texture_factor *= pow(2.0, float(alt_piece));
		} else {
			camera_altitude_from_terrain = -1.0;
		}*/
		if (camera_altitude_from_terrain < altitude_uv_scale_threshold) {
			scale_per_texture_factor *= pow(2.0, float(alt_piece));
		} else {
			camera_altitude_from_terrain = -1.0;
		}

		if (distance_from_camera_on_terrain < ground_uv_scale_threshold) {
			if (camera_altitude_from_terrain > 0.0) {
				vec3 fragment_world_pos = (INV_VIEW_MATRIX * vec4(vertex_in, 1.0)).xyz;
				int camera_piece_x = int(floor(CAMERA_POSITION_WORLD.x / piece_size));
				int camera_piece_z = int(floor(CAMERA_POSITION_WORLD.z / piece_size));
				int frag_piece_x = int(floor(fragment_world_pos.x / piece_size));
				int frag_piece_z = int(floor(fragment_world_pos.z / piece_size));
				pieces_from_camera_piece = max(int(abs(camera_piece_x - frag_piece_x)), int(abs(camera_piece_z - frag_piece_z)));
				if (pieces_from_camera_piece <= 1)
				{
					ground_uv_scale_per_texture_computed /= (scale_per_texture_factor / 20.0);
					//ground_uv_scale_per_texture_computed = vec4(40.0);
				}
				else if (pieces_from_camera_piece <= 3)
				{
					ground_uv_scale_per_texture_computed /= (scale_per_texture_factor / 10.0);
					//ground_uv_scale_per_texture_computed = vec4(20.0);
				}
				else if (pieces_from_camera_piece <= 5)
				{
					ground_uv_scale_per_texture_computed /= (scale_per_texture_factor / 10.0);
					//ground_uv_scale_per_texture_computed = vec4(20.0);
				}
				else if (pieces_from_camera_piece <= 7)
				{
					ground_uv_scale_per_texture_computed /= (scale_per_texture_factor / 8.0);
					//ground_uv_scale_per_texture_computed = vec4(16.0);
					//ground_uv_scale_per_texture_computed = ground_uv_scale_per_texture_in;
				}
				else if (pieces_from_camera_piece <= 9)
				{
					ground_uv_scale_per_texture_computed /= (scale_per_texture_factor / 4.0);
				}
				else if (pieces_from_camera_piece <= 11)
				{
					ground_uv_scale_per_texture_computed /= (scale_per_texture_factor / 2.0);
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
	vec4 splat_pixel_in = v_splat;


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

	bool north_border_pixel;
	bool south_border_pixel;
	bool west_border_pixel;
	bool east_border_pixel;
	vec4 splat_pixel_computed;
// Expression:73
	north_border_pixel = false;
	south_border_pixel = false;
	west_border_pixel = false;
	east_border_pixel = false;
	splat_pixel_computed = vec4(0.0, 0.0, 0.0, 0.0);
	{
		north_border_pixel = false;
		south_border_pixel = false;
		west_border_pixel = false;
		east_border_pixel = false;
		splat_pixel_computed = splat_pixel_in;

		if (!editmode_pixel && !globalmap_pixel) {
			if (is_on_upper_border(uv_quadrant, distance_from_border)) {
				north_border_pixel = true;
				//splat_pixel_computed = splat_pixel_computed + ;
			}
			if (is_on_lower_border(uv_quadrant, distance_from_border)) {
				south_border_pixel = true;
				//splat_pixel_computed = splat_pixel_computed + ;
			}
			if (is_on_left_border(uv_quadrant, distance_from_border)) {
				west_border_pixel = true;
				//splat_pixel_computed = splat_pixel_computed + ;
			}
			if (is_on_right_border(uv_quadrant, distance_from_border)) {
				east_border_pixel = true;
				//splat_pixel_computed = splat_pixel_computed + ;
			}
		}
		//splat_pixel_computed = splat_pixel_in;
	}



	vec2 ground_uv0;
	vec2 ground_uv1;
	vec2 ground_uv2;
	vec3 ground_uv3;
// Expression:10
	ground_uv0 = vec2(0.0, 0.0);
	ground_uv1 = vec2(0.0, 0.0);
	ground_uv2 = vec2(0.0, 0.0);
	ground_uv3 = vec3(0.0, 0.0, 0.0);
	{
		vec3 base_ground_uv;

		//ground_uv_scale_per_texture_computed = vec4(2.0);
		if (new) {
			ground_uv_scale_per_texture_computed = vec4(1.0, 1.0, 1.0, 1.0);
		}
		base_ground_uv = vec3(uv_quadrant.x, vertex_world_pos.y * MODEL_MATRIX[1][1], uv_quadrant.y);
		ground_uv0 = base_ground_uv.xz * ground_uv_scale_per_texture_computed.x;
		ground_uv1 = base_ground_uv.xz * ground_uv_scale_per_texture_computed.y;
		ground_uv2 = base_ground_uv.xz * ground_uv_scale_per_texture_computed.z;
		ground_uv3 = base_ground_uv * ground_uv_scale_per_texture_computed.w;

	}


// ParameterRef:35
	vec4 tile_reduction_per_texture = u_tile_reduction_per_texture;


	vec3 albedo_computed_2;
	float roughness_computed_2;
	vec3 normal_computed_2;
	vec4 ab0;
	vec4 ab1;
	vec4 ab2;
	vec4 ab3;
	vec4 nr0;
	vec4 nr1;
	vec4 nr2;
	vec4 nr3;
// Expression:30
	albedo_computed_2 = vec3(0.0, 0.0, 0.0);
	roughness_computed_2 = 0.0;
	normal_computed_2 = vec3(0.0, 0.0, 0.0);
	ab0 = vec4(0.0, 0.0, 0.0, 0.0);
	ab1 = vec4(0.0, 0.0, 0.0, 0.0);
	ab2 = vec4(0.0, 0.0, 0.0, 0.0);
	ab3 = vec4(0.0, 0.0, 0.0, 0.0);
	nr0 = vec4(0.0, 0.0, 0.0, 0.0);
	nr1 = vec4(0.0, 0.0, 0.0, 0.0);
	nr2 = vec4(0.0, 0.0, 0.0, 0.0);
	nr3 = vec4(0.0, 0.0, 0.0, 0.0);
	{
		roughness_computed_2 = roughness_computed_1;
		albedo_computed_2 = albedo_computed_1;
		normal_computed_2 = normal_computed_1;

		if (!editmode_pixel && !globalmap_pixel) {
			if (triplanar) {
				// Only do triplanar on one texture slot,
				// because otherwise it would be very expensive and cost many more ifs.
				// I chose the last slot because first slot is the default on new splatmaps,
				// and that's a feature used for cliffs, which are usually designed later.

				vec3 blending = get_triplanar_blend(normal_computed_1);

				//ab3 = texture_triplanar(u_ground_albedo_bump_3, ground_uv3, blending);
				//nr3 = texture_triplanar(u_ground_normal_roughness_3, ground_uv3, blending);
				ab3 = texture_triplanar_ab_layers(3, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, ground_uv3, blending);
				nr3 = texture_triplanar_nr_layers(3, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, ground_uv3, blending);

			} else {
				if (tile_reduction_per_texture[3] > 0.0) {
					//ab3 = texture_antitile(u_ground_albedo_bump_3, u_ground_normal_roughness_3, ground_uv3.xz, nr3);
					ab3 = texture_antitile_layers(3, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, ground_uv3.xz, nr3);
				} else {
					//ab3 = texture(u_ground_albedo_bump_3, ground_uv3.xz);
					//nr3 = texture(u_ground_normal_roughness_3, ground_uv3.xz);
					ab3 = texture_albedo_bump(3, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, ground_uv3.xz);
					nr3 = texture_normal_roughness(3, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, ground_uv3.xz);
				}
			}

			if (tile_reduction_per_texture[0] > 0.0) {
				//ab0 = texture_antitile(u_ground_albedo_bump_0, u_ground_normal_roughness_0, ground_uv0, nr0);
				ab0 = texture_antitile_layers(0, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, ground_uv0, nr0);
			} else {
				//ab0 = texture(u_ground_albedo_bump_0, ground_uv0);
				//nr0 = texture(u_ground_normal_roughness_0, ground_uv0);
				ab0 = texture_albedo_bump(0, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, ground_uv0);
				nr0 = texture_normal_roughness(0, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, ground_uv0);
			}
			if (tile_reduction_per_texture[1] > 0.0) {
				//ab1 = texture_antitile(u_ground_albedo_bump_1, u_ground_normal_roughness_1, ground_uv1, nr1);
				ab1 = texture_antitile_layers(1, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, ground_uv1, nr1);
			} else {
				//ab1 = texture(u_ground_albedo_bump_1, ground_uv1);
				//nr1 = texture(u_ground_normal_roughness_1, ground_uv1);
				ab1 = texture_albedo_bump(1, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, ground_uv1);
				nr1 = texture_normal_roughness(1, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, ground_uv1);
			}
			if (tile_reduction_per_texture[2] > 0.0) {
				//ab2 = texture_antitile(u_ground_albedo_bump_2, u_ground_normal_roughness_2, ground_uv2, nr2);
				ab2 = texture_antitile_layers(2, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, ground_uv2, nr2);
			} else {
				//ab2 = texture(u_ground_albedo_bump_2, ground_uv2);
				//nr2 = texture(u_ground_normal_roughness_2, ground_uv2);
				ab2 = texture_albedo_bump(2, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, ground_uv2);
				nr2 = texture_normal_roughness(2, north_border_pixel, south_border_pixel, west_border_pixel, east_border_pixel, ground_uv2);
			}

			/*if (north_border_pixel || south_border_pixel || west_border_pixel || east_border_pixel) {
				vec4 _ab0 = mix(ab0, ab1, 0.5);
				vec4 _ab1 = mix(ab1, ab0, 0.5);
				ab0 = _ab0;
				ab1 = _ab1;
			}*/

			/*vec3 red = vec3(1.0, 0.0, 0.0);
			vec3 green = vec3(0.0, 1.0, 0.0);
			vec3 blue = vec3(0.0, 0.0, 1.0);
			vec3 yellow = apricot_color;
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
		}
	}


	vec3 tint0 = v_tint0;
	vec3 tint1 = v_tint1;
	vec3 tint2 = v_tint2;
	vec3 tint3 = v_tint3;

	bool depth_blending = u_depth_blending;

	vec3 albedo_computed_3;
	float roughness_computed_3;
	vec3 normal_computed_3;
	float ao_computed_1;
	float ao_light_affect_computed_1;
	albedo_computed_3 = vec3(0.0, 0.0, 0.0);
	roughness_computed_3 = 0.0;
	normal_computed_3 = vec3(0.0, 0.0, 0.0);
	ao_computed_1 = 0.0;
	ao_light_affect_computed_1 = 0.0;
	{
		if (editmode_pixel || globalmap_pixel) {
			roughness_computed_3 = roughness_computed_2;
			albedo_computed_3 = albedo_computed_2;
			normal_computed_3 = normal_computed_2;
		} else {
			// col(0-3) is the result of the pixel fetched from u_ground_albedo_bump_(0-3) modified
			// by the value fetched from u_terrain_colormap and relative to the vertex corresponding
			// to current pixel
			// the value fetched from u_terrain_colormap if modified to the white according to the
			// vector u_colormap_opacity_per_texture (default value don't modify the color)
			vec3 col0 = ab0.rgb * tint0;
			vec3 col1 = ab1.rgb * tint1;
			vec3 col2 = ab2.rgb * tint2;
			vec3 col3 = ab3.rgb * tint3;
			//col0 = ab0.rgb;
			//col1 = ab1.rgb;
			//col2 = ab2.rgb;
			//col3 = ab3.rgb;

			vec4 rough = vec4(nr0.a, nr1.a, nr2.a, nr3.a);

			//vec3 normal0 = unpack_normal(nr0);
			//vec3 normal1 = unpack_normal(nr1);
			//vec3 normal2 = unpack_normal(nr2);
			//vec3 normal3 = unpack_normal(nr3);
			vec3 normal0 = nr0.rgb;
			vec3 normal1 = nr1.rgb;
			vec3 normal2 = nr2.rgb;
			vec3 normal3 = nr3.rgb;

			vec4 w;
			// TODO An #ifdef macro would be nice! Or copy/paste everything in a different shader...
			if (depth_blending) {
				w = get_depth_blended_weights(splat_pixel_computed, vec4(ab0.a, ab1.a, ab2.a, ab3.a));
			} else {
				w = splat_pixel_computed.rgba;
			}

			float w_sum = (w.r + w.g + w.b + w.a);

			albedo_computed_3 = (
				w.r * col0.rgb +
				w.g * col1.rgb +
				w.b * col2.rgb +
				w.a * col3.rgb) / w_sum;

			roughness_computed_3 = (
				w.r * rough.r +
				w.g * rough.g +
				w.b * rough.b +
				w.a * rough.a) / w_sum;

			vec3 ground_normal = /*u_terrain_normal_basis **/ (
				w.r * normal0 +
				w.g * normal1 +
				w.b * normal2 +
				w.a * normal3) / w_sum;
			// If no splat_pixel_computed textures are defined, normal vectors will default to (1,1,1),
			// which is incorrect, and causes the terrain to be shaded wrongly in some directions.
			// However, this should not be a problem to fix in the shader,
			// because there MUST be at least one splat_pixel_computed texture set.
			//ground_normal = normalize(ground_normal);
			// TODO Make the plugin insert a default normalmap if it's empty

			// Combine terrain normals with detail normals (not sure if correct but looks ok)
			normal_computed_3 = normalize(vec3(normal_computed_2.x + ground_normal.x, normal_computed_2.y, normal_computed_2.z + ground_normal.z));
			normal_computed_3 = mix(normal_computed_3, normal_computed_2, globalmap_factor);
			albedo_computed_3 = mix(albedo_computed_3, albedo_computed_2, globalmap_factor);
			roughness_computed_3 = mix(roughness_computed_3, 1.0, globalmap_factor);
			ao_computed_1 = (w.r * ab0.a +	w.g * ab1.a + w.b * ab2.a +	w.a * ab3.a) / w_sum;
			ao_light_affect_computed_1 = 0.1;
			//METALLIC = (w.r * ab0.a +	w.g * ab1.a + w.b * ab2.a +	w.a * ab3.a) / w_sum;
			//SPECULAR = 0.5;

			/*vec3 red = vec3(1.0, 0.0, 0.0);
			vec3 green = vec3(0.0, 1.0, 0.0);
			vec3 blue = vec3(0.0, 0.0, 1.0);
			vec3 yellow = apricot_color;
			if (splat_pixel_computed.x < 0.0)	{
				albedo_computed_3 = red;
			}
			if (splat_pixel_computed.y < 0.0)	{
				albedo_computed_3 = green;
			}
			if (splat_pixel_computed.z < 0.0)	{
				albedo_computed_3 = blue;
			}
			if (splat_pixel_computed.a < 0.0)	{
				albedo_computed_3 = yellow;
			}*/
		}
	}

	vec2 mouse_hit_uv_quadrant = u_mouse_hit_uv_quadrant;

	float mouse_hit_radius = u_mouse_hit_radius;

	bool grid_on = u_grid_on;

	vec3 albedo_computed_4;
	float roughness_computed_4;
	vec3 normal_computed_4;
	float quad_line_thickness;
	albedo_computed_4 = vec3(0.0, 0.0, 0.0);
	roughness_computed_4 = 0.0;
	normal_computed_4 = vec3(0.0, 0.0, 0.0);
	quad_line_thickness = 0.0;
	{
		albedo_computed_4 = albedo_computed_3;
		normal_computed_4 = (VIEW_MATRIX * (vec4(normal_computed_3, 0.0))).xyz;
		roughness_computed_4 = roughness_computed_3;

		quad_line_thickness = 0.05;

		// DEBUG: wisualize pieces
		/*if (pieces_from_camera_piece == 0) {
			albedo_computed_4 = vec3(1.0, 0.0, 0.0);
		} else if (pieces_from_camera_piece == 1) {
			albedo_computed_4 = vec3(0.0, 1.0, 0.0);
		} else if (pieces_from_camera_piece == 2) {
			albedo_computed_4 = vec3(0.0, 0.0, 1.0);
		} else if (pieces_from_camera_piece == 3) {
			albedo_computed_4 = vec3(1.0, 0.0, 1.0);
		}*/
		// DEBUG: wisualize pieces
		//albedo_computed_4 = vec3(v_close_mask);	// DEBUG
		//albedo_computed_4 = vec3(v_middle_mask);	// DEBUG

		//bool grid_on = !(mouse_hit_uv_quadrant == vec2(-1));
		/*if (grid_on) {
			float half_texel_size = 0.5 / vec2(textureSize(u_terrain_heightmap, 0)).x;
			vec2 uv_begin_texel = uv_quadrant - vec2(half_texel_size);
			vec2 distance_from_vertex =
				fract(vec2(uv_begin_texel.x / (half_texel_size * 2.0), uv_begin_texel.y / (half_texel_size * 2.0)));
			if (distance_from_vertex.x < quad_line_thickness || (1.0 - distance_from_vertex.x) < quad_line_thickness
				|| distance_from_vertex.y < quad_line_thickness || (1.0 - distance_from_vertex.y) < quad_line_thickness) {
				if ((distance_from_vertex.x < quad_line_thickness || (1.0 - distance_from_vertex.x) < quad_line_thickness)
					&& (distance_from_vertex.y < quad_line_thickness || (1.0 - distance_from_vertex.y) < quad_line_thickness)) {
					//albedo_computed_4 = mix(albedo_computed_4, vec3(1.0, 0.0, 0.0), 0.3);	// GDN_TheWorld_Globals::g_color_yellow_red
					albedo_computed_4 = vec3(1.0, 0.0, 0.0);	// GDN_TheWorld_Globals::g_color_yellow_red
				} else {
					//albedo_computed_4 = mix(albedo_computed_4, apricot_color, 0.3);	// GDN_TheWorld_Globals::g_color_yellow_apricot
					albedo_computed_4 = apricot_color;	// GDN_TheWorld_Globals::g_color_yellow_apricot
				}
			}
			vec2 g_uv0 = fract(ground_uv0);
			float uv_line_thickness = quad_line_thickness / 10.0;
			if (g_uv0.x < uv_line_thickness || (1.0 - g_uv0.x) < uv_line_thickness
				|| g_uv0.y < uv_line_thickness || (1.0 - g_uv0.y) < uv_line_thickness) {
				albedo_computed_4 = mix(albedo_computed_4, vec3(0.0, 0.0, 1.0), 0.3);		// GDN_TheWorld_Globals::g_color_blue;
			}
		}*/

		if (mouse_hit_uv_quadrant != vec2(-1)) {
			float half_texel_size = 0.5 / vec2(textureSize(u_terrain_heightmap, 0)).x;
			vec2 uv_begin_texel = uv_quadrant - vec2(half_texel_size);
			vec2 distance_from_vertex =
				fract(vec2(uv_begin_texel.x / (half_texel_size * 2.0), uv_begin_texel.y / (half_texel_size * 2.0)));
			float grid_radius = mouse_hit_radius * 5.0;
			if (grid_radius != 0.0 && distance(mouse_hit_uv_quadrant, uv_quadrant) < grid_radius)
			{
				if (distance_from_vertex.x < quad_line_thickness || (1.0 - distance_from_vertex.x) < quad_line_thickness
					|| distance_from_vertex.y < quad_line_thickness || (1.0 - distance_from_vertex.y) < quad_line_thickness) {
					if ((distance_from_vertex.x < quad_line_thickness || (1.0 - distance_from_vertex.x) < quad_line_thickness)
						&& (distance_from_vertex.y < quad_line_thickness || (1.0 - distance_from_vertex.y) < quad_line_thickness)) {
						//albedo_computed_4 = mix(albedo_computed_4, vec3(1.0, 0.0, 0.0), 0.3);	// GDN_TheWorld_Globals::g_color_yellow_red
						albedo_computed_4 = vec3(1.0, 0.0, 0.0);	// GDN_TheWorld_Globals::g_color_yellow_red
					} else {
						//albedo_computed_4 = mix(albedo_computed_4, apricot_color, 0.3);	// GDN_TheWorld_Globals::g_color_yellow_apricot
						albedo_computed_4 = apricot_color;	// GDN_TheWorld_Globals::g_color_yellow_apricot
					}
				}
			}

			if (mouse_hit_radius != 0.0 && distance(mouse_hit_uv_quadrant, uv_quadrant) < mouse_hit_radius) {
				vec3 mouse_hit_albedo = apricot_color;		// GDN_TheWorld_Globals::g_color_yellow_apricot
				albedo_computed_4 = mix(albedo_computed_4, mouse_hit_albedo, 0.3);
			}
		}
	}

	float quadrant_texture_lod = v_lod;

	vec3 albedo_computed_5;
	float roughness_computed_5;
	vec3 normal_computed_5;
	albedo_computed_5 = vec3(0.0, 0.0, 0.0);
	roughness_computed_5 = 0.0;
	normal_computed_5 = vec3(0.0, 0.0, 0.0);
	{
		albedo_computed_5 = albedo_computed_4;
		normal_computed_5 = normal_computed_4;
		roughness_computed_5 = roughness_computed_4;
		if (quadrant_texture_lod >= 0.0) {
			//quadrant_texture_lod = floor(quadrant_texture_lod);
			float f = floor(quadrant_texture_lod);
			float c = ceil(quadrant_texture_lod);
			if ((quadrant_texture_lod - f) > (c - quadrant_texture_lod) ) {
				quadrant_texture_lod = c;
			} else {
				quadrant_texture_lod = f;
			}

			float chunk_border_line_thickness = 0.005;

			if (u_editmode_selected > 0.0 && is_on_the_border(UV, quad_line_thickness)) {
				albedo_computed_5 = apricot_color;		// GDN_TheWorld_Globals::g_color_yellow_apricot
			} else {
				if (mouse_hit_uv_quadrant != vec2(-1) && distance(mouse_hit_uv_quadrant, UV) < mouse_hit_radius) {
					albedo_computed_5 = apricot_color;		// GDN_TheWorld_Globals::g_color_yellow_apricot
				} else {
					if (is_on_the_border(UV, chunk_border_line_thickness) || is_on_the_border(uv_chunk, chunk_border_line_thickness)) {
						//albedo_computed_5 = vec3(1.0, 1.0, 1.0);		// GDN_TheWorld_Globals::g_color_white
						albedo_computed_5 = vec3(0.0, 0.0, 0.0);		// GDN_TheWorld_Globals::g_color_black
					} else {
						if (quadrant_texture_lod >= 0.0 && quadrant_texture_lod <= 8.0) {
							albedo_computed_5 = lod_colors[int(quadrant_texture_lod)];
						} else {
							albedo_computed_5 = lod_colors[9];
						}
					}
				}
			}
		}

		//bool grid_on = !(mouse_hit_uv_quadrant == vec2(-1));
		if (grid_on) {
			float half_texel_size_in_uv_coords = 0.5 / vec2(textureSize(u_terrain_heightmap, 0)).x;
			vec2 uv_begin_texel = uv_quadrant - vec2(half_texel_size_in_uv_coords);	// assuming uv is in the center of a texel for each fragment
			vec2 distance_of_current_fragment_from_grid_vertex = fract(vec2(uv_begin_texel.x / (half_texel_size_in_uv_coords * 2.0), uv_begin_texel.y / (half_texel_size_in_uv_coords * 2.0)));
			if (distance_of_current_fragment_from_grid_vertex.x < quad_line_thickness || (1.0 - distance_of_current_fragment_from_grid_vertex.x) < quad_line_thickness
				|| distance_of_current_fragment_from_grid_vertex.y < quad_line_thickness || (1.0 - distance_of_current_fragment_from_grid_vertex.y) < quad_line_thickness) {
				if ((distance_of_current_fragment_from_grid_vertex.x < quad_line_thickness || (1.0 - distance_of_current_fragment_from_grid_vertex.x) < quad_line_thickness)
					&& (distance_of_current_fragment_from_grid_vertex.y < quad_line_thickness || (1.0 - distance_of_current_fragment_from_grid_vertex.y) < quad_line_thickness)) {
					//albedo_computed_5 = mix(albedo_computed_5, vec3(1.0, 0.0, 0.0), 0.3);	// GDN_TheWorld_Globals::g_color_yellow_red
					albedo_computed_5 = vec3(1.0, 0.0, 0.0);	// GDN_TheWorld_Globals::g_color_yellow_red
				} else {
					//albedo_computed_5 = mix(albedo_computed_5, apricot_color, 0.3);	// GDN_TheWorld_Globals::g_color_yellow_apricot
					albedo_computed_5 = apricot_color;	// GDN_TheWorld_Globals::g_color_yellow_apricot
				}
			}
			vec2 g_uv0 = fract(ground_uv0);
			float uv_line_thickness = quad_line_thickness / 10.0;
			if (g_uv0.x < uv_line_thickness || (1.0 - g_uv0.x) < uv_line_thickness
				|| g_uv0.y < uv_line_thickness || (1.0 - g_uv0.y) < uv_line_thickness) {
				albedo_computed_5 = mix(albedo_computed_5, vec3(0.0, 0.0, 1.0), 0.3);		// GDN_TheWorld_Globals::g_color_blue;
			}
		}
		
		uint num_vertices_per_chunk = u_num_vertices_per_chunk;
		bool need_blending = u_need_blending;
		if (!gu_show_need_blending)
			need_blending = false;
		bool wireframe = need_blending;
		if (!wireframe)
			wireframe = gu_show_wireframe;
		//wireframe = true;	// DEBUG
		if (wireframe)
		{
			bool need_blending_north = u_need_blending_north;
			bool need_blending_south = u_need_blending_south;
			bool need_blending_east = u_need_blending_east;
			bool need_blending_west = u_need_blending_west;
			//need_blending_north = false;
			//need_blending_south = false;
			//need_blending_east = true;
			//need_blending_west = false;
			float uv_wire_width = u_uv_wire_width;
			float uv_border_wire_width = u_uv_wire_width * 3.0;
			float half_texel_size_in_uv_coords = 0.5 / vec2(textureSize(u_terrain_heightmap, 0)).x;
			//half_texel_size_in_uv_coords = 0.0;	// DEBUG
			
			if (uv_quadrant.x < (half_texel_size_in_uv_coords + uv_border_wire_width))					// check left border of quadrant
			{
				if (need_blending_west) {
					albedo_computed_5 = u_wire_color_border_blending.rgb;
				}
				else {
					albedo_computed_5 = u_wire_color.rgb;
				}
			}
			else if (uv_quadrant.y < (half_texel_size_in_uv_coords + uv_border_wire_width))				// check up border of quadrant
			{
				if (need_blending_north) {
					albedo_computed_5 = u_wire_color_border_blending.rgb;
				}
				else {
					albedo_computed_5 = u_wire_color.rgb;
				}
			}
			else if ((1.0 - uv_quadrant.x) < (half_texel_size_in_uv_coords + uv_border_wire_width))		// check right border of quadrant
			{
				if (need_blending_east) {
					albedo_computed_5 = u_wire_color_border_blending.rgb;
				}
				else {
					albedo_computed_5 = u_wire_color.rgb;
				}
			}
			else if  ((1.0 - uv_quadrant.y) < (half_texel_size_in_uv_coords + uv_border_wire_width))	// check bottom border of quadrant
			{
				if (need_blending_south) {
					albedo_computed_5 = u_wire_color_border_blending.rgb;
				}
				else {
					albedo_computed_5 = u_wire_color.rgb;
				}
			}
			else
			{
				float uv_distance_from_vertices = 1.0 / float(num_vertices_per_chunk - uint(1));
				vec2 uv_distance_from_previous_vertex = fract(uv_chunk / vec2(uv_distance_from_vertices)) * vec2(uv_distance_from_vertices);
				vec2 uv_distance_from_next_vertex = vec2(uv_distance_from_vertices) - uv_distance_from_previous_vertex;
				if ((uv_distance_from_previous_vertex.x < (half_texel_size_in_uv_coords + uv_wire_width)) || (uv_distance_from_previous_vertex.y < (half_texel_size_in_uv_coords + uv_wire_width))
					|| (uv_distance_from_next_vertex.x < (half_texel_size_in_uv_coords + uv_wire_width)) || (uv_distance_from_next_vertex.y < (half_texel_size_in_uv_coords + uv_wire_width)))
				{
					albedo_computed_5 = u_wire_color.rgb;
				}
				else
				{
					if (need_blending) {
						if (u_editmode_selected > 0.0) {
							albedo_computed_5 = u_selected_albedo.rgb;
						} else {
							albedo_computed_5 = u_need_blending_albedo.rgb;
						}
					} else {
						albedo_computed_5 = u_wire_albedo.rgb;
					}
					alpha = 0.5;
				}
			}
		}

		/*if (quadrant_texture_lod >= 0.0 && quadrant_texture_lod <= 511.0) {
			albedo_computed_5 = vec3(1.0);	// white
		} else {
			albedo_computed_5 = vec3(0.0);	// black
		}*/
		/*if (uv_chunk.x >= 0.0 && uv_chunk.x <= 1.0 && uv_chunk.y >= 0.0 && uv_chunk.y <= 1.0) {
			albedo_computed_5 = vec3(1.0);	// white
		}*/
		//albedo_computed_5 = vec3(uv_chunk.x, uv_chunk.y, 1.0);
	}
	

	// Output
	if (u_barycentric_wireframe)
	{
		/*vec3 dBaryCoordX = dFdx(barycentrics);
		vec3 dBaryCoordY = dFdy(barycentrics);
		vec3 dBaryCoord  = sqrt(dBaryCoordX*dBaryCoordX + dBaryCoordY*dBaryCoordY);
		vec3 Remap = smoothstep(
			vec3(0.0),
			dBaryCoord,
			barycentrics
		);
		float ClosestEdge = min(min(Remap.x, Remap.y), Remap.z);
		ALBEDO = vec3(ClosestEdge);*/

		vec3 deltas = fwidth(barycentrics);
		vec3 barys_s = smoothstep(deltas * u_wire_width - u_wire_smoothness, deltas * u_wire_width + u_wire_smoothness, barycentrics);
		float wires = min(barys_s.x, min(barys_s.y, barys_s.z));
		ALBEDO = mix(u_wire_color.rgb, u_wire_albedo.rgb, wires);
		//ALPHA = alpha;
	}
	else
	{
		ALBEDO = albedo_computed_5;
		ROUGHNESS = roughness_computed_5;
		AO = ao_computed_1;
		AO_LIGHT_AFFECT = ao_light_affect_computed_1;
		NORMAL = normal_computed_5;
		//ALPHA = alpha;
	}
	
	if (gu_highlight_hit_quadrant && mouse_hit_uv_quadrant != vec2(-1) && (mouse_hit_uv_quadrant.x >= 0.0 && mouse_hit_uv_quadrant.x <= 1.0 && mouse_hit_uv_quadrant.y >= 0.0 && mouse_hit_uv_quadrant.y <= 1.0))
	{
		/*float shine = abs(sin(TIME * u_shine_speed));
		float start_smoothness = 0.05;
		float smooth_shine = mix(start_smoothness, u_smoothness, shine);
		vec3 shine_color = apricot_color;
		if (gu_hold_blending)
			shine_color = red_salmon_color;
		ALBEDO = mix(ALBEDO, shine_color.rgb, smooth_shine);*/
		ALBEDO = mix(ALBEDO, apricot_color, 0.05);
	}
}
