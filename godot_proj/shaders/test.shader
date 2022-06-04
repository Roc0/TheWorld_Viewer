shader_type spatial;

// Development shader used to debug or help authoring.

uniform sampler2D u_terrain_heightmap;
uniform sampler2D u_terrain_normalmap;
uniform sampler2D u_terrain_colormap;
uniform sampler2D u_map; // This map will control color
uniform mat4 u_terrain_inverse_transform;
uniform mat3 u_terrain_normal_basis;

varying float v_hole;


vec3 unpack_normal(vec4 rgba) {
	return rgba.xzy * 2.0 - vec3(1.0);
}

void vertex() {
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
	
	vec4 value = texture(u_map, UV);
	// TODO Blend toward checker pattern to show the alpha channel
	
	ALBEDO = value.rgb;
	ROUGHNESS = 0.5;
	NORMAL = (INV_CAMERA_MATRIX * (vec4(normal, 0.0))).xyz;
}
