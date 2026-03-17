@tool
extends Node3D

const voxelMaterial = preload("res://materials/voxel_material.tres")

@export_tool_button("Copy to clipboard") var copy_button = _copy
@export_tool_button("Calculate max score") var max_score_button = _mx_score
@export_tool_button("Insert voxel") var insert_button = _add_voxel

var voxel_size = .2

func _copy():
	var text = ""
	for voxel in get_children():
		text+= voxel.name
	DisplayServer.clipboard_set(text)
	print(text)

func _mx_score():
	var scre = 0
	for voxel in get_children():
		scre+=10
	DisplayServer.clipboard_set(str(scre))
	print(scre)

func _add_voxel():
	var newVoxelContainer :StaticBody3D = StaticBody3D.new()
	newVoxelContainer.name = "Voxel"
	var newMesh :Mesh = BoxMesh.new()
	newMesh.size = Vector3.ONE*voxel_size
	var newS = BoxShape3D.new()
	newS.size = Vector3.ONE*voxel_size
	var newCS :CollisionShape3D = CollisionShape3D.new()
	newCS.shape = newS
	newVoxelContainer.add_child(newCS)
	var newVoxel :MeshInstance3D = MeshInstance3D.new()
	newVoxel.mesh = newMesh
	newVoxel.material_override = voxelMaterial
	newVoxel.name = "Mesh"
	newVoxelContainer.add_child(newVoxel)
	add_child(newVoxelContainer)
	newVoxelContainer.owner = get_tree().edited_scene_root
