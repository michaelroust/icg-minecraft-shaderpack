void GetMaterials(out float smoothness, out float metalness, out float f0, inout float emissive,
                  out float ao, out vec3 normalMap, vec2 newCoord, vec2 dcdx, vec2 dcdy) {
    vec4 specularMap = texture2DGradARB(specular, newCoord, dcdx, dcdy);

    #if MATERIAL_FORMAT == 0
    smoothness = specularMap.r;
    
    metalness = specularMap.g;
    f0 = 0.02;

    emissive = mix(specularMap.b * specularMap.b, 1.0, emissive);
    ao = 1.0;

	normalMap = texture2DGradARB(normals, newCoord, dcdx, dcdy).xyz * 2.0 - 1.0;
    if (normalMap.x + normalMap.y < -1.999) normalMap = vec3(0.0, 0.0, 1.0);
    #endif

    #if MATERIAL_FORMAT == 1
    smoothness = specularMap.r;

    f0 = specularMap.g;
    metalness = f0 >= 0.9 ? 1.0 : 0.0;

    emissive = mix(specularMap.a < 1.0 ? specularMap.a * specularMap.a : 0.0, 1.0, emissive);
    ao = texture2DGradARB(normals, newCoord, dcdx, dcdy).z;

	normalMap = vec3(texture2DGradARB(normals, newCoord, dcdx, dcdy).xy, 0.0) * 2.0 - 1.0;
    if (normalMap.x + normalMap.y > -1.999) {
        if (length(normalMap.xy) > 1.0) normalMap.xy = normalize(normalMap.xy);
        normalMap.z = sqrt(1.0 - dot(normalMap.xy, normalMap.xy));
        normalMap = normalize(clamp(normalMap, vec3(-1.0), vec3(1.0)));
    }else{
        normalMap = vec3(0.0, 0.0, 1.0);
        ao = 1.0;
    }
    #endif

    vec2 mipx = dcdx * atlasSize;
    vec2 mipy = dcdy * atlasSize;
    float delta = max(dot(mipx, mipx), dot(mipy, mipy));
    float miplevel = max(0.25 * log2(delta), 0.0);
    
    normalMap = normalize(mix(vec3(0.0, 0.0, 1.0), normalMap, 1.0 / exp2(miplevel)));
}