extends Node

signal client_connected(id, info)
signal client_disconnected(id, nick)
signal server_disconnected

const DEFAULT_PORT : int = 8080
const MAX_CLIENTS : int = 10

var peer : ENetMultiplayerPeer = null

var clients : Dictionary = {}
var local_data : Dictionary = {"name" : "Host"}
var clients_loaded : int = 0

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_client_connected)
	multiplayer.peer_disconnected.connect(_on_client_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	pass

func create_client(ip : String) -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, DEFAULT_PORT)
	multiplayer.multiplayer_peer = peer
	pass

func create_server() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(DEFAULT_PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer
	
	clients[1] = local_data
	client_connected.emit(1, local_data)
	pass

@rpc("any_peer", "call_local", "reliable")
func client_loaded():
	if multiplayer.is_server():
		clients_loaded += 1
		if clients_loaded == clients.size():
			# call to start
			clients_loaded = 0
	pass

@rpc("any_peer", "reliable")
func register_client(new_info : Dictionary) -> void:
	var new_client_id : int = multiplayer.get_remote_sender_id()
	clients[new_client_id] = new_info
	client_connected.emit(new_client_id, new_info)
	pass

func _on_client_connected(id):
	register_client.rpc_id(id, local_data)
	pass

func _on_client_disconnected(id):
	var nick = clients[id]["name"]
	clients.erase(id)
	client_disconnected.emit(id, nick)
	pass


func _on_connected() -> void:
	var id : int = multiplayer.get_unique_id()
	clients[id] = local_data
	client_connected.emit(id, local_data)
	pass

func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = null
	pass

func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	clients.clear()
	server_disconnected.emit()
	pass
