extends CharacterBody2D

const SERVER_SYNC_RATE := 12.0

@export var peer_id := 1:
	set(value):
		peer_id = value
		_update_authority()

@export var profile: Dictionary = {}:
	set(value):
		profile = value
		_apply_profile()

var facing_radians := 0.0
var _input_vector := Vector2.ZERO
var _sync_accumulator := 0.0
var _target_position := Vector2.ZERO
var _target_facing := 0.0

@onready var facing_line: Line2D = %FacingLine
@onready var name_label: Label = %NameLabel
@onready var body: Sprite2D = %Body


func _ready() -> void:
	_update_authority()
	_apply_profile()
	_target_position = global_position
	_target_facing = facing_radians


func _physics_process(delta: float) -> void:
	if _is_local_player():
		_collect_input()
		_send_input_to_server()

	if multiplayer.is_server():
		_server_move(delta)
		_sync_accumulator += delta
		if _sync_accumulator >= 1.0 / SERVER_SYNC_RATE:
			_sync_accumulator = 0.0
			_apply_state.rpc(global_position, facing_radians, velocity)
	elif not multiplayer.is_server():
		global_position = global_position.lerp(_target_position, min(delta * 14.0, 1.0))
		facing_radians = lerp_angle(facing_radians, _target_facing, min(delta * 14.0, 1.0))

	_update_visuals()


func _collect_input() -> void:
	_input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _input_vector.length_squared() > 0.001:
		facing_radians = _input_vector.angle()


func _send_input_to_server() -> void:
	if multiplayer.is_server():
		return
	_server_receive_input.rpc_id(1, _input_vector, facing_radians)


func _server_move(_delta: float) -> void:
	var speed := float(profile.get("base_stats", {}).get("speed", 220))
	velocity = _input_vector * speed
	move_and_slide()
	if velocity.length_squared() > 0.001:
		facing_radians = velocity.angle()


@rpc("any_peer", "unreliable")
func _server_receive_input(input_vector: Vector2, input_facing: float) -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != peer_id:
		return
	_input_vector = input_vector.limit_length(1.0)
	facing_radians = input_facing


@rpc("authority", "call_local", "unreliable")
func _apply_state(server_position: Vector2, server_facing: float, server_velocity: Vector2) -> void:
	_target_position = server_position
	_target_facing = server_facing
	velocity = server_velocity
	if multiplayer.is_server():
		global_position = server_position
		facing_radians = server_facing


func _update_authority() -> void:
	set_multiplayer_authority(1)


func _is_local_player() -> bool:
	return peer_id == NetworkManager.get_peer_id()


func _apply_profile() -> void:
	if not is_inside_tree():
		return
	name_label.text = profile.get("name", "Player")
	var affinity_id := String(profile.get("affinity_id", "metal"))
	body.modulate = GameState.get_affinity(affinity_id)["color"]


func _update_visuals() -> void:
	facing_line.rotation = facing_radians
