shader_type spatial;
//render_mode  skip_vertex_transform;		// Fireflies along seams fix: https://github.com/Zylann/godot_heightmap_plugin/issues/312 (https://github.com/godotengine/godot/issues/35067)
											// https://github.com/godotengine/godot/issues/35067#issuecomment-1058617216

// Development shader used to debug or help authoring.

#include "res://addons/twviewer/shaders/include/CommonFunctions.gdshaderinc"

uniform float u_lod;

uniform sampler2D u_terrain_heightmap;
uniform sampler2D u_terrain_normalmap;
uniform mat4 u_terrain_inverse_transform;
uniform mat3 u_terrain_normal_basis;
uniform float u_grid_step;			// Heightmap grid step it is indipendent from lod
uniform float u_editmode_selected = 0.0;
uniform float u_num_vertices_per_chunk;		// it is the number of squares of a chunk we get the real number of vertices adding 1
uniform float u_lod_grid_step;		// real distance from each point of the chunk at the current lod
uniform float u_lod_chunk_size;				// chunk size at the current lod
uniform float u_terrain_height = 1.0;	// NOTSET
uniform float u_quad_border_line_thickness = 0.005;	// NOTSET
uniform float u_chunk_border_line_thickness = 0.002;	// NOTSET

void vertex() {
	vec4 vertex_world_pos = MODEL_MATRIX * vec4(VERTEX, 1);
	vec2 cell_coords = (u_terrain_inverse_transform * vertex_world_pos).xz;
	cell_coords /= vec2(u_grid_step);		// WARNING
	// Must add a half-offset so that we sample the center of pixels,
	// otherwise bilinear filtering of the textures will give us mixed results (#183)
	cell_coords += vec2(0.5);
	UV = cell_coords / vec2(textureSize(u_terrain_heightmap, 0));	// Normalized UV (linear interpolation expressing a value from 0 to 1)
		
	UV2 = VERTEX.xz / vec2(u_lod_chunk_size);						// Normalized UV2 (linear interpolation from VERTEX position in he chunk and the chunk size wwexpressing a value from 0 to 1)

	// Height displacement
	//float h = texture(u_terrain_heightmap, UV).r;
	float h = get_height(u_terrain_heightmap, u_terrain_height, UV);
	VERTEX.y = h;
	NORMAL = get_normal(u_terrain_normalmap, u_terrain_normal_basis, UV);
}

bool is_on_the_border_of_the_chunk(vec2 uv, float line_thickness){
	//float line_thickness = 0.01;
	if (uv.x > line_thickness && uv.x < (1.0 - line_thickness) && uv.y > line_thickness && uv.y < (1.0 - line_thickness)) {
		return false;
	} else {
		return true;
	}
}

void fragment() {
	vec3 normal = get_normal(u_terrain_normalmap, u_terrain_normal_basis, UV);
	
	if (u_editmode_selected > 0.0 && is_on_the_border(UV, u_quad_border_line_thickness)) {
		ALBEDO = vec3(1.0, 0.749, 0.0);		// GDN_TheWorld_Globals::g_color_yellow_apricot
	} else {
		if (is_on_the_border(UV, u_chunk_border_line_thickness) || is_on_the_border(UV2, u_chunk_border_line_thickness)) {
			ALBEDO = vec3(1.0, 1.0, 1.0);		// GDN_TheWorld_Globals::g_color_white
		} else {
			if (u_lod == 0.0) {
				ALBEDO = vec3(1.0, 0.749, 0.0);		// GDN_TheWorld_Globals::g_color_yellow_apricot
			} else {
				if (u_lod == 1.0) {
					ALBEDO = vec3(0.498, 1.0, 0.831);		// GDN_TheWorld_Globals::g_color_aquamarine_green
				} else {
					if (u_lod == 2.0) {
						ALBEDO = vec3(0.0, 1.0, 0.0);		// GDN_TheWorld_Globals::g_color_green
					} else {
						if (u_lod == 3.0) {
							ALBEDO = vec3(0.0, 1.0, 1.0);		// GDN_TheWorld_Globals::g_color_cyan
						} else {
							if (u_lod == 4.0) {
								//ALBEDO = vec3(1.0, 0.753, 0.796);		// GDN_TheWorld_Globals::g_color_pink
								ALBEDO = vec3(0.870, 0.192, 0.388);		// GDN_TheWorld_Globals::g_color_pink_cerise
							} else {
								if (u_lod == 5.0) {
									ALBEDO = vec3(0.0, 0.0, 1.0);		// GDN_TheWorld_Globals::g_color_blue
								} else {	// u_lod == 6.0 and greater
									ALBEDO = vec3(1.0, 0.0, 0.0);		// GDN_TheWorld_Globals::g_color_red
								}
							}
						}
					}
				}
			}
		}
	}

	//ALBEDO = v_color;
	//ALBEDO = vec3(1.0, 0.0, 0.0); // DEBUG: use red for material albedo
	ROUGHNESS = 0.5;
	NORMAL = (VIEW_MATRIX * (vec4(normal, 0.0))).xyz;
}
