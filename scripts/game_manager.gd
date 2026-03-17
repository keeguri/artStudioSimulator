extends Node

@export var PLAYER_SPAWNER :PackedScene
@export var NEW_PLSTATS :PackedScene
@export var spawn_path : Node3D

@export var lui : Control
@export var ui : Control
@export var ui_sinfo : Label
@export var ui_labels : VBoxContainer

@export var statue_list :Array[StatueResource]

var current_order:StatueResource

func _set_label():
	var dif:StatueResource.StatueDifficulty = current_order.statue_difficulty
	var l:String
	if dif == StatueResource.StatueDifficulty.Easy:
		l = "Легкая"
	elif dif == StatueResource.StatueDifficulty.Normal:
		l = "Трудная"
	elif dif == StatueResource.StatueDifficulty.Hard:
		l = "Сложная"
	var s_temp = """
	Заказ: {0}
	Награда: {1} очков
	Сложность: {2}
	""".format([current_order.statue_name, current_order.statue_reward, l])
	ui_sinfo.text = s_temp

func _ready() -> void:
	current_order = statue_list[0]

	_set_label()
	
	if Netvar.is_host:
		var instantiated_ps = PLAYER_SPAWNER.instantiate()
		instantiated_ps.spawn_path = spawn_path
		instantiated_ps.game_manager = self
		get_parent().call_deferred(&"add_child", instantiated_ps)

@rpc("authority","call_local")
func clear_item_ownership(object_path:NodePath) -> void:
	var object :RigidBody3D = get_tree().current_scene.get_node(object_path)
	object.set_meta("owner", "")

@rpc("any_peer", "call_local")
func _show_results():
	lui._on_close_pressed()
	var pedistals = get_tree().get_nodes_in_group("pedistals")
	var all_things = []
	for ped in pedistals:
		var cname = ped.claimedName
		if cname == "": continue
		var ret = ped._calculate_accuracy_score(current_order.voxel_data)
		var new_thing = NEW_PLSTATS.instantiate()
		new_thing.get_node("StatueName").text = current_order.statue_name
		new_thing.get_node("PlayerName").text = cname
		new_thing.get_node("Accuracy").text = str(int(ret[0]*100))+"%"
		new_thing.get_node("Points").text = str(int(ret[1]))
		new_thing.set_meta("accuracy", ret[0])
		ui_labels.add_child(new_thing)
		all_things.append(new_thing)
	all_things.sort_custom(func(a,b): if a.get_meta("accuracy") < b.get_meta("accuracy"): return false else: return true)
	for i in range(all_things.size()):
		var thing = all_things[i]
		ui_labels.move_child(thing, i+1)
	ui.visible = true
	await get_tree().create_timer(5).timeout
	ui.visible = false
	for i in all_things:
		i.queue_free()
	all_things.clear()
		
		

func _on_buy_pressed() -> void:
	if !Netvar.is_host: return
	_show_results.rpc()
