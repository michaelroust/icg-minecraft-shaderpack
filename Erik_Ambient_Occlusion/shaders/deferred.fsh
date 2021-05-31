#version 120

//Varyings//
varying vec2 texCoord;

//Uniforms//
uniform float far, near;
uniform float aspectRatio;
uniform mat4 gbufferProjection;
uniform sampler2D depthtex0;

//Includes//
#define Bayer4(a)   (Bayer2(  0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer8(a)   (Bayer4(  0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer16(a)  (Bayer8(  0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer32(a)  (Bayer16( 0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer64(a)  (Bayer32( 0.5 * (a)) * 0.25 + Bayer2(a))


//Common Functions//

float Bayer2(vec2 a) {
    a = floor(a);
    return fract(dot(a, vec2(0.5, a.y * 0.75)));
}



float GetLinearDepth(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
}


vec2 OffsetDist(float x) {
	float n = fract(x * 8.0) * 3.1415;
    return vec2(cos(n), sin(n)) * x;
}

float AmbientOcclusion(float dither) {
	float ao = 0.0;

	float depth = texture2D(depthtex0, texCoord).r;
	if(depth >= 1.0) return 1.0;

	float hand = float(depth < 0.56);
	depth = GetLinearDepth(depth);


	float currentStep = 0.2 * dither + 0.2;

	float radius = 0.35;
	float fovScale = gbufferProjection[1][1] / 1.37;
	float distScale = max((far - near) * depth + near, 5.0);
	vec2 scale = radius * vec2(1.0 / aspectRatio, 1.0) * fovScale / distScale;
	float mult = (0.7 / radius) * (far - near) * (hand > 0.5 ? 1024.0 : 1.0);

	for(int i = 0; i < 4; i++) {
		vec2 offset = OffsetDist(currentStep) * scale;
		float angle = 0.0, dist = 0.0;

		for(int i = 0; i < 2; i++){
			float sampleDepth = GetLinearDepth(texture2D(depthtex0, texCoord + offset).r);
			float sample = (depth - sampleDepth) * mult;
			angle += clamp(0.5 - sample, 0.0, 1.0);
			dist += clamp(0.25 * sample - 1.0, 0.0, 1.0);
			offset = -offset;
		}

		ao += clamp(angle + dist, 0.0, 1.0);
		currentStep += 0.2;
	}

	ao *= 0.25;

	return ao;
}


//Program//
void main() {
    float ao = AmbientOcclusion(Bayer64(gl_FragCoord.xy));

    /* DRAWBUFFERS:4 */
    gl_FragData[0] = vec4(ao, 0.0, 0.0, 0.0);
}