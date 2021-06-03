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

vec3 gammaToLinearSpace(vec3 color) {
	return pow(color, vec3(2.2f));
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
	vec3 samples[64];
	float ao = 0.0;


	//generates random vectors for hemisphere
	// for(int i = 0; i < 64; i++){

	// 	float x = i / 8;
	// 	float y = mod(i,8);
	// 	vec3 sample = vec3(
	// 					   texture2D(noisetex, vec2(x, y)).r * 2.0 - 1.0,
	// 					   texture2D(noisetex, vec2(x, y)).g * 2.0 - 1.0,
	// 					   texture2D(noisetex, vec2(x,y)).b);

	// 	//sample = normalize(sample);
	// 	//float scale = float(i) / 64.0;
	// 	//scale   = lerp(0.1, 1.0, scale * scale);
	// 	//sample *= scale;
	// 	samples[i] = sample;
	// }

	// int x = int(texCoord.x);
	// int y = int(texCoord.y);
	// int xy = x * y;
	// float modu  = mod(xy, 64);
	// int a = int(modu);
	// gl_FragData[0] = vec4(samples[a], 1.0);

	// gl_FragData[0] = texture2D(noisetex, vec2(x,y));

	// for(int i = 0; i < 64; ++i) {
	// 	vec4 sample = texture2D(noisetex, texCoord + i);
	// }

	//------------------------------------------------------------------------


	vec3 normal = texture2D(colortex2, texCoord).rgb * 2.0 - 1.0; // View Space
	float depth = readDepth(texCoord);

	vec3 fragScreenPos = vec3(texCoord, depth);

	// vec3 fragPos = getCameraSpacePosition(texCoord, depth).rgb;

	vec3 randomVec = normalize(vec3(1,0,0)); // TODO Make it actually random
	vec3 tangent = normalize(randomVec - normal * dot(randomVec, normal));
	vec3 bitangent = cross(normal, tangent);
	mat3 TBN = mat3(tangent, bitangent, normal);

	float radius = 0.9;

	//------------------------------------------------------------------------
	// For loop samples

	int numberSamples = 64;

	// vec3 hemiSamples[5] = vec3[](
	// 		vec3(0,0,1),
	// 		vec3(0.5, 0.5, 0.5), vec3(-0.5, 0.5, 0.5), vec3(0.5, -0.5, 0.5), vec3(-0.5, -0.5, 0.5)
	// 	);

	vec3 hemiSamples[64] = vec3[](
		vec3(-0.4635, -0.5686, 0.7294),
		vec3(0.4497, 0.6349, 0.5371),
		vec3(-0.1021, -0.9312, 0.8837),
		vec3(0.7449, 0.8846, 0.2518),
		vec3(0.2165, 0.9083, 0.9982),
		vec3(-0.2117, -0.0614, 0.8031),
		vec3(-0.5691, 0.3512, 0.4544),
		vec3(0.3121, 0.2400, 0.6888),
		vec3(0.9693, -0.6746, 0.1404),
		vec3(0.0110, -0.0869, 0.8366),
		vec3(-0.4479, -0.7380, 0.5038),
		vec3(0.5634, -0.4178, 0.8702),
		vec3(0.8675, 0.6075, 0.2390),
		vec3(0.2651, 0.0692, 0.0521),
		vec3(0.6920, 0.3415, 0.4489),
		vec3(-0.5006, -0.9764, 0.4815),
		vec3(-0.3946, 0.3455, 0.5846),
		vec3(-0.9221, -0.0400, 0.7002),
		vec3(0.3486, -0.4383, 0.9014),
		vec3(-0.2011, -0.1460, 0.7734),
		vec3(0.3386, -0.0229, 0.8584),
		vec3(0.9176, 0.3863, 0.7237),
		vec3(0.4438, -0.9149, 0.1935),
		vec3(0.5230, 0.2869, 0.2164),
		vec3(-0.8552, 0.5447, 0.4822),
		vec3(0.1818, -0.0418, 0.1461),
		vec3(0.2574, -0.2619, 0.7889),
		vec3(-0.8998, 0.7765, 0.2891),
		vec3(0.6066, -0.7704, 0.8869),
		vec3(0.9544, -0.6429, 0.3301),
		vec3(-0.0039, 0.3814, 0.9517),
		vec3(-0.1255, 0.8220, 0.9686),
		vec3(0.3684, -0.0279, 0.4677),
		vec3(-0.9433, -0.9848, 0.4076),
		vec3(0.3966, -0.6064, 0.2337),
		vec3(-0.6676, -0.2215, 0.1226),
		vec3(0.6459, -0.3826, 0.7403),
		vec3(-0.7432, 0.9575, 0.4924),
		vec3(0.6356, 0.4105, 0.1937),
		vec3(-0.9365, -0.2512, 0.4406),
		vec3(0.8251, 0.8729, 0.2863),
		vec3(0.6326, 0.0780, 0.8823),
		vec3(-0.9081, 0.7214, 0.8981),
		vec3(0.5411, 0.7913, 0.6763),
		vec3(0.3650, 0.2763, 0.3065),
		vec3(-0.3383, 0.8912, 0.4531),
		vec3(0.2880, -0.1651, 0.1817),
		vec3(0.1789, 0.4037, 0.1091),
		vec3(0.1829, -0.3375, 0.4622),
		vec3(-0.2354, 0.5434, 0.6243),
		vec3(-0.9898, 0.2566, 0.8857),
		vec3(0.4476, -0.7962, 0.7802),
		vec3(-0.8157, 0.1923, 0.4975),
		vec3(-0.7457, 0.0931, 0.1153),
		vec3(0.8127, -0.1205, 0.6161),
		vec3(-0.5357, 0.4545, 0.2322),
		vec3(-0.2391, -0.6752, 0.9611),
		vec3(0.8146, 0.8360, 0.0778),
		vec3(-0.3862, 0.7644, 0.9532),
		vec3(0.2289, -0.7150, 0.2798),
		vec3(-0.7738, -0.5272, 0.6896),
		vec3(0.0018, 0.8874, 0.2174),
		vec3(0.5254, 0.0948, 0.8674),
		vec3(-0.2028, -0.1404, 0.6009)
	);

	for (int i = 0; i < numberSamples; i++) {

		// float x = i / numberSamples;
		// float y = mod(i,numberSamples);
		// vec3 hemisphereSample = texture2D(noisetex, vec2(x, y)).rgb;

		// vec2 noiseSamplePos = texCoord +
		// int  noiseX = int(gl_FragCoord.x - 0.5) % 4;
		// int  noiseY = int(gl_FragCoord.y - 0.5) % 4;
		// vec3 random = noise[noiseX + (noiseY * 4)];

		// vec3 hemisphereSample = vec3(0,0,1);
		vec3 hemisphereSample = hemiSamples[i];
		// hemisphereSample = normalize(hemisphereSample);

		// float noiseX = mod(texCoord.x - 0.5 + (i/noiseTextureResolution), noiseTextureResolution);
		// float noiseY = mod(texCoord.y - 0.5, noiseTextureResolution);
		// vec3 hemisphereSample = texture2D(noisetex, vec2(noiseX, noiseY)).rgb;
		// hemisphereSample.xy = hemisphereSample.xy * 2.0 - 1.0;

		// hemisphereSample = normalize(hemisphereSample);

		// Scaling the sample (i think its optional, for now)
		//-----------------------------------------------------
		// sample = normalize(sample);
		// float scale = 32.0 / 64.0;
		// scale   = lerp(0.1, 1.0, scale * scale);
		// sample *= scale;
		//-----------------------------------------------------


		//---------
		// Before
		// vec3 samplePos = screenPos + TBN * (hemisphereSample * radius); // Sample pos in view-space
		//---------
		// After
		vec3 sampleInViewSpace = TBN * hemisphereSample; // samplePos in ViewSpace

		vec3 fragViewPos = screenToViewPos(fragScreenPos);

		// Move sample to near the fragment
		sampleInViewSpace = fragViewPos + sampleInViewSpace * radius;

		// NOW transform sampleInViewSpace to ScreenSpace
		vec3 movedSampleInScreenSpace = viewToScreenPos(sampleInViewSpace);

		vec3 offsetPosInScreenSpace = vec3(movedSampleInScreenSpace.xy, readDepth(movedSampleInScreenSpace.xy));
		vec3 offsetPosInViewSpace = screenToViewPos(offsetPosInScreenSpace);

		//---------

		ao += (sampleInViewSpace.z + 0.005 <= offsetPosInViewSpace.z ? 0.0 : 1.0);
	}

	ao = ao / numberSamples;

	// ao=1.0;

	// gl_FragData[0] = vec4(ao/numberSamples);

	gl_FragData[0] = texture2D(colortex0, texCoord) * ao;

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