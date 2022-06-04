shader_type spatial;

// Development shader used to debug or help authoring.

uniform sampler2D u_terrain_heightmap;
uniform sampler2D u_terrain_normalmap;
uniform sampler2D u_terrain_colormap;
uniform sampler2D u_map; // This map will control color
uniform mat4 u_terrain_inverse_transform;
uniform mat3 u_terrain_normal_basis;

varying float v_hole;

void vertex() {
	VERTEX.y += cos(VERTEX.x * 4.0) * sin(VERTEX.z * 4.0);
}
