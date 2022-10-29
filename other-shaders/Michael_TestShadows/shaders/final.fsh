#version 120

varying vec2 texcoord;

uniform sampler2D colortex0;

void main() {
    vec3 Color = texture2D(colortex0, texcoord).rgb;
    gl_FragColor = vec4(Color, 1.0f);

    // Sample and apply gamma correction
    // vec3 Color = pow(texture2D(colortex0, texcoord).rgb, vec3(1.0f / 2.2f));
}