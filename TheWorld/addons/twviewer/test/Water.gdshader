shader_type spatial;

global uniform bool gu_show_chunks = false;
uniform uint u_optimization_level = 0;
uniform float u_editmode_selected = 0;
uniform bool u_grid_on = false;
uniform float u_quad_border_line_thickness = 0.005;
uniform float u_mouse_hit_radius = 0.0010000000475;
uniform uint u_num_vertices_per_chunk;
uniform vec2 u_mouse_hit = vec2(-1.000000, -1.000000);
uniform mat4 u_terrain_inverse_transform;
uniform float u_grid_step = 2.0;
uniform float u_quadrant_size = 4096.0;

const vec3 lod_colors[10] = {
	vec3(1.0, 0.749, 0.0),		// GDN_TheWorld_Globals::g_color_yellow_apricot
	vec3(0.498, 1.0, 0.831),	// GDN_TheWorld_Globals::g_color_aquamarine_green
	vec3(0.0, 1.0, 0.0),		// GDN_TheWorld_Globals::g_color_green
	vec3(0.0, 1.0, 1.0),		// GDN_TheWorld_Globals::g_color_cyan
	vec3(0.980, 0.592, 0.447),	// GDN_TheWorld_Globals::g_color_red_salmon
	vec3(0.0, 0.0, 1.0),		// GDN_TheWorld_Globals::g_color_blue
	vec3(0.623, 0.168, 0.408),	// GDN_TheWorld_Globals::g_color_pink_amaranth
	vec3(0.561, 0.737, 0.561),	// GDN_TheWorld_Globals::g_color_darksea_green
	vec3(1.0, 0.0, 0.0),		// GDN_TheWorld_Globals::g_color_red
	vec3(0.0, 0.0, 0.0)		// GDN_TheWorld_Globals::g_color_black
};

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec3 albedo : source_color = vec3(0.0, 0.32, 0.43);
uniform vec3 albedo2 : source_color = vec3(1.0, 1.0, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0;
uniform float roughness : hint_range(0.0, 1.0) = 0.02;
global uniform sampler2D gu_sea_wave;
global uniform sampler2D gu_sea_texture_normal;
global uniform sampler2D gu_sea_texture_normal2;
//uniform sampler2D wave;
//uniform sampler2D texture_normal;
//uniform sampler2D texture_normal2;
uniform vec2 wave_direction = vec2(2.0,0.0); // Direction of wave 1
uniform vec2 wave_direction2 = vec2(0.0,1.0); // Direction of wave 2
uniform float time_scale : hint_range(0.0, 0.2, 0.005) = 0.005; // *** Rate of movement multiplied by TIME
uniform float noise_scale = 1000.0;		// ***
uniform float height_scale = 30.0;		// *** -15 / +15

uniform vec4 color_deep : source_color = vec4(0.10, 0.29, 0.32, 1.0); // Deep depth color
uniform vec4 color_shallow : source_color = vec4(0.0, 0.55, 0.65, 1.0); // Shallow depth color
uniform float beers_law = 2.0; // Beer's law application
uniform float depth_offset = -0.75; // Offset

uniform float edge_scale = 0.1;
uniform float near = 1.0;
uniform float far = 20000.0;
uniform vec3 edge_color : source_color = vec3(1.0, 1.0, 1.0);

// Varying variables
//varying float v_height;
varying vec3 v_world_pos;
varying float v_lod;

#include "res://addons/twviewer/shaders/include/CommonFunctions.gdshaderinc"

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

float edge(float depth){
	depth = 2.0 * depth - 1.0;
	return near * far / (far + depth * (near - far));
}

void vertex() {
	// VERTEX coords are local to the chunk (as the material is applied to the mesh which is tied to the chunk) so they start from the beginning of the chunk: we need
	// to trasform them in world coord to abstract from chunk
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float height = texture(gu_sea_wave, v_world_pos.xz / noise_scale + TIME * time_scale).r;
	//v_height = height;
	VERTEX.y += height * height_scale;

	//VERTEX.y = 0.0;		// DEBUG
	//VERTEX.y = 1000.0;	// DEBUG

	// SETTING UV (mapping of the VERTEX in current quadrant)
	//vec4 vertex_world_pos = MODEL_MATRIX * vec4(VERTEX, 1);
	vec4 vertex_world_pos = vec4(v_world_pos, 1.0);
	// to calculate coords of the vertex local to the quadrant we use affine inverse matrix of the global trasform of the quadtree
	vec4 vertex_local_to_quadrant_pos = u_terrain_inverse_transform * vertex_world_pos;
	UV = vertex_local_to_quadrant_pos.xz / vec2(u_quadrant_size);		// mapping of vertex_local_to_quadrant_pos in current quadrant from 0.0 (start of the quadrant) to 1.0 (end of the quadrant)

	float lod = -1.0;
	if (gu_show_chunks) {
		// SETTING UV2 (mapping of the VERTEX in current chunk) and lod of current chunk
		int vertex_col = int(floor(mod(float(VERTEX_ID), float(u_num_vertices_per_chunk))));		// vertex_col ranges from 0 to u_num_vertices_per_chunk - 1
		int vertex_row = int(floor(float(VERTEX_ID) / float(u_num_vertices_per_chunk)));			// vertex_row ranges from 0 to u_num_vertices_per_chunk - 1
		float step_between_vertices_in_current_mesh = -1.0;
		if ((vertex_col == 0 && vertex_row == 0) || (vertex_col == 0 && vertex_row == int(u_num_vertices_per_chunk - uint(1)))
			|| (vertex_col == int(u_num_vertices_per_chunk - uint(1)) && vertex_row == 0) || (vertex_col == int(u_num_vertices_per_chunk - uint(1)) && vertex_row == int(u_num_vertices_per_chunk - uint(1)))) {
		} else {
			// VERTEX coords are local to the chunk (as the material is applied to the mesh which is tied to the chunk) so they start from the beginning of the chunk
			if (vertex_col == 0) {	// vertex_row is > 0
				step_between_vertices_in_current_mesh = floor(VERTEX.z / float(vertex_row));	// in world units
			} else {
				step_between_vertices_in_current_mesh = floor(VERTEX.x / float(vertex_col));	// in world units
			}
		}
		if (abs(step_between_vertices_in_current_mesh + 1.0) < 0.0001) {
			UV2 = vec2(0.0, 0.0);
			lod = 99.0;
		} else {
			float chunk_size = step_between_vertices_in_current_mesh * float(u_num_vertices_per_chunk - uint(1));	// in world units
			UV2 = VERTEX.xz / vec2(chunk_size);		// mapping of the VERTEX in current chunk from 0.0 (start of the chunk) to 1.0 (end of the chunk)
			//UV2 = vec2(float(vertex_col) / float(u_num_vertices_per_chunk), float(vertex_row) / float(u_num_vertices_per_chunk));
			//lod = log2(step_between_vertices_in_current_mesh);
			lod = log2(step_between_vertices_in_current_mesh) - 1.0;
			//lod = float(step_between_vertices_in_current_mesh);
		}
	}
	v_lod = lod;
}

void fragment() {
	// Depth variables and calc
	float depth_texture = texture(DEPTH_TEXTURE, SCREEN_UV).r * 2.0 - 1.0;
	float depth = PROJECTION_MATRIX[3][2] / (depth_texture + PROJECTION_MATRIX[2][2]);
	float depth_blend = exp((depth+VERTEX.z + depth_offset) * -beers_law);
	depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
	float depth_blend_power = clamp(pow(depth_blend, 2.5), 0.0, 1.0);

	// Retrieving depth color and applying the deep and shallow colors
	vec3 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, depth_blend_power * 2.5).rgb;
	vec3 depth_color = mix(color_shallow.rgb, color_deep.rgb, depth_blend_power);
	vec3 color = mix(screen_color * depth_color, depth_color * 0.25, depth_blend_power * 0.5);

	// Getting edge depth calc
	float z_depth = edge(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	float z_pos = edge(FRAGCOORD.z);
	float z_dif = z_depth - z_pos;

	// Time calculations for wave (normal map) movement
	vec2 time = (TIME * wave_direction) * time_scale; // Movement rate of first wave
	vec2 time2 = (TIME * wave_direction2) * time_scale; // Movement rate of second wave

	// Blend normal maps into one
	vec3 normal_blend = mix(texture(gu_sea_texture_normal, v_world_pos.xz + time).rgb, texture(gu_sea_texture_normal2, v_world_pos.xz + time2).rgb, 0.5);

	// Calculate Fresnel
	float fresnel = fresnel(5.0, NORMAL, VIEW);
	vec3 surface_color = mix(albedo, albedo2, fresnel); // Interpolate albedo values by frensel

	vec3 depth_color_adj = mix(edge_color, color, step(edge_scale, z_dif));

	ALBEDO = clamp(surface_color + depth_color_adj,vec3(0.0),vec3(1.0));
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal_blend;

	float lod = v_lod;
	if (lod >= 0.0) {
		float f = floor(lod);
		float c = ceil(lod);
		if ((lod - f) > (c - lod) ) {
			lod = c;
		} else {
			lod = f;
		}

		float chunk_border_line_thickness = 0.005;

		if (u_editmode_selected > 0.0 && is_on_the_border(UV, u_quad_border_line_thickness)) {
			ALBEDO = vec3(1.0, 0.749, 0.0);		// GDN_TheWorld_Globals::g_color_yellow_apricot
		} else {
			if (u_mouse_hit != vec2(-1) && distance(u_mouse_hit, UV) < u_mouse_hit_radius) {
				ALBEDO = vec3(1.0, 0.749, 0.0);		// GDN_TheWorld_Globals::g_color_yellow_apricot
			} else {
				if (is_on_the_border(UV, chunk_border_line_thickness) || is_on_the_border(UV2, chunk_border_line_thickness)) {
					//albedo_out = vec3(1.0, 1.0, 1.0);		// GDN_TheWorld_Globals::g_color_white
					ALBEDO = vec3(0.0, 0.0, 0.0);		// GDN_TheWorld_Globals::g_color_black
				} else {
					if (lod >= 0.0 && lod <= 8.0) {
						ALBEDO = lod_colors[int(lod)];
					} else {
						ALBEDO = lod_colors[9];
					}
				}
			}
		}
	}
}