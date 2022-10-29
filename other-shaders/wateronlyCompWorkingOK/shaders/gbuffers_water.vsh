#version 120

varying vec4 color;
varying vec2 lmcoord;
varying vec3 normal;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform vec3 cameraPosition;
uniform float frameTimeCounter;

void main() {
	
	vec4 position = gl_ModelViewMatrix * gl_Vertex;
	vec4 viewpos = gbufferModelViewInverse * position;
	viewpos = gbufferModelView * viewpos;

	// Generate wavy water surface with noise
	vec3 worldpos = viewpos.xyz + cameraPosition;
	float fy = fract(worldpos.y + 0.1);
	float PI = 3.1415927;
	float wave = 0.05 * sin(2 * PI * (frameTimeCounter*0.75 + worldpos.x /  7.0 + worldpos.z / 13.0))
				   + 0.05 * sin(2 * PI * (frameTimeCounter*0.6 + worldpos.x / 11.0 + worldpos.z /  5.0));
	float displacement = clamp(wave, -fy, 1.0-fy);
	viewpos.y += displacement*0.5;

	gl_Position = gl_ProjectionMatrix * viewpos;
	
	color = gl_Color;

	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;

	// we need 
	normal = normalize(gl_NormalMatrix * normalize(gl_Normal));
	
}