#version 120

uniform sampler2D depthtex0;

varying vec2 texcoord;

/*
const int colortex1Format = r32f;
*/
const vec4 colortex2ClearColor = vec4(1.0, 0.0, 0.0, 1.0);

const int STEPS = 5;
const float STEP_DIST = 0.01 / float(STEPS);

void main() {
	float depth = 999.0;

	for (int i = -STEPS; i <= STEPS; i++) {
		depth = min(depth, texture2D(depthtex0, texcoord + vec2(i * STEP_DIST, 0.0)).r);
	}

	/* DRAWBUFFERS:1 */
	gl_FragData[0] = vec4(depth, 1.0, 0.0, 1.0);
}