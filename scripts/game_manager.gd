extends Node

@export var PLAYER_SPAWNER :PackedScene
@export var spawn_path : Node3D

func _ready() -> void:
	if Netvar.is_host:
		var instantiated_ps = PLAYER_SPAWNER.instantiate()
		instantiated_ps.spawn_path = spawn_path
		get_parent().call_deferred(&"add_child", instantiated_ps)
