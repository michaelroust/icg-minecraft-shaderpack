#version 120

varying vec2 texcoord;
varying vec4 texColor;
varying vec3 normal;


void main() {
    gl_Position = ftransform();
    normal = normalize(gl_NormalMatrix * gl_Normal);

    texcoord = gl_MultiTexCoord0.xy;
    texColor = gl_Color;
}