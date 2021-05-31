#version 120

varying vec4 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D gaux1;
uniform sampler2D gaux2;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;			

vec3 nvec3(vec4 pos){
    return pos.xyz/pos.w;
}

float cdist(vec2 coord) {
	return max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0;
}

// RAYMATCHING ALGORITHM
// ARGUMENT_1: ray - is the vector from the camera position to the current fragment position
// ARGUMENT_2: normal - is the vector pointing in the direction of the interpolated vertex normal for the current fragment
// ARGUMENT_3: ref_ray - is the reflection ray pointing in the reflected direction of the fragment position
vec4 raymarching(vec3 ray, vec3 normal, vec3 ref_ray){
    // default color
    vec4 color = vec4(0.0);
    
    vec3 vector = ref_ray;

    // starting position where the ray hits the screen (vector from eye to current fragment)
    vec3 start_ray = ray;
    // increment, first point on screen to check for hit
    ray += vector;
    int sr = 0;

    // iteration number for the incrementing the ray
    for (int i = 0; i < 35; i++) {
        // space conversions - we execute a transformation from view space to screen space
        // we project to screen space, perform perspective divide and convert from xy coordinates to screen coordinates
        vec4 start_frag = gbufferProjection * vec4(ray, 1.0);
        vec3 frag = start_frag.xyz / start_frag.w;
        frag = frag * 0.5 + 0.5;
        
        // if the fragment is out of the screen return with default color there is no intersection/reflection
        if (frag.x < 0 || frag.x > 1 || frag.y < 0 || frag.y > 1 || frag.z < 0 || frag.z > 1.0) break;
        // calculate the screen space coordinate for the incremented rays
        // from the depthtex0 we get the distance vector for the fragment
        vec3 spos = vec3(frag.st, texture2D(depthtex0, frag.st).r);
        // convert back the view space
        spos = nvec3(gbufferProjectionInverse * vec4(spos * 2.0 - 1.0, 1.0));
		
        // calculate the deviation
        float err = abs(ray.z - spos.z);
		
        // if the deviation is small enough refine it
        if (err < pow(length(vector) * 1.85, 1.15) && texture2D(gaux2, frag.st).g < 0.01) {
            sr++;
            
            if(sr >= 4){

                float border = clamp(1.0 - pow(cdist(frag.st), 1.0), 0.0, 1.0);
                color = texture2D(composite, frag.st);
                float land = texture2D(gaux1, frag.st).g;
                land = float(land < 0.03);
                spos.z = mix(ray.z, 2000.0 * (0.4 + 1.0 * 0.6), land);
                color.a = 1.0;
                color.a *= border;
                break;

            }

            ray = start_ray;
            vector *= 0.1;
        }

        // increment the ray delta by an even larger number than before
        vector *= 2.2;
        // store the last no-hit in start_ray
        start_ray = ray;
        // sample a different point on screen
        ray += vector;
    }

    return color;

}

void main() {

    // CALL THE RAYMATCHING ALGORITHM
    // with arguments of fragment's position, normal, and reflection about the normal
    
    // ARGUMENT_1: ray - is the vector from the camera position to the current fragment position
    // we know the texture coordinate and how far away from the camera the current point on the ray is, this is given by the depth texture
    // depthtex0 stores the depth information of the screen (it includes water -> stores the coordinate of the water surface)
    vec3 ray = vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r);
    // from the screen space we can tranform the coordinates back to view space
    ray = (gbufferProjectionInverse * vec4(ray * 2.0 - 1.0, 1.0)).xyz / (gbufferProjectionInverse * vec4(ray * 2.0 - 1.0, 1.0)).w;
    // ARGUMENT_2: normal - is the vector pointing in the direction of the interpolated vertex normal for the current fragment
    vec3 normal = normalize(texture2D(gnormal, texcoord.st).rgb * 2.0 - 1.0);
    // ARGUMENT_3: ref_ray - is the reflection ray pointing in the reflected direction of the fragment position -- length of one
    vec3 ref_ray = normalize(reflect(normalize(ray), normal));
    // RAYMATCHING
    vec4 reflection = raymarching(ray, normal, ref_ray);
    
    // take the color information from the texture and mix it with the result of the raymatching algorithm to present reflection on screen
    vec4 color = texture2D(composite, texcoord.st);
    color.rgb = mix(color.rgb, reflection.rgb, reflection.a * (vec3(1.0) - color.rgb) * 1.0);
	
    gl_FragColor = vec4(color.rgb, 0.0);
}
