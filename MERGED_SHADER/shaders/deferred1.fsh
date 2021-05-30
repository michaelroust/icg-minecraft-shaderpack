#version 120

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////

//Varyings//
varying vec2 texCoord;


//Uniforms//
uniform float far, near;
uniform float viewWidth, viewHeight, aspectRatio;


uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D depthtex0;

uniform sampler2D noisetex;
uniform int noiseTextureResolution;

const bool colortex4MipmapEnabled = true;

#define AO_STRENGTH 1.5

//Common Variables//

// TODO Refactor
mat2 getRotationMatrix(in vec2 coord) {

	// vec2 noiseTexCoord = coord * vec2(viewWidth / noiseTextureResolution, viewHeight / noiseTextureResolution); // Seems it doesn't rescale things well enough
	vec2 noiseTexCoord = vec2(mod(coord.x, noiseTextureResolution), mod(coord.y, noiseTextureResolution));
	float theta = texture2D(noisetex, noiseTexCoord).r;

	return mat2(
		cos(theta), -sin(theta),
		sin(theta), cos(theta)
	);
}


//Program//
void main() {
    vec4 color      = texture2D(colortex0, texCoord);
	float z         = texture2D(depthtex0, texCoord).r;

	if (z < 1.0) {

		int kernel_radius = 2;

		mat2 rotationMatrix = getRotationMatrix(texCoord);
		float aoLevel = 0.0;
		// Blur kernel filtering
		for (int y = -kernel_radius; y <= kernel_radius; y++) {
			for (int x = -kernel_radius; x <= kernel_radius; x++) {
				vec2 offset = vec2(x/viewWidth, y/viewHeight);
				offset = rotationMatrix * offset;

				aoLevel += texture2D(colortex4, texCoord + offset).r;
			}
		}
		aoLevel = aoLevel / pow((2*kernel_radius+1), 2);

		color.rgb *= (aoLevel);
	}

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = color;

}
