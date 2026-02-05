#version 120

uniform sampler2D lightmap;
uniform sampler2D texture;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying float normalShading;

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;
	color *= texture2D(lightmap, lmcoord);

	/* DRAWBUFFERS:02 */
	gl_FragData[0] = color;
	gl_FragData[1] = vec4(normalShading, 0.5, 0.0, color.a);
}