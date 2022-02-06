var move = (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S")) || gamepad_button_check_pressed(0, gp_shoulderr)) - (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W")) || gamepad_button_check_pressed(0, gp_shoulderl));

if (move != 0) {
	current_button += move;
	if (current_button < 0) current_button = array_length_1d(buttons) - 1;
	if (current_button > array_length_1d(buttons) - 1) current_button = 0;
}

if (keyboard_check_pressed(vk_enter) || gamepad_button_check_pressed(0, gp_face1)) {
	switch (current_button) {
		case 0:
			room_goto(room_play);
		break;
		
		case 1:
			game_end();
		break;
	}
}