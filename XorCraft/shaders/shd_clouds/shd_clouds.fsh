varying vec4 v_color;
varying vec2 v_coord;

uniform float time;

void main()
{
	vec2 scroll = vec2(.005,.003)*time;
	vec4 tex = texture2D(gm_BaseTexture,fract(v_coord+scroll));
	
	vec2 c = v_coord*2.-1.;
	tex.a *= .5-.5*dot(c,c);
    gl_FragColor = v_color * tex;
}