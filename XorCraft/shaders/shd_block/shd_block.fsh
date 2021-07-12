#define TEX 8.

varying vec4 v_color;
varying vec3 v_normal;
varying vec2 v_coord;
varying float v_block;

void main()
{
	float l = dot(v_normal,sqrt(vec3(.2,.5,.3)))*.2+.8;
	vec2 uv = (fract(v_coord)+mod(floor(v_block/vec2(1,TEX)),TEX))/TEX;
	vec4 tex = texture2D(gm_BaseTexture,uv);
	tex.rgb *= l;
    gl_FragColor = v_color * tex * (v_block>0.?1.:.8);
}