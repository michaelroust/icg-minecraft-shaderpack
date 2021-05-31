#version 120

varying vec4 tintColor;
varying vec2 lmcoord;
varying vec3 normal;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

#define WAVING_WATER
#ifdef WAVING_WATER
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
const float PI = 3.1415927;
#endif

void main() {

	vec4 position = gl_ModelViewMatrix * gl_Vertex;
	vec4 viewpos = gbufferModelViewInverse * position;
	viewpos = gbufferModelView * viewpos;

	#ifdef WAVING_WATER
	vec3 worldpos = viewpos.xyz + cameraPosition;
	float fy = fract(worldpos.y + 0.1);
	float wave = 0.05 * sin(2 * PI * (frameTimeCounter*0.75 + worldpos.x /  7.0 + worldpos.z / 13.0))
				   + 0.05 * sin(2 * PI * (frameTimeCounter*0.6 + worldpos.x / 11.0 + worldpos.z /  5.0));
	float displacement = clamp(wave, -fy, 1.0-fy);
	viewpos.y += displacement*1.0;
	#endif

	gl_Position = gl_ProjectionMatrix * viewpos;

	tintColor = gl_Color;

	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
	normal = normalize(gl_NormalMatrix * gl_Normal);

}