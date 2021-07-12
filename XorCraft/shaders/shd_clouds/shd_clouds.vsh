attribute vec3 in_Position;
attribute vec3 in_TextureCoord;

varying vec4 v_color;
varying vec2 v_coord;

void main()
{
	
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position,1);
	
    v_color = vec4(1,1,1,1);
	v_coord = in_TextureCoord.xy;
}