#version 120

uniform sampler2D colortex1;

varying vec2 texcoord;

const int STEPS = 5;
const float STEP_DIST = 0.01 / float(STEPS);

void main() {
	float depth = 999.0;

	for (int i = -STEPS; i <= STEPS; i++) {
		depth = min(depth, texture2D(colortex1, texcoord + vec2(0.0, i * STEP_DIST)).r);
	}

	/* DRAWBUFFERS:1 */
	gl_FragData[0] = vec4(depth, 1.0, 0.0, 1.0);
}