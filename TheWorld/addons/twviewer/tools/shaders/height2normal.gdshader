shader_type canvas_item;

#include "res://addons/twviewer/shaders/include/CommonFunctions.gdshaderinc"

uniform float u_grid_step;			// Heightmap grid step it is indipendent from lod

// 	n.z *= -1.0; ???
vec4 pack_normal_local(vec3 n) {
	return vec4((0.5 * (n + 1.0)).xzy, 1.0);
}

float get_height_local(sampler2D tex, vec2 uv) {
	//return sample_heightmap(tex, uv);
	return get_height(tex, 1.0, uv);
}

void fragment() {
	//vec2 uv = UV;
	//vec2 ps = TEXTURE_PIXEL_SIZE;
	//float left = get_height_local(TEXTURE, uv + vec2(-ps.x, 0));
	//float right = get_height_local(TEXTURE, uv + vec2(ps.x, 0));
	//float back = get_height_local(TEXTURE, uv + vec2(0, -ps.y));
	//float fore = get_height_local(TEXTURE, uv + vec2(0, ps.y));
	//vec3 n = normalize(vec3(left - right, 2.0, fore - back));
	//COLOR = pack_normal_local(n, 1.0);
	//// DEBUG
	////COLOR.r = fract(TIME * 100.0);
}

