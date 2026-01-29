extends CanvasLayer

@export var game_scene:PackedScene

func _on_play_pressed() -> void:
	get_tree().change_scene_to_packed(game_scene)
