#version 120

varying vec2 texCoord;
uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D colortex4;
uniform sampler2D depthtex0;
uniform sampler2D gPosition;
uniform sampler2D noisetex;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform float far, near;

const float ambientOcclusionLevel = 0.0;

const int noiseTextureResolution = 64;



float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

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


float lerp(float a, float b, float f){
    return a + f * (b - a);
}

float readDepth(vec2 coord)
{
	return texture2D(depthtex0, coord).r;
}


vec3 screenToViewPos(vec3 screenPos) {
	vec3 clipPos = screenPos * 2.0 - 1.0;
	vec4 tmp = gbufferProjectionInverse * vec4(clipPos, 1.0);
	vec3 viewPos = tmp.xyz / tmp.w;
	return viewPos;
}

vec3 viewToScreenPos(vec3 viewPos) {
	vec4 tmp = gbufferProjection * vec4(viewPos, 1.0);
	vec3 clipPos = tmp.xyz / tmp.w;
	vec3 screenPos = clipPos * 0.5 + 0.5;
	return screenPos;
}


void main() {
	float ao = 0.0;

	//------------------------------------------------------------------------

	vec3 normal = texture2D(colortex2, texCoord).rgb * 2.0 - 1.0; // View Space
	float depth = readDepth(texCoord);

	vec3 fragScreenPos = vec3(texCoord, depth);

	vec3 randomVec = normalize(vec3(1,0,0)); // TODO Make it actually random
	vec3 tangent = normalize(randomVec - normal * dot(randomVec, normal));
	vec3 bitangent = cross(normal, tangent);
	mat3 TBN = mat3(tangent, bitangent, normal);

	float radius = 1.0;

	//------------------------------------------------------------------------
	// For loop samples

	int numberSamples = 32;

	for (int i = 0; i < numberSamples; i++) {

		float x = (i + 0.5) / float(noiseTextureResolution);
		float y = (floor(float(i) / float(noiseTextureResolution)) + 0.5) / float(noiseTextureResolution);
		vec3 hemisphereSample = texture2D(noisetex, vec2(x, y)).rgb;
		hemisphereSample.xy = hemisphereSample.xy * 2.0 - 1.0;

		hemisphereSample = normalize(hemisphereSample);

		//-----------------------------------------------------
		hemisphereSample = normalize(hemisphereSample);
		float scale = i / 64.0;
		scale   = lerp(0.1, 1.0, scale * scale);
		hemisphereSample *= scale;
		//-----------------------------------------------------

		vec3 sampleInViewSpace = TBN * hemisphereSample; // samplePos in ViewSpace

		vec3 fragViewPos = screenToViewPos(fragScreenPos);

		// Move sample to near the fragment
		sampleInViewSpace = fragViewPos + sampleInViewSpace * radius;

		// NOW transform sampleInViewSpace to ScreenSpace
		vec3 movedSampleInScreenSpace = viewToScreenPos(sampleInViewSpace);

		vec3 offsetPosInScreenSpace = vec3(movedSampleInScreenSpace.xy, readDepth(movedSampleInScreenSpace.xy));
		vec3 offsetPosInViewSpace = screenToViewPos(offsetPosInScreenSpace);

		//-----------------------------------------------------

		// if offsetPosInViewSpace is closer than sampleInViewSpace the sample contributes to occlusion
		ao += (sampleInViewSpace.z + 0.005 <= offsetPosInViewSpace.z ? 0.0 : 1.0);
	}

	ao = ao / numberSamples;

	ao = pow(ao, 1.5);

	// ao=1.0;

	// gl_FragData[0] = vec4(ao/numberSamples);

	// gl_FragData[0] = texture2D(colortex0, texCoord) * ao;
	// gl_FragData[0] = vec4(gammaToGammaSpace(gammaToLinearSpace(texture2D(colortex0, texCoord).rgb) * ao), 1.0);

	//------------------------------------------------------------------------

	/* RENDERTARGETS:N,N,N,N,4 */
    gl_FragData[4] = vec4(ao, 0.0, 0.0, 0.0);
}