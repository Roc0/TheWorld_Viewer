shader_type canvas_item;

global uniform bool gu_camera_on_sea = false;
global uniform float gu_camera_under_water = -1;

uniform vec4 color : source_color = vec4(0.117, 0.77, 0.258, 1);	// vec4(0.04, 0.022, 0.199, 1);
uniform sampler2D fast_noise : repeat_enable;
uniform sampler2D screen_content: hint_screen_texture, filter_linear_mipmap;
uniform vec2 speed = vec2(0.03, 0.04);
uniform float wave_strength = 2;
uniform float color_strength = 0.16;

void fragment() {
	bool under_water = false;
	if (gu_camera_on_sea && gu_camera_under_water > 0.0) {
		under_water = true;
	}

	if (under_water)
	{
		vec2 uv = UV + speed * TIME;
		vec2 noise = texture(fast_noise, uv).rg;
		COLOR = vec4(color.r, color.g, color.b, 1) + vec4(noise.x * color_strength, noise.y * color_strength, noise.x * color_strength, 1);
		COLOR *= texture(screen_content, SCREEN_UV + noise * (wave_strength / 100.0));
	}
	else
	{
		COLOR = texture(screen_content, SCREEN_UV);
	}

}