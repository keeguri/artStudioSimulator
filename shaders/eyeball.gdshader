shader_type spatial;

uniform vec4 eyelid_color : source_color;
uniform vec4 eye_color : source_color;
uniform vec4 pupil_color : source_color;

uniform float pupil_size = 1.0;
uniform float blink_frequency = 1.0;
uniform float blink_softener = 10.0;
uniform float resting_position : hint_range(0.0, 10.0) = 1.0;

varying vec3 pixel_pos_local;

void vertex() {
    pixel_pos_local = VERTEX;
}

void fragment() {
	vec4 final_color = eye_color;
	float blink_wave =abs(sin(blink_frequency*TIME)/blink_softener);
	float local_rest_height = min(resting_position,blink_wave);



	if (pixel_pos_local.y > local_rest_height || pixel_pos_local.y < -local_rest_height){
		final_color = eyelid_color;
	}
	else if (pixel_pos_local.z <= pupil_size) {
		final_color = pupil_color;
	}
	ALBEDO = final_color.rgb;
}
