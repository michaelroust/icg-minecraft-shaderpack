#version 120

uniform sampler2D gcolor;
uniform sampler2D gaux1;
varying vec4 texcoord;

//----------------MAIN------------------

void main() {

	float wave = 0.0;

	vec3 aux = texture2D(gaux1, texcoord.st).rgb;

	if(aux.g > 0.01 && aux.g < 0.07) {
		wave = 1.;
	}

	vec3 color = texture2D(gcolor, texcoord.st).rgb;

	/* DRAWBUFFERS:NNN3N5 */
	gl_FragData[3] = vec4(color, 1);
	gl_FragData[5] = vec4(0.0, wave, 0.0, 0.0);
}
