extends PanelContainer

@onready var info: RichTextLabel = %Info
@onready var exp_button: Button = %ExpButton


func _ready() -> void:
	exp_button.pressed.connect(_on_exp_pressed)
	GameState.local_profile_changed.connect(func(_profile: Dictionary) -> void: refresh())
	GameState.exp_changed.connect(func(_peer_id: int, _exp: int, _level: int) -> void: refresh())
	refresh()


func refresh() -> void:
	if not is_inside_tree():
		return
	var profile := GameState.local_profile
	var stats: Dictionary = profile.get("base_stats", {})
	info.text = "[b]%s[/b]\n系别：%s\n等级：%d\nEXP：%d / %d\n\nHP：%d\n灵质：%d\n攻击：%d\n防御：%d\n专注：%d\n速度：%d" % [
		profile.get("name", "未命名"),
		profile.get("affinity_name", "-"),
		profile.get("level", 1),
		profile.get("exp", 0),
		profile.get("next_exp", GameState.exp_for_level(2)),
		stats.get("hp", 0),
		stats.get("ether", 0),
		stats.get("attack", 0),
		stats.get("defense", 0),
		stats.get("focus", 0),
		stats.get("speed", 0),
	]


func _on_exp_pressed() -> void:
	var peer_id := NetworkManager.get_peer_id()
	NetworkManager.request_add_exp(peer_id, 60)
