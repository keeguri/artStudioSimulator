extends Area3D

@export var gui : Control

func open_gui():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	gui.show()
