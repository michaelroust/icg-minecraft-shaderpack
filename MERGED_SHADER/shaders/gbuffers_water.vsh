#version 120

varying vec4 tintColor;
varying vec2 lmcoord;
varying vec3 normal;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

#define WAVING_WATER
#ifdef WAVING_WATER
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
const float PI = 3.1415927;
#endif

/////////////////////////////////////////////////////
// CODE FROM 3RD PARTY LIBRARY
/////////////////////////////////////////////////////
// we were asked to modify coordinates based on noise, we used a 3rd party library provided to us by TAs
// based on webgl noise library for other approach than sinusodial
// see this repository: https://github.com/ashima/webgl-noise/blob/master/src/noise2D.glsl
//#define NOISY_WATER
#ifdef NOISY_WATER
vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}
vec2 mod289(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}
vec3 permute(vec3 x) {
  return mod289(((x*34.0)+1.0)*x);
}

float snoise(vec2 v)
  {
  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                     -0.577350269189626,  // -1.0 + 2.0 * C.x
                      0.024390243902439); // 1.0 / 41.0
// First corner
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);

// Other corners
  vec2 i1;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

// Permutations
  i = mod289(i); // Avoid truncation effects in permutation
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
		+ i.x + vec3(0.0, i1.x, 1.0 ));

  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;

// Gradients: 41 points uniformly over a line, mapped onto a diamond.
// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;

// Normalise gradients implicitly by scaling m
// Approximation of: m *= inversesqrt( a0*a0 + h*h );
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

// Compute final noise value at P
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 6 * dot(m, g);
}
#endif

/////////////////////////////////////////////////////
// CODE ENDS FROM 3RD PARTY LIBRARY
/////////////////////////////////////////////////////

//============================================================================
/*
* Calculates normals, modifies the vertex coordinates for wavy water
*/
void main() {

	// transformation to world coordinates to calculate displacement of vertices heights,
	// i.e. y coordinate, depth information
	vec4 frag_viewPos = gl_ModelViewMatrix * gl_Vertex;
	vec4 frag_eyePos = gbufferModelViewInverse * frag_viewPos;
	vec4 frag_feetPos = gbufferModelView * frag_eyePos;

	// sinusodial approach
	#ifdef WAVING_WATER
	vec3 frag_worldPos = frag_feetPos.xyz + cameraPosition;
	float fy = fract(frag_worldPos.y + 0.1);
	float wave = 0.05 * sin(2 * PI * (frameTimeCounter * 0.75 + frag_worldPos.x /  7.0 + frag_worldPos.z / 13.0))
				   + 0.05 * sin(2 * PI * (frameTimeCounter * 0.6 + frag_worldPos.x / 11.0 + frag_worldPos.z /  5.0));
	float displacement = clamp(wave, -fy, 1.0 - fy);
	frag_feetPos.y += displacement;
	#endif

	// webgl-noise library 2D noise calculation for diplacement of vertices
	#ifdef NOISY_WATER
	frag_feetPos.y += snoise(vec2(frag_feetPos.x, frag_feetPos.y));
	#endif

	gl_Position = gl_ProjectionMatrix * frag_feetPos;

	// store water color info and normals
	tintColor = gl_Color;
	normal = normalize(gl_NormalMatrix * gl_Normal);
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;

}