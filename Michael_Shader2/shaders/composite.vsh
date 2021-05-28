#version 120


varying vec2 texcoord;
varying vec3 lightVector;
varying vec3 lightColor;
varying vec3 skyColor; // Contains AmbientLightStrength coeff


uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;


void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	if (worldTime < 12700 || worldTime > 23250) {
		// Day

		lightVector = normalize(sunPosition);
		lightColor = vec3(1.0);
		skyColor = vec3(0.3);
	} else {
		// Night

		lightVector = normalize(moonPosition);
		lightColor = vec3(0.1);
		skyColor = vec3(0.03);
	}
}