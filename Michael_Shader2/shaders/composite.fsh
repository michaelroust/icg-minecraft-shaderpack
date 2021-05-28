#version 120


//----------------------------------------------------------------------------
// Varyings

varying vec2 texcoord;
varying vec3 lightVector;
varying vec3 lightColor;
varying vec3 skyColor;

//----------------------------------------------------------------------------
// Uniforms

uniform sampler2D colortex0; 	// 0  - gcolor/colortex0 has its color cleared to the current fog color before rendering.
uniform sampler2D colortex1; 	// 1  - gdepth/colortex1 has its color cleared to solid white before rendering and uses a higher precision storage buffer suitable for storing depth values.
uniform sampler2D colortex2; 	// 2  - gnormal/colortex2 The rest have their color cleared to black with 0 alpha.
uniform sampler2D colortex3; 	// 3
// uniform sampler2D colortex4; 	// 7
// uniform sampler2D colortex5; 	// 8
// uniform sampler2D colortex6; 	// 9
// uniform sampler2D colortex7; 	// 10

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

struct Lightmap {
	float torchLightStrength;
	float skyLightStrength;
};

struct Fragment {
	vec3 albedo;
	vec3 normal;
	float emission;
};

vec3 calculateLighting(in Fragment frag, in Lightmap lightmap) {
	float directLightStrength = dot(frag.normal, lightVector);
	directLightStrength = max(0.0, directLightStrength);
	vec3 directLight = directLightStrength * lightColor;

	vec3 torchColor = vec3(1.0f, 0.9, 0.8);
	vec3 torchLight = torchColor * lightmap.torchLightStrength;

	vec3 skyLight = skyColor * lightmap.skyLightStrength;

	vec3 litColor = frag.albedo * (directLight + skyLight + torchLight);
	// vec3 litColor = frag.albedo * (directLight);
	// vec3 litColor = frag.albedo * (lightmap.skyLightStrength);

	return mix(litColor, frag.albedo, frag.emission);
}


//============================================================================

// This tells which gl_FragDatas we will be writing to
/* RENDERTARGETS: 0 */

void main() {
	vec4 Color = texture2D(colortex0, texcoord);
	vec3 Albedo = Color.rgb;
	float Emission = texture2D(colortex1, texcoord).a;
	vec3 Normal = texture2D(colortex2, texcoord).rgb * 2.0f - 1.0f;

	// float Depth = texture2D(depthtex0, texcoord).r;

	// Fragment frag;
	// frag.albedo = Albedo;
	// frag.normal = Normal;
	// frag.emission = Emission;

	Fragment frag = Fragment(Albedo, Normal, Emission);
	Lightmap lightmap = Lightmap(texture2D(colortex1, texcoord).r, texture2D(colortex1, texcoord).g);

	// vec3 FinalColor2 = calculateLighting(frag);
	vec3 FinalColor = calculateLighting(frag, lightmap);

	// if (depth == 1.0) {
	// 	gl_FragData[0] = Color;
	// 	return;
	// }

	//-----------------------------------------------------------------

	// The Diffuse Light Contribution
	// float DirectLightStrength = dot(Normal, lightVector);
	// DirectLightStrength = max(0.0, DirectLightStrength);

	// float AmbientLightStrength = 0.3;

	// vec3 LitColor = Albedo * (DirectLightStrength + AmbientLightStrength);

	// vec3 FinalColor = mix(LitColor, Albedo, Emission);

	//-----------------------------------------------------------------

	gl_FragData[0] = vec4(FinalColor, 1.0f);

	//-----------------------------------------------------------------
	//Debug

	// gl_FragData[0] = Color;
	// gl_FragData[0] = vec4(Albedo, 1.0f);
	// gl_FragData[0] = vec4(Normal, 1.0f);
	// gl_FragData[0] = vec4(Emission);

	// gl_FragData[0] = texture2D(colortex3, texcoord);
}