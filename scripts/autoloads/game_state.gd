extends Node

const XP_THRESHOLDS := [0, 50, 120, 220, 350]
const RESOURCE_CAPS := {"food": 20, "gold": 50, "materials": 30}
const STORAGE_MULTIPLIER := 1.25
const HUNGER_DAMAGE := 5
const HEALER_POST_EVENT_HEAL := 10
const RETREAT_HP_FRACTION := 0.1

var turn: int = 0
var team: Array = []
var resources: Dictionary = {"food": 10, "gold": 5, "materials": 5}
var team_position: Vector2i = Vector2i.ZERO
var last_safe_position: Vector2i = Vector2i.ZERO
var camp_position: Vector2i = Vector2i.ZERO
var explored_tiles: Dictionary = {}
var camp_upgrades: Array = []
var team_xp: int = 0

func init_run(hero_ids: Array, start_pos: Vector2i) -> void:
	turn = 0
	resources = {"food": 10, "gold": 5, "materials": 5}
	explored_tiles = {}
	camp_upgrades = []
	team_xp = 0
	team_position = start_pos
	last_safe_position = start_pos
	camp_position = start_pos
	team = []
	for id in hero_ids:
		var def: Dictionary = DataStore.heroes[id]
		team.append(_make_hero_state(def))

func _make_hero_state(def: Dictionary) -> Dictionary:
	var stats: Dictionary = def["base_stats"]
	return {
		"id": def["id"],
		"role": def["role"],
		"level": 1,
		"hp": stats["hp"],
		"max_hp": stats["hp"],
		"stamina": stats["stamina"],
		"max_stamina": stats["stamina"],
		"attack": stats["attack"],
		"defense": stats["defense"],
		"passive": def["passive"],
		"ability": def["ability"].duplicate(true),
	}

# --- XP & Leveling ---

func add_xp(amount: int) -> Array:
	team_xp += amount
	var leveled_up: Array = []
	var new_level := _level_for_xp(team_xp)
	for i in range(team.size()):
		if new_level > team[i]["level"]:
			team[i]["level"] = new_level
			leveled_up.append(i)
	return leveled_up

func _level_for_xp(xp: int) -> int:
	for i in range(XP_THRESHOLDS.size() - 1, -1, -1):
		if xp >= XP_THRESHOLDS[i]:
			return i + 1
	return 1

func apply_perk(hero_index: int, perk: String) -> void:
	var h: Dictionary = team[hero_index]
	if perk.begins_with("hp+"):
		var n := int(perk.substr(3))
		h["max_hp"] += n
		h["hp"] = min(h["hp"] + n, h["max_hp"])
	elif perk.begins_with("attack+"):
		h["attack"] += int(perk.substr(7))
	elif perk.begins_with("defense+"):
		h["defense"] += int(perk.substr(8))
	elif perk.begins_with("stamina+"):
		var n := int(perk.substr(8))
		h["max_stamina"] += n
		h["stamina"] = min(h["stamina"] + n, h["max_stamina"])

# --- Resources ---

func add_resources(gains: Dictionary) -> void:
	var caps := get_resource_caps()
	for key in gains:
		if resources.has(key):
			resources[key] = min(resources[key] + gains[key], caps.get(key, 9999))

func spend_resources(costs: Dictionary) -> bool:
	for key in costs:
		if resources.get(key, 0) < costs[key]:
			return false
	for key in costs:
		resources[key] -= costs[key]
	return true

func get_resource_caps() -> Dictionary:
	var caps := RESOURCE_CAPS.duplicate()
	if "storage_unit" in camp_upgrades:
		for key in caps:
			caps[key] = int(caps[key] * STORAGE_MULTIPLIER)
	return caps

# --- HP & Damage ---

func heal_team(amount: int) -> void:
	for h in team:
		h["hp"] = min(h["hp"] + amount, h["max_hp"])

func damage_team(amount: int) -> void:
	var fighter_idx := _find_passive("frontline")
	if fighter_idx >= 0 and team.size() > 1:
		var fighter_share := int(amount * 0.30)
		var others_total := amount - fighter_share
		var other_count := team.size() - 1
		_hurt(team[fighter_idx], max(1, fighter_share))
		for i in range(team.size()):
			if i != fighter_idx:
				_hurt(team[i], max(1, others_total / other_count))
	else:
		var per_hero: int = max(1, amount / team.size())
		for h in team:
			_hurt(h, per_hero)

func restore_stamina() -> void:
	for h in team:
		h["stamina"] = h["max_stamina"]

func apply_healer_passive() -> void:
	if _find_passive("post_event_heal") >= 0:
		heal_team(HEALER_POST_EVENT_HEAL)

func retreat() -> void:
	team_position = last_safe_position
	for h in team:
		h["hp"] = max(1, int(h["max_hp"] * RETREAT_HP_FRACTION))

func _hurt(hero: Dictionary, amount: int) -> void:
	hero["hp"] = max(0, hero["hp"] - amount)

func _find_passive(passive: String) -> int:
	for i in range(team.size()):
		if team[i]["passive"] == passive:
			return i
	return -1

func has_role(role: String) -> bool:
	for h in team:
		if h["role"] == role:
			return true
	return false

# --- Map State ---

func mark_explored(pos: Vector2i) -> void:
	explored_tiles[pos] = true

func is_explored(pos: Vector2i) -> bool:
	return explored_tiles.get(pos, false)

func unmark_explored(pos: Vector2i) -> void:
	explored_tiles.erase(pos)

func is_alive() -> bool:
	for h in team:
		if h["hp"] > 0:
			return true
	return false

# --- Save / Load ---

func save() -> void:
	var f := FileAccess.open("user://save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(to_dict()))

func load_save() -> bool:
	if not FileAccess.file_exists("user://save.json"):
		return false
	var f := FileAccess.open("user://save.json", FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if data == null:
		return false
	from_dict(data)
	return true

func to_dict() -> Dictionary:
	return {
		"turn": turn,
		"team": team,
		"resources": resources,
		"team_position": _v2i(team_position),
		"last_safe_position": _v2i(last_safe_position),
		"camp_position": _v2i(camp_position),
		"explored_tiles": explored_tiles.keys().map(_v2i),
		"camp_upgrades": camp_upgrades,
		"team_xp": team_xp,
	}

func from_dict(d: Dictionary) -> void:
	turn = d["turn"]
	team = d["team"]
	resources = d["resources"]
	team_position = _iv2(d["team_position"])
	last_safe_position = _iv2(d["last_safe_position"])
	camp_position = _iv2(d["camp_position"])
	explored_tiles = {}
	for v in d["explored_tiles"]:
		explored_tiles[_iv2(v)] = true
	camp_upgrades = d["camp_upgrades"]
	team_xp = d["team_xp"]

func _v2i(v: Vector2i) -> Dictionary:
	return {"x": v.x, "y": v.y}

func _iv2(d: Dictionary) -> Vector2i:
	return Vector2i(d["x"], d["y"])
