extends Node

@export var boot_scene: PackedScene

var _current_scene: Node


func _ready() -> void:
	open_boot()


func open_boot() -> void:
	_change_scene(boot_scene)


func open_scene(scene: PackedScene) -> void:
	_change_scene(scene)


func open_node(node: Node) -> void:
	if _current_scene:
		_current_scene.queue_free()
	_current_scene = node
	add_child(_current_scene)


func _change_scene(scene: PackedScene) -> void:
	if _current_scene:
		_current_scene.queue_free()
	_current_scene = scene.instantiate()
	add_child(_current_scene)
