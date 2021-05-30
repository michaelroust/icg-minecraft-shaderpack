#version 120

uniform sampler2D colortex0;

varying vec4 texcoord;
varying vec3 tintColor;

varying vec3 normal;

varying vec4 lmcoord;

/* RENDERTARGETS: 0,1,2 */

void main() {
    vec4 Color = texture2D(colortex0, texcoord.st);
    Color.rgb *= tintColor;

    gl_FragData[0] = Color;
    // gl_FragData[1] = vec4(0.0f);
    gl_FragData[1] = vec4(lmcoord.xy, 0.0, 0.0);
    gl_FragData[2] = vec4(normal * 0.5f + 0.5f, 1.0f);
}
