extends CanvasLayer

@export var game_scene:PackedScene

func _on_play_pressed() -> void:
	Netvar.create_client()
	Netvar.load_game_scene()


func _on_host_pressed() -> void:
	Netvar.create_server()
	Netvar.load_game_scene()
