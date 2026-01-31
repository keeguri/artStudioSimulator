extends CanvasLayer

const SHADER_PATH = "res://shaders/eyeball.gdshader"

@export var camera :Camera3D
@export var defaultPosition :Node3D
@export var customizePosition :Node3D

@export var main_screen :Control
@export var customize_screen :Control

@export var playermodel_body :MeshInstance3D
@export var playermodel_head :MeshInstance3D
@export var playermodel_leftEye :MeshInstance3D
@export var playermodel_rightEye :MeshInstance3D
@export var playermodel_beret :MeshInstance3D

@export var username_line :LineEdit

var prefered_position :Vector3
var new_body_material :StandardMaterial3D
var new_beret_material :StandardMaterial3D
var new_shader_material :ShaderMaterial



func _ready():
	prefered_position = defaultPosition.global_position

	new_beret_material = StandardMaterial3D.new()
	new_beret_material.albedo_color = Netvar.accessory_color

	new_body_material = StandardMaterial3D.new()
	new_body_material.albedo_color = Netvar.body_color
	new_shader_material = ShaderMaterial.new()
	new_shader_material.shader = load(SHADER_PATH)

	new_shader_material.set_shader_parameter(&"eyelid_color", new_body_material.albedo_color)
	new_shader_material.set_shader_parameter(&"eye_color", Color(1.0,1.0,1.0))
	new_shader_material.set_shader_parameter(&"pupil_color", Color(0.0,0.0,0.0))
	new_shader_material.set_shader_parameter(&"pupil_size", -0.4)
	new_shader_material.set_shader_parameter(&"blink_frequency", 0.4)
	new_shader_material.set_shader_parameter(&"blink_softener", 0.2)
	new_shader_material.set_shader_parameter(&"resting_position", 0.453)

	playermodel_body.material_override = new_body_material
	playermodel_head.material_override = new_body_material
	
	playermodel_leftEye.material_override = new_shader_material
	playermodel_rightEye.material_override = new_shader_material

	playermodel_beret.material_override = new_beret_material

	username_line.text = Netvar.username

func _on_play_pressed() -> void:
	if !is_username_valid(Netvar.username): return
	Netvar.create_client()
	Netvar.load_game_scene()


func is_username_valid(username:String) -> bool:
	var spaceless :String = username.remove_chars(" ")
	if username == "" or spaceless == "":
		return false
	return true

func _on_host_pressed() -> void:
	if !is_username_valid(Netvar.username): return
	Netvar.create_server()
	Netvar.load_game_scene()


func _on_customize_pressed() -> void:
	main_screen.hide()
	customize_screen.show()
	prefered_position = customizePosition.global_position


func _on_customize_back_pressed() -> void:
	customize_screen.hide()
	main_screen.show()
	prefered_position = defaultPosition.global_position

func _process(delta):
	camera.global_position = camera.global_position.lerp(prefered_position, 4*delta)

func _on_body_picker_color_changed(color: Color) -> void:
	Netvar.body_color = color
	new_body_material.albedo_color = color
	new_shader_material.set_shader_parameter(&"eyelid_color", color)


func _on_beret_picker_color_changed(color: Color) -> void:
	Netvar.accessory_color = color
	new_beret_material.albedo_color = color


func _on_line_edit_text_changed(new_text: String) -> void:
	Netvar.username = new_text
