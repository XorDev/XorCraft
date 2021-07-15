///@desc Update

var _mx,_my,_cx,_cy;
_cx = window_get_width()/2;
_cy = window_get_height()/2;
_mx = window_mouse_get_x()-_cx;
_my = window_mouse_get_y()-_cy;

//Turn if the inventory is not open
if !inventory_open
{
	window_mouse_set(_cx,_cy);

	dx = (dx-_mx/80*global.sensitivity+360)%360;
	dy = clamp(dy-_my/80*global.sensitivity,-89,89);
}

//Escape to end the game
if keyboard_check_pressed(vk_escape)
{
	if (inventory_open) inventory_open = false;
	else game_end();
}

//Controls
var _kf,_ks,_kv,_kb,_kj;
_kf = (keyboard_check(ord("D")) || keyboard_check(vk_right)) - (keyboard_check(ord("A")) || keyboard_check(vk_left));
_ks = (keyboard_check(ord("W")) || keyboard_check(vk_up)) - (keyboard_check(ord("S")) || keyboard_check(vk_down));
_kv = (keyboard_check(vk_pageup) || keyboard_check(vk_space)) - (keyboard_check(vk_pagedown) || keyboard_check(vk_shift));
_kb = .1+(global.creative?.8:.1)*keyboard_check(vk_control);
_kj = keyboard_check(vk_space);

//Movement
vx = lerp(vx,(dsin(dx)*_kf+dcos(dx)*_ks)*_kb,.1);
vy = lerp(vy,(dcos(dx)*_kf-dsin(dx)*_ks)*_kb,.1);
vz = global.creative ? lerp(vz,(_kv)*_kb,.1): vz-grav;

var X,Y,Z;
X = floor(x);
Y = floor(y);
Z = floor(z);

//Rough collision system
for(var I = 0; I<=1;I++)
{
	if voxel_get(floor(x+vx+.5),Y,Z-I) {vx = min(vx,0); x = min(x,floor(x+1))}
	if voxel_get(X,floor(y+vy+.5),Z-I) {vy = min(vy,0); y = min(y,floor(y+1))}
	if voxel_get(X,Y,floor(z+vz+.5-I)) {vz = min(vz,0); z = min(z,floor(z+1))}
	if voxel_get(floor(x+vx-.5),Y,Z-I) {vx = max(vx,0); x = max(x,floor(x-1))}
	if voxel_get(X,floor(y+vy-.5),Z-I) {vy = max(vy,0); y = max(y,floor(y-1))}
	if voxel_get(X,Y,floor(z+vz-.8-I)) {vz = max(vz,.3*_kj); z = max(z,floor(z-1.3))}
}

x += vx;
y += vy;
z += vz;

//Magic floor
vz = max(vz,3-z);
z = max(z,3);

X = x;
Y = y;
Z = z;

//View direction
var _dx,_dy,_dz;
_dx = +dcos(dx)*dcos(dy);
_dy = -dsin(dx)*dcos(dy);
_dz = +dsin(dy);
	
/*
function fract(x)
{
	return x-floor(x);
}
//var _sx,_sy,_sz,_rx,_ry,_rz;
_sx = sign(_dx);
_sy = sign(_dy);
_sz = sign(_dz);

_rx = _dx==0? _sx*infinity : _sx/_dx;
_ry = _dy==0? _sx*infinity : _sy/_dy;
_rz = _dz==0? _sx*infinity : _sz/_dz;
*/

//Raycast (approximate)
var i = 0;
SH = 0;
for(;i<24;i++)
{	
	/*
	var _tx,_ty,_tz;
	_tx = 1-fract(_sx*X) * _rx;
	_ty = 1-fract(_sy*Y) * _ry;
	_tz = 1-fract(_sz*Z) * _rz;
	
	if (_tx < _ty && _tx < _tz)
	{
		X += _dx*_tx;
		Y += _dy*_tx;
		Z += _dz*_tx;
	}
	else if (_ty < _tz)
	{
		X += _dx*_ty;
		Y += _dy*_ty;
		Z += _dz*_ty;
	}
	else
	{
		X += _dx*_tz;
		Y += _dy*_tz;
		Z += _dz*_tz;
	}*/
	//Step 1/3 of a block
	X += _dx/3;
	Y += _dy/3;
	Z += _dz/3;
	
	SX = floor(X);
	SY = floor(Y);
	SZ = floor(Z);
	
	//Stop when you hit a block
	if voxel_get(SX,SY,SZ) 
	{
		SH = 1;
		break;
	}
	
	CX = SX;
	CY = SY;
	CZ = SZ;
}


//Update inventory + animation
inventory_anim = lerp(inventory_anim,inventory_open,.1);

if keyboard_check_pressed(ord("E"))
{
	inventory_open = !inventory_open;
	window_mouse_set(_cx,_cy);
	
	window_set_cursor(inventory_open? cr_default: cr_cross)
}

//Update selection.
select = (select-mouse_wheel_up()+mouse_wheel_down()+9)%9;
if keyboard_check(ord("1")) select = 0;
if keyboard_check(ord("2")) select = 1;
if keyboard_check(ord("3")) select = 2;
if keyboard_check(ord("4")) select = 3;
if keyboard_check(ord("5")) select = 4;
if keyboard_check(ord("6")) select = 5;
if keyboard_check(ord("7")) select = 6;
if keyboard_check(ord("8")) select = 7;
if keyboard_check(ord("9")) select = 8;

//Block placement/breaking
if !inventory_open
{
	//Place if far enough (and if selector hit a block)
	if mouse_check_button_pressed(mb_right) && (i>2.8-_dz) && SH
	{
		//Check if you have a block to place
		if (ds_list_size(inventory_i)>select) && inventory_q[|select] || global.creative
		{
			//Place
			var snd = audio_play_sound(snd_place,0,0);
			audio_sound_pitch(snd,random(.6)+.7);
		
			voxel_set(CX,CY,CZ,inventory_i[|select]+1,1);
			if !global.creative inventory_q[|select]--
		}
	}
	//Break block
	if mouse_check_button_pressed(mb_left)
	{
		var snd = audio_play_sound(snd_break,0,0);
		audio_sound_pitch(snd,random(.6)+.7);
	
		var B = voxel_set(SX,SY,SZ,0,1);
		//Add broken block to inventory
		if B
		{
			var pos = ds_list_find_index(inventory_i,B-1);
			if (pos>=0) inventory_q[|pos]++;
			else
			{
				ds_list_add(inventory_i,B-1);
				ds_list_add(inventory_q,1);
			}
		}
	}
}
//Toggles:

if keyboard_check_pressed(vk_f1)
{
	debug = !debug;
	show_debug_overlay(debug);
}
if keyboard_check_pressed(vk_f2)
{
	hide = !hide;
}

//Update chunks
gen_chunks();