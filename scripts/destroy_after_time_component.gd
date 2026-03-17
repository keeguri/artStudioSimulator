extends Node

@export var to_delete : Node

func _ready():
	get_tree().create_timer(.5).timeout.connect(_on_timeout)

func _on_timeout() -> void:
	to_delete.queue_free()