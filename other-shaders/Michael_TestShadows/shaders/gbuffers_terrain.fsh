#version 120

//============================================================================

//----------------------------------------------------------------------------
// Varyings

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

varying vec3 Normal;

//----------------------------------------------------------------------------
// Uniforms

uniform sampler2D texture;
uniform sampler2D lightmap;

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

/* RENDERTARGETS: 0,2 */

//============================================================================

void main() {
	vec4 TextureColor = texture2D(texture, texcoord) * glcolor;
	vec4 LightmapColor = texture2D(lightmap, lmcoord);

	gl_FragData[0] = TextureColor * LightmapColor;
	gl_FragData[2] = vec4(Normal * 0.5f + 0.5f, 1.0f);
}

//============================================================================
