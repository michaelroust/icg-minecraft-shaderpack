//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

varying vec2 texCoord;

//Program//
void main() {
    gl_FragData[0] = vec4(0.0, 0.0, 1.0, 1.0);
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

varying vec2 texCoord;

uniform mat4 gbufferModelView, gbufferModelViewInverse;

//Program//
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;    
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
}

#endif