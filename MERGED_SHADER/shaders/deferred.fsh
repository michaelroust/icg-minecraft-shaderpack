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

#define AO_DETAIL 128
#define AO_STRENGTH 1.25

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



float computeAO(float depth){

	float ao = 0.0;

    vec3 normal = texture2D(colortex2, texCoord).rgb * 2.0 - 1.0; // View Space
	vec3 fragScreenPos = vec3(texCoord, depth);
	
	// adds random rotation to rotate the sample kernel
	vec3 randomVec = normalize(texture2D(depthtex0, texCoord).xyz);
	vec3 tangent = normalize(randomVec - normal * dot(randomVec, normal));
	vec3 bitangent = cross(normal, tangent);

	// transforms hemisphere from tangent space
	mat3 TBN = mat3(tangent, bitangent, normal);

	int numberSamples = AO_DETAIL;
	float radius = 1.25;

	for (int i = 0; i < numberSamples; i++) {

		float x = (i + 0.5) / float(noiseTextureResolution);
		float y = (floor(float(i) / float(noiseTextureResolution)) + 0.5) / float(noiseTextureResolution);
		
		vec3 hemisphereSample = texture2D(noisetex, vec2(x, y)).rgb;
		
		// map it onto unit hemisphere in tangent space
		hemisphereSample.xy = hemisphereSample.xy * 2.0 - 1.0;


		hemisphereSample = normalize(hemisphereSample);

		float scale = i / numberSamples;
		scale   =  mix(0.1, 1.0, scale * scale);
		hemisphereSample *= scale;

		vec3 sampleInViewSpace = TBN * hemisphereSample; // samplePos in ViewSpace
		vec3 fragViewPos = screenToViewPos(fragScreenPos);

		// Move sample to near the fragment
		sampleInViewSpace = fragViewPos + sampleInViewSpace * radius;

		// transform sampleInViewSpace to ScreenSpace
		vec3 movedSampleInScreenSpace = viewToScreenPos(sampleInViewSpace);
		
		vec3 offsetPosInScreenSpace = vec3(movedSampleInScreenSpace.xy, texture2D(depthtex0,movedSampleInScreenSpace.xy).r);
		vec3 offsetPosInViewSpace = screenToViewPos(offsetPosInScreenSpace);

		float sampleDepth = offsetPosInViewSpace.z;

		// if offsetPosInViewSpace is closer than the sampleInViewSpace the sample contributes to occlusion
		ao += (sampleInViewSpace.z + 0.01 <= sampleDepth ? 0.0 : 1.0);
	}

	ao = ao / numberSamples;
	return pow(ao, AO_STRENGTH);

}


void main() {

	#define AO

	#ifdef AO
		float depth = texture2D(depthtex0, texCoord).r;
		float ao = computeAO(depth);
	#else
		float ao = 1.0;
	#endif
		/* RENDERTARGETS:N,N,N,N,4 */
		gl_FragData[4] = vec4(ao, 0.0, 0.0, 0.0);
}