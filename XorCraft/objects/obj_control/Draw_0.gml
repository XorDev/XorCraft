///@desc 3D scene


//Set matrices
view = matrix_build_lookat(x,y,z,x+dcos(dx)*dcos(dy),y-dsin(dx)*dcos(dy),z+dsin(dy),0,0,1);
matrix_set(matrix_view,view);
matrix_set(matrix_projection,proj);

//Draw skybox
gpu_set_cullmode(cull_clockwise);
gpu_set_ztestenable(0);
shader_set(shd_sky);
vertex_submit(sky, pr_trianglelist, -1);
gpu_set_ztestenable(1);

//Draw clouds
shader_set(shd_clouds);
var uni_time = shader_get_uniform(shd_clouds,"time");
shader_set_uniform_f(uni_time,get_timer()/1000000);
vertex_submit(clouds, pr_trianglelist, sprite_get_texture(spr_clouds,0));

//Draw chunks
shader_set(shd_block);
for(var I = 0;I<ds_list_size(chunk_b);I++)
{
	if chunk_b[|I]<0 continue;
	//if ds_list_size(update_list) && (I == update_list[|0]) continue;
	vertex_submit(chunk_b[|I], pr_trianglelist, sprite_get_texture(spr_textures,0));
}

//If selector hits something draw it.
if SH
{
	var uni_pos = shader_get_uniform(shd_cursor,"pos");
	shader_set(shd_cursor);
	
	shader_set_uniform_f(uni_pos,SX+.5,SY+.5,SZ+.5);
	vertex_submit(cursor, pr_linelist, -1);
}
shader_reset();