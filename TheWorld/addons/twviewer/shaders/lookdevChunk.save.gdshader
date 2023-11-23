shader_type spatial;
//render_mode  skip_vertex_transform;		// Fireflies along seams fix: https://github.com/Zylann/godot_heightmap_plugin/issues/312 (https://github.com/godotengine/godot/issues/35067)
											// https://github.com/godotengine/godot/issues/35067#issuecomment-1058617216

// Development shader used to debug or help authoring.

#include "res://addons/twviewer/shaders/include/CommonFunctions.gdshaderinc"

uniform sampler2D u_terrain_heightmap;
uniform sampler2D u_terrain_normalmap;
//uniform sampler2D u_terrain_colormap;						// TODORIC
uniform sampler2D u_map; // This map will control color of fragments
uniform mat4 u_terrain_inverse_transform;
uniform mat3 u_terrain_normal_basis;
uniform float u_grid_step;		// Heightmap grid step it is indipendent from lod
uniform float u_editmode_selected = 0.0;
uniform vec2 u_mouse_hit = vec2(-1);
uniform float u_mouse_hit_radius = 0.01;
uniform float u_terrain_height = 1.0;	// NOTSET
uniform float u_quad_border_line_thickness = 0.005;	// NOTSET

void vertex() {
	vec4 wpos = MODEL_MATRIX * vec4(VERTEX, 1);
	vec2 cell_coords = (u_terrain_inverse_transform * wpos).xz;
	cell_coords /= vec2(u_grid_step);		// WARNING
	cell_coords += vec2(0.5);		// Must add a half-offset so that we sample the center of pixels, otherwise bilinear filtering of the textures will give us mixed results (#183)
	
	UV = cell_coords / vec2(textureSize(u_terrain_heightmap, 0));	// Normalized UV (linear interpolation expressing a value from 0 to 1)

	float h = get_height(u_terrain_heightmap, u_terrain_height, UV);	// Height displacement
	VERTEX.y = h;

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
	
	//ALBEDO = vec3(0.0, 1.0, 0.0);

	//ALBEDO = v_color;
	//ALBEDO = vec3(1.0, 0.0, 0.0); // DEBUG: use red for material albedo
	ROUGHNESS = 0.5;
	NORMAL = (VIEW_MATRIX * (vec4(normal, 0.0))).xyz;
}
