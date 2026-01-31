extends CharacterBody3D

const EYEBALL_SHADER = "res://shaders/eyeball.gdshader"

@export var STEP_PARTICLES : PackedScene

@export var SPEED : float = 4.0
var sens = 0.0035
@export var ACELL_SPEED = 1
@export var DECELL_SPEED = 1
@export var AIR_CONTROL = 1
@export var PLAYERMODEL_TURN_SPEED = 0.5

@export var footstep_spawn_offset:Vector3

var time = 0

@export var head: Node3D
@export var camera:Camera3D
@export var playermodel: Skeleton3D
@export var pm_player: AnimationPlayer

var head_rest_position:Vector3

enum PLAYER_STATE{
	IDLING,
	WALKING,
	AIRBORNE,
}

var state:PLAYER_STATE = PLAYER_STATE.IDLING

func _input(event: InputEvent) -> void:
	if !is_multiplayer_authority(): return
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * sens)
		camera.rotate_x(-event.relative.y * sens)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90),deg_to_rad(90))

func _handle_viewbobbing() -> void:
	var end_position:Vector3 = head_rest_position
	if state == PLAYER_STATE.WALKING:
		var sine : float = sin(time*SPEED*3)/20
		end_position = Vector3(0,head_rest_position.y+sine,0)
	head.position = head.position.lerp(end_position, 0.2)

func _handle_animations() -> void:
	match state:
		PLAYER_STATE.IDLING:
			pm_player.current_animation = "Idle"
		PLAYER_STATE.WALKING:
			pm_player.current_animation = "Walk"
		PLAYER_STATE.AIRBORNE:
			pm_player.current_animation = "Idle"
		_:
			pm_player.current_animation = "Idle"

func _rotate_playermodel() -> void:
	playermodel.rotation.y = lerp_angle(playermodel.rotation.y, head.rotation.y, PLAYERMODEL_TURN_SPEED)

func _enter_tree() -> void:
	set_multiplayer_authority(int(name))
	if is_multiplayer_authority():
		playermodel.get_node("Head").hide()
		playermodel.get_node("HeadAttachment/LeftEye").hide()
		playermodel.get_node("HeadAttachment/RightEye").hide()
		playermodel.get_node("HeadAttachment/Beret").hide()
		get_node("Username").hide()

func _ready() -> void:
	if is_multiplayer_authority():
		camera.current = true
		head_rest_position = head.position
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		return

func _physics_process(delta: float) -> void:

	_rotate_playermodel()

	if !is_multiplayer_authority(): return
	time += delta
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("exit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var input_dir := Input.get_vector("a", "d", "w", "s")
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if is_on_floor():
			state = PLAYER_STATE.WALKING
			velocity.x = lerp(velocity.x, direction.x * SPEED, ACELL_SPEED)
			velocity.z = lerp(velocity.z, direction.z * SPEED, ACELL_SPEED)
		else:
			state = PLAYER_STATE.AIRBORNE
			velocity.x = lerp(velocity.x, direction.x * SPEED, AIR_CONTROL)
			velocity.z = lerp(velocity.z, direction.z * SPEED, AIR_CONTROL)
	else:
		if is_on_floor():
			state = PLAYER_STATE.IDLING
			velocity.x = lerp(velocity.x, 0.0, DECELL_SPEED)
			velocity.z = lerp(velocity.z, 0.0, DECELL_SPEED)
		else:
			state = PLAYER_STATE.AIRBORNE
			velocity.x = lerp(velocity.x, direction.x * SPEED, AIR_CONTROL)
			velocity.z = lerp(velocity.z, direction.z * SPEED, AIR_CONTROL)
	_handle_animations()
	_handle_viewbobbing()
	move_and_slide()

@rpc("any_peer", "call_local")
func attempt_to_apply():
	apply_user.rpc(Netvar.body_color, Netvar.accessory_color, Netvar.username)

@rpc("any_peer", "call_local")
func apply_user(color:Color, accessory_color:Color, username:String):

	var body_meshinstance :MeshInstance3D = get_node("Playermodel/Armature/Skeleton3D/Body")
	var head_meshinstance :MeshInstance3D = get_node("Playermodel/Armature/Skeleton3D/Head")
	
	var accessory_meshinstance :MeshInstance3D = get_node("Playermodel/Armature/Skeleton3D/HeadAttachment/Beret")

	var leftEye_meshinstance :MeshInstance3D = get_node("Playermodel/Armature/Skeleton3D/HeadAttachment/LeftEye")
	var rightEye_meshinstance :MeshInstance3D = get_node("Playermodel/Armature/Skeleton3D/HeadAttachment/RightEye")

	var username_label :Label3D = get_node("Username")

	var newMaterial :StandardMaterial3D = StandardMaterial3D.new()
	newMaterial.albedo_color = color
	
	var newBeretMaterial :StandardMaterial3D = StandardMaterial3D.new()
	newBeretMaterial.albedo_color = accessory_color
	
	var newEyeball :ShaderMaterial = ShaderMaterial.new()
	newEyeball.shader = load(EYEBALL_SHADER)

	newEyeball.set_shader_parameter(&"eyelid_color", color)
	newEyeball.set_shader_parameter(&"eye_color", Color(1.0,1.0,1.0))
	newEyeball.set_shader_parameter(&"pupil_color", Color(0.0,0.0,0.0))
	newEyeball.set_shader_parameter(&"pupil_size", -0.4)
	newEyeball.set_shader_parameter(&"blink_frequency", 0.4)
	newEyeball.set_shader_parameter(&"blink_softener", 0.2)
	newEyeball.set_shader_parameter(&"resting_position", 0.453)

	body_meshinstance.material_override = newMaterial
	head_meshinstance.material_override = newMaterial
	accessory_meshinstance.material_override = newBeretMaterial
	
	leftEye_meshinstance.material_override = newEyeball
	rightEye_meshinstance.material_override = newEyeball

	username_label.text = username