draw_set_font(fnt_menu);
var Y = y;
for (var i = 0; i < array_length_1d(buttons); i ++) {
	if (current_button = i) draw_set_color(c_red);
	else draw_set_color(c_white);
	draw_text(x, Y, buttons[i]);
	Y += 80;
}