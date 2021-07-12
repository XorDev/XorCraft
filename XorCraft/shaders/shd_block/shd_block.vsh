attribute vec3 in_Position;
attribute vec3 in_TextureCoord;//block, normal, ao

varying vec4 v_color;
varying vec3 v_normal;
varying vec2 v_coord;
varying float v_block;

void main()
{
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position,1);
	
	vec3 normals[6];
	normals[0] = vec3(+1,0,0);
	normals[1] = vec3(-1,0,0);
	normals[2] = vec3(0,+1,0);
	normals[3] = vec3(0,-1,0);
	normals[4] = vec3(0,0,+1);
	normals[5] = vec3(0,0,-1);
    vec3 norm = normals[int(in_TextureCoord.y)];
	vec2 coords = in_Position.xy;
	if (abs(norm.x)>.5) coords = in_Position.yz;
	if (abs(norm.y)>.5) coords = in_Position.zx;
	
    v_color = vec4(pow(in_TextureCoord.zzz,vec3(1,.8,.6)),1);
	v_normal = norm;
    v_coord = coords;
	v_block = in_TextureCoord.x-.5;
}