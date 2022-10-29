#version 120

varying vec4 color;
varying vec2 lmcoord;
varying vec3 normal;

void main() {
	/* DRAWBUFFERS:024 */
	gl_FragData[0] = vec4(0.0, 0.0, 0.1, 0.7); // watercolor - gcolor
	gl_FragData[1] = vec4(normalize(normal) * 0.5 + 0.5, 1.0);	// gnormal
	gl_FragData[2] = vec4(lmcoord.t, mix(1.0,0.05,1.), lmcoord.s, 1.0); // gaux1
}