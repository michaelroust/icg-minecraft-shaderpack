#version 120

uniform sampler2D lightmap;
uniform sampler2D texture;
uniform vec4 entityColor;

varying vec2 lmCoord;
varying vec2 texCoord;
varying vec4 tintColor;

varying vec3 normal;


void main() {
	vec4 color = texture2D(texture, texCoord) * tintColor;
	color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);

	/* RENDERTARGETS: 0,1,2 */
	gl_FragData[0] = color;
	gl_FragData[1] = vec4(lmCoord, 0.0f, 0.0f);
	gl_FragData[2] = vec4(normal * 0.5 + 0.5, 1.0);;
}