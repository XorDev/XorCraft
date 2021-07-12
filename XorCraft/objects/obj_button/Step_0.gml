///@desc


var _inst = instance_position(mouse_x,mouse_y,obj_button);
window_set_cursor(instance_exists(_inst)? cr_handpoint: cr_default);
image_index = (_inst==id);