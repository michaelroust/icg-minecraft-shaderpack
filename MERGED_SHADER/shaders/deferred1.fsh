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

		//--------------------------------------------------------------------------------
		// Box blur

		// int kernel_radius = 2;
		// mat2 rotationMatrix = getRotationMatrix(texCoord);
		// float aoLevel = 0.0;
		// // Blur kernel filtering
		// for (int y = -kernel_radius; y <= kernel_radius; y++) {
		// 	for (int x = -kernel_radius; x <= kernel_radius; x++) {
		// 		vec2 offset = vec2(x/viewWidth, y/viewHeight);
		// 		offset = rotationMatrix * offset;
		// 		aoLevel += texture2D(colortex4, texCoord + offset).r;
		// 	}
		// }
		// aoLevel = aoLevel / pow((2*kernel_radius+1), 2);


		//--------------------------------------------------------------------------------
		// Hardcoded Gaussian Blur

		float aoLevels[25];
		int kernel_radius_here = 2;
		for (int y = -kernel_radius_here; y <= kernel_radius_here; y++) {
			for (int x = -kernel_radius_here; x <= kernel_radius_here; x++) {
				vec2 offset = vec2(x/viewWidth, y/viewHeight);
				// offset = rotationMatrix * offset;
				aoLevels[(y + kernel_radius_here) * (2 * kernel_radius_here + 1) + (x + kernel_radius_here)] =
					texture2D(colortex4, texCoord + offset).r;
			}
		}
    	float aoLevel =
        aoLevels[0] * 0.00376 + aoLevels[1] * 0.015019 + aoLevels[2] * 0.023792 + aoLevels[3] * 0.015019 + aoLevels[4] * 0.003765 +
        aoLevels[5] * 0.015019 + aoLevels[6] * 0.059912 + aoLevels[7] * 0.094907 + aoLevels[8] * 0.059912 + aoLevels[9] * 0.015019 +
        aoLevels[10] * 0.023792 + aoLevels[11] * 0.094907 + aoLevels[12] * 0.150342 + aoLevels[13] * 0.094907 + aoLevels[14] * 0.023792 +
        aoLevels[15] * 0.015019 + aoLevels[16] * 0.059912 + aoLevels[17] * 0.094907 + aoLevels[18] * 0.059912 + aoLevels[19] * 0.015019 +
        aoLevels[20] * 0.00376 + aoLevels[21] * 0.015019 + aoLevels[22] * 0.023792 + aoLevels[23] * 0.015019 + aoLevels[24] * 0.003765;
		//--------------------------------------------------------------------------------

		color.rgb *= (aoLevel);
	}

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = color;

}
