#version 120

//Varyings//
varying vec2 texCoord;

//Program//
void main() {
	texCoord = gl_MultiTexCoord0.xy;
	gl_Position = ftransform();
}
