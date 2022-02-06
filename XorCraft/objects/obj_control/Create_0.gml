///@desc Initialize

//Randomize seed
randomize();

//Max number of microseconds to be spent on a chunk.
#macro MICROSECONDS 12000

//Set AA as high as possible
aa = max(display_aa&2,display_aa&4,display_aa&8);
display_reset(aa,0);

draw_set_font(fnt_main);

hide = 0;

#region Formats
vertex_format_begin();
vertex_format_add_position_3d();
vertex_format_add_custom(vertex_type_float3,vertex_usage_texcoord);
format = vertex_format_end();

vertex_format_begin();
vertex_format_add_position_3d();
format_pos = vertex_format_end();
#endregion

//Chunk variables
num = global.world_size;
size = 8;
height = 32;

//Chunk data, x/y position, vertex buffer and chunk id
chunks = ds_list_create();
chunk_x = ds_list_create();
chunk_y = ds_list_create();
//chunk buffers
chunk_b = ds_list_create();
//Generated?
for(var X = 0;X<num;X++)
for(var Y = 0;Y<num;Y++)
{
	chunk_g[X][Y] = -1;//Not set yet
}

//Updating chunks
update_list = ds_list_create();
update_chunk = vertex_create_buffer();
UB = 0;


//Cursor variables
CX = 0;
CY = 0;
CZ = 0;
SX = 0;
SY = 0;
SZ = 0;
SH = 0;

//Generation terrain at chunk x/y
function gen_terrain(CX,CY)
{
	//Check if chunk has been already generated.
	if chunk_g[CX][CY]<0
	{
		//Chunk id
		var CI = ds_list_size(chunks);
		chunk_g[CX][CY] = CI;
		
		//Fill with blank data.
		var blank_array = array_create(size,0);
		for(var X = 0;X<size;X++)
		{
			blank_array[X] = array_create(size,0);
			for(var Y = 0;Y<size;Y++)
			{
				blank_array[X][Y] = array_create(size,0);
			}
		}
		//Add chunks
		ds_list_add(chunks,blank_array);
		ds_list_add(chunk_x,CX*size);
		ds_list_add(chunk_y,CY*size);
		ds_list_add(chunk_b,-1);
	
		//Block column x/y
		for(var X = 0;X<size;X++)
		for(var Y = 0;Y<size;Y++)
		{
			//World X?Y
			var _X,_Y;
			_X = X+CX*size;
			_Y = Y+CY*size;
			//Terrain smoothness
			var smooth = sin(_X*.034)*cos(_Y*.045)*.5+.5;
			//Terrain height (one normal, one extra dense)
			var height1 = (cos(_X*.131)*sin(_Y*.112)*.2+cos(_X/4.3)*sin(_Y/5.1)*.1)*smooth+.4;
			var height2 = sin(_X*.022)*sin(_Y*.023)*1.6+sin(_X/9.1)*sin(_Y/6.7)*1.2-2;
			var h = floor(max(height1,height2)*height);
			var treasure = -1;
			//Chance of treasure (ore)
			if !irandom(60) treasure = irandom(h/2);
		
			//Fill column
			for(var Z = 0;Z<height;Z++)
			{
				var v = clamp(h-Z,0,4);
				v += v && height1<height2;
				//Add treasure
				if (Z == treasure) v = choose(9,9,9,9,10);
				chunks[|CI][X][Y][Z] = v;
			}
		}
		return CI;
	}
	//already generated?
	else return -1;
}

//Various voxel fill scripts:
function gen_line(X,Y,Z1,Z2,B,I)
{
	for(var Z = Z1; Z<=Z2; Z++)
	{
		chunks[|I][X][Y][Z] = B;
	}
}

function gen_wall_x(X1,X2,Y,Z1,Z2,B,I)
{
	for(var X = X1; X<=X2; X++)
	{
		gen_line(X,Y,Z1,Z2,B,I);
	}
}

function gen_wall_y(X,Y1,Y2,Z1,Z2,B,I)
{
	for(var Y = Y1; Y<=Y2; Y++)
	{
		gen_line(X,Y,Z1,Z2,B,I);
	}
}

function gen_cubiod(X1,X2,Y1,Y2,Z1,Z2,B,I)
{
	for(var X = X1; X<=X2; X++)
	{
		gen_wall_y(X,Y1,Y2,Z1,Z2,B,I);
	}
}

