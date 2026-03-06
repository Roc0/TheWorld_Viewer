const int c_north_quadrant_border_row = 0;	// North / Top Quadrant
const int c_south_quadrant_border_row = 1;	// South / Bottom Quadrant
const int c_west_quadrant_border_row = 2;	// West / Left Quadrant
const int c_east_quadrant_border_row = 3;	// East / Right Quadrant

bool is_on_upper_border(vec2 uv, float distance_from_border)
{
	if (uv.y >= 0.0 && uv.y < distance_from_border) {
		return true;
	} else {
		return false;
	}
}

bool is_on_lower_border(vec2 uv, float distance_from_border)
{
	if (uv.y > (1.0 - distance_from_border) && uv.y <= 1.0) {
		return true;
	} else {
		return false;
	}
}

bool is_on_left_border(vec2 uv, float distance_from_border)
{
	if (uv.x >= 0.0 && uv.x < distance_from_border) {
		return true;
	} else {
		return false;
	}
}

bool is_on_right_border(vec2 uv, float distance_from_border)
{
	if (uv.x > (1.0 - distance_from_border) && uv.x <= 1.0) {
		return true;
	} else {
		return false;
	}
}

vec3 unpack_normal(vec4 rgba)
{
	// If we consider texture space starts from top-left corner and Y goes down,
	// then Y+ in pixel space corresponds to Z+ in terrain space,
	// while X+ also corresponds to X+ in terrain space.
	vec3 n = rgba.xzy * 2.0 - vec3(1.0);
	// Had to negate Z because it comes from Y in the normal map,
	// and OpenGL-style normal maps are Y-up.
	//n.z *= -1.0;
	return n;
}

vec4 pack_normal(vec3 n, float a)
{
	//n.z *= -1.0;
	return vec4((n.xzy + vec3(1.0)) * 0.5, a);
}

float get_height(sampler2D heightmap, float terrain_height, vec2 uv)
{
	float f_lod_zero = 0.0;
	return textureLod(heightmap, uv, f_lod_zero).r * terrain_height;
}

float fetch_height(sampler2D heightmap, float terrain_height, ivec2 _index)
{
	int i_lod_zero = 0;
	return texelFetch(heightmap, _index, i_lod_zero).r * terrain_height;
}

vec3 get_normal(sampler2D normalmap, mat3 terrain_normal_basis, vec2 uv)
{
	float f_lod_zero = 0.0;
	// Need to use terrain_normal_basis to handle scaling.
	vec3 n = terrain_normal_basis * unpack_normal(textureLod(normalmap, uv, f_lod_zero));
	//n = unpack_normal(texture(normalmap, uv));
	return normalize(n);
}

/*vec3 compute_normal(sampler2D heightmap, vec2 vertex_cell_coords_in_textures, float grid_step, float terrain_height)
{
	const vec3 offsets = vec3(0, 1, 2);
	ivec2 _index[4];
	_index[0] = ivec2(vertex_cell_coords_in_textures + offsets.xy);
	_index[1] = ivec2(vertex_cell_coords_in_textures + offsets.yy);
	_index[2] = ivec2(vertex_cell_coords_in_textures + offsets.yx);
	_index[3] = ivec2(vertex_cell_coords_in_textures + offsets.xx);

	float h[4];

	h[3] = fetch_height(heightmap, terrain_height, _index[3]);	// 0 (0, 0)
	h[2] = fetch_height(heightmap, terrain_height, _index[2]);	// 1 (1, 0)
	h[0] = fetch_height(heightmap, terrain_height, _index[0]);	// 2 (0, 1)
	
	return normalize(vec3(h[3] - h[2], grid_step, h[3] - h[0]));
}*/

