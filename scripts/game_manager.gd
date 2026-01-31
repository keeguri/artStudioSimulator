extends Node

@export var PLAYER_SPAWNER :PackedScene
@export var spawn_path : Node3D

func _ready() -> void:
	if Netvar.is_host:
		var instantiated_ps = PLAYER_SPAWNER.instantiate()
		instantiated_ps.spawn_path = spawn_path
		instantiated_ps.game_manager = self
		get_parent().call_deferred(&"add_child", instantiated_ps)

@rpc("authority","call_local")
func clear_item_ownership(object_path:NodePath) -> void:
	var object :RigidBody3D = get_tree().current_scene.get_node(object_path)
	object.set_meta("owner", "")