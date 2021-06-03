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

// vec3 gammaToLinearSpace(vec3 color) {
// 	return pow(color, vec3(2.2f));
// }

vec3 gammaToLinearSpace(vec3 color) {
	return pow(color, vec3(2.4f));
}

vec3 gammaToGammaSpace(vec3 color) {
	return pow(color, vec3(1.0f/2.4f));
}


float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
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



vec3 nvec3(vec4 pos){
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos){
    return vec4(pos.xyz, 1.0);
}

vec4 getCameraSpacePosition(in vec2 coord, in float depth) {
	// Normalized Device Coordinates
	vec4 posNdcSpace = vec4(vec3(coord.x, coord.y, depth) * 2.0 - 1.0, 1.0); // ndcSpace = clipSpace
	vec4 posCameraSpace = gbufferProjectionInverse * posNdcSpace;

	return posCameraSpace / posCameraSpace.w;
}

/* RENDERTARGETS:0,N,N,N,4 */

float readDepth(vec2 coord)
{
//   float z = texture2D(depthtex0, coord).r;
//   float z_n = 2.0 * z - 1.0;
//   return (2.0 * near) / (far + near - z * (far-near));
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

	float radius = 2.0;

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

	ao = pow(ao, 2.3);

	// ao=1.0;

	// gl_FragData[0] = vec4(ao/numberSamples);

	// gl_FragData[0] = texture2D(colortex0, texCoord) * ao;
	gl_FragData[0] = vec4(gammaToGammaSpace(gammaToLinearSpace(texture2D(colortex0, texCoord).rgb) * ao), 1.0);

	//------------------------------------------------------------------------


  /*
	vec4 texColor = texture2D(colortex0, texCoord);
	vec3 normal = texture2D(colortex2, texCoord).rgb * 2.0 - 1.0;
	float depth = readDepth(texCoord);
	vec3 randomVec = texture2D(noisetex, texCoord).xyz;
  	randomVec = normalize(randomVec);
	vec3 fragPos = getCameraSpacePosition(texCoord, depth).rgb;


	vec3 tangent   = normalize(randomVec - normal * dot(randomVec, normal));
	vec3 bitangent = cross(normal, tangent);
	mat3 TBN       = mat3(tangent, bitangent, normal);
	float radius = 0.5;


	for(int i = 0; i < 64; ++i)
	{
	 // get sample position
	float bias = 0.0;
    vec3 samplePos = TBN * samples[i]; // from tangent to view-space

    samplePos   = fragPos + samplePos * radius;
    vec4 offset = vec4(samplePos, 1.0);
    offset      = gbufferProjection * offset;    // from view to clip-space
    offset.xyz /= offset.w;               // perspective divide
    offset.xyz  = offset.xyz; // transform to range 0.0 - 1.0
    float sampleDepth = readDepth(offset.xy);
    ao += (sampleDepth >= samplePos.z + bias ? 0.05 : 0.0);
	}

	*/
    gl_FragData[4] = vec4(ao, 0.0, 0.0, 0.0);
}