#version 120

varying vec4 texcoord;

void main() {
	// ftransform basically expands to gl_ModelViewProjectionMatrix * gl_Vertex. gl_Vertex is the in-built vertex attribute.`gl_ModelViewProjectionMatrix` is the in-build model view projection matrix.
	gl_Position = ftransform();
	// gl_MultiTexCoord0 is the in-built texture coordinate attribute, in built texture coordinates are vec4
	texcoord = gl_MultiTexCoord0;
}
