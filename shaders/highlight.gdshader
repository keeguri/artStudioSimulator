shader_type spatial;

uniform vec3 highlight_color : source_color;
uniform float blink_speed = 1;

void vertex() {
	
}

void fragment() {
	ALBEDO = highlight_color;
	ALPHA = sin(TIME*blink_speed)/10.0;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
