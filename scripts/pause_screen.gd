extends Control

func _on_quit_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Netvar.terminate_connection_load_main_menu()