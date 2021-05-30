#version 120

uniform sampler2D colortex1;

uniform sampler2D lightmap;
uniform sampler2D texture;
uniform vec4 entityColor;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

varying vec3 normal;


void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;
	color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
	color *= texture2D(lightmap, lmcoord);


	/* RENDERTARGETS: 0,1,2 */
	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(lmcoord, 0.0f, 0.0f);
	gl_FragData[2] = vec4(normal * 0.5 + 0.5, 1.0);;

}