vec3 compute_normal(sampler2D heightmap, vec2 vertex_cell_coords_in_textures, sampler2D heightmap_border_rows, vec2 vertex_cell_coords_in_heightmap_optlvl_zero, float grid_step, float terrain_height, bool use_external_borders)
{
	// vertex_cell_coords_in_textures is a 0-based index of the pixel in the heightmap and it ranges from 0 to heightmapSize - 1 (f.i. 1024 or 2048)
	int lod_zero = 0;
	vec2 heightmapSize = vec2(textureSize(heightmap, lod_zero));		// number of vertices per size of the texture f.i. 1025 or 2049 assuming each quadrant size 1024 or 2048
	ivec2 _index = ivec2(vertex_cell_coords_in_textures);
	ivec2 _index_optlvl_zero = ivec2(vertex_cell_coords_in_heightmap_optlvl_zero);
	float h;
	float right_h;
	float bottom_h;
	if (distance(vertex_cell_coords_in_textures.x, heightmapSize.x - 1.0) < 1.0) {
		// the pixel is in the right edge of the heightmap
		if (use_external_borders) {
			h = fetch_height(heightmap, terrain_height, _index);
			right_h = texelFetch(heightmap_border_rows, ivec2(_index_optlvl_zero.y, c_east_quadrant_border_row), lod_zero).r;
			if (distance(vertex_cell_coords_in_textures.y, heightmapSize.y - 1.0) < 1.0) {
				// the pixel is in the bottom/right corner of the heightmap
				bottom_h = texelFetch(heightmap_border_rows, ivec2(_index_optlvl_zero.x, c_south_quadrant_border_row), lod_zero).r;
			} else {
				bottom_h = fetch_height(heightmap, terrain_height, _index + ivec2(0, 1));
			}
		} else {
			h = fetch_height(heightmap, terrain_height, _index - ivec2(1, 0));
			right_h = fetch_height(heightmap, terrain_height, _index);
			bottom_h = fetch_height(heightmap, terrain_height, _index - ivec2(1, -1));
		}
	} else {
		if (distance(vertex_cell_coords_in_textures.y, heightmapSize.y - 1.0) < 1.0) {
			// the pixel is in the bottom edge of the heightmap but not in the bottom/right corner of the heightmap
			if (use_external_borders) {
				h = fetch_height(heightmap, terrain_height, _index);
				right_h = fetch_height(heightmap, terrain_height, _index + ivec2(1, 0));
				bottom_h = texelFetch(heightmap_border_rows, ivec2(_index_optlvl_zero.x, c_south_quadrant_border_row), lod_zero).r;
			} else {
				h = fetch_height(heightmap, terrain_height, _index - ivec2(0, 1));
				right_h = fetch_height(heightmap, terrain_height, _index - ivec2(-1, 1));
				bottom_h = fetch_height(heightmap, terrain_height, _index);
			}
		} else {
			h = fetch_height(heightmap, terrain_height, _index);
			right_h = fetch_height(heightmap, terrain_height, _index + ivec2(1, 0));
			bottom_h = fetch_height(heightmap, terrain_height, _index + ivec2(0, 1));
		}
	}
	return normalize(vec3(h - right_h, grid_step, h - bottom_h));
}

vec3 get_normal_1(sampler2D tex, vec2 uv)
{
	return unpack_normal(texture(tex, uv));
}

float lerp_f(float a, float b, float t)
{
	return a + (t * (b - a));
}

vec4 compute_splat(sampler2D heightmap, vec2 vertex_cell_coords_in_textures, float grid_step, float terrain_height, vec3 _normal,
					float slope_vertical_factor, float slope_flat_factor, float dirt_on_rocks_factor, float high_elevation_factor, float low_elevation_factor, float min_height, float max_height)
{
	// u_slope_vertical_factor, u_slope_flat_factor, u_dirt_on_rocks_factor, u_high_elevation_factor, u_low_elevation_factor, u_min_height, u_max_height

	//vec2 uv = UV;
	//float h = get_height(TEXTURE, u_terrain_height, uv);
	float h = fetch_height(heightmap, terrain_height, ivec2(vertex_cell_coords_in_textures));
	
	//vec3 _normal = get_normal_1(u_terrain_normalmap, uv);
	float slope = (slope_vertical_factor * (1.0 - _normal.y)) - slope_flat_factor;
	float rocks_amount = clamp(slope, 0.0, 1.0);
	float dirt_amount = clamp(rocks_amount * dirt_on_rocks_factor, 0.0, 1.0);
	float high_elevation_amount = high_elevation_factor * ((h - min_height) / (max_height - min_height)) - low_elevation_factor;
	high_elevation_amount = clamp(high_elevation_amount, 0.0, 1.0);
	float low_elevation_amount = 1.0 - high_elevation_amount;
	
	vec4 splat_pixel;
	
	splat_pixel.r = low_elevation_amount;
	splat_pixel.r = lerp_f(splat_pixel.r, 0.0, high_elevation_amount);
	splat_pixel.r = lerp_f(splat_pixel.r, 0.0, dirt_amount);
	splat_pixel.r = lerp_f(splat_pixel.r, 0.0, rocks_amount);
	splat_pixel.g = high_elevation_amount;
	splat_pixel.g = lerp_f(splat_pixel.g, 0.0, dirt_amount);
	splat_pixel.g = lerp_f(splat_pixel.g, 0.0, rocks_amount);
	splat_pixel.b = dirt_amount;
	splat_pixel.b = lerp_f(splat_pixel.b, 0.0, rocks_amount);
	splat_pixel.a = rocks_amount;
	
	return splat_pixel;
}

bool is_on_the_border(vec2 uv, float distance_from_border)
{
	if (uv.x > distance_from_border && uv.x < (1.0 - distance_from_border) && uv.y > distance_from_border && uv.y < (1.0 - distance_from_border)) {
		return false;
	} else {
		return true;
	}
}

vec4 encode_height_to_viewport(float h)
{
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

float decode_height_from_viewport(vec4 c)
{
	uint u = uint(c.r * 255.0)
		| (uint(c.g * 255.0) << 8u)
		| (uint(c.b * 255.0) << 16u)
		| (uint(c.a * 255.0) << 24u);
	return uintBitsToFloat(u);
}
