shader_type canvas_item;

uniform vec4 u_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 u_color_visible_quadrants = vec4(1.0, 0.0, 0.0, 1.0);
uniform float u_line_thickness = 0.008;
uniform bool u_frame_visible = false;
uniform int u_num_quadrants;
uniform float u_quadrant_size;
uniform vec2 u_world_camera_quadrant_pos;
uniform int u_num_visible_quadrants_on_north_side = -1;
uniform int u_num_visible_quadrants_on_south_side = -1;
uniform int u_num_visible_quadrants_on_west_side = -1;
uniform int u_num_visible_quadrants_on_east_side = -1;
uniform int u_num_cache_quadrants = -1;

varying vec2 world_pos;

void vertex() {
	// Called for every vertex the material is visible on.
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0, 1.0)).xy;
}

void fragment() {
	if (u_frame_visible)
	{
		bool on_quadrant_border = false;
		float uv_fragment = 1.0 / float(u_num_quadrants);
		for (int x = 0; x < u_num_quadrants; x++)
		{
			for (int y = 0; y < u_num_quadrants; y++)
			{
				vec2 upper_left_quadrant_uv = vec2(float(x) * uv_fragment, float(y) * uv_fragment);
				if ((UV.x - upper_left_quadrant_uv.x) > 0.0 && (UV.x - upper_left_quadrant_uv.x) < u_line_thickness)
				{
					on_quadrant_border = true;
					break;
				}
				else if (((upper_left_quadrant_uv.x + uv_fragment) - UV.x) > 0.0 && ((upper_left_quadrant_uv.x + uv_fragment) - UV.x) < u_line_thickness)
				{
					on_quadrant_border = true;
					break;
				}
				else if ((UV.y - upper_left_quadrant_uv.y) > 0.0 && (UV.y - upper_left_quadrant_uv.y) < u_line_thickness)
				{
					on_quadrant_border = true;
					break;
				}
				else if (((upper_left_quadrant_uv.y + uv_fragment) - UV.y) > 0.0 && ((upper_left_quadrant_uv.y + uv_fragment) - UV.y) < u_line_thickness)
				{
					on_quadrant_border = true;
					break;
				}
			}
		}
		if (on_quadrant_border)
		{
			COLOR = u_color;

			/*if (u_num_visible_quadrants_on_north_side > -1 && u_num_visible_quadrants_on_south_side > -1 && u_num_visible_quadrants_on_west_side > -1 && u_num_visible_quadrants_on_east_side > -1)
			{
				float distance_north = 0.0;
				float distance_south = 0.0;
				float distance_west = 0.0;
				float distance_east = 0.0;

				float quadrant_size = u_quadrant_size;

				bool pixel_in_north_quadrant = false;
				bool pixel_in_south_quadrant = false;
				bool pixel_in_west_quadrant = false;
				bool pixel_in_east_quadrant = false;
				if (world_pos.y < u_world_camera_quadrant_pos.y)
				{
					pixel_in_north_quadrant = true;
					distance_north = u_world_camera_quadrant_pos.y - world_pos.y;
				}
				else if (world_pos.y > u_world_camera_quadrant_pos.y + quadrant_size)
				{
					pixel_in_south_quadrant = true;
					distance_south =  world_pos.y - (u_world_camera_quadrant_pos.y + quadrant_size);
				}
				if (world_pos.x < u_world_camera_quadrant_pos.x)
				{
					pixel_in_west_quadrant = true;
					distance_west = u_world_camera_quadrant_pos.x - world_pos.x;
				}
				else if (world_pos.x > u_world_camera_quadrant_pos.x + quadrant_size)
				{
					pixel_in_east_quadrant = true;
					distance_east =  world_pos.x - (u_world_camera_quadrant_pos.x + quadrant_size);
				}

				if (pixel_in_north_quadrant && distance_north < float(u_num_visible_quadrants_on_north_side))
				{
					COLOR = u_color_visible_quadrants;
				}
				if (pixel_in_south_quadrant && distance_south < float(u_num_visible_quadrants_on_south_side))
				{
					COLOR = u_color_visible_quadrants;
				}
				if (pixel_in_west_quadrant && distance_west < float(u_num_visible_quadrants_on_west_side))
				{
					COLOR = u_color_visible_quadrants;
				}
				if (pixel_in_east_quadrant && distance_east < float(u_num_visible_quadrants_on_east_side))
				{
					COLOR = u_color_visible_quadrants;
				}
			}*/
		}
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
