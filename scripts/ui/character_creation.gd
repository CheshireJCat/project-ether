extends Control

const WORLD_SCENE := preload("res://scenes/world/World.tscn")

@export var initial_name := ""

@onready var name_edit: LineEdit = %NameEdit
@onready var affinity_grid: GridContainer = %AffinityGrid
@onready var description: RichTextLabel = %Description
@onready var create_button: Button = %CreateButton
@onready var status_label: Label = %StatusLabel

var _selected_affinity := "metal"
var _buttons: Dictionary = {}


func _ready() -> void:
	name_edit.text = initial_name
	create_button.pressed.connect(_on_create_pressed)
	_build_affinity_buttons()
	_select_affinity(_selected_affinity)


func _build_affinity_buttons() -> void:
	for affinity in GameState.AFFINITIES:
		var affinity_id := String(affinity["id"])
		var button := Button.new()
		button.custom_minimum_size = Vector2(160, 72)
		button.text = "%s  %s" % [affinity["name"], affinity_id]
		button.toggle_mode = true
		button.pressed.connect(func() -> void: _select_affinity(affinity_id))
		affinity_grid.add_child(button)
		_buttons[affinity_id] = button


func _select_affinity(affinity_id: String) -> void:
	_selected_affinity = affinity_id
	for id in _buttons:
		_buttons[id].button_pressed = id == affinity_id
	var affinity := GameState.get_affinity(affinity_id)
	description.text = "[color=%s][font_size=26]%s系[/font_size][/color]\n%s" % [
		affinity["color"].to_html(false),
		affinity["name"],
		affinity["description"],
	]


func _on_create_pressed() -> void:
	var profile := GameState.create_profile(name_edit.text, _selected_affinity)
	status_label.text = "正在写入灵质签名..."
	NetworkManager.submit_local_profile(profile)
	get_tree().root.get_node("Main").open_scene(WORLD_SCENE)
