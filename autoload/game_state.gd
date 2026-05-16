extends Node

signal local_profile_changed(profile: Dictionary)
signal profile_changed(peer_id: int, profile: Dictionary)
signal exp_changed(peer_id: int, exp: int, level: int)

const AFFINITIES: Array[Dictionary] = [
	{"id": "metal", "name": "金", "color": Color("#F2C94C"), "description": "锋锐、凝形、破甲。"},
	{"id": "wood", "name": "木", "color": Color("#6FCF97"), "description": "生长、牵引、恢复。"},
	{"id": "water", "name": "水", "color": Color("#56CCF2"), "description": "流动、潜行、缠绕。"},
	{"id": "fire", "name": "火", "color": Color("#EB5757"), "description": "爆发、灼烧、压制。"},
	{"id": "earth", "name": "土", "color": Color("#B08968"), "description": "稳固、防御、地形。"},
	{"id": "spirit", "name": "灵", "color": Color("#BB6BD9"), "description": "感知、共鸣、要害洞察。"},
]

var local_profile: Dictionary = {}
var profiles: Dictionary = {}


func create_profile(character_name: String, affinity_id: String) -> Dictionary:
	var sanitized_name := character_name.strip_edges()
	if sanitized_name.is_empty():
		sanitized_name = "无名旅者"

	var affinity := get_affinity(affinity_id)
	var profile := {
		"name": sanitized_name,
		"affinity_id": affinity["id"],
		"affinity_name": affinity["name"],
		"level": 1,
		"exp": 0,
		"next_exp": exp_for_level(2),
		"base_stats": {
			"hp": 120,
			"ether": 80,
			"attack": 16,
			"defense": 10,
			"focus": 12,
			"speed": 220,
		},
		"created_at": Time.get_unix_time_from_system(),
	}
	set_local_profile(profile)
	return profile


func set_local_profile(profile: Dictionary) -> void:
	local_profile = profile.duplicate(true)
	var local_id := multiplayer.get_unique_id() if multiplayer.multiplayer_peer else 1
	set_profile(local_id, local_profile)
	local_profile_changed.emit(local_profile)


func set_profile(peer_id: int, profile: Dictionary) -> void:
	profiles[peer_id] = profile.duplicate(true)
	profile_changed.emit(peer_id, profiles[peer_id])


func remove_profile(peer_id: int) -> void:
	profiles.erase(peer_id)


func reset_session() -> void:
	local_profile = {}
	profiles.clear()
	local_profile_changed.emit(local_profile)


func get_profile(peer_id: int) -> Dictionary:
	return profiles.get(peer_id, local_profile if peer_id == 1 else {})


func has_local_profile() -> bool:
	return not local_profile.is_empty()


func add_exp(peer_id: int, amount: int) -> void:
	if not profiles.has(peer_id):
		return

	var profile: Dictionary = profiles[peer_id]
	profile["exp"] = int(profile.get("exp", 0)) + max(amount, 0)
	var level := int(profile.get("level", 1))
	while int(profile["exp"]) >= exp_for_level(level + 1):
		level += 1
	profile["level"] = level
	profile["next_exp"] = exp_for_level(level + 1)
	profiles[peer_id] = profile
	exp_changed.emit(peer_id, profile["exp"], profile["level"])
	profile_changed.emit(peer_id, profile)


func exp_for_level(level: int) -> int:
	return int(round(100.0 * pow(float(max(level, 1)), 1.5)))


func get_affinity(affinity_id: String) -> Dictionary:
	for affinity in AFFINITIES:
		if affinity["id"] == affinity_id:
			return affinity
	return AFFINITIES[0]
