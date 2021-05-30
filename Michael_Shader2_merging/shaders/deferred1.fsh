#version 120

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////

//Varyings//
varying vec2 texCoord;


//Uniforms//
uniform float far, near;
uniform float viewWidth, viewHeight, aspectRatio;


uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D depthtex0;
const bool colortex4MipmapEnabled = true;

#define AO_STRENGTH 1.5

//Common Variables//


//Program//
void main() {
    vec4 color      = texture2D(colortex0, texCoord);
	float z         = texture2D(depthtex0, texCoord).r;

	if (z < 1.0) {
		color.rgb *= texture2D(colortex4, texCoord).r;
	}

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = color;

}