//Check voxel at X/Y/Z
function voxel_get(X,Y,Z)
{
	var CX,CY,CI;
	CX = floor(X/size);
	CY = floor(Y/size);
	
	//Inside map?
	if (CX>=0 && CX<num && CY>=0 && CY<num && Z>=0 && Z<height)
	{
		CI = chunk_g[CX][CY];
		//Inside chunk?
		if (CI>=0)
		{
			return chunks[|CI][X-CX*size][Y-CY*size][Z];
		}
		else return 0;
	}
	else return 0;
}

//Set voxel value at X/Y/Z (and update chunk?)
function voxel_set(X,Y,Z,value,update)
{
	var CX,CY,CI;
	CX = floor(X/size);
	CY = floor(Y/size);
	
	//Inside map?
	if (CX>=0 && CX<num && CY>=0 && CY<num && Z>=0 && Z<height)
	{
		CI = chunk_g[CX][CY];
		//Inside chunk?
		if (CI>=0)
		{
			var _block = chunks[|CI][X-CX*size][Y-CY*size][Z]
			chunks[|CI][X-CX*size][Y-CY*size][Z] = value;
			
			if update
			{
				vertex_delete_buffer(update_chunk);
				update_chunk = vertex_create_buffer();
				
				if ds_list_size(update_list)
				{
					if (ds_list_find_value(update_list,CI)==undefined) ds_list_insert(update_list,0,CI);
				}
				else ds_list_insert(update_list,0,CI);
				
				//Check for neighboring chunks
				for(var I = X-1;I<=X+1;I+=2)
				for(var J = Y-1;J<=Y+1;J+=2)
				{
					var _CX,_CY;
					_CX = clamp(floor(I/size),0,num-1);
					_CY = clamp(floor(J/size),0,num-1);
					if (_CX != CX || _CY != CY)
					{
						ds_list_insert(update_list,1,chunk_g[_CX][_CY]);
					}
				}
				UB = 0;
			}
			return _block;
		}
		else return 0;
	}
	else return 0;
}

//Generate plane vertex buffer (used for clouds)
function gen_plane_buff(buff,S,Z)
{	
	vertex_position_3d(buff,-S,-S,Z);
	vertex_float3(buff,0,0,0);
	vertex_position_3d(buff,+S,-S,Z);
	vertex_float3(buff,1,0,0);
	vertex_position_3d(buff,-S,+S,Z);
	vertex_float3(buff,0,1,0);
	vertex_position_3d(buff,+S,-S,Z);
	vertex_float3(buff,1,0,0);
	vertex_position_3d(buff,+S,+S,Z);
	vertex_float3(buff,1,1,0);
	vertex_position_3d(buff,-S,+S,Z);
	vertex_float3(buff,0,1,0);
}

