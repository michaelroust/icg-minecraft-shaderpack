#version 120

//----------------------------------------------------------------------------
// Varyings

varying vec2 texCoord;
varying vec3 lightVector;
varying vec3 lightColor;
varying vec3 skyColor;

//----------------------------------------------------------------------------
// Uniforms

uniform sampler2D colortex0; 	// gcolor/colortex0 has its color cleared to the current fog color before rendering.
uniform sampler2D colortex1; 	// gdepth/colortex1 has its color cleared to solid white before rendering and uses a higher precision storage buffer suitable for storing depth values.
uniform sampler2D colortex2; 	// gnormal/colortex2 The rest have their color cleared to black with 0 alpha.
// uniform sampler2D colortex3; 	// 3
uniform sampler2D colortex4; 	// 7
// uniform sampler2D colortex5; 	// 8
// uniform sampler2D colortex6; 	// 9
// uniform sampler2D colortex7; 	// 10

uniform sampler2D depthtex0; 	// Apparently contains depth info
uniform sampler2D shadowtex0;	// Contains a shadow map (rendered from sun position, need to change to eye space to use this, I think).

uniform sampler2D depthtex1;
uniform sampler2D depthtex2;

uniform sampler2D noisetex;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform vec3 cameraPosition;

// uniform int viewWidth;
// uniform int viewHeight;

// Direction of the sun (not normalized!)
// A vec3 indicating the position of the sun in eye space.
// uniform vec3 sunPosition;

//----------------------------------------------------------------------------
// Optifine Constants

// const int shadowMapResolution = 32;
// const int shadowMapResolution = 1024;
// const int shadowMapResolution = 4096;
const int shadowMapResolution = 16384;
// const int shadowMapResolution = 32768;
const float sunPathRotation = -10.0f;

const int noiseTextureResolution = 64;

//----------------------------------------------------------------------------
// Our constants

const float shadowBias = 0.0005; // Reasonable values within [0.001, 0.000001]

//----------------------------------------------------------------------------

//============================================================================
// Gamma Correction

vec3 gammaToLinearSpace(vec3 color) {
	return pow(color, vec3(2.2f));
}

vec3 gammaToGammaSpace(vec3 color) {
	return pow(color, vec3(1.0f/2.2f));
}

//============================================================================
// Space Transformation Functions

vec4 getCameraSpacePosition(in vec2 coord, in float depth) {
	// Normalized Device Coordinates
	vec4 posNdcSpace = vec4(vec3(coord.x, coord.y, depth) * 2.0 - 1.0, 1.0);
	vec4 posCameraSpace = gbufferProjectionInverse * posNdcSpace;

	return posCameraSpace / posCameraSpace.w;
}

vec4 getWorldSpacePosition(in vec2 coord, in float depth) {
	vec4 posCameraSpace = getCameraSpacePosition(coord, depth);
	vec4 posWorldSpace = gbufferModelViewInverse * posCameraSpace;
	posWorldSpace.xyz += cameraPosition.xyz;
	return posWorldSpace;
}

vec3 getShadowSpacePosition(in vec2 coord, in float depth) {
	vec4 posWorldSpace = getWorldSpacePosition(coord, depth);

	posWorldSpace.xyz -= cameraPosition;
	vec4 posShadowSpace = shadowModelView * posWorldSpace;
	posShadowSpace = shadowProjection * posShadowSpace;
	posShadowSpace /= posShadowSpace.w;

	posShadowSpace.xyz = posShadowSpace.xyz * 0.5 + 0.5;
	return posShadowSpace.xyz;
}

//============================================================================
// Randomness / noise

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
// Lighting

// Use with offset = vec2(0.) for plain hard shadows
float getHardShadow(in vec2 coord, in vec2 offset, in float depth) {

	vec3 shadowCoord = getShadowSpacePosition(coord, depth);
	float shadowMapSample = texture2D(shadowtex0, shadowCoord.xy + offset).r;

	float visibility = step(shadowCoord.z - shadowMapSample, shadowBias);

	return visibility;
}

float getSoftShadow(in vec2 coord, in float depth) {

	float visibilitySample = 0.0;

	int kernel_radius = 3; // Could be made a const

	mat2 rotationMatrix = getRotationMatrix(getRandomAngle(coord));

	// PCF filtering with simple box kernel
	for (int y = -kernel_radius; y <= kernel_radius; y++) {
		for (int x = -kernel_radius; x <= kernel_radius; x++) {
			vec2 offset = vec2(x,y) / shadowMapResolution;
			offset = rotationMatrix * offset;

			visibilitySample += getHardShadow(coord, offset, depth);
		}
	}

	return visibilitySample / pow((2 * kernel_radius + 1), 2);
}

vec3 calculateLighting(in vec2 texCoord, in vec3 albedo, in vec3 normal, in float emission,
		in float depth, in float torchLightStrength, in float skyLightStrength) {

	float directLightStrength = dot(normal, lightVector);
	directLightStrength = max(0.0, directLightStrength);

	vec3 directLightColor = directLightStrength * lightColor * getSoftShadow(texCoord, depth);

	vec3 torchColor = vec3(1, 0.85, 0.7);
	vec3 torchLightColor = torchColor * pow(torchLightStrength, 4);

	vec3 skyLightColor = skyColor * pow(skyLightStrength, 2);

	vec3 litColor = albedo * (directLightColor + skyLightColor + torchLightColor);

	return mix(litColor, albedo, emission);
}

//============================================================================

void main() {
	//=================================================================
	// Read values from color textures

	vec4 texColor = texture2D(colortex0, texCoord);
	vec3 albedo = gammaToLinearSpace(texColor.rgb);

	vec4 lightingData = texture2D(colortex1, texCoord);

	float torchLightStrength = lightingData.r;
	float skyLightStrength = lightingData.g;
	float emission = lightingData.b;

	vec3 normal = texture2D(colortex2, texCoord).rgb * 2.0f - 1.0f;

	float depth = texture2D(depthtex0, texCoord).r;

	//=================================================================
	// Run calculations

	vec3 finalColor = gammaToGammaSpace(calculateLighting(texCoord, albedo, normal, emission, depth, torchLightStrength, skyLightStrength));

	//=================================================================
	// Write outputs

	// This tells which gl_FragDatas we will be writing to
	/* RENDERTARGETS: 0,N,N,N,N,5 */

	gl_FragData[0] = vec4(finalColor, 1.);

	//=================================================================
	// Wave stuff

	vec3 waveInfo = texture2D(colortex4, texCoord).rgb;

	float wave = 0.0;
	if(waveInfo.g > 0.01 && waveInfo.g < 0.07) {
		wave = 1.;
	}

	gl_FragData[5] = vec4(0.0, wave, 0.0, 0.0);

	//=================================================================
	//Debug

	// gl_FragData[0] = Color;
	// gl_FragData[0] = vec4(Albedo, 1.0f);
	// gl_FragData[0] = vec4(Normal, 1.0f);
	// gl_FragData[0] = vec4(Emission);

	// gl_FragData[0] = vec4(texture2D(colortex1, texCoord).b);

	// gl_FragData[0] = vec4(pow(texture2D(depthtex2, texcoord).r, 50));

	// gl_FragData[0] = texture2D(noisetex, texcoord);
}