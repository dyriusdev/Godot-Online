extends Node

const DEFAULT_PORT : int = 8080
const MAX_CLIENTS : int = 10

@onready var client_connection_timeout : Timer = Timer.new()

var server : ENetMultiplayerPeer = null
var client : ENetMultiplayerPeer = null

var ip_address : String = ""

var is_client_connected_to_server : bool = false
var networked_object_index : int = 0 :
	set = _networked_object_index_set

@rpc("any_peer")
func peer_networked_object_index_set(value : int) -> void:
	networked_object_index = value
	pass

func _networked_object_index_set(value : int) -> void:
	networked_object_index = value
	if get_tree().is_server():
		rpc("peer_networked_object_index_set", networked_object_index)
	pass

func _ready() -> void:
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_server_disconnected)
	multiplayer.connected_to_server.connect(_connected_to_server)
	
	add_child(client_connection_timeout)
	client_connection_timeout.wait_time = 10
	client_connection_timeout.one_shot = true
	
	client_connection_timeout.timeout.connect(_on_client_connection_timeout)
	
	ip_address = IP.get_local_addresses()[3]
	
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") and not ip.ends_with(".1"):
			ip_address = ip
			break
	pass

func create_server() -> void:
	server = ENetMultiplayerPeer.new()
	server.create_server(DEFAULT_PORT, MAX_CLIENTS)
	
	multiplayer.multiplayer_peer = server
	pass

func join_server() -> void:
	client = ENetMultiplayerPeer.new()
	client.create_client(ip_address, DEFAULT_PORT)
	
	multiplayer.multiplayer_peer = client
	client_connection_timeout.start()
	pass

func reset_network_connection() -> void:
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer = null
	pass

func _connected_to_server() -> void:
	print("Successfully connected to the server")
	is_client_connected_to_server = true
	pass

func _server_disconnected() -> void:
	print("Disconnected from the server")
	
	# delete nodes in group net
	
	reset_network_connection()
	pass

func _on_client_connection_timeout() -> void:
	if not is_client_connected_to_server:
		print("Client has been timed out")
		reset_network_connection()
	pass

func _connection_failed() -> void:
	# delete nodes in group net
	
	reset_network_connection()
	pass
