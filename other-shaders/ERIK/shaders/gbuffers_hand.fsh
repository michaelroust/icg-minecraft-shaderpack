#version 120

uniform sampler2D colortex0;
uniform sampler2D colortex1;

varying vec2 texCoord;
varying vec4 tintColor;
varying vec3 normal;

varying vec4 lmCoord;

void main(){
    vec4 color = texture2D(colortex0, texCoord);
    color *= tintColor;

    /* RENDERTARGETS: 0,1,2 */
    gl_FragData[0] = color;
    gl_FragData[1] = vec4(lmCoord.xy, 0.0, 1.0); // But this lets me see effects in hand
    // gl_FragData[1] = texture2D(colortex1, texcoord); // This is better
    gl_FragData[2] = vec4(normal * 0.5 + 0.5, 1.0);
}
