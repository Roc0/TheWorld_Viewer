shader_type spatial;
render_mode unshaded, shadows_disabled;
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

uniform int u_scale_change_num_steps = 1;
uniform float u_piece_size = 200.0;
uniform int u_piecing_threshold = 3;

varying float v_distance_from_camera;

int greater(int v1, int v2)
{
	if (v1 > v2)
	{
		return v1;
	}
	else
	{
		return v2;
	}
}

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
		vertex_world_pos.y = 0.0;
	} else {
		VERTEX.y = h;
		vertex_world_pos.y = h;
	}

	NORMAL = get_normal(u_terrain_normalmap, u_terrain_normal_basis, UV);	// Need to use u_terrain_normal_basis to handle scaling.
	
	v_distance_from_camera = distance(vertex_world_pos.xyz, INV_VIEW_MATRIX[3].xyz);
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
	
	// DEBUG pieces near cam at higher resolution
	//if (/*v_distance_from_camera_y < 50.0 &&*/ v_distance_from_camera < (u_piece_size * float(u_piecing_threshold)))
	//{
	//	vec3 fragment_world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	//	int camera_piece_x = int(floor(CAMERA_POSITION_WORLD.x / u_piece_size));
	//	int camera_piece_y = int(floor(CAMERA_POSITION_WORLD.z / u_piece_size));
	//	int frag_piece_x = int(floor(fragment_world_pos.x / u_piece_size));
	//	int frag_piece_y = int(floor(fragment_world_pos.z / u_piece_size));
	//	int pieces_from_camera_piece = greater(int(abs(camera_piece_x - frag_piece_x)), int(abs(camera_piece_y - frag_piece_y)));
	//	if (pieces_from_camera_piece == 0)
	//	{
	//		ALBEDO = vec3(1.0, 0.0, 0.0);
	//	}
	//	if (pieces_from_camera_piece == 1)
	//	{
	//		ALBEDO = vec3(0.0, 1.0, 0.0);
	//	}
	//	if (pieces_from_camera_piece == 2)
	//	{
	//		ALBEDO = vec3(0.0, 0.0, 1.0);
	//	}
	//}
	// DEBUG pieces near cam at higher resolution

	// DEBUG
	//ALBEDO = vec3(fragment_world_pos.x / 100000.0, fragment_world_pos.y / 1000.0, fragment_world_pos.z / 100000.0);
	//ALBEDO = CAMERA_POSITION_WORLD / 10000;
	//ALBEDO = v_camera_pos / 1000;
	//ALBEDO = vec3(v_distance_from_camera / 1000.0, 0.0, 0.0);
	//ALBEDO = vec3(UV.x, UV.y, 1.0);	// DEBUG: check uv
	//ALBEDO = vec3(1.0, 0.0, 0.0); 	// DEBUG: use red for material albedo
	// DEBUG
	
	//ROUGHNESS = 0.5;
	NORMAL = (VIEW_MATRIX * (vec4(normal, 0.0))).xyz;
}
