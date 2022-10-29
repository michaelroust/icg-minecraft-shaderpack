#version 120

uniform sampler2D gcolor; // Value 0
uniform sampler2D gdepth; // Value 1
// uniform sampler2D shadowtex0; // Value 5

uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;

uniform sampler2D shadow;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;


// Direction of the sun (not normalized!)
uniform vec3 sunPosition;


varying vec2 texcoord;

// const int shadowMapResolution = 32;
// const int shadowMapResolution = 1024;
const int shadowMapResolution = 16384;
const float sunPathRotation = -10.0f;

const float shadowBias = 0.001f; // Reasonable values within [0.001, 0.000001]
const float intensityAmbientCoeff = 0.5f;

//============================================================================

float GetShadow(float depth) {
    vec3 ClipSpace = vec3(texcoord, depth) * 2.0f - 1.0f;
    vec4 ViewW = gbufferProjectionInverse * vec4(ClipSpace, 1.0f);
    vec3 View = ViewW.xyz / ViewW.w;
    vec4 World = gbufferModelViewInverse * vec4(View, 1.0f);
    vec4 ShadowSpace = shadowProjection * shadowModelView * World;
    vec3 SampleCoords = ShadowSpace.xyz * 0.5f + 0.5f;
    return step(SampleCoords.z - shadowBias, texture2D(shadowtex0, SampleCoords.xy).r);
}

//============================================================================


/*
Notes:
- shadow, shadowtex0 and etc have coords in shadowSpace (understand conversion)

*/

void main() {
	// vec3 color = texture2D(gcolor, texcoord).rgb;

	// gl_FragData[0] = vec4(color, 1.0); //gcolor

	// -------------------------------------------------

	vec3 TextureColor = texture2D(gcolor, texcoord).rgb;
	float Depth = texture2D(depthtex0, texcoord).r;

	// Skip all calculation for the sky
	if(Depth == 1.0f){
        gl_FragData[0] = vec4(TextureColor, 1.0f);
        return;
    }

	vec3 Albedo = pow(TextureColor, vec3(2.2f));

	//-----------------------------------------------------------------
	// Ambient

	// Basically Albedo = Ambient Lighting Contribution
	vec3 ContribAmbient = intensityAmbientCoeff * Albedo;

	//-----------------------------------------------------------------
	// Diffuse
	// vec3 Normal = normalize(texture2D(gdepth, texcoord).rgb * 2.0f - 1.0f);
	// float NdotL = max(dot(Normal, normalize(sunPosition)), 0.0f);
	// NdotL doesn't behave as expected because it is in eye space!!!

	vec3 ContribDiffuse = Albedo * GetShadow(Depth);

	//-----------------------------------------------------------------
	// Specular
	vec3 ContribSpecular = vec3(0.0f);

	vec3 Color = ContribAmbient + ContribDiffuse + ContribSpecular;

	//-----------------------------------------------------------------
	// Gamma Correction
	Color = pow(Color, vec3(1.0f/ 2.2f));

	//-----------------------------------------------------------------

	// Debugging

	vec3 red = vec3(1.0f, 0.0f, 0.0f);
	vec3 green = vec3(0.0f, 1.0f, 0.0f);
	vec3 blue = vec3(0.0f, 0.0f, 1.0f);

	// color = texture2D(depthtex0, texcoord).rgb;

	// color = texture2D(shadowtex0, texcoord).rgb;
	// color = texture2D(shadow, texcoord).rgb;

	// color = red;
	// color = TextureColor;

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(Color, 1.0);
}
