extends StaticBody3D

@export var voxel_size = .2
@export var speed = .5

@export var boxArea:Area3D
@export var voxelHolder:Node3D
@export var editModeCamera:Camera3D
@export var cameraHolder:Node3D
@export var cameraRotator:Node3D
@export var voxelMaterial:Material
var is_searching:bool = true
var is_editing:bool = false

var current_player:CharacterBody3D

@rpc("any_peer", "call_local")
func destroy_voxel(voxel_path:NodePath):
	var voxel :StaticBody3D = get_tree().current_scene.get_node(voxel_path)
	voxel.queue_free()

func enter_edit_mode(player) -> void:
	player.accept_input = false
	player.camera.current = false
	editModeCamera.current = true
	current_player = player
	is_editing = true
	player.toggle_cursor(false)

func exit_edit_mode() -> void:
	var player = current_player
	player.accept_input = true
	player.camera.current = true
	editModeCamera.current = false
	is_editing = false
	player.toggle_cursor(true)

func _handle_edit_mode_actions(delta) -> void:
	if Input.is_action_pressed("a"):
		cameraHolder.rotate_y(-speed*delta)
	elif Input.is_action_pressed("d"):
		cameraHolder.rotate_y(speed*delta)
	if Input.is_action_pressed("q"):
		cameraRotator.rotate_x(speed*delta)
	elif Input.is_action_pressed("e"):
		cameraRotator.rotate_x(-speed*delta)
	if Input.is_action_pressed("w"):
		cameraHolder.position.y = clamp(cameraHolder.position.y + speed*delta, 0, 6)
	elif Input.is_action_pressed("s"):
		cameraHolder.position.y = clamp(cameraHolder.position.y - speed*delta, 0, 6)
	if Input.is_action_just_pressed("exit"):
		exit_edit_mode()

func _handle_voxels() -> void:
		var mouse_pos = editModeCamera.get_viewport().get_mouse_position()
		var space_state : PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.new()

		query.collision_mask = 16
		query.from = editModeCamera.project_ray_origin(mouse_pos)
		query.to =	query.from + editModeCamera.project_ray_normal(mouse_pos) * 1000

		var collision = space_state.intersect_ray(query)

		if collision and collision.collider and Input.is_action_just_pressed("pickup"):
			destroy_voxel.rpc(get_tree().current_scene.get_path_to(collision.collider))
    
@rpc("authority", "call_local")
func _create_statue(dimensions:Vector3, activator:NodePath) -> void:
	get_tree().current_scene.get_node(activator).queue_free()
	#create voxels
	var sum :Vector3 = Vector3.ZERO
	var vec_count :int = 0

	var offset = Vector3(dimensions.x - 1, dimensions.y - 1, dimensions.z - 1) * voxel_size * 0.5
	for y in range(dimensions.y):
		for x in range(dimensions.x):
			for z in range(dimensions.z):
				var newVoxelContainer :StaticBody3D = StaticBody3D.new()
				newVoxelContainer.collision_layer = 16
				newVoxelContainer.name = "Voxel_"+str(x)+str(y)+str(z)
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
				voxelHolder.add_child(newVoxelContainer)
				newVoxelContainer.position = Vector3(x,y,z)*voxel_size+offset
				newVoxelContainer.top_level = true
				sum+=newVoxelContainer.global_position
				vec_count+=1
	var center = sum/vec_count
	voxelHolder.global_position = center - Vector3(0, dimensions.y*voxel_size/2,0)
	for voxel : StaticBody3D in voxelHolder.get_children():
		voxel.top_level = false
	voxelHolder.position = Vector3(0,.3,0)


func _process(delta: float) -> void:

	#DebugDraw3D.draw_sphere(voxelHolder.global_position, 0.4)

	if Netvar.is_host and is_searching:
		for node in boxArea.get_overlapping_bodies():
			if node.has_meta("statue_dimensions") and node.get_meta("owner", "") == "":
				is_searching = false
				_create_statue.rpc(node.get_meta("statue_dimensions"), get_tree().current_scene.get_path_to(node))
				break
	if is_editing:
		_handle_edit_mode_actions(delta)
		_handle_voxels()
	
