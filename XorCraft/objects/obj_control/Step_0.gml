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
	dx -= sign(gamepad_axis_value(0, gp_axisrh)) * 2;
	dy -= sign(gamepad_axis_value(0, gp_axisrv)) * 2;
}
else {
	window_mouse_set(window_mouse_get_x() + sign(gamepad_axis_value(0, gp_axisrh)) * 5, window_mouse_get_y() + sign(gamepad_axis_value(0, gp_axisrv)) * 5);
}

//Escape to end the game
if keyboard_check_pressed(vk_escape)
{
	if (inventory_open) inventory_open = false;
	else game_end();
}

//Controls
var _kf,_ks,_kv,_kb,_kj,_kr;
_kf = (keyboard_check(ord("D")) || keyboard_check(vk_right) || sign(gamepad_axis_value(0, gp_axislh)) > 0) - (keyboard_check(ord("A")) || keyboard_check(vk_left) || sign(gamepad_axis_value(0, gp_axislh)) < 0);
_ks = (keyboard_check(ord("W")) || keyboard_check(vk_up) || sign(gamepad_axis_value(0, gp_axislv)) < 0) - (keyboard_check(ord("S")) || keyboard_check(vk_down) || sign(gamepad_axis_value(0, gp_axislv)) > 0);
_kv = (keyboard_check(vk_pageup)) - (keyboard_check(vk_pagedown));
_kb = .1+(global.creative?.8:.1)*keyboard_check(vk_control);
_kj = keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1);
_kr = keyboard_check(vk_shift) || gamepad_button_check(0, gp_face2);

//Movement

vx = lerp(vx,(dsin(dx)*_kf+dcos(dx)*_ks)*_kb,.1);
vy = lerp(vy,(dcos(dx)*_kf-dsin(dx)*_ks)*_kb,.1);
vz = global.creative ? lerp(vz,(_kv)*_kb,.50):vz-grav;

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

if (_kr) {
	x += vx * 1.5;
	y += vy * 1.5;
}
else {
	x += vx;
	y += vy;
}
z += vz;

//Magic floor
vz = max(vz,3-z);
z = max(z,3);

if (z = 3 && _kj) {
	vz = max(vz, .3);
}

X = x;
Y = y;
Z = z;

//View direction
var _dx,_dy,_dz;
_dx = +dcos(dx)*dcos(dy);
_dy = -dsin(dx)*dcos(dy);
_dz = +dsin(dy);

SH = 0;
for(var i = 0;i<24;i++)
{
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

if (keyboard_check_pressed(ord("E")) || gamepad_button_check_pressed(0, gp_face3))
{
	inventory_open = !inventory_open;
	window_mouse_set(_cx,_cy);
	
	window_set_cursor(inventory_open? cr_default: cr_cross)
}

//Update selection.
select = (select-mouse_wheel_up()+mouse_wheel_down()+9)%9;
if (gamepad_button_check_pressed(0, gp_shoulderrb) && select != 8) select ++;
if (gamepad_button_check_pressed(0, gp_shoulderlb) && select != 0) select --;
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
	if (mouse_check_button_pressed(mb_right) && (i>2.8-_dz) && SH || gamepad_button_check_pressed(0, gp_shoulderl) && (i>2.8-_dz) && SH)
	{
		//Check if you have a block to place
		if (ds_list_size(inventory_i)>select) && inventory_q[|select] || global.creative
		{
			//Place
			var snd = audio_play_sound(snd_place,0,0);
			audio_sound_pitch(snd,random(.6)+.7);
		
			voxel_set(CX,CY,CZ,inventory_i[|select]+1,1);
			if !global.creative inventory_q[|select]--
			if (inventory_q[|select] = 0) {
				ds_list_delete(inventory_i, select);
				ds_list_delete(inventory_q, select);
			}
		}
	}
	//Break block
	if (mouse_check_button_pressed(mb_left) || gamepad_button_check_pressed(0, gp_shoulderr))
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
	hide = !hide;
}

//Update chunks
gen_chunks();