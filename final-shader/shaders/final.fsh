#version 120

varying vec4 texcoord;

uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D colortex4;
uniform sampler2D colortex5;

uniform sampler2D depthtex0;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

//============================================================================
// Ray Marching Parameters

const int rough_pass_iteration = 35;
const int fine_pass_iteration = 5;
const float rough_increment = 2.0;
const float fine_increment = 0.1;

//============================================================================
// RAYMATCHING ALGORITHM
// ARGUMENT_1: ray - is the vector from the camera position to the current fragment position
// ARGUMENT_2: normal - is the vector pointing in the direction of the interpolated vertex normal for the current fragment
// ARGUMENT_3: ref_ray - is the reflection ray pointing in the reflected direction of the fragment position
// arguments are in view space
vec4 raymarching(vec3 fwd_ray_viewPos, vec3 normal, vec3 ref_ray_viewPos){
    // default color
    vec4 color = vec4(0.0);
    // ray position to sample for hit, currently the reflected ray has unit length
    // it will be incremented in each iteration
    vec3 ray_viewPos = fwd_ray_viewPos + ref_ray_viewPos;
    int fine_pass = 0;

    // ROUGH PASS
    // iteration number for incrementing the length of the reflected ray
    // max iteration determines the max length of the reflected vector, how far reflection can appear
    // samples a different fragment for hit in each iteration
    for (int i = 0; i < rough_pass_iteration; i++) {
        // transformation from view space to screen space
        // transform the possible intersection point, the ray to screen space
        vec4 ray_clipPos = gbufferProjection * vec4(ray_viewPos, 1.0);
        vec3 tmp1 = ray_clipPos.xyz / ray_clipPos.w;
        vec3 ray_screenPos = tmp1 * 0.5 + 0.5;
        
        // if the fragment is out of the screen return with default color there is no intersection/reflection
        if (   ray_screenPos.x < 0  ||  ray_screenPos.x > 1.0
            || ray_screenPos.y < 0  ||  ray_screenPos.y > 1.0
            || ray_screenPos.z < 0  ||  ray_screenPos.z > 1.0) break;
        
        // otherwise
        // check the exact/real depth coordinates at the xy coordinates of the sampled ray position
        // from the depthtex0 we get the distance vector for the sampled fragment
        // convert back the real position on screen from screen space to view space
        vec3 real_screenPos = vec3(ray_screenPos.st, texture2D(depthtex0, ray_screenPos.st).r);
        vec3 real_clipPos = real_screenPos * 2.0 - 1.0;
        vec4 tmp2 = gbufferProjectionInverse * vec4(real_clipPos, 1.0);
        vec3 real_viewPos = tmp2.xyz / tmp2.w;

        // FINE PASS
        // if the deviation of the sampled position depth and the real depth is smaller than
        // the other increment by the vector in the next iteration and
        // the sampled position is not water then start the refinement pass
        if (    abs(ray_viewPos.z - real_viewPos.z) < pow(length(ref_ray_viewPos) * 1.85, 1.10)
                && texture2D(colortex5, ray_screenPos.st).g < 0.01) {
            
            // determines the refinement iteration number
            if(fine_pass >= fine_pass_iteration) {

                // sample the color texture at the sample position
                color = texture2D(colortex0, ray_screenPos.st);
                // adjust the depth depending on the lightmap
                float land = texture2D(colortex4, ray_screenPos.st).g;
                land = float(land < 0.01);
                real_screenPos.z = mix(ray_viewPos.z, 2000.0, land);

                // adjust visibility at borders
                float border = clamp(1.0 -
                    pow(max(abs(ray_screenPos.s - 0.5), abs(ray_screenPos.t - 0.5)) * 2.0,
                    1.0),
                    0.0, 1.0);
                color.a *= border;
                break;

            }

            // adjust the next iteration increment for the fine pass
            fine_pass++;
            ray_viewPos = fwd_ray_viewPos;
            ref_ray_viewPos *= fine_increment;
        }

        // increment the ray delta by a larger number than before
        ref_ray_viewPos *= rough_increment;
        // store the last no-hit in start_ray
        fwd_ray_viewPos = ray_viewPos;
        // sample a different point on screen
        ray_viewPos += ref_ray_viewPos;
    }

    return color;
}

//============================================================================
/*
/* Calculates reflection on water surface
*/
void main() {
    // Read the color of the fragment from the colortex0 texture
	vec4 color = texture2D(colortex0, texcoord.st);

    #define REFLECTIONS
    #ifdef REFLECTIONS
    // Calculate reflection for water entities only, get the information out from the colortex5 texture
    bool water = texture2D(colortex5, texcoord.xy).g > 0.0 ? true : false;
    if (water) {
        // ARGUMENT_1:
        // ray - is the vector from the camera position to the current fragment position
        // we know the fragment coordinate in screen space and how far away from the camera the current point on the ray is,
        // this is given by the depth texture, depthtex0 stores the depth information of the screen (it includes water -> stores the coordinate of the water surface)
        // coordinates are stored in screen space, we need to tranform the coordinates back to view space
        // transformation from screen space to view space
        vec3 fwd_ray_screenPos = vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r);
        vec3 fwd_ray_clipPos = fwd_ray_screenPos * 2.0 - 1.0;
        vec4 tmp = gbufferProjectionInverse * vec4(fwd_ray_clipPos, 1.0);
        vec3 fwd_ray_viewPos = tmp.xyz / tmp.w;
        // ARGUMENT_2:
        // normal - is the vector pointing in the direction of the interpolated vertex normal for the current fragment
        // it has been stored previously in colortex2 texture and can be sampled now
        vec3 normal = normalize(texture2D(colortex2, texcoord.st).rgb * 2.0 - 1.0);
        // ARGUMENT_3:
        // ref_ray - is the reflection ray pointing in the reflected direction of the fragment position -- length of one
        vec3 ref_ray_viewPos = normalize(reflect(normalize(fwd_ray_viewPos), normal));
        
        // CALL THE RAYMARCHING ALGORITHM
        // with arguments of fragment's position, normal, and reflection about the normal in view space
        vec4 reflection = raymarching(fwd_ray_viewPos, normal, ref_ray_viewPos);

        // mix the previously stored color with the reflected color
        color.rgb = mix(color.rgb, reflection.rgb, reflection.a * (vec3(1.0) - color.rgb) * 1.0);
    }
    #endif

    gl_FragColor = vec4(color.rgb, 0.0);
}