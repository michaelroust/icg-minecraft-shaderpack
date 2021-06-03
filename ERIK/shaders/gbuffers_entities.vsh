#version 120

varying vec2 lmCoord;
varying vec2 texCoord;
varying vec4 tintColor;

varying vec3 normal;

void main() {
	gl_Position = ftransform();
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	// Reading and rescaling lightmap to [0-1] range
	vec2 LightmapCoords = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    lmCoord.xy = (LightmapCoords * 33.05f / 32.0f) - (1.05f / 32.0f);

	tintColor = gl_Color;

	normal = normalize(gl_NormalMatrix * gl_Normal);
}