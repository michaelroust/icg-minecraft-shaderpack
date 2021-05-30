#version 120

varying vec2 texcoord;
varying vec4 texColor;
varying vec3 normal;

varying vec4 lmcoord;

void main() {
    gl_Position = ftransform();
    normal = normalize(gl_NormalMatrix * gl_Normal);

    vec2 LightmapCoords = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    lmcoord.xy = (LightmapCoords * 33.05f / 32.0f) - (1.05f / 32.0f);

    texcoord = gl_MultiTexCoord0.xy;
    texColor = gl_Color;
}