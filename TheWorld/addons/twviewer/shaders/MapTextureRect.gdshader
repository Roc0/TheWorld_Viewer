shader_type canvas_item;

const int world_quadrant_nope = -1;
const int world_quadrant_camera = 0;
const int world_quadrant_initial = 1;
const int world_quadrant_growing = 2;
const int world_quadrant_cache = 3;
uniform int u_world_quadrant = -1;
uniform bool u_status = false;

uniform bool u_frame_visible = false;

void fragment()
{
	if (u_frame_visible)
	{
		
	}
}
