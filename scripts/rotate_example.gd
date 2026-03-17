extends Node3D

@export var rotate_speed:float = 1.0


func _process(delta: float) -> void:
	rotate_y(rotate_speed*delta)
