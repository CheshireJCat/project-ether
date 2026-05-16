extends Node2D

@export var player_scene: PackedScene
@export var character_sheet_scene: PackedScene
@export var skill_tree_scene: PackedScene

@onready var players: Node2D = %Players
@onready var hud_label: Label = %HudLabel
@onready var exit_button: Button = %ExitButton

var _character_sheet: Control
var _skill_tree: Control


func _ready() -> void:
	NetworkManager.peer_joined.connect(_on_peer_joined)
	NetworkManager.peer_left.connect(_on_peer_left)
	GameState.profile_changed.connect(_on_profile_changed)
	exit_button.pressed.connect(_on_exit_pressed)
	_spawn_existing_players()
	_request_spawn.rpc_id(1, NetworkManager.get_peer_id(), GameState.local_profile)
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_character_sheet"):
		_toggle_character_sheet()
	if event.is_action_pressed("toggle_skill_tree"):
		_toggle_skill_tree()


func _spawn_existing_players() -> void:
	if multiplayer.is_server():
		for peer_id in GameState.profiles.keys():
			_spawn_player(peer_id, GameState.get_profile(peer_id))


@rpc("any_peer", "call_local", "reliable")
func _request_spawn(peer_id: int, profile: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	for existing in players.get_children():
		var existing_player := existing as Node2D
		var existing_peer_id := int(String(existing_player.name))
		if existing_peer_id != peer_id:
			_spawn_player_for_all.rpc_id(
				peer_id,
				existing_peer_id,
				GameState.get_profile(existing_peer_id),
				existing_player.global_position
			)
	GameState.set_profile(peer_id, profile)
	_spawn_player(peer_id, profile)
	var player := players.get_node(str(peer_id)) as Node2D
	_spawn_player_for_all.rpc(peer_id, profile, player.global_position)


@rpc("authority", "call_local", "reliable")
func _spawn_player_for_all(peer_id: int, profile: Dictionary, spawn_position: Vector2) -> void:
	GameState.set_profile(peer_id, profile)
	_spawn_player(peer_id, profile, spawn_position)


func _spawn_player(peer_id: int, profile: Dictionary, spawn_position := Vector2.INF) -> void:
	var node_name := str(peer_id)
	if players.has_node(node_name):
		return

	var player := player_scene.instantiate()
	player.name = node_name
	player.peer_id = peer_id
	player.profile = profile
	player.position = spawn_position if spawn_position != Vector2.INF else _spawn_position_for(peer_id)
	players.add_child(player)


func _spawn_position_for(peer_id: int) -> Vector2:
	var index := players.get_child_count()
	var angle := float(index) * TAU / 8.0
	return Vector2(640, 360) + Vector2.RIGHT.rotated(angle) * (80.0 + float(peer_id % 4) * 24.0)


func _on_peer_joined(peer_id: int) -> void:
	if multiplayer.is_server():
		hud_label.text = "玩家 %d 已连接，等待角色资料。" % peer_id


func _on_peer_left(peer_id: int) -> void:
	var node_name := str(peer_id)
	if players.has_node(node_name):
		players.get_node(node_name).queue_free()
	_update_hud()


func _on_profile_changed(peer_id: int, _profile: Dictionary) -> void:
	if players.has_node(str(peer_id)):
		players.get_node(str(peer_id)).profile = GameState.get_profile(peer_id)
	_update_hud()


func _toggle_character_sheet() -> void:
	if not _character_sheet:
		_character_sheet = character_sheet_scene.instantiate()
		%CanvasLayer.add_child(_character_sheet)
	_character_sheet.visible = not _character_sheet.visible
	if _character_sheet.visible:
		_character_sheet.refresh()


func _toggle_skill_tree() -> void:
	if not _skill_tree:
		_skill_tree = skill_tree_scene.instantiate()
		%CanvasLayer.add_child(_skill_tree)
	_skill_tree.visible = not _skill_tree.visible


func _update_hud() -> void:
	var profile := GameState.local_profile
	var label_name := String(profile.get("name", "未命名"))
	var affinity := String(profile.get("affinity_name", "-"))
	hud_label.text = "%s / %s系 / Peer %d    WASD 移动    C 面板    K 技能树" % [
		label_name,
		affinity,
		NetworkManager.get_peer_id(),
	]


func _on_exit_pressed() -> void:
	NetworkManager.close()
	GameState.reset_session()
	get_tree().root.get_node("Main").open_boot()
