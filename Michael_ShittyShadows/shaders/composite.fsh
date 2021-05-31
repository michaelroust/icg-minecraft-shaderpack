#version 120


//----------------------------------------------------------------------------
// Varyings

varying vec2 texcoord;

//----------------------------------------------------------------------------
// Uniforms

uniform sampler2D colortex0; 	// 0  - gcolor/colortex0 has its color cleared to the current fog color before rendering.
uniform sampler2D colortex1; 	// 1  - gdepth/colortex1 has its color cleared to solid white before rendering and uses a higher precision storage buffer suitable for storing depth values.
uniform sampler2D colortex2; 	// 2  - The rest have their color cleared to black with 0 alpha.
uniform sampler2D colortex3; 	// 3
uniform sampler2D colortex4; 	// 7
uniform sampler2D colortex5; 	// 8
uniform sampler2D colortex6; 	// 9
uniform sampler2D colortex7; 	// 10

uniform sampler2D depthtex0; 	// Apparently contains depth info
uniform sampler2D shadowtex0;	// Contains a shadow map (rendered from sun position, need to change to eye space to use this, I think).

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

// Direction of the sun (not normalized!)
// A vec3 indicating the position of the sun in eye space.
uniform vec3 sunPosition;

//----------------------------------------------------------------------------
// Optifine Constants

const int RGB16 = 1;
const int RGBA16 = 1;
/* colortex0Format:RGBA16 */
/* colortex2Format:RGB16 */

// const int shadowMapResolution = 32;
// const int shadowMapResolution = 1024;
const int shadowMapResolution = 16384;
const float sunPathRotation = -10.0f;

//----------------------------------------------------------------------------
// Our constants

// const float shadowBias = 0.0f;
const float shadowBias = 0.001f; // Reasonable values within [0.001, 0.000001]
const float intensityAmbientCoeff = 0.2f;

//----------------------------------------------------------------------------

//============================================================================

// vec3 EyeToWorldSpace()


float GetShadow(float depth) {
	// Create a 3D vector with (screenX, screenY, depth) and rescale to [-1, 1]
    vec3 ClipSpace = vec3(texcoord, depth) * 2.0f - 1.0f;

	//
    vec4 ViewW = gbufferProjectionInverse * vec4(ClipSpace, 1.0f);
    vec3 View = ViewW.xyz / ViewW.w;
    vec4 World = gbufferModelViewInverse * vec4(View, 1.0f);
    vec4 ShadowSpace = shadowProjection * shadowModelView * World;
    vec3 SampleCoords = ShadowSpace.xyz * 0.5f + 0.5f;
    return step(SampleCoords.z - shadowBias, texture2D(shadowtex0, SampleCoords.xy).r);
}

vec3 gamma(vec3 color) {
	return pow(color, vec3(2.2f));
}

vec3 invgamma(vec3 color) {
	return pow(color, vec3(1.0f/2.2f));
}

//============================================================================

// This tells which gl_FragDatas we will be writing to
/* RENDERTARGETS: 0 */

void main() {
	vec3 ColorIn = texture2D(colortex0, texcoord).rgb;

	float Depth = texture2D(depthtex0, texcoord).r;

	if(Depth == 1.0f){
        gl_FragData[0] = vec4(ColorIn, 1.0f);
        return;
    }

	vec3 Normal = normalize(texture2D(colortex2, texcoord).rgb * 2.0f - 1.0f);
	vec3 Albedo = gamma(ColorIn);

	//-----------------------------------------------------------------
	// Ambient

	vec3 ContribAmbient = intensityAmbientCoeff * Albedo;

	//-----------------------------------------------------------------
	// Diffuse

	// Missing logic for : if NdotL < 0 then ContribDiffuse = 0;
	// Will do this in later stages

	vec3 ContribDiffuse = GetShadow(Depth) * Albedo;


	//-----------------------------------------------------------------

	vec3 ColorOut = ContribAmbient + ContribDiffuse;
	ColorOut = invgamma(ColorOut);

	//-----------------------------------------------------------------
	// Debugging

	vec3 red = vec3(1.0f, 0.0f, 0.0f);
	vec3 green = vec3(0.0f, 1.0f, 0.0f);
	vec3 blue = vec3(0.0f, 0.0f, 1.0f);

	// ColorOut = vec3(texture2D(depthtex0, texcoord));
	// ColorOut = Normal;

	//-----------------------------------------------------------------

	// gl_FragData[0] = vec4(ColorIn, 1.0);
	gl_FragData[0] = vec4(ColorOut, 1.0);
}