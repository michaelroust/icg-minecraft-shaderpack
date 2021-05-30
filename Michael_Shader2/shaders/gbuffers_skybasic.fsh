#version 120

varying vec3 tintColor;

/* RENDERTARGETS: 0,1 */

void main(){
    gl_FragData[0] = vec4(tintColor, 1.0);
    gl_FragData[1] = vec4(0.0f, 0.0f,0.5f,1.0f);
}