//Generate basic cube (for cursor)
function gen_cube_base(buff)
{
	var X,Y,Z,b,l;
	X = -0.5; Y = -0.5; Z = -0.5;
	b = 0;
	l = 0;//lightness?
	
	//z0
	vertex_position_3d(buff,X+0,Y+0,Z+0);
	vertex_float3(buff,b,5,l);
	vertex_position_3d(buff,X+1,Y+0,Z+0);
	vertex_float3(buff,b,5,l);
	vertex_position_3d(buff,X+0,Y+1,Z+0);
	vertex_float3(buff,b,5,l);
	vertex_position_3d(buff,X+1,Y+0,Z+0);
	vertex_float3(buff,b,5,l);
	vertex_position_3d(buff,X+1,Y+1,Z+0);
	vertex_float3(buff,b,5,l);
	vertex_position_3d(buff,X+0,Y+1,Z+0);
	vertex_float3(buff,b,5,l);

	//z1
	vertex_position_3d(buff,X+0,Y+0,Z+1);
	vertex_float3(buff,b,4,l);
	vertex_position_3d(buff,X+0,Y+1,Z+1);
	vertex_float3(buff,b,4,l);
	vertex_position_3d(buff,X+1,Y+0,Z+1);
	vertex_float3(buff,b,4,l);
	vertex_position_3d(buff,X+1,Y+0,Z+1);
	vertex_float3(buff,b,4,l);
	vertex_position_3d(buff,X+0,Y+1,Z+1);
	vertex_float3(buff,b,4,l);
	vertex_position_3d(buff,X+1,Y+1,Z+1);
	vertex_float3(buff,b,4,l);
	
	//y0
	vertex_position_3d(buff,X+1,Y+0,Z+0);
	vertex_float3(buff,b,3,l);
	vertex_position_3d(buff,X+0,Y+0,Z+0);
	vertex_float3(buff,b,3,l);
	vertex_position_3d(buff,X+0,Y+0,Z+1);
	vertex_float3(buff,b,3,l);
	vertex_position_3d(buff,X+1,Y+0,Z+1);
	vertex_float3(buff,b,3,l);
	vertex_position_3d(buff,X+1,Y+0,Z+0);
	vertex_float3(buff,b,3,l);
	vertex_position_3d(buff,X+0,Y+0,Z+1);
	vertex_float3(buff,b,3,l);

	//y1
	vertex_position_3d(buff,X+0,Y+1,Z+0);
	vertex_float3(buff,b,2,l);
	vertex_position_3d(buff,X+1,Y+1,Z+0);
	vertex_float3(buff,b,2,l);
	vertex_position_3d(buff,X+0,Y+1,Z+1);
	vertex_float3(buff,b,2,l);
	vertex_position_3d(buff,X+1,Y+1,Z+0);
	vertex_float3(buff,b,2,l);
	vertex_position_3d(buff,X+1,Y+1,Z+1);
	vertex_float3(buff,b,2,l);
	vertex_position_3d(buff,X+0,Y+1,Z+1);
	vertex_float3(buff,b,2,l);


	//x0
	vertex_position_3d(buff,X+0,Y+0,Z+0);
	vertex_float3(buff,b,1,l);
	vertex_position_3d(buff,X+0,Y+1,Z+0);
	vertex_float3(buff,b,1,l);
	vertex_position_3d(buff,X+0,Y+0,Z+1);
	vertex_float3(buff,b,1,l);
	vertex_position_3d(buff,X+0,Y+1,Z+0);
	vertex_float3(buff,b,1,l);
	vertex_position_3d(buff,X+0,Y+1,Z+1);
	vertex_float3(buff,b,1,l);
	vertex_position_3d(buff,X+0,Y+0,Z+1);
	vertex_float3(buff,b,1,l);

	//x1
	vertex_position_3d(buff,X+1,Y+1,Z+0);
	vertex_float3(buff,b,0,l);
	vertex_position_3d(buff,X+1,Y+0,Z+0);
	vertex_float3(buff,b,0,l);
	vertex_position_3d(buff,X+1,Y+0,Z+1);
	vertex_float3(buff,b,0,l);
	vertex_position_3d(buff,X+1,Y+1,Z+1);
	vertex_float3(buff,b,0,l);
	vertex_position_3d(buff,X+1,Y+1,Z+0);
	vertex_float3(buff,b,0,l);
	vertex_position_3d(buff,X+1,Y+0,Z+1);
	vertex_float3(buff,b,0,l);
}

