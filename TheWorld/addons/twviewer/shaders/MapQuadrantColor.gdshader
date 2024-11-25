shader_type canvas_item;

//uniform vec4 u_color : source_color = vec4(1, 0, 0, 0);
//uniform float u_alpha = 0.05;
const int world_quadrant_nope = -1;
const int world_quadrant_camera = 0;
const int world_quadrant_initial = 1;
const int world_quadrant_growing = 2;
const int world_quadrant_cache = 3;
uniform int u_world_quadrant = -1;
uniform bool u_quadrant_ready = false;

void fragment()
{
	//COLOR.rgb = u_color.rgb;
	//COLOR.a = u_alpha;

	vec4 color = vec4(1.0, 1.0, 1.0, 0.0);
	float alpha = 0.0;

	if (u_world_quadrant != world_quadrant_nope)
	{
		if (u_world_quadrant == world_quadrant_camera)
		{
			color = vec4(0.0, 1.0, 1.0, 0.0);
		}
		else if (u_world_quadrant == world_quadrant_initial)
		{
			color = vec4(0.0, 0.0, 1.0, 0.0);
		}
		else if (u_world_quadrant == world_quadrant_growing)
		{
			color = vec4(1.0, 0.0, 0.0, 0.0);
		}
		else if (u_world_quadrant == world_quadrant_cache)
		{
			color = vec4(1.0, 1.0, 1.0, 0.0);
		}
	}

	if (u_quadrant_ready)
	{
		alpha = 0.1;
	}
	else
	{
		alpha = 0.05;
	}

	COLOR.rgb = color.rgb;
	COLOR.a = alpha;
}
