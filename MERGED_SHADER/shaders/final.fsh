#version 120

varying vec4 texcoord;

uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D colortex4;
uniform sampler2D colortex5;

uniform sampler2D depthtex0;

////////////     RAYTRACING       ////////////

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

const float stp = 1.2;
const float ref = 0.1;
const float inc = 2.2;
const int maxf = 4;

vec3 nvec3(vec4 pos){
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos){
    return vec4(pos.xyz, 1.0);
}

float cdist(vec2 coord) {
	return max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0;
}


vec4 raytrace(vec3 fragpos, vec3 normal){

    float wave = 0.0;
	vec3 aux = texture2D(colortex4, texcoord.st).rgb;
	if(aux.g > 0.01 && aux.g < 0.07) {
		wave = 1.;
	}
	vec4 nm = vec4(0.0, wave, 0.0, 0.0);

    vec4 color = vec4(0.0);
    vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
    vec3 vector = stp * rvector;
    vec3 oldpos = fragpos;
    fragpos += vector;
    int sr = 0;
    for(int i = 0; i < 40; i++){
        vec3 pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
        if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
        vec3 spos = vec3(pos.st, texture2D(depthtex0, pos.st).r);
        spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
		float err = abs(fragpos.z-spos.z);
		if(err < pow(length(vector)*1.85,1.15) && texture2D(colortex5,pos.st).g < 0.01){
                sr++;
                if(sr >= maxf){
                    float border = clamp(1.0 - pow(cdist(pos.st), 1.0), 0.0, 1.0);
                    color = texture2D(colortex0, pos.st);
					float land = texture2D(colortex4, pos.st).g;
					land = float(land < 0.03);
					spos.z = mix(fragpos.z,2000.0*(0.4+1.0*0.6),land);
					color.a = 1.0;
                    color.a *= border;
                    break;
                }
                fragpos = oldpos;
                vector *=ref;
        }
        vector *= inc;
        oldpos = fragpos;
        fragpos += vector;
    }
    return color;
}

////////////     RAYTRACING       ////////////


//------------MAIN----------------

void main() {

	vec4 color = texture2D(colortex0, texcoord.st);
    gl_FragColor = vec4(color.rgb, 0.0);

    #define REFLECTIONS
    #ifdef REFLECTIONS
    float wave = texture2D(colortex5,texcoord.xy).g;
    if (wave > 0.0) {
        vec3 fragpos = vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r);

        fragpos = nvec3(gbufferProjectionInverse * nvec4(fragpos * 2.0 - 1.0));

        vec3 normal = texture2D(colortex2, texcoord.st).rgb * 2.0 - 1.0;

        vec4 reflection = raytrace(fragpos, normalize(normal));

        color.rgb = mix(color.rgb, reflection.rgb, reflection.a * (vec3(1.0) - color.rgb) * 1.0);
    }
    #endif

    gl_FragColor = vec4(color.rgb, 0.0);
}