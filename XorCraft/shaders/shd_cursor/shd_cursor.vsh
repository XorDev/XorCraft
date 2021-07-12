attribute vec3 in_Position;
attribute vec2 in_TextureCoord;

varying vec4 v_color;

uniform vec3 pos;

void main()
{
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position+pos,1);
	
    v_color = vec4(0,0,0,1);
}