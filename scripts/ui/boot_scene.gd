extends Control

const CHARACTER_CREATION_SCENE := preload("res://scenes/ui/CharacterCreation.tscn")

@onready var enter_game_button: Button = %EnterGameButton
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	GameState.reset_session()
	_auto_start_server()
	enter_game_button.pressed.connect(_on_enter_game_pressed)
	enter_game_button.button_down.connect(_set_enter_button_pressed.bind(true))
	enter_game_button.button_up.connect(_set_enter_button_pressed.bind(false))
	NetworkManager.connection_ready.connect(_on_connection_ready)
	NetworkManager.network_failed.connect(_on_network_failed)
	NetworkManager.disconnected.connect(_on_disconnected)
	await get_tree().process_frame
	enter_game_button.pivot_offset = enter_game_button.size * 0.5


func _auto_start_server() -> void:
	status_label.text = "正在初始化本地服务器..."
	enter_game_button.disabled = true
	var error := NetworkManager.host(NetworkManager.DEFAULT_PORT)
	if error == OK:
		status_label.text = "服务器已就绪"
		enter_game_button.disabled = false
	else:
		status_label.text = "服务器启动失败，点击按钮重试。"
		enter_game_button.disabled = false


func _on_enter_game_pressed() -> void:
	if not NetworkManager.is_network_active():
		_auto_start_server()
		if not NetworkManager.is_network_active():
			return
	_enter_character_creation()


func _on_connection_ready() -> void:
	status_label.text = "服务器已就绪"
	enter_game_button.disabled = false


func _on_network_failed(message: String) -> void:
	status_label.text = message
	enter_game_button.disabled = false


func _on_disconnected() -> void:
	status_label.text = "已断开连接。"
	enter_game_button.disabled = false


func _enter_character_creation() -> void:
	var creation := CHARACTER_CREATION_SCENE.instantiate()
	creation.initial_name = "旅者"
	get_tree().root.get_node("Main").open_node(creation)


func _set_enter_button_pressed(is_pressed: bool) -> void:
	enter_game_button.scale = Vector2(0.97, 0.97) if is_pressed else Vector2.ONE
