#version 120



//Optifine Constants//
/*
colortex0Format:RGBA16
colortex2Format:RGB16
colortex3Format:RGBA16;
colortex4Format:RGBA16
*/

varying vec2 texcoord;

uniform sampler2D colortex0;

void main() {
    vec4 Color = texture2D(colortex0, texcoord);
    gl_FragColor = Color;
}