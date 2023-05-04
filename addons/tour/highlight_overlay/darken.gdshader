shader_type canvas_item;

uniform sampler2D zones_sampler;

void fragment() {
	COLOR.a *= texture(zones_sampler, UV).r;
}
