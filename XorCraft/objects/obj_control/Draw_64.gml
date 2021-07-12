///@desc Inventory + Hotbar

if hide exit;

var _w = window_get_width();
var _h = window_get_height();
var _mx = window_mouse_get_x();
var _my = window_mouse_get_y();

gpu_set_cullmode(cull_noculling);
gpu_set_ztestenable(0);

draw_set_alpha(.2+.4*inventory_anim);
draw_roundrect_color_ext(_w/2-96*4-64,_h-96-64-inventory_anim*96*4,_w/2+96*4+64,_h-96+64,16,16,$444444,0,0);
var _x,_y,_cx,_cy;
_x = _w/2-96*4;
_cx = clamp(round((_mx-_x)/96),0,8);
_x += (_cx*inventory_anim+select*(1-inventory_anim))*96;
_y = _h-96;
_cy = clamp(round((_my-_y)/96),-4,0);
_y += _cy*96*inventory_anim;
draw_roundrect(_x-48,_y-48,_x+48,_y+48,0);
draw_set_alpha(1);

var I = (_cx-_cy*9);
if  inventory_open && mouse_check_button_pressed(mb_left)
{
	if (I<ds_list_size(inventory_i))
	inventory_item = _cx-_cy*9;
}

if  mouse_check_button_released(mb_left)
{
	if (I<ds_list_size(inventory_i))
	{
		var _I = inventory_i[|I];
		var _Q = inventory_q[|I];
	
		inventory_i[|I] = inventory_i[|inventory_item];
		inventory_q[|I] = inventory_q[|inventory_item];
	
		inventory_i[|inventory_item] = _I;
		inventory_q[|inventory_item] = _Q;
	}
	inventory_item = -1;
}

for(var I = 0;I<ds_list_size(inventory_i);I++)
{
	if !inventory_open && I>=9 break;
	
	var _ID = inventory_i[|I];
	var _Q  = inventory_q[|I];
	var _selected = (select==I)
	
	var _x,_y;
	_x = _w/2-96*4+(I%9)*96-32;
	_x = lerp(_x,_mx-32,inventory_item==I);
	_y = _h-96-32-(I div 9)*96-8*_selected;
	_y = lerp(_y,_my-32,inventory_item==I);
	
	draw_sprite_part_ext(spr_textures,0,(_ID%8)*8,(_ID div 8)*8,8,8,_x,_y,8,8,-1,_Q || global.creative  ?1:.4);
	
	if _selected
	{
		gpu_set_blendmode(bm_add);
		draw_sprite_part_ext(spr_textures,0,(_ID%8)*8,(_ID div 8)*8,8,8,_x,_y,8,8,-1,.2);
		gpu_set_blendmode(bm_normal);
	}
	if _Q draw_text(_x,_y,_Q);
}