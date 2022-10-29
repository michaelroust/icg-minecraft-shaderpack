#if defined OVERWORLD || defined END
#include "/lib/lighting/shadows.glsl"

vec3 DistortShadow(inout vec3 worldPos, float distortFactor) {
	worldPos.xy /= distortFactor;
	worldPos.z *= 0.2;
	return worldPos * 0.5 + 0.5;
}
#endif

void GetLighting(inout vec3 albedo, out vec3 shadow, vec3 viewPos, vec3 worldPos,
                 vec2 lightmap, float smoothLighting, float NoL, float vanillaDiffuse,
                 float parallaxShadow, float emissive, float foliage) {

    #if defined OVERWORLD || defined END
    #if SHADOW_PIXEL > 0
    worldPos = floor((worldPos + cameraPosition) * SHADOW_PIXEL + 0.01) /
               SHADOW_PIXEL - cameraPosition;
    #endif
    
    vec3 shadowPos = ToShadow(worldPos);

    float distb = sqrt(dot(shadowPos.xy, shadowPos.xy));
    float distortFactor = distb * shadowMapBias + (1.0 - shadowMapBias);
    shadowPos = DistortShadow(shadowPos, distortFactor);

    float doShadow = float(
        shadowPos.x > 0.0 && shadowPos.x < 1.0 &&
        shadowPos.y > 0.0 && shadowPos.y < 1.0
    );

    #ifdef OVERWORLD
    doShadow *= float(lightmap.y > 0.001);
    #endif
    
    if ((NoL > 0.0 || foliage > 0.5)) {
        if (doShadow > 0.5) {
            float biasFactor = sqrt(1.0 - NoL * NoL) / NoL;
            float distortBias = distortFactor * shadowDistance / 256.0;
            distortBias *= 8.0 * distortBias;
            float distanceBias = sqrt(dot(worldPos.xyz, worldPos.xyz)) * 0.005;
            
            float bias = (distortBias * biasFactor + distanceBias + 0.05) / shadowMapResolution;
            float offset = 1.0 / shadowMapResolution;

            if (foliage > 0.5) {
                bias = 0.0002;
                offset = 0.0007;
            }

            #if SHADOW_PIXEL > 0
            bias += 0.0025 / SHADOW_PIXEL;
            #endif
            
            shadow = GetShadow(shadowPos, bias, offset);
        } else shadow = vec3(lightmap.y);
    }
    
    shadow *= parallaxShadow;
    vec3 fullShadow = shadow * max(NoL * 1.01 - 0.01, foliage);
    
    #ifdef OVERWORLD
    float shadowMult = (1.0 - 0.95 * rainStrength) * shadowFade;
    vec3 sceneLighting = mix(ambientCol, lightCol, fullShadow * shadowMult);
    sceneLighting *= (4.0 - 3.0 * eBS) * lightmap.y * lightmap.y;
    #endif

    #ifdef END
    vec3 sceneLighting = endCol.rgb * (0.075 * fullShadow + 0.025);
    #endif

    if (foliage > 0.5){
        float VdotL = clamp(dot(normalize(viewPos.xyz), lightVec), 0.0, 1.0);
        float subsurface = pow(VdotL, 25.0) * (1.0 - rainStrength);
        sceneLighting *= fullShadow * subsurface + 1.0;
    }
    #else
    vec3 sceneLighting = netherColSqrt.rgb * 0.1;
    #endif

    vanillaDiffuse *= foliage * 0.8 + 1.0;
    
    float newLightmap  = pow(lightmap.x, 10.0) * (EMISSIVE_BRIGHTNESS + 0.5) + lightmap.x * 0.7;
    vec3 blockLighting = blocklightCol * newLightmap * newLightmap;

    vec3 minLighting = minLightCol * (1.0 - eBS);
    //minLighting = 0.0;

    #ifdef TOON_LIGHTMAP
    minLighting *= floor(smoothLighting * 8.0 + 1.001) / 4.0;
    smoothLighting = 1.0;
    #endif
    
    vec3 emissiveColor = sqrt(albedo * length(albedo) + vec3(0.00001));
    vec3 emissiveLighting = emissiveColor * (emissive * 4.0 / vanillaDiffuse);
    
    float nightVisionLighting = nightVision * 0.25;
    
    albedo *= sceneLighting + blockLighting + emissiveLighting + nightVisionLighting + minLighting;
    albedo *= vanillaDiffuse * smoothLighting * smoothLighting;

    #ifdef DESATURATION
    #ifdef OVERWORLD
    float desatAmount = sqrt(max(sqrt(length(fullShadow / 3.0)) * lightmap.y, lightmap.y)) *
                        sunVisibility * (1.0 - rainStrength * 0.4) + sqrt(lightmap.x + emissive);

    vec3 desatNight   = lightNight / LIGHT_NI;
    vec3 desatWeather = weatherCol.rgb / weatherCol.a * 0.5;

    desatNight *= desatNight; desatWeather *= desatWeather;
    
    float desatNWMix  = (1.0 - sunVisibility) * (1.0 - rainStrength);

    vec3 desatColor = mix(desatWeather, desatNight, desatNWMix);
    desatColor = mix(vec3(0.1), desatColor, sqrt(lightmap.y)) * 10.0;
    #endif

    #ifdef NETHER
    float desatAmount = sqrt(lightmap.x + emissive);

    vec3 desatColor = netherColSqrt.rgb / netherColSqrt.a;
    #endif

    #ifdef END
    float desatAmount = sqrt(lightmap.x + emissive);

    vec3 desatColor = endCol.rgb * 1.25;
    #endif

    desatAmount = clamp(desatAmount, DESATURATION_FACTOR * 0.4, 1.0);
    desatColor *= 1.0 - desatAmount;

    albedo = mix(GetLuminance(albedo) * desatColor, albedo, desatAmount);
    #endif
}