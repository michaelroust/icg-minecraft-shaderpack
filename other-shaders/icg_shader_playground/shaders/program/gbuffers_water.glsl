//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

varying vec2 texCoord;

uniform sampler2D colortex0;

//Program//
void main() {
	// The internal shaders outputs it's color to a texture called `colortex0`.

    gl_FragData[0] = vec4(0.0, 0.0, 1.0, 1.0);
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

varying vec2 texCoord;

uniform mat4 gbufferModelView, gbufferModelViewInverse;

//Program//
void main() {
	texCoord = gl_MultiTexCoord0.st; // texture coordinate attribute
	gl_Position = ftransform(); // gl_ModelViewProjectionMatrix * gl_Vertex, gl_Vertex is in clip space already
}

#endif