extends Panel

@onready var ip_input : TextEdit = get_node("VBox/IpBox/IpText")
@onready var name_input : TextEdit = get_node("VBox/NameBox/NameText")
@onready var chat_input : TextEdit = get_node("Chat/VBox/Input")
@onready var chat_output : TextEdit = get_node("Chat/VBox/Output")

func _ready() -> void:
	Network.client_connected.connect(_on_client_connected)
	Network.client_disconnected.connect(_on_client_disconnected)
	Network.server_disconnected.connect(_on_server_disconnected)
	
	Network.client_loaded.rpc_id(1)
	pass

func _input(_event : InputEvent) -> void:
	if Input.is_key_pressed(KEY_ENTER) and not chat_input.text.is_empty():
		rpc("send_message", "[%s] : %s\n" % [Network.local_data["name"], chat_input.text])
		chat_output.text += "[You] : %s\n" % chat_input.text
		chat_input.clear()
	pass

func _on_client_connected(id : int, info : Dictionary) -> void:
	Network.clients[id] = info
	chat_output.text += "[Server] '%s' is connected!\n" % info["name"]
	pass

func _on_client_disconnected(id : int, nick : String) -> void:
	chat_output.text += "[Server] client '%s' is disconnected!\n" % nick
	Network.clients.erase(id)
	pass

func _on_server_disconnected() -> void:
	chat_output.text += "[Server] Server is offline!\n"
	pass

func _on_host_pressed() -> void:
	Network.create_server()
	pass

func _on_connect_pressed() -> void:
	if ip_input.text.is_valid_ip_address() and not name_input.text.is_empty():
		Network.local_data["name"] = name_input.text
		Network.create_client(ip_input.text)
		$VBox/Disconnect.disabled = false
	pass

func _on_disconnect_pressed() -> void:
	multiplayer.multiplayer_peer = null
	pass



@rpc("any_peer")
func send_message(message : String) -> void:
	if not message.is_empty():
		chat_output.text += message
	pass
