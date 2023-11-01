
vec3 unpack_normal(vec4 rgba) {
	// If we consider texture space starts from top-left corner and Y goes down,
	// then Y+ in pixel space corresponds to Z+ in terrain space,
	// while X+ also corresponds to X+ in terrain space.
	vec3 n = rgba.xzy * 2.0 - vec3(1.0);
	// Had to negate Z because it comes from Y in the normal map,
	// and OpenGL-style normal maps are Y-up.
	//n.z *= -1.0;
	return n;
}

vec4 pack_normal(vec3 n, float a) {
	//n.z *= -1.0;
	return vec4((n.xzy + vec3(1.0)) * 0.5, a);
}

float get_height(sampler2D tex, float terrain_height, vec2 uv){
	return texture(tex, uv).r * terrain_height;
}

vec3 get_normal(sampler2D tex, mat3 terrain_normal_basis, vec2 uv){
	// Need to use terrain_normal_basis to handle scaling.
	vec3 n = terrain_normal_basis * unpack_normal(texture(tex, uv));
	//vec3 n = unpack_normal(texture(tex, uv));
	return normalize(n);
}

vec3 get_normal_1(sampler2D tex, vec2 uv){
	return unpack_normal(texture(tex, uv));
}

bool is_on_the_border(vec2 uv, float line_thickness){
	//float line_thickness = 0.01;
	if (uv.x > line_thickness && uv.x < (1.0 - line_thickness) && uv.y > line_thickness && uv.y < (1.0 - line_thickness)) {
		return false;
	} else {
		return true;
	}
}

float lerp_f(float a, float b, float t) {
	return a + (t * (b - a));
}

vec4 encode_height_to_viewport(float h) {
	//return vec4(encode_height_to_rgb8_unorm(h), 1.0);

	// Encode regular floats into an assumed RGBA8 output color.
	// This is used because Godot 4.0 doesn't support RF viewports,
	// and the irony is, even if float viewports get supported, it's likely it will end up RGBAF,
	// which is wasting bandwidth because we are only interested in R...
	uint u = floatBitsToUint(h);
	return vec4(
		float((u >> 0u) & 255u),
		float((u >> 8u) & 255u),
		float((u >> 16u) & 255u),
		float((u >> 24u) & 255u)
	) / vec4(255.0);
}

float decode_height_from_viewport(vec4 c) {
	uint u = uint(c.r * 255.0) 
		| (uint(c.g * 255.0) << 8u) 
		| (uint(c.b * 255.0) << 16u) 
		| (uint(c.a * 255.0) << 24u);
	return uintBitsToFloat(u);
}
