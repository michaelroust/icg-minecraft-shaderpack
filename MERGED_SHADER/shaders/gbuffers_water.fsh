#version 120

varying vec4 tintColor;
varying vec2 lmcoord;
varying vec3 normal;

void main() {

	/* RENDERTARGETS:0,N,2,N,4 */
	// gl_FragData[0] = vec4(0.0, 0.0, 0.1, 0.7); // watercolor
	gl_FragData[0] = tintColor * vec4(0.4, 0.4, 0.6, 0.6);
	gl_FragData[2] = vec4(normalize(normal) * 0.5 + 0.5, 1.0);
	gl_FragData[4] = vec4(lmcoord.t, mix(1.0,0.05,1.), lmcoord.s, 1.0);
}