//Generate voxel at X,Y,Z
function gen_cube(buff,X,Y,Z,I,shadow)
{
	X += chunk_x[|I];
	Y += chunk_y[|I];
	
	var b = voxel_get(X,Y,Z);
	
	//Skip if there's no voxel
	if !b 
	{
		return 0;	
		exit;
	}
	
	var l = 1-.5*shadow;
	
	//beautiful code:
	var C = [[[1,1,1],[1,1,1],[1,1,1]],[[1,1,1],[1,1,1],[1,1,1]],[[1,1,1],[1,1,1],[1,1,1]]];
	
	//AO is enabled, check all neighboring voxels (there's probably a faster way)
	if global.AO
	{
		for(var _X = -1;_X<=1;_X++)
		for(var _Y = -1;_Y<=1;_Y++)
		for(var _Z = -1;_Z<=1;_Z++)
		{
			C[_X+1][_Y+1][_Z+1] = .5+.5*!voxel_get(X+_X,Y+_Y,Z+_Z);	
		}
	}
	//Add quads:
	
	//z0
	if  !voxel_get(X,Y,Z-1)
	{
		var c1,c2,c3,c4;
		c1 = C[0][1][0] * C[1][0][0] * C[0][0][0];
		c2 = C[2][1][0] * C[1][0][0] * C[2][0][0];
		c3 = C[0][1][0] * C[1][2][0] * C[0][2][0];
		c4 = C[2][1][0] * C[1][2][0] * C[2][2][0];
		
		vertex_position_3d(buff,X+0,Y+0,Z+0);
		vertex_float3(buff,b,5,l*c1);
		vertex_position_3d(buff,X+1,Y+0,Z+0);
		vertex_float3(buff,b,5,l*c2);
		vertex_position_3d(buff,X+0,Y+1,Z+0);
		vertex_float3(buff,b,5,l*c3);
		vertex_position_3d(buff,X+1,Y+0,Z+0);
		vertex_float3(buff,b,5,l*c2);
		vertex_position_3d(buff,X+1,Y+1,Z+0);
		vertex_float3(buff,b,5,l*c4);
		vertex_position_3d(buff,X+0,Y+1,Z+0);
		vertex_float3(buff,b,5,l*c3);
	}

	//z1
	if !voxel_get(X,Y,Z+1)// || Z>height-2
	{
		var c1,c2,c3,c4;
		c1 = C[0][1][2] * C[1][0][2] * C[0][0][2];
		c2 = C[2][1][2] * C[1][0][2] * C[2][0][2];
		c3 = C[0][1][2] * C[1][2][2] * C[0][2][2];
		c4 = C[2][1][2] * C[1][2][2] * C[2][2][2];
		
		vertex_position_3d(buff,X+0,Y+0,Z+1);
		vertex_float3(buff,b,4,l*c1);
		vertex_position_3d(buff,X+0,Y+1,Z+1);
		vertex_float3(buff,b,4,l*c3);
		vertex_position_3d(buff,X+1,Y+0,Z+1);
		vertex_float3(buff,b,4,l*c2);
		vertex_position_3d(buff,X+1,Y+0,Z+1);
		vertex_float3(buff,b,4,l*c2);
		vertex_position_3d(buff,X+0,Y+1,Z+1);
		vertex_float3(buff,b,4,l*c3);
		vertex_position_3d(buff,X+1,Y+1,Z+1);
		vertex_float3(buff,b,4,l*c4);
	}

	//y0
	if !voxel_get(X,Y-1,Z)// || Y<1
	{
		var c1,c2,c3,c4;
		c1 = C[0][0][1] * C[1][0][0] * C[0][0][0];
		c2 = C[2][0][1] * C[1][0][0] * C[2][0][0];
		c3 = C[0][0][1] * C[1][0][2] * C[0][0][2];
		c4 = C[2][0][1] * C[1][0][2] * C[2][0][2];
		
		vertex_position_3d(buff,X+1,Y+0,Z+0);
		vertex_float3(buff,b,3,c2);
		vertex_position_3d(buff,X+0,Y+0,Z+0);
		vertex_float3(buff,b,3,c1);
		vertex_position_3d(buff,X+0,Y+0,Z+1);
		vertex_float3(buff,b,3,c3);
		vertex_position_3d(buff,X+1,Y+0,Z+1);
		vertex_float3(buff,b,3,c4);
		vertex_position_3d(buff,X+1,Y+0,Z+0);
		vertex_float3(buff,b,3,c2);
		vertex_position_3d(buff,X+0,Y+0,Z+1);
		vertex_float3(buff,b,3,c3);
	}

	//y1
	if !voxel_get(X,Y+1,Z)// || Y>size-2
	{
		var c1,c2,c3,c4;
		c1 = C[0][2][1]*C[1][2][0]*C[0][2][0];
		c2 = C[2][2][1]*C[1][2][0]*C[2][2][0];
		c3 = C[0][2][1]*C[1][2][2]*C[0][2][2];
		c4 = C[2][2][1]*C[1][2][2]*C[2][2][2];
		
		vertex_position_3d(buff,X+0,Y+1,Z+0);
		vertex_float3(buff,b,2,c1);
		vertex_position_3d(buff,X+1,Y+1,Z+0);
		vertex_float3(buff,b,2,c2);
		vertex_position_3d(buff,X+0,Y+1,Z+1);
		vertex_float3(buff,b,2,c3);
		vertex_position_3d(buff,X+1,Y+1,Z+0);
		vertex_float3(buff,b,2,c2);
		vertex_position_3d(buff,X+1,Y+1,Z+1);
		vertex_float3(buff,b,2,c4);
		vertex_position_3d(buff,X+0,Y+1,Z+1);
		vertex_float3(buff,b,2,c3);
	}


	//x0
	if !voxel_get(X-1,Y,Z)// || X<1
	{
		var c1,c2,c3,c4;
		c1 = C[0][0][1] * C[0][1][0] * C[0][0][0];
		c2 = C[0][2][1] * C[0][1][0] * C[0][2][0];
		c3 = C[0][0][1] * C[0][1][2] * C[0][0][2];
		c4 = C[0][2][1] * C[0][1][2] * C[0][2][2];
		
		vertex_position_3d(buff,X+0,Y+0,Z+0);
		vertex_float3(buff,b,1,c1);
		vertex_position_3d(buff,X+0,Y+1,Z+0);
		vertex_float3(buff,b,1,c2);
		vertex_position_3d(buff,X+0,Y+0,Z+1);
		vertex_float3(buff,b,1,c3);
		vertex_position_3d(buff,X+0,Y+1,Z+0);
		vertex_float3(buff,b,1,c2);
		vertex_position_3d(buff,X+0,Y+1,Z+1);
		vertex_float3(buff,b,1,c4);
		vertex_position_3d(buff,X+0,Y+0,Z+1);
		vertex_float3(buff,b,1,c3);
	}

	//x1
	if !voxel_get(X+1,Y,Z)// || X>size-2
	{
		var c1,c2,c3,c4;
		c1 = C[2][0][1] * C[2][1][0] * C[2][0][0];
		c2 = C[2][2][1] * C[2][1][0] * C[2][2][0];
		c3 = C[2][0][1] * C[2][1][2] * C[2][0][2];
		c4 = C[2][2][1] * C[2][1][2] * C[2][2][2];
		
		vertex_position_3d(buff,X+1,Y+1,Z+0);
		vertex_float3(buff,b,0,c2);
		vertex_position_3d(buff,X+1,Y+0,Z+0);
		vertex_float3(buff,b,0,c1);
		vertex_position_3d(buff,X+1,Y+0,Z+1);
		vertex_float3(buff,b,0,c3);
		vertex_position_3d(buff,X+1,Y+1,Z+1);
		vertex_float3(buff,b,0,c4);
		vertex_position_3d(buff,X+1,Y+1,Z+0);
		vertex_float3(buff,b,0,c2);
		vertex_position_3d(buff,X+1,Y+0,Z+1);
		vertex_float3(buff,b,0,c3);
	}
	return 1;
}

