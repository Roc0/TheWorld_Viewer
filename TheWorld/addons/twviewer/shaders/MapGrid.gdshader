shader_type canvas_item;

uniform vec4 u_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float u_line_thickness = 0.008;
uniform bool u_frame_visible = false;
uniform int u_num_quadrants = 5;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	//COLOR = vec4(0.0, UV.x, UV.y, 1.0);
	//if (u_frame_visible)
	//	if (UV.x < u_line_thickness || UV.y < u_line_thickness || UV.x > (1.0 - u_line_thickness) || (UV.y > 1.0 - u_line_thickness))
	//		COLOR = u_color;
			
	if (u_frame_visible)  {
		float uv_fragment = 1.0 / float(u_num_quadrants);
		for (int x = 0; x < u_num_quadrants; x++) {
			for (int y = 0; y < u_num_quadrants; y++) {
				vec2 upper_left_quadrant_uv = vec2(float(x) * uv_fragment, float(y) * uv_fragment);
				if ((UV.x - upper_left_quadrant_uv.x) > 0.0 && (UV.x - upper_left_quadrant_uv.x) < u_line_thickness)
					COLOR = u_color;
				if (((upper_left_quadrant_uv.x + uv_fragment) - UV.x) > 0.0 && ((upper_left_quadrant_uv.x + uv_fragment) - UV.x) < u_line_thickness)
					COLOR = u_color;
				if ((UV.y - upper_left_quadrant_uv.y) > 0.0 && (UV.y - upper_left_quadrant_uv.y) < u_line_thickness)
					COLOR = u_color;
				if (((upper_left_quadrant_uv.y + uv_fragment) - UV.y) > 0.0 && ((upper_left_quadrant_uv.y + uv_fragment) - UV.y) < u_line_thickness)
					COLOR = u_color;
			}
		}
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
