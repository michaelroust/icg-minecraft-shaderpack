#version 120

varying vec4 texCoord;
varying vec3 tintColor;

varying vec3 normal;

varying vec4 lmCoord;

void main(){
    gl_Position = ftransform();
    texCoord = gl_MultiTexCoord0;
    tintColor = gl_Color.rgb;

    // Note
    // gl_MultiTexCoord1.r  Contains Torch Light Strength
    // gl_MultiTexCoord1.g  Contains Sky Light Strength
    //                      both are stored in range [0-16] or [0-256] depending on MC version.
    //                      Adaptive conversion below

    // Reading and rescaling lightmap to [0-1] range
    vec2 LightmapCoords = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    lmCoord.xy = (LightmapCoords * 33.05f / 32.0f) - (1.05f / 32.0f);

    // Normal in eye/camera space
    normal = normalize(gl_NormalMatrix * gl_Normal);
}
