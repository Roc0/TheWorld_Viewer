shader_type canvas_item;
render_mode blend_disabled;

#include "res://addons/twviewer/shaders/include/CommonFunctions.gdshaderinc"

uniform float u_grid_step = 2.0;		// Heightmap grid step it is indipendent from lod
uniform float u_terrain_height = 1.0;	// NOTSET

void fragment() {
	vec2 uv = UV;
	vec2 ps = TEXTURE_PIXEL_SIZE;
	vec3 n;
	
	float h = get_height(TEXTURE, u_terrain_height, uv);

	if (distance(uv.x, 1.0) >= ps.x && distance(uv.y, 1.0) >= ps.y) {
		// Not near right border and not near bottom border
		float right_h = get_height(TEXTURE, u_terrain_height, uv + vec2(ps.x, 0));
		float bottom_h = get_height(TEXTURE, u_terrain_height, uv + vec2(0, ps.y));
		n = normalize(vec3(h - right_h, u_grid_step, h - bottom_h));
	} else {
		if (distance(uv.x, 1.0) < ps.x && distance(uv.y, 1.0) >= ps.y) {
			// Near right border but not near bottom border
			float bottom_h = get_height(TEXTURE, u_terrain_height, uv + vec2(0, ps.y));
			float left_h = get_height(TEXTURE, u_terrain_height, uv + vec2(-ps.x, 0));
			n = normalize(vec3(h - bottom_h, u_grid_step, h - left_h));		
		} else {
			if (distance(uv.x, 1.0) >= ps.x && distance(uv.y, 1.0) < ps.y ) {
				// Near botton border but not near right border
				float right_h = get_height(TEXTURE, u_terrain_height, uv + vec2(ps.x, 0));
				float top_h = get_height(TEXTURE, u_terrain_height, uv + vec2(0, -ps.y));
				n = normalize(vec3(h - top_h, u_grid_step, h - right_h));
			} else {
				// Near botton border and near right border
				float left_h = get_height(TEXTURE, u_terrain_height, uv + vec2(-ps.x, 0));
				float top_h = get_height(TEXTURE, u_terrain_height, uv + vec2(0, -ps.y));
				n = normalize(vec3(h - left_h, u_grid_step, h - top_h));
			}
		}
	}
	
	COLOR = pack_normal(n, 1.0);
	
	/*
	float h;
	float right_h;
	float bottom_h;

	if (distance(uv.x, 1.0) < ps.x) {
		// Near right border
		// WRONG: we calc normal in the pixel on the left not in the current pixel
		h = get_height(TEXTURE, u_terrain_height, uv - vec2(ps.x, 0));
		right_h = get_height(TEXTURE, u_terrain_height, uv);
		bottom_h = get_height(TEXTURE, u_terrain_height, uv - vec2(ps.x, -ps.y));
	} else {
		if (distance(uv.y, 1.0) < ps.y) {
			// Near right border
			// WRONG: we calc normal in the pixel above the current pixel not in the current pixel
			h = get_height(TEXTURE, u_terrain_height, uv - vec2(0, ps.y));
			right_h = get_height(TEXTURE, u_terrain_height, uv - vec2(-ps.x, ps.y));
			bottom_h = get_height(TEXTURE, u_terrain_height, uv);
		} else {
			// Correct
			h = get_height(TEXTURE, u_terrain_height, uv);
			right_h = get_height(TEXTURE, u_terrain_height, uv + vec2(ps.x, 0));
			bottom_h = get_height(TEXTURE, u_terrain_height, uv + vec2(0, ps.y));
		}
	}

	//h = get_height(TEXTURE, u_terrain_height, uv);
	//right_h = get_height(TEXTURE, u_terrain_height, uv + vec2(ps.x, 0));
	//bottom_h = get_height(TEXTURE, u_terrain_height, uv + vec2(0, ps.y));
	vec3 n = normalize(vec3(h - right_h, u_grid_step, h - bottom_h));
	COLOR = pack_normal(n, 1.0);
	//COLOR = encode_height_to_viewport(h);	// DEBUG: pong texel height as pixel color
	*/
}
