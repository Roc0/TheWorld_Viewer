
vec3 unpack_normal(vec4 rgba) {
	// If we consider texture space starts from top-left corner and Y goes down,
	// then Y+ in pixel space corresponds to Z+ in terrain space,
	// while X+ also corresponds to X+ in terrain space.
	vec3 n = rgba.xzy * 2.0 - vec3(1.0);
	// Had to negate Z because it comes from Y in the normal map,
	// and OpenGL-style normal maps are Y-up.
	n.z *= -1.0;
	return n;
}

vec4 pack_normal(vec3 n, float a) {
	n.z *= -1.0;
	return vec4((n.xzy + vec3(1.0)) * 0.5, a);
}

float get_height(sampler2D tex, float terrain_height, vec2 uv){
	return texture(tex, uv).r * terrain_height;
}

vec3 get_normal(sampler2D tex, mat3 terrain_normal_basis, vec2 uv){
	// Need to use terrain_normal_basis to handle scaling.
	vec3 n = terrain_normal_basis * unpack_normal(texture(tex, uv));
	return normalize(n);
}
