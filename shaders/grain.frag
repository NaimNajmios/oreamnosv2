#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uSeed;

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7)) + uSeed) * 43758.5453123);
}

void main() {
  vec2 coord = FlutterFragCoord().xy;
  float noise = hash(floor(coord / 2.0));
  fragColor = vec4(vec3(noise), noise * 0.12);
}
