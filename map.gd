extends Node3D


func _ready() -> void:
	if DisplayServer.get_screen_count() == 1:
		return
	var new_position = DisplayServer.screen_get_position(1)
	new_position.x += DisplayServer.screen_get_size(1).x - DisplayServer.window_get_size().x
	DisplayServer.window_set_position(new_position)
