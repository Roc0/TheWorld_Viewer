shader_type canvas_item;

uniform vec4 u_quadrant_border_color = vec4(0.15, 0.15, 0.15, 1.0);
uniform vec4 u_texture_border_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform bool u_highlighted = false;
uniform float u_line_thickness = 0.008;
global uniform bool gu_map_grid_on = false;
uniform int u_num_quadrants;
uniform float u_quadrant_size;

//varying vec2 world_pos;

/*
void vertex() {
	// Called for every vertex the material is visible on.
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0, 1.0)).xy;
}
*/

void fragment() {
	vec4 color = vec4(1.0, 1.0, 1.0, 0.0);
	float alpha = 0.0;
	vec2 uv = UV;

	float line_thickness_for_quadrant_border = u_line_thickness;
	float line_thickness_for_texture_border = u_line_thickness;
	if (u_highlighted)
		line_thickness_for_texture_border *= 3.0;
	if (gu_map_grid_on)
	{
		bool on_quadrant_border = false;
		float uv_fragment = 1.0 / float(u_num_quadrants);
		for (int x = 0; x < u_num_quadrants; x++)
		{
			for (int y = 0; y < u_num_quadrants; y++)
			{
				vec2 upper_left_quadrant_uv = vec2(float(x) * uv_fragment, float(y) * uv_fragment);
				if ((uv.x - upper_left_quadrant_uv.x) > 0.0 && (uv.x - upper_left_quadrant_uv.x) < line_thickness_for_quadrant_border)
				{
					on_quadrant_border = true;
					break;
				}
				else if (((upper_left_quadrant_uv.x + uv_fragment) - uv.x) > 0.0 && ((upper_left_quadrant_uv.x + uv_fragment) - uv.x) < line_thickness_for_quadrant_border)
				{
					on_quadrant_border = true;
					break;
				}
				else if ((uv.y - upper_left_quadrant_uv.y) > 0.0 && (uv.y - upper_left_quadrant_uv.y) < line_thickness_for_quadrant_border)
				{
					on_quadrant_border = true;
					break;
				}
				else if (((upper_left_quadrant_uv.y + uv_fragment) - uv.y) > 0.0 && ((upper_left_quadrant_uv.y + uv_fragment) - uv.y) < line_thickness_for_quadrant_border)
				{
					on_quadrant_border = true;
					break;
				}
			}
		}

		bool on_texture_border = false;
		{
			if (uv.x >= 0.0 && uv.x < line_thickness_for_texture_border)
				on_texture_border = true;
			if ((1.0 - uv.x) >= 0.0 && (1.0 - uv.x) < line_thickness_for_texture_border)
				on_texture_border = true;
			if (uv.y >= 0.0 && uv.y < line_thickness_for_texture_border)
				on_texture_border = true;
			if ((1.0 - uv.y) >= 0.0 && (1.0 - uv.y) < line_thickness_for_texture_border)
				on_texture_border = true;
		}

		if (on_quadrant_border)
		{
			color = u_quadrant_border_color;
			alpha = 1.0;
		}

		if (on_texture_border)
		{
			color = u_texture_border_color;
			alpha = 1.0;
		}
	}

	COLOR.rgb = color.rgb;
	COLOR.a = alpha;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
