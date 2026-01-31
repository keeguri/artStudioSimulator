extends Node

@export var PLAYER_SCENE :PackedScene

var spawn_path :Node3D

func _ready() -> void:
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	_peer_connected(1)

func _apply_color():
	for player:CharacterBody3D in spawn_path.get_children():
		player.attempt_to_apply.rpc_id(int(player.name))

func _peer_connected(id:int):
	var player_node :CharacterBody3D = PLAYER_SCENE.instantiate()
	player_node.name = str(id)
	spawn_path.add_child(player_node)
	player_node.global_position = Vector3(0,1.05,0)
	_apply_color()

func _peer_disconnected(id:int):
	var player_node :CharacterBody3D = spawn_path.get_node(str(id))
	player_node.queue_free()
