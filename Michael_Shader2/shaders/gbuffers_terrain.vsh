#version 120

varying vec4 texcoord;
varying vec3 tintColor;

varying vec3 normal;

varying vec4 lmcoord;

void main(){
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0;
    tintColor = gl_Color.rgb;

    // lmcoord = gl_MultiTexCoord1;
    vec2 LightmapCoords = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    lmcoord.xy = (LightmapCoords * 33.05f / 32.0f) - (1.05f / 32.0f);

    // Here normal is the normal in eyeSpace
    normal = normalize(gl_NormalMatrix * gl_Normal);
}
