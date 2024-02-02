shader_type canvas_item;
render_mode blend_disabled;

#include "res://addons/twviewer/shaders/include/CommonFunctions.gdshaderinc"

uniform float u_grid_step = 2.0;		// Heightmap grid step it is indipendent from lod
uniform float u_terrain_height = 1.0;	// NOTSET

void fragment() {
	vec2 uv = UV;
	vec2 ps = TEXTURE_PIXEL_SIZE;
	float h;
	float right_h;
	float fore_h;
	if (distance(uv.x, 1.0) < ps.x) {
		h = get_height(TEXTURE, u_terrain_height, uv - vec2(ps.x, 0));
		right_h = get_height(TEXTURE, u_terrain_height, uv);
		fore_h = get_height(TEXTURE, u_terrain_height, uv - vec2(ps.x, -ps.y));
	} else {
		if (distance(uv.y, 1.0) < ps.y) {
			h = get_height(TEXTURE, u_terrain_height, uv - vec2(0, ps.y));
			right_h = get_height(TEXTURE, u_terrain_height, uv - vec2(-ps.x, ps.y));
			fore_h = get_height(TEXTURE, u_terrain_height, uv);
		} else {
			h = get_height(TEXTURE, u_terrain_height, uv);
			right_h = get_height(TEXTURE, u_terrain_height, uv + vec2(ps.x, 0));
			fore_h = get_height(TEXTURE, u_terrain_height, uv + vec2(0, ps.y));
		}
	}
	//h = get_height(TEXTURE, u_terrain_height, uv);
	//right_h = get_height(TEXTURE, u_terrain_height, uv + vec2(ps.x, 0));
	//fore_h = get_height(TEXTURE, u_terrain_height, uv + vec2(0, ps.y));
	vec3 n = normalize(vec3(h - right_h, u_grid_step, h - fore_h));
	COLOR = pack_normal(n, 1.0);
	//COLOR = encode_height_to_viewport(h);	// DEBUG: pong texel height as pixel color
}
