#version 120

varying vec2 texCoord;
varying vec3 lightVector;
varying vec3 lightColor;

varying vec3 skyColor; // Sort of contains AmbientLightStrength coeff

// Day night cycle
uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

void main() {
	gl_Position = ftransform();
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	if (worldTime < 12500 || worldTime > 23500) {
		// Day

		lightVector = normalize(sunPosition);
		lightColor = vec3(1.0);
		skyColor = vec3(0.35f);
	} else {
		// Night

		lightVector = normalize(moonPosition);
		lightColor = vec3(0.1);
		skyColor = vec3(0.025);
	}
}