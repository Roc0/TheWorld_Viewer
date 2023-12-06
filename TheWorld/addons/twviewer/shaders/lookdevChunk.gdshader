shader_type spatial;
//render_mode  skip_vertex_transform;		// Fireflies along seams fix: https://github.com/Zylann/godot_heightmap_plugin/issues/312 (https://github.com/godotengine/godot/issues/35067)
											// https://github.com/godotengine/godot/issues/35067#issuecomment-1058617216

// Development shader used to debug or help authoring.

#include "res://addons/twviewer/shaders/include/CommonFunctions.gdshaderinc"

uniform sampler2D u_terrain_heightmap;
uniform sampler2D u_terrain_normalmap;
uniform sampler2D u_map; // This map will control color of fragments
uniform mat4 u_terrain_inverse_transform;
uniform mat3 u_terrain_normal_basis;
uniform float u_grid_step;		// Heightmap grid step it is indipendent from lod
uniform float u_editmode_selected = 0.0;
uniform vec2 u_mouse_hit = vec2(-1);
uniform float u_mouse_hit_radius = 0.01;
uniform float u_terrain_height = 1.0;	// NOTSET
uniform float u_quad_border_line_thickness = 0.005;	// NOTSET
uniform bool u_force_height_0 = false;
uniform uint u_optimization_level = 0;

void vertex() {
	vec4 vertex_world_pos = MODEL_MATRIX * vec4(VERTEX, 1);		// VERTEX coords are local to the chunk (as the material is applied to the mesh which is tied to the chunk) so they start from the beginning of the chunk: we need to trasform in world coord to abstract from chunk
	vec4 vertex_local_to_quadrant_pos = u_terrain_inverse_transform * vertex_world_pos;	// to calculate coords of the vertex local to the quadrant we use affine inverse matrix of the global trasform of the quadtree
	vec2 vertex_cell_coords_in_textures = vertex_local_to_quadrant_pos.xz / vec2(u_grid_step * pow(2.0, float(u_optimization_level)));	// to get correct value from the textures (in the range 0 / max size in local coord) we need to consider the step (dividing by it): in the textures heigths/normals are adjacent but in global/local coords are separated by the step
	vertex_cell_coords_in_textures += vec2(0.5);		// Moreover must add a half-offset so that we sample the center of pixels, otherwise bilinear filtering of the textures will give us mixed results (#183)
	UV = vertex_cell_coords_in_textures / vec2(textureSize(u_terrain_heightmap, 0));	// Normalized UV to be in the range 0/1
	
	//vec2 uv = (VERTEX.xz / vec2(u_grid_step)) / vec2(textureSize(u_terrain_heightmap, 0));							// DEBUG: check uv
	//vec2 uv = (vertex_local_to_quadrant_pos.xz / vec2(u_grid_step)) / vec2(textureSize(u_terrain_heightmap, 0));		// DEBUG: check uv
	//vec2 uv = (vertex_local_to_quadrant_pos.xz / vec2(u_grid_step)) / vec2(textureSize(u_terrain_heightmap, 0));		// DEBUG: check uv
	//UV = uv;																											// DEBUG: check uv

	float h = get_height(u_terrain_heightmap, u_terrain_height, UV);	// Height displacement
	if (u_force_height_0) {
		VERTEX.y = 0.0;
	} else {
		VERTEX.y = h;
	}

	NORMAL = get_normal(u_terrain_normalmap, u_terrain_normal_basis, UV);	// Need to use u_terrain_normal_basis to handle scaling.
}

void fragment() {
	vec3 normal = get_normal(u_terrain_normalmap, u_terrain_normal_basis, UV);
	vec4 value = texture(u_map, UV);
	
	if (u_editmode_selected > 0.0 && is_on_the_border(UV, u_quad_border_line_thickness)) {
		ALBEDO = vec3(1.0, 0.749, 0.0);		// GDN_TheWorld_Globals::g_color_yellow_apricot
	} else {
		if (u_mouse_hit != vec2(-1) && distance(u_mouse_hit, UV) < u_mouse_hit_radius) {
			ALBEDO = vec3(1.0, 0.749, 0.0);		// GDN_TheWorld_Globals::g_color_yellow_apricot
		} else {
			ALBEDO = value.rgb;
		}
	}
	
	//ALBEDO = vec3(UV.x, UV.y, 1.0);	// DEBUG: check uv
	//ALBEDO = vec3(1.0, 0.0, 0.0); 	// DEBUG: use red for material albedo
	
	//ROUGHNESS = 0.5;
	NORMAL = (VIEW_MATRIX * (vec4(normal, 0.0))).xyz;
}
