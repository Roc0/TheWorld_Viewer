shader_type spatial;
render_mode blend_mix, cull_back;

global uniform sampler2D gu_sea_texture_normal;
global uniform sampler2D gu_sea_texture_normal2;

uniform float u_terrain_height = 1.0;	// NOTSET
uniform sampler2D u_terrain_heightmap;
uniform uint u_optimization_level = 0;
uniform float u_grid_step = 2.0;
uniform mat4 u_terrain_inverse_transform;
uniform float u_quadrant_size = 4096.0;

uniform vec3 u_sea_color : source_color = vec3(0.10, 0.19, 0.32);	// vec3(0.0, 0.03, 0.34);		// vec3(0.0, 0.19, 0.46);		// vec3(0.0, 0.32, 0.43);
uniform vec3 u_sea_color2 : source_color = vec3(0.25, 0.32, 0.43);	// vec3(0.25, 0.32, 0.43);	// vec3(1.0, 1.0, 1.0);
uniform float u_metallic : hint_range(0.0, 1.0) = 0.8;
uniform float u_roughness : hint_range(0.0, 1.0) = 0.02;
uniform vec2 u_wave_direction = vec2(2.0,0.0); // Direction of wave 1
uniform vec2 u_wave_direction2 = vec2(0.0,1.0); // Direction of wave 2
uniform float u_time_scale : hint_range(0.0, 0.2, 0.0005) = 0.0005; // *** Rate of movement multiplied by TIME
uniform float u_rough_sea_factor : hint_range(0.0, 20.0, 1.0) = 10.0;	// ***

// Varying variables
varying vec3 v_world_pos;

#include "res://addons/twviewer/shaders/include/CommonFunctions.gdshaderinc"

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

void vertex() {
	// VERTEX coords are local to the chunk (as the material is applied to the mesh which is tied to the chunk) so they start from the beginning of the chunk: we need
	// to trasform them in world coord to abstract from chunk
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// SETTING UV (mapping of the VERTEX in current quadrant)
	//vec4 vertex_world_pos = MODEL_MATRIX * vec4(VERTEX, 1);
	vec4 vertex_world_pos = vec4(v_world_pos, 1.0);
	// to calculate coords of the vertex local to the quadrant we use affine inverse matrix of the global trasform of the quadtree
	vec4 vertex_local_to_quadrant_pos = u_terrain_inverse_transform * vertex_world_pos;
	UV = vertex_local_to_quadrant_pos.xz / vec2(u_quadrant_size);		// mapping of vertex_local_to_quadrant_pos in current quadrant from 0.0 (start of the quadrant) to 1.0 (end of the quadrant)

	vec2 vertex_cell_coords_in_textures = vertex_local_to_quadrant_pos.xz / vec2(u_grid_step * pow(2.0, float(u_optimization_level)));
	vertex_cell_coords_in_textures += vec2(0.5);	// IMPORTANT: now vertex_cell_coords_in_textures ranges from 0.5
													// to (heightmap size - 1) + 0.5 with increment of 1.0 between each coord

	vec2 terrain_uv = vertex_cell_coords_in_textures / vec2(textureSize(u_terrain_heightmap, 0));
	float terrain_vertex_height = get_height(u_terrain_heightmap, u_terrain_height, terrain_uv);		// Height displacement from heigthmap

	float sea_vertex_height = VERTEX.y;
	if (terrain_vertex_height > sea_vertex_height) {
		sea_vertex_height += -1.0;
		//sea_vertex_height += 1.0;
	} else {
		sea_vertex_height += 1.0;
	}
	VERTEX.y += sea_vertex_height;

	//if (VERTEX.y == 0.0)
	//	VERTEX.y = 0.0;
	//VERTEX.y = -1.0;

	// terrain_vertex_height == 1.0
	//if (terrain_vertex_height > 0.0)
	//	VERTEX.y = -1.0;
}

void fragment() {
	float metallic = u_metallic;
	float roughness = u_roughness;
	float alpha = 1.0;

	// Time calculations for wave (normal map) movement
	//float time_scale_factor = clamp(abs(CAMERA_POSITION_WORLD.y), 0.0, u_max_altitude_for_time_scale_factor) / u_max_altitude_for_time_scale_factor;	// normalized 0 on the surface to 1 at max_altitude_for_time_scale_factor
	float time_scale_factor = 0.00;
	time_scale_factor = (time_scale_factor * 4.0) + 1.0;	// normalized 1 on the surface to 5 at max_altitude_for_time_scale_factor
	vec2 time = (TIME * u_wave_direction) * u_time_scale * time_scale_factor * (u_rough_sea_factor / 6.0) /*/ 0.5*/; // Movement rate of first wave
	vec2 time2 = (TIME * u_wave_direction2) * u_time_scale * time_scale_factor * (u_rough_sea_factor / 6.0) /*/ 0.5*/; // Movement rate of second wave

	// Blend normal maps into one
	vec3 normal_blend = mix(texture(gu_sea_texture_normal, (UV + time) * 10.0 ).rgb, texture(gu_sea_texture_normal2, (UV + time2) * 10.0).rgb, 0.5);

	vec3 surface_color = u_sea_color;

	// Calculate Fresnel
	{
		float fresnel = fresnel(1.0, NORMAL, VIEW);
		surface_color = mix(u_sea_color, u_sea_color2, fresnel / 5.0); // Interpolate albedo values by frensel
	}

	ALBEDO = surface_color;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal_blend;
	ALPHA = alpha;
}