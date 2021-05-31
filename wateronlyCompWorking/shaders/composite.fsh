#version 120

uniform sampler2D colortex0;
uniform sampler2D colortex4;
varying vec4 texcoord;

//----------------MAIN------------------

void main() {


	vec3 waveInfo = texture2D(colortex4, texcoord.st).rgb;

	float wave = 0.0;
	if(waveInfo.g > 0.01 && waveInfo.g < 0.07) {
		wave = 1.;
	}

	vec3 color = texture2D(colortex0, texcoord.st).rgb;

	/* RENDERTARGETS:0,N,N,N,N,5 */
	gl_FragData[0] = vec4(color, 1);
	// gl_FragData[3] = vec4(color, 1);
	gl_FragData[5] = vec4(0.0, wave, 0.0, 0.0);
}
