extends Control

func _on_close_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hide()
