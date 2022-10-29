#version 120

//============================================================================
// Varyings

varying vec2 texCoord;

//============================================================================
// Uniforms

uniform sampler2D colortex0;

uniform sampler2D noisetex;

uniform float viewWidth;
uniform float viewHeight;

const int noiseTextureResolution = 64;

//============================================================================
// Bloom Parameters

const int   kernel_radius   = 2;
const float separation      = 2.0;
const float threshold       = 0.87;
const float amount          = 0.20;

//============================================================================

vec3 superGammaToLinearSpace(vec3 color) {
	return pow(color, vec3(3.2f));
}

vec3 superGammaToGammaSpace(vec3 color) {
	return pow(color, vec3(1.0f/3.2f));
}

//============================================================================

float getRandomAngle(in vec2 coord) {
	vec2 noiseTexCoord = vec2(mod(coord.x, noiseTextureResolution), mod(coord.y, noiseTextureResolution));
	float theta = texture2D(noisetex, noiseTexCoord).r;
	return theta;
}

mat2 getRotationMatrix(float theta) {
	return mat2(
		cos(theta), -sin(theta),
		sin(theta), cos(theta)
	);
}

//============================================================================

vec3 brightFilter(in vec3 color) {
	// Different cutoff functions possible

	// float brightness = (color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722);
	// return brightness > threshold ? color : vec3(0.0);

    // return color * brightness;

    // return max(color.r, max(color.r, color.g)) > threshold ? color : vec3(0.0);
    return max(color.r, max(color.r, color.g)) > threshold ? color : vec3(0.0);
}

vec3 bloom(in vec2 texCoord) {
	vec3 bloomColor = vec3(0.0);

	// mat2 rotationMatrix = getRotationMatrix(getRandomAngle(texCoord));

	for (int y = -kernel_radius; y <= kernel_radius; y++) {
		for (int x = -kernel_radius; x <= kernel_radius; x++) {
			vec2 offset = vec2(x/viewWidth, y/viewHeight) * separation;
			// offset = rotationMatrix * offset;

			bloomColor += brightFilter(texture2D(colortex0, texCoord + offset).rgb);
		}
	}
    bloomColor = bloomColor / pow((2 * kernel_radius + 1), 2);

	return mix(vec3(0.0), bloomColor, amount);
}


vec3 bloomGaussianBlur(in vec2 texCoord) {
	// vec3 bloomColor = vec3(0.0);

	// mat2 rotationMatrix = getRotationMatrix(getRandomAngle(texCoord));

    vec3 bloomColors[25];

    int kernel_radius_here = 2;

	for (int y = -kernel_radius_here; y <= kernel_radius_here; y++) {
		for (int x = -kernel_radius_here; x <= kernel_radius_here; x++) {
			vec2 offset = vec2(x/viewWidth, y/viewHeight) * separation;
			// offset = rotationMatrix * offset;

            bloomColors[(y + kernel_radius_here) * (2 * kernel_radius_here + 1) + (x + kernel_radius_here)] =
                brightFilter(texture2D(colortex0, texCoord + offset).rgb);
		}
	}

    vec3 bloomColor =
        bloomColors[0] * 0.00376 + bloomColors[1] * 0.015019 + bloomColors[2] * 0.023792 + bloomColors[3] * 0.015019 + bloomColors[4] * 0.003765 +
        bloomColors[5] * 0.015019 + bloomColors[6] * 0.059912 + bloomColors[7] * 0.094907 + bloomColors[8] * 0.059912 + bloomColors[9] * 0.015019 +
        bloomColors[10] * 0.023792 + bloomColors[11] * 0.094907 + bloomColors[12] * 0.150342 + bloomColors[13] * 0.094907 + bloomColors[14] * 0.023792 +
        bloomColors[15] * 0.015019 + bloomColors[16] * 0.059912 + bloomColors[17] * 0.094907 + bloomColors[18] * 0.059912 + bloomColors[19] * 0.015019 +
        bloomColors[20] * 0.00376 + bloomColors[21] * 0.015019 + bloomColors[22] * 0.023792 + bloomColors[23] * 0.015019 + bloomColors[24] * 0.003765;

	return mix(vec3(0.0), bloomColor, amount);
}


//============================================================================

void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

    #define BLOOM
    #ifdef BLOOM
    color = superGammaToLinearSpace(color);

    // color += bloom(texCoord);
    color += bloomGaussianBlur(texCoord);

    color = superGammaToGammaSpace(color);
    #endif
    /* RENDERTARGETS: 0 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
}
