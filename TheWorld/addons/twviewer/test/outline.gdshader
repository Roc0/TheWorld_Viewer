shader_type spatial;
render_mode unshaded;

uniform sampler2D screen_texture : source_color, hint_screen_texture, filter_nearest;
uniform sampler2D depth_texture : source_color, hint_depth_texture, filter_nearest;
uniform sampler2D normal_texture : source_color, hint_normal_roughness_texture, filter_nearest;

uniform float depth_threshold : hint_range(0, 1) = 0.05;
uniform float reverse_depth_threshold : hint_range(0, 1) = 0.25;
uniform float normal_threshold : hint_range(0, 1) = 0.6;

uniform float darken_amount : hint_range(0, 1, 0.01) = 0.3;
uniform float lighten_amount : hint_range(0, 10, 0.01) = 1.5;

uniform vec3 normal_edge_bias = vec3(1, 1, 1);
uniform vec3 light_direction = vec3(-0.96, -0.18, 0.2);

// this shader must be attached to a QuadMesh (2m x 2m without subdivide)
// set to a MeshInstance3D child of the camera

float get_depth(vec2 screen_uv, mat4 inv_projection_matrix) {
	float depth = texture(depth_texture, screen_uv).r;	// The values returned by depth_texture are between 0.0 (near camera) and 1.0 and are nonlinear.
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, depth);		// Transform screen coordinates in NDC (normalized device coordinates). NDC run -1.0 to 1.0 in x and y directions and from 0.0 to 1.0 in the z direction when using the Vulkan backend.
	vec4 view = inv_projection_matrix * vec4(ndc, 1.0);	// Convert NDC to view space and linearize it by multiplying the NDC by INV_PROJECTION_MATRIX.
	view.xyz /= view.w;									// Normalize quaternion
	return -view.z;										// Because the camera is facing the negative z direction, the position will have a negative z value. In order to get a usable depth value, we have to negate view.z
}

void vertex() {
	POSITION = vec4(VERTEX, 1.0);						// Setting POSITION we tell godot to use coord as is and avoid automatic transformation to clip space before passing to the GPU. VERTEX coord are in local space.
}

void fragment() {
	float depth = get_depth(SCREEN_UV, INV_PROJECTION_MATRIX);			// depth now run from 0 (near camera) and 1 (far away) and is linearized.
	vec3 normal = texture(normal_texture, SCREEN_UV).xyz * 2.0 - 1.0;	// normal_texture contains values which run from 0 to 1, forcing them to run from -1 to 1
	vec2 texel_size = 1.0 / VIEWPORT_SIZE.xy;

	vec2 uvs[4];
	uvs[0] = vec2(SCREEN_UV.x, min(1.0 - 0.001, SCREEN_UV.y + texel_size.y));
	uvs[1] = vec2(SCREEN_UV.x, max(0.0, SCREEN_UV.y - texel_size.y));
	uvs[2] = vec2(min(1.0 - 0.001, SCREEN_UV.x + texel_size.x), SCREEN_UV.y);
	uvs[3] = vec2(max(0.0, SCREEN_UV.x - texel_size.x), SCREEN_UV.y);

	float depth_diff = 0.0;
	float depth_diff_reversed = 0.0;
	float nearest_depth = depth;
	vec2 nearest_uv = SCREEN_UV;

	float normal_sum = 0.0;
	for (int i = 0; i < 4; i++) {
		float d = get_depth(uvs[i], INV_PROJECTION_MATRIX);
		depth_diff += depth - d;
		depth_diff_reversed += d - depth;

		if (d < nearest_depth) {
			nearest_depth = d;
			nearest_uv = uvs[i];
		}

		vec3 n = texture(normal_texture, uvs[i]).xyz * 2.0 - 1.0;
		vec3 normal_diff = normal - n;

		// Edge pixels should yield to the normal closest to the bias direction
		float normal_bias_diff = dot(normal_diff, normal_edge_bias);
		float normal_indicator = smoothstep(-0.01, 0.01, normal_bias_diff);

		normal_sum += dot(normal_diff, normal_diff) * normal_indicator;
	}
	float depth_edge = step(depth_threshold, depth_diff);

	// The reverse depth sum produces depth lines inside of the object, but they don't look as nice as the normal depth_diff
	// Instead, we can use this value to mask the normal edge along the outside of the object
	float reverse_depth_edge = step(reverse_depth_threshold, depth_diff_reversed);

	float indicator = sqrt(normal_sum);
	float normal_edge = step(normal_threshold, indicator - reverse_depth_edge);

	vec3 original = texture(screen_texture, SCREEN_UV).rgb;
	vec3 nearest = texture(screen_texture, nearest_uv).rgb;

	mat3 view_to_world_normal_mat = mat3(
            INV_VIEW_MATRIX[0].xyz,
            INV_VIEW_MATRIX[1].xyz,
            INV_VIEW_MATRIX[2].xyz
	);
	float ld = dot((view_to_world_normal_mat * normal), normalize(light_direction));

	vec3 depth_col = nearest * darken_amount;
	vec3 normal_col = original * (ld > 0.0 ? darken_amount : lighten_amount);
	vec3 edge_mix = mix(normal_col, depth_col, depth_edge);

	ALBEDO = mix(original, edge_mix, (depth_edge > 0.0 ? depth_edge : normal_edge));
}