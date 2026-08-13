shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec4 flash_color : source_color = vec4(1.0, 0.78, 0.35, 1.0);
uniform float intensity : hint_range(0.0, 8.0) = 4.0;
uniform float age : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float fade = pow(1.0 - clamp(age, 0.0, 1.0), 2.0);
	ALBEDO = flash_color.rgb * intensity * fade;
	ALPHA = fade;
}
