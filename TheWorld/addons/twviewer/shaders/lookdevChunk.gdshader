shader_type spatial;
//render_mode  skip_vertex_transform;		// Fireflies along seams fix: https://github.com/Zylann/godot_heightmap_plugin/issues/312 (https://github.com/godotengine/godot/issues/35067)
											// https://github.com/godotengine/godot/issues/35067#issuecomment-1058617216

// Development shader used to debug or help authoring.

#include "res://addons/twviewer/shaders/include/CommonFunctions.gdshaderinc"

uniform sampler2D u_terrain_heightmap;
uniform sampler2D u_terrain_normalmap;
uniform sampler2D u_terrain_colormap;						// TODORIC
uniform sampler2D u_map; // This map will control color of fragments
uniform mat4 u_terrain_inverse_transform;
uniform mat3 u_terrain_normal_basis;
uniform float u_grid_step;		// Heightmap grid step it is indipendent from lod
uniform float u_editmode_selected = 0.0;
uniform vec2 u_mouse_hit = vec2(-1);
uniform float u_mouse_hit_radius = 0.01;
uniform float u_terrain_height = 1.0;	// NOTSET
uniform float u_quad_border_line_thickness = 0.005;	// NOTSET
//uniform float u_vertex_scale = 1.0;

//varying float v_hole;
//varying vec3 v_color;

//vec3 unpack_normal(vec4 rgba) {
//	//return rgba.xzy * 2.0 - vec3(1.0);
//	// If we consider texture space starts from top-left corner and Y goes down,
//	// then Y+ in pixel space corresponds to Z+ in terrain space,
//	// while X+ also corresponds to X+ in terrain space.
//	vec3 n = rgba.xzy * 2.0 - vec3(1.0);
//	// Had to negate Z because it comes from Y in the normal map,
//	// and OpenGL-style normal maps are Y-up.
//	n.z *= -1.0;
//	return n;
//}

//vec4 pack_normal(vec3 n, float a) {
//	n.z *= -1.0;
//	return vec4((n.xzy + vec3(1.0)) * 0.5, a);
//}

//float get_height(sampler2D tex, vec2 uv){
//	return texture(tex, uv).r * u_terrain_height;
//}

//vec3 get_normal(sampler2D tex, mat3 terrain_normal_basis, vec2 uv){
//	// Need to use terrain_normal_basis to handle scaling.
//	vec3 n = terrain_normal_basis * unpack_normal(texture(tex, uv));
//	return normalize(n);
//}

void vertex() {
	vec4 wpos = MODEL_MATRIX * vec4(VERTEX, 1);
	vec2 cell_coords = (u_terrain_inverse_transform * wpos).xz;
	cell_coords /= vec2(u_grid_step);		// WARNING
	// Must add a half-offset so that we sample the center of pixels,
	// otherwise bilinear filtering of the textures will give us mixed results (#183)
	cell_coords += vec2(0.5);
	// Normalized UV (linear interpolation expressing a value from 0 to 1)
	UV = cell_coords / vec2(textureSize(u_terrain_heightmap, 0));

	// Height displacement
	//float h = texture(u_terrain_heightmap, UV).r;
	float h = get_height(u_terrain_heightmap, u_terrain_height, UV);
	VERTEX.y = h;
	//wpos.y = h;

	// Putting this in vertex saves 2 fetches from the fragment shader,
	// which is good for performance at a negligible quality cost,
	// provided that geometry is a regular grid that decimates with LOD.
	// (downside is LOD will also decimate tint and splat, but it's not bad overall)
	//vec4 tint = texture(u_terrain_colormap, UV);
	//v_hole = tint.a;
	//v_color = tint.rgb;

	// Need to use u_terrain_normal_basis to handle scaling.
	// For some reason I also had to invert Z when sampling terrain normals... not sure why
	//NORMAL = u_terrain_normal_basis * unpack_normal(texture(u_terrain_normalmap, UV));
	NORMAL = get_normal(u_terrain_normalmap, u_terrain_normal_basis, UV);
	
	//VERTEX *= u_vertex_scale;
	
	//VERTEX = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;		// Fireflies along seams fix: https://github.com/Zylann/godot_heightmap_plugin/issues/312 (https://github.com/godotengine/godot/issues/35067)
	//VERTEX = (INV_CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;	// Fireflies along seams fix: https://github.com/Zylann/godot_heightmap_plugin/issues/312 (https://github.com/godotengine/godot/issues/35067)
	////VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;				// Fireflies along seams fix: alternative to two up lines
	//NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);	// Fireflies along seams fix:
}

void fragment() {
	//if (v_hole < 0.5) {
	//	// TODO Add option to use vertex discarding instead, using NaNs
	//	discard;
	//}

	vec3 normal = get_normal(u_terrain_normalmap, u_terrain_normal_basis, UV);
	
	vec4 value = texture(u_map, UV);
	// TODO Blend toward checker pattern to show the alpha channel
	
	if (u_editmode_selected > 0.0 && is_on_the_border(UV, u_quad_border_line_thickness)) {
		ALBEDO = vec3(1.0, 0.749, 0.0);		// GDN_TheWorld_Globals::g_color_yellow_apricot
	} else {
		if (u_mouse_hit != vec2(-1) && distance(u_mouse_hit, UV) < u_mouse_hit_radius) {
			ALBEDO = vec3(1.0, 0.749, 0.0);		// GDN_TheWorld_Globals::g_color_yellow_apricot
		} else {
			ALBEDO = value.rgb;
		}
	}

	//ALBEDO = v_color;
	//ALBEDO = vec3(1.0, 0.0, 0.0); // DEBUG: use red for material albedo
	ROUGHNESS = 0.5;
	NORMAL = (VIEW_MATRIX * (vec4(normal, 0.0))).xyz;
}
