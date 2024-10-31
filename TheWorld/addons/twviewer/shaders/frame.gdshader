shader_type canvas_item;

uniform vec4 u_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float u_thickness = 0.008;
uniform bool u_frame_visible = false;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	//COLOR = vec4(0.0, UV.x, UV.y, 1.0);
	if (u_frame_visible)
		if (UV.x < u_thickness || UV.y < u_thickness || UV.x > 1.0 - u_thickness || UV.y > 1.0 - u_thickness)
			COLOR = u_color;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
