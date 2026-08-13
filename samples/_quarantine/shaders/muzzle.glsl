// WebGPU / WebGL fallback muzzle — same contract as MuzzleFlash.shader
precision mediump float;
uniform sampler2D uFlash;
uniform vec3 uColor;
uniform float uIntensity;
uniform float uAge;
varying vec2 vUv;
void main() {
  vec4 t = texture2D(uFlash, vUv);
  float fade = 1.0 - clamp(uAge, 0.0, 1.0);
  fade *= fade;
  gl_FragColor = t * vec4(uColor, 1.0) * uIntensity * fade;
}