//Updates chunks every step.
function gen_chunks()
{
	//If there are chunks to update
	if ds_list_size(update_list)
	{
		//First chunk in list
		var I = update_list[|0];
		//Start vertex buffer on the first block
		if (UB==0)
		{
			//if (update_chunk >= 0) 
			vertex_begin(update_chunk,format);
		}
	
		var start = get_timer();
		//Iterate through all blocks
		while(UB<size*size*height)
		{
			//Reset shadow value for each column.
			var shadow = 0;
			repeat(height)
			{
				shadow = max(shadow*.9,gen_cube(update_chunk,(UB div height) % size,(UB div (height*size)) % size,height-(UB%height),I,shadow));
				UB++;
			}
			//Break if taking too long (continues next frame)
			if (get_timer()-start) > MICROSECONDS break;
		}
		//If you're at the last block
		if (UB>=size*size*height)
		{
			//Reset counter
			UB = 0;
			//Finish vertex buffer
			vertex_end(update_chunk);
			vertex_freeze(update_chunk);
			
			//Delete old chunk buffer and replace it.
			if (chunk_b[|I]>=0) vertex_delete_buffer(chunk_b[|I]);
			chunk_b[|I] = update_chunk;
			//Create new buffer.
			update_chunk = vertex_create_buffer();
			ds_list_delete(update_list,0);
		}
	}
	//If there's nothing on the update list, look for some
	else
	{
		var dist = infinity;
		var pick = -1;
		//Check nearby chunks (please don't judge)
		repeat(90)
		{
			var I,D;
			//Find a random chunk and check it's distance
			I = irandom(ds_list_size(chunk_b)-1);
			D = point_distance(x-size/2,y-size/2,chunk_x[|I],chunk_y[|I]);
			//If it's closer than last one, save it.
			if (chunk_b[|I]<0 && D<dist) 
			{
				dist = D
				pick = I;
			}
		}
		//Add the nearest pick to the list.
		if (pick>=0) ds_list_add(update_list,pick);
	}
}

