shader_type spatial;
render_mode  skip_vertex_transform;		// Fireflies along seams fix: https://github.com/Zylann/godot_heightmap_plugin/issues/312 (https://github.com/godotengine/godot/issues/35067)

// Development shader used to debug or help authoring.

uniform sampler2D u_terrain_heightmap;
uniform sampler2D u_terrain_normalmap;
uniform sampler2D u_terrain_colormap;
//uniform sampler2D u_map; // This map will control color
uniform mat4 u_terrain_inverse_transform;
uniform mat3 u_terrain_normal_basis;
uniform float u_grid_step_in_wu;

varying float v_hole;
varying vec3 v_color;

vec3 unpack_normal(vec4 rgba) {
	return rgba.xzy * 2.0 - vec3(1.0);
}

void vertex() {
	vec4 wpos = WORLD_MATRIX * vec4(VERTEX, 1);
	vec2 cell_coords = (u_terrain_inverse_transform * wpos).xz;
	
	cell_coords /= vec2(u_grid_step_in_wu);		// WARNING
	
	// Must add a half-offset so that we sample the center of pixels,
	// otherwise bilinear filtering of the textures will give us mixed results (#183)
	//cell_coords += vec2(0.5);

	// Normalized UV (linear interpolation expressing a value from 0 to 1)
	UV = cell_coords / vec2(textureSize(u_terrain_heightmap, 0));

	// Height displacement
	float h = texture(u_terrain_heightmap, UV).r;
	VERTEX.y = h;
	wpos.y = h;

	// Putting this in vertex saves 2 fetches from the fragment shader,
	// which is good for performance at a negligible quality cost,
	// provided that geometry is a regular grid that decimates with LOD.
	// (downside is LOD will also decimate tint and splat, but it's not bad overall)
	vec4 tint = texture(u_terrain_colormap, UV);
	v_hole = tint.a;
	v_color = tint.rgb;

	// Need to use u_terrain_normal_basis to handle scaling.
	// For some reason I also had to invert Z when sampling terrain normals... not sure why
	NORMAL = u_terrain_normal_basis 
		* (unpack_normal(texture(u_terrain_normalmap, UV)) * vec3(1, 1, -1));
		
	VERTEX = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;		// Fireflies along seams fix: https://github.com/Zylann/godot_heightmap_plugin/issues/312 (https://github.com/godotengine/godot/issues/35067)
	VERTEX = (INV_CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;	// Fireflies along seams fix: https://github.com/Zylann/godot_heightmap_plugin/issues/312 (https://github.com/godotengine/godot/issues/35067)
}

void fragment() {
	if (v_hole < 0.5) {
		// TODO Add option to use vertex discarding instead, using NaNs
		discard;
	}

	vec3 terrain_normal_world = 
		u_terrain_normal_basis * (unpack_normal(texture(u_terrain_normalmap, UV)) * vec3(1,1,-1));
	terrain_normal_world = normalize(terrain_normal_world);
	vec3 normal = terrain_normal_world;
	
	//vec4 value = texture(u_map, UV);
	// TODO Blend toward checker pattern to show the alpha channel
	//ALBEDO = value.rgb;
	
	ALBEDO = v_color;
	//ALBEDO = vec3(1.0, 0.0, 0.0); // DEBUG: use red for material albedo
	ROUGHNESS = 0.5;
	NORMAL = (INV_CAMERA_MATRIX * (vec4(normal, 0.0))).xyz;
}
