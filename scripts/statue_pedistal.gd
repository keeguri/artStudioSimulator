extends StaticBody3D

const PARTICLE_SCENE = "uid://25whkck7ilsq" # res://prefabs/voxel_destruction_particles.tscn

var claimedName:String = ""

@export var voxel_size = .2
@export var speed = .5

@export var boxArea:Area3D
@export var voxelHolder:Node3D
@export var editModeCamera:Camera3D
@export var cameraHolder:Node3D
@export var cameraRotator:Node3D
@export var voxelMaterial:Material
@export var shakeComponent:ShakerComponent3D
@export var clamedPersonName:Label3D
var is_searching:bool = true
var is_editing:bool = false

var current_player:CharacterBody3D

@rpc("any_peer", "call_local")
func destroy_voxel(voxel_path:NodePath) -> void:
	var voxel :StaticBody3D = get_tree().current_scene.get_node(voxel_path)
	var new_particle : GPUParticles3D = preload(PARTICLE_SCENE).instantiate()
	add_child(new_particle)
	new_particle.global_position = voxel.global_position
	shakeComponent.play_shake()
	voxel.queue_free()


func enter_edit_mode(player) -> void:
	if player.get_node("Username").text != claimedName:
		if claimedName == "":
			_claim_pedistal.rpc(player.name)
		return
	player.can_pause = false
	player.accept_input = false
	player.playermodel.hide()
	player.camera.current = false
	editModeCamera.current = true
	current_player = player
	is_editing = true
	player.toggle_cursor(false)

func exit_edit_mode() -> void:
	var player = current_player
	player.accept_input = true
	player.camera.current = true
	player.playermodel.show()
	editModeCamera.current = false
	is_editing = false
	player.toggle_cursor(true)
	player.can_pause = true

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

		if collision and collision.collider and voxelHolder.is_ancestor_of(collision.collider):
			DebugDraw3D.draw_box(collision.collider.global_position, Quaternion.IDENTITY, Vector3.ONE*voxel_size, Color.WHITE, true)

		if collision and collision.collider and Input.is_action_just_pressed("pickup"):
			if !voxelHolder.is_ancestor_of(collision.collider): return
			destroy_voxel.rpc(get_tree().current_scene.get_path_to(collision.collider))

@rpc("any_peer", "call_local")
func _claim_pedistal(playerPath):
	var player = get_tree().current_scene.get_node("Spawnpath").get_node(NodePath(playerPath))
	var playerName :String = player.get_node("Username").text
	var groupers = get_tree().get_nodes_in_group("pedistals")
	for node in groupers:
		if node.claimedName == playerName:
			return
	claimedName = playerName
	clamedPersonName.text = claimedName
	_create_statue(Vector3(5,10,5), NodePath())

func _calculate_accuracy_score(comparison:String):
	var accuracy:float = 0
	var score:float = 0
	var correct = 0
	var bebe:float = len(comparison)/9.0
	for voxel in voxelHolder.get_children():
		if voxel.name in comparison:
			correct+=1
			score+=10
		else:
			correct-=1
			score=max(score-10, 0)
	accuracy = correct/bebe
	return [accuracy, score]


@rpc("authority", "call_local")
func _create_statue(dimensions:Vector3, activator:NodePath) -> void:
	if activator != NodePath():
		get_tree().current_scene.get_node(activator).queue_free()
	
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
	
