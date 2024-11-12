shader_type canvas_item;

uniform vec4 u_color : source_color = vec4(1, 0, 0, 0);
uniform float u_alpha = 0.05;

void fragment() {
	COLOR.rgb = u_color.rgb;
	COLOR.a = u_alpha;
}
