shader_type canvas_item;
render_mode blend_disabled;

#include "res://addons/twviewer/shaders/include/CommonFunctions.gdshaderinc"

uniform sampler2D u_terrain_normalmap;
uniform float u_slope_vertical_factor = 4.0;
uniform float u_slope_flat_factor = 1.0;
uniform float u_dirt_on_rocks_factor = 2.0;
uniform float u_high_elevation_factor = 4.0;
uniform float u_low_elevation_factor = 2.0;
uniform float u_min_heigth;
uniform float u_max_heigth;
uniform float u_splatmap_mode = 1.0;	// NOTSET
uniform float u_grid_step = 2.0;		// Heightmap grid step it is indipendent from lod
uniform float u_terrain_height = 1.0;	// NOTSET

void fragment() {
	vec2 uv = UV;
	float h = get_height(TEXTURE, u_terrain_height, uv);
	vec3 n = get_normal_1(u_terrain_normalmap, uv);
	float slope = (u_slope_vertical_factor * (1.0 - n.y)) - u_slope_flat_factor;
	float rocks_amount = clamp(slope, 0.0, 1.0);
	float dirt_amount = clamp(rocks_amount * u_dirt_on_rocks_factor, 0.0, 1.0);
	float high_elevation_amount = u_high_elevation_factor * ((h - u_min_heigth) / (u_max_heigth - u_min_heigth)) - u_low_elevation_factor;
	high_elevation_amount = clamp(high_elevation_amount, 0.0, 1.0);
	float low_elevation_amount = 1.0 - high_elevation_amount;
	
	vec4 splat_pixel;
	
	//u_splatmap_mode == 1.0;
	splat_pixel.r = low_elevation_amount;
	splat_pixel.r = lerp_f(splat_pixel.r, 0.0, high_elevation_amount);
	splat_pixel.r = lerp_f(splat_pixel.r, 0.0, dirt_amount);
	splat_pixel.r = lerp_f(splat_pixel.r, 0.0, rocks_amount);
	splat_pixel.g = high_elevation_amount;
	splat_pixel.g = lerp_f(splat_pixel.g, 0.0, dirt_amount);
	splat_pixel.g = lerp_f(splat_pixel.g, 0.0, rocks_amount);
	splat_pixel.b = dirt_amount;
	splat_pixel.b = lerp_f(splat_pixel.b, 0.0, rocks_amount);
	splat_pixel.a = rocks_amount;

	COLOR = splat_pixel;
	//COLOR = encode_height_to_viewport(h);	// DEBUG: pong texel height as pixel color
	//COLOR = vec4(n, 1.0);					// DEBUG: pong texel normal as pixel color
}
