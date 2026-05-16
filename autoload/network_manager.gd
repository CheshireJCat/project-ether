extends Node

signal hosting_started(port: int)
signal join_started(address: String, port: int)
signal network_failed(message: String)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal connection_ready()
signal disconnected()

const DEFAULT_PORT := 24567
const MAX_CLIENTS := 8

var is_host := false
var current_port := DEFAULT_PORT


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host(port: int = DEFAULT_PORT) -> Error:
	close()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_CLIENTS)
	if error != OK:
		network_failed.emit("开房失败，端口 %d 可能被占用。错误码：%d" % [port, error])
		return error

	multiplayer.multiplayer_peer = peer
	is_host = true
	current_port = port
	hosting_started.emit(port)
	connection_ready.emit()
	return OK


func join(address: String, port: int = DEFAULT_PORT) -> Error:
	close()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address.strip_edges(), port)
	if error != OK:
		network_failed.emit("加入失败，请检查 IP 和端口。错误码：%d" % error)
		return error

	multiplayer.multiplayer_peer = peer
	is_host = false
	current_port = port
	join_started.emit(address, port)
	return OK


func close() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	is_host = false


func get_peer_id() -> int:
	return multiplayer.get_unique_id() if multiplayer.multiplayer_peer else 1


func is_network_active() -> bool:
	return multiplayer.multiplayer_peer != null


func submit_local_profile(profile: Dictionary) -> void:
	var peer_id := get_peer_id()
	if multiplayer.is_server():
		_submit_profile(peer_id, profile)
	else:
		_submit_profile.rpc_id(1, peer_id, profile)


func request_add_exp(peer_id: int, amount: int) -> void:
	if multiplayer.is_server():
		_request_add_exp(peer_id, amount)
	else:
		_request_add_exp.rpc_id(1, peer_id, amount)


@rpc("any_peer", "call_local", "reliable")
func _submit_profile(peer_id: int, profile: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	GameState.set_profile(peer_id, profile)


@rpc("any_peer", "call_local", "reliable")
func _request_add_exp(peer_id: int, amount: int) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id != 0 and sender_id != peer_id:
		return
	GameState.add_exp(peer_id, amount)
	_sync_profile.rpc(peer_id, GameState.get_profile(peer_id))


@rpc("authority", "call_local", "reliable")
func _sync_profile(peer_id: int, profile: Dictionary) -> void:
	GameState.set_profile(peer_id, profile)
	if peer_id == get_peer_id():
		GameState.set_local_profile(profile)


func _on_peer_connected(peer_id: int) -> void:
	peer_joined.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	GameState.remove_profile(peer_id)
	peer_left.emit(peer_id)


func _on_connected_to_server() -> void:
	connection_ready.emit()


func _on_connection_failed() -> void:
	network_failed.emit("连接房主失败。")
	close()


func _on_server_disconnected() -> void:
	disconnected.emit()
	close()