//Generate world (adding trees, rocks and structures)
for(var X = 0;X<num;X++)
for(var Y = 0;Y<num;Y++)
{
	var CI = gen_terrain(X,Y);
	
	//trees
	if !irandom(15)
	{
		var _x = irandom(size-6)+2;
		var _y = irandom(size-6)+2;
		var _h = 12+irandom(8);
		var _d = _h+choose(4,4,3);
		
		gen_line(_x,_y,8,_h,7,CI);
		gen_cubiod(_x-2,_x+2,_y-2,_y+2,_h,_d,8,CI);
		if !irandom(3) gen_cubiod(_x-1,_x+1,_y-1,_y+1,_d+1,_d+2,8,CI);
	}
	//rocks
	if !irandom(60)
	{
		var _s = 1+irandom(4);
		var _x = irandom(size-_s-1);
		var _y = irandom(size-_s-1);
		var _z = 4+irandom(8);
		var _h = 1+irandom(_s);
		var _m = choose(3,3,3,3,3,3,4,4,4,4,5);
		
		gen_cubiod(_x,_x+_s,_y,_y+_s,_z,_z+_h,_m,CI);
	}
	//structures
	else if global.structures && !irandom(global.structures)
	{
		var _door = irandom(3);
		var _m = choose(3,3,4,6,6,6,6,7,12);
		var _w = irandom(size-5)+4;
		var _d = irandom(size-5)+4;
		var _h = 16+irandom(6);
		if _door != 0 gen_wall_x(0,_w,0,6,_h,_m,CI);
		if _door != 1 gen_wall_x(0,_w,_d,6,_h,_m,CI);
		if _door != 2 gen_wall_y(0,1,_d-1,6,_h,_m,CI);
		if _door != 3 gen_wall_y(_w,1,_d-1,6,_h,_m,CI);
		
		gen_cubiod(0,_w,0,_d,_h,_h+1,12,CI);
		gen_cubiod(1,_w-1,1,_d-1,12,_h,0,CI);
		gen_cubiod(1,_w-1,1,_d-1,0,12,11,CI);
	}
	/*
	if (CI>=0)
	{
		var _size = ds_list_size(update_list);
		ds_list_insert(update_list,min(floor(sqrt(X*X+Y*Y)),_size-1),CI);
	}
	*/
}


sky = vertex_create_buffer();
vertex_begin(sky,format);
gen_cube_base(sky);
vertex_end(sky);
vertex_freeze(sky);

clouds = vertex_create_buffer();
vertex_begin(clouds,format);
for(var Z = 144;Z>128;Z--)
gen_plane_buff(clouds,512,height+Z);
vertex_end(clouds);
vertex_freeze(clouds);


#region Cursor model
cursor = vertex_create_buffer();
vertex_begin(cursor,format_pos);

vertex_position_3d(cursor,-.5,-.5,-.5);
vertex_position_3d(cursor,+.5,-.5,-.5);
vertex_position_3d(cursor,-.5,+.5,-.5);
vertex_position_3d(cursor,+.5,+.5,-.5);
vertex_position_3d(cursor,-.5,-.5,+.5);
vertex_position_3d(cursor,+.5,-.5,+.5);
vertex_position_3d(cursor,-.5,+.5,+.5);
vertex_position_3d(cursor,+.5,+.5,+.5);

vertex_position_3d(cursor,-.5,-.5,-.5);
vertex_position_3d(cursor,-.5,-.5,+.5);
vertex_position_3d(cursor,-.5,+.5,-.5);
vertex_position_3d(cursor,-.5,+.5,+.5);
vertex_position_3d(cursor,+.5,-.5,-.5);
vertex_position_3d(cursor,+.5,-.5,+.5);
vertex_position_3d(cursor,+.5,+.5,-.5);
vertex_position_3d(cursor,+.5,+.5,+.5);

vertex_position_3d(cursor,-.5,-.5,-.5);
vertex_position_3d(cursor,-.5,+.5,-.5);
vertex_position_3d(cursor,-.5,-.5,+.5);
vertex_position_3d(cursor,-.5,+.5,+.5);
vertex_position_3d(cursor,+.5,-.5,-.5);
vertex_position_3d(cursor,+.5,+.5,-.5);
vertex_position_3d(cursor,+.5,-.5,+.5);
vertex_position_3d(cursor,+.5,+.5,+.5);

vertex_end(cursor);
vertex_freeze(cursor);
#endregion

//id and quanitity
inventory_i = ds_list_create();
inventory_q = ds_list_create();
inventory_open = 0;
inventory_anim = 0;
//Picked up item
inventory_item = -1;

select = 0;

//fill inventory
if global.creative
{
	for(var I = 0;I<26;I++)
	{
		ds_list_add(inventory_i,I);
		ds_list_add(inventory_q,0);
	}
}

dx = 0;
dy = 0;

x = size*num/2;
y = size*num/2;
z = height+2;

//velocity
vx = 0;
vy = 0;
vz = 0;
grav = .02;

view = matrix_build_lookat(x,y,z,0,0,0,0,0,1);
proj = matrix_build_projection_perspective_fov(75,16/9,.1,10000);