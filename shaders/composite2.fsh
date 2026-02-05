#version 120

uniform sampler2D colortex0; // color
uniform sampler2D colortex2; // normal
uniform sampler2D depthtex0; // depth
uniform sampler2D colortex1; // min depth

varying vec2 texcoord;

uniform bool hideGUI;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform vec3 cameraPositionFract;

#define VOXEL_SCALE 16.0 // [1.0 2.0 4.0 8.0 16.0 32.0 64.0 128.0]
float VOXEL_SCALE_INV = 1.0 / VOXEL_SCALE;

vec3 screenToViewPos(vec3 screenPos) {
	vec4 p = gbufferProjectionInverse * vec4(screenPos * 2.0 - 1.0, 1.0);
	return p.xyz / p.w;
}

vec3 viewToScreenPos(vec3 viewPos) {
	vec4 p = gbufferProjection * vec4(viewPos, 1.0);
	return p.xyz / p.w * 0.5 + 0.5;
}

vec3 screenToEyePos(vec3 screenPos) {
	return mat3(gbufferModelViewInverse) * screenToViewPos(screenPos);
}

vec3 eyeToScreenPos(vec3 voxelPos) {
	return viewToScreenPos(mat3(gbufferModelView) * voxelPos);
}

vec3 roundVoxelPos(vec3 p) {
	return (floor(p * VOXEL_SCALE) + 0.5001) * VOXEL_SCALE_INV;
}

void main() {
	vec3 color = texture2D(colortex0, texcoord).rgb;

	float rawDepth = texture2D(depthtex0, texcoord).r;
	if (rawDepth < MC_HAND_DEPTH * 0.5 + 0.5) {
		gl_FragData[0] = vec4(color, 1.0);
		return;
	}

	float depth = texture2D(colortex1, texcoord).r;
	vec3 normal = vec3(0.0, 1.0, 0.0);
	float lightStrength = 0.0;
	bool hit = false;

	for (int k = 0; k < 2; k++) {
		if (k == 1) {
			depth = rawDepth;
		}

		vec3 eyePos = screenToEyePos(vec3(texcoord, depth));
		vec3 dir = normalize(eyePos);

		vec3 pos = (cameraPositionFract + eyePos) * VOXEL_SCALE - dir * 5.0;

		vec3 deltaDist = abs(vec3(length(dir)) / dir);
		ivec3 mapPos = ivec3(floor(pos));
		ivec3 istep = ivec3(sign(dir));
		ivec3 step = ivec3(sign(dir));
		vec3 sideDist = (sign(dir) * (vec3(mapPos) - pos) + (sign(dir) * 0.5) + 0.5) * deltaDist;

		for (int i = 0; i <= 25; i++) {
			if (sideDist.x < sideDist.z && sideDist.x < sideDist.y) {
				sideDist.x += deltaDist.x;
				mapPos.x += istep.x;
				normal = vec3(step.x, 0.0, 0.0);
			} else if (sideDist.z < sideDist.y) {
				sideDist.z += deltaDist.z;
				mapPos.z += istep.z;
				normal = vec3(0.0, 0.0, step.z);
			} else {
				sideDist.y += deltaDist.y;
				mapPos.y += istep.y;
				normal = vec3(0.0, step.y, 0.0);
			}

			// collision
			vec3 myVoxelPos = (vec3(mapPos) + 0.5) * VOXEL_SCALE_INV;
			vec3 eyePos = myVoxelPos - cameraPositionFract;
			vec3 viewPos = mat3(gbufferModelView) * eyePos;
			vec3 screenPos = viewToScreenPos(viewPos);
			float myDepth = texture2D(depthtex0, screenPos.xy).r;
			if (
					screenPos.z > myDepth
					&& viewPos.z < 0.0
					&& i > 3
				) {
				hit = true;
				color = texture2D(colortex0, screenPos.xy).rgb;
				lightStrength = texture2D(colortex2, screenPos.xy).g;
				break;
			}
		}
		if (hit) {
			break;
		}
	}

	float light = dot(normal * normal, vec3(0.6, 0.25 * -normal.y + 0.75, 0.8));
	color = mix(
		color * texture2D(colortex1, texcoord).r,
		color * light,
		lightStrength
	);

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0);
}