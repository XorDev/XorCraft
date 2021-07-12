attribute vec3 in_Position;
attribute vec2 in_TextureCoord;

varying vec4 v_color;

void main()
{
	vec4 pos = gm_Matrices[MATRIX_WORLD_VIEW] * vec4(-in_Position*8.,0);
	pos.w = 1.;
	
    gl_Position = gm_Matrices[MATRIX_PROJECTION] * pos;
	
    v_color = vec4(exp((in_Position.z-.5)*vec3(2,1,.6)),1);
}