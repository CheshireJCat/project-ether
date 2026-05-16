extends PanelContainer

const SKILL_TREE_PATH := "res://data/skill_tree.json"

@onready var skill_list: VBoxContainer = %SkillList


func _ready() -> void:
	_load_skill_tree()


func _load_skill_tree() -> void:
	var file := FileAccess.open(SKILL_TREE_PATH, FileAccess.READ)
	if file == null:
		_add_error("无法读取技能树：%s" % SKILL_TREE_PATH)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_add_error("技能树 JSON 格式错误。")
		return

	for node in parsed.get("nodes", []):
		_add_skill_node(node)


func _add_skill_node(skill: Dictionary) -> void:
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	var label := RichTextLabel.new()
	label.custom_minimum_size = Vector2(760, 88)
	label.bbcode_enabled = true
	label.fit_content = true
	label.text = "[b]%s[/b]  消耗：%d\n%s\n前置：%s" % [
		skill.get("name", "未命名技能"),
		skill.get("cost", 0),
		skill.get("description", ""),
		", ".join(skill.get("requires", [])) if not skill.get("requires", []).is_empty() else "无",
	]
	margin.add_child(label)
	panel.add_child(margin)
	skill_list.add_child(panel)


func _add_error(message: String) -> void:
	var label := Label.new()
	label.text = message
	skill_list.add_child(label)
