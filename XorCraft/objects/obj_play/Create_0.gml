///@desc

event_inherited();

var settings = file_text_open_read("settings.txt");

global.world_size = 40;
global.AO = true;
global.fullscreen = true;
global.sensitivity = 10;
global.creative = false;
global.structures = 120;

if (settings>=0)
{
	var line = file_text_readln(settings);
	global.world_size = real(string_digits(line));
	
	line = file_text_readln(settings);
	global.AO = string_count("true",line);
	
	line = file_text_readln(settings);
	global.fullscreen = string_count("true",line);
	
	line = file_text_readln(settings);
	global.sensitivity = real(string_digits(line));
	
	line = file_text_readln(settings);
	global.creative = string_count("true",line);
	
	line = file_text_readln(settings);
	global.structures = real(string_digits(line));
}

if global.fullscreen
{
window_set_fullscreen(1);
surface_resize(application_surface,display_get_width(),display_get_height());
}
