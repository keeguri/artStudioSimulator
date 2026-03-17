extends Node


const SERVER_PORT :int = 8080
const GAME_SCENE = "res://scenes/game.tscn"
const MAIN_MENU_SCENE = "res://scenes/menu.tscn"
const ARG_PLAYER_NAME = "--username="

var is_host : bool = false

var username :String = ""
var body_color :Color = Color(1,1,1)
var accessory_color :Color = Color(1,1,1)

func upnp_setup():
	var upnp = UPNP.new()
	
	var result = upnp.discover()
	assert(result == UPNP.UPNP_RESULT_SUCCESS, \
	"UPNP DISCOVER FAILED: ERROR %s" % result)
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
	"UPNP INVALID GATEWAY")

	var mapres = upnp.add_port_mapping(SERVER_PORT)
	assert(mapres == UPNP.UPNP_RESULT_SUCCESS, \
	"UPNP PORT MAPPING FAILED: ERROR %s" % mapres)
	
	print("SUCCESS! ADDRESS: %s" % upnp.query_external_address())

func _ready():
	var args = OS.get_cmdline_user_args()
	print(args)
	for arg in args:
		if arg.contains('='):
			var parts = arg.split("=")
			var key = parts[0]
			var value = parts[1]
			if key == ARG_PLAYER_NAME:
				username = value
				print("Player username set to:",value)

func create_server():
	is_host = true
	var peer :ENetMultiplayerPeer= ENetMultiplayerPeer.new()
	peer.create_server(SERVER_PORT)
	multiplayer.multiplayer_peer = peer
	print('Created Server')
	upnp_setup()

func create_client(ip:String = 'localhost', host_port : int = SERVER_PORT):
	is_host = false
	_setup_connection_signals()
	var peer :ENetMultiplayerPeer= ENetMultiplayerPeer.new()
	peer.create_client(ip, host_port)
	multiplayer.multiplayer_peer = peer
	print('Created Client')

func _setup_connection_signals():
	if !multiplayer.server_disconnected.is_connected(_server_disconnected):
		multiplayer.server_disconnected.connect(_server_disconnected)

func _disconnect_connection_signals():
	if multiplayer.server_disconnected.has_connections():
		multiplayer.server_disconnected.disconnect(_server_disconnected)

func _server_disconnected():
	print("Server Disconnected")
	terminate_connection_load_main_menu()

func load_game_scene():
	get_tree().call_deferred(&"change_scene_to_packed", preload(GAME_SCENE))

func _load_main_menu():
	get_tree().call_deferred(&"change_scene_to_packed", preload(MAIN_MENU_SCENE))

func terminate_connection_load_main_menu():
	print("loading menu")
	_load_main_menu()
	_terminate_connection()
	_disconnect_connection_signals()

func _terminate_connection():
	print("terminating connection")
	multiplayer.multiplayer_peer = null