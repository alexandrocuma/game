extends Node

signal event_started(event: Dictionary)
signal choice_required(event: Dictionary)
signal combat_started(enemy_group: Dictionary)
signal combat_resolved(outcome: Dictionary)
signal event_resolved(result: Dictionary)

func fire_event(tile_def: Dictionary) -> void:
	var table_id: String = tile_def.get("event_table", "")
	if table_id == "" or not DataStore.event_tables.has(table_id):
		event_resolved.emit({})
		return

	var event := _select_event(table_id)
	if event.is_empty():
		event_resolved.emit({})
		return

	event_started.emit(event)
	_dispatch(event)

# --- Selection ---

func _select_event(table_id: String) -> Dictionary:
	var table: Dictionary = DataStore.event_tables[table_id]
	var has_scout := GameState.has_role("scout")
	var pool: Array = []

	for entry in table["events"]:
		var event_id: String = entry["event_id"]
		if not DataStore.events.has(event_id):
			continue
		var ev: Dictionary = DataStore.events[event_id]
		var w: float = float(entry["weight"])
		if has_scout and ev.get("scout_reduces_chance", false):
			w *= 0.6
		pool.append({"event": ev, "w": w})

	return _weighted_pick(pool)

func _weighted_pick(pool: Array) -> Dictionary:
	if pool.is_empty():
		return {}
	var total := 0.0
	for item in pool:
		total += item["w"]
	var roll := randf() * total
	var acc := 0.0
	for item in pool:
		acc += item["w"]
		if roll <= acc:
			return item["event"]
	return pool[-1]["event"]

# --- Dispatch ---

func _dispatch(event: Dictionary) -> void:
	match event.get("type", ""):
		"combat":    _handle_combat(event)
		"gather":    _handle_gather(event)
		"encounter": _handle_encounter(event)
		"hazard":    _handle_hazard(event)
		"quiet":     _handle_quiet(event)
		"win":       _handle_win(event)
		_:           event_resolved.emit({"type": "unknown"})

# --- Handlers ---

func _handle_combat(event: Dictionary) -> void:
	var group_id: String = event.get("enemy_group", "")
	if not DataStore.enemies.has(group_id):
		event_resolved.emit({"type": "combat", "outcome": "no_enemy"})
		return
	resolve_combat(DataStore.enemies[group_id], {})

# Public entry point for combat not triggered by a tile event (e.g. roaming enemies).
# `context` is merged into the event_resolved result so callers can attach metadata.
func resolve_combat(enemy_group: Dictionary, context: Dictionary = {}) -> void:
	combat_started.emit(enemy_group)

	var outcome := CombatResolver.resolve(GameState.team, enemy_group)
	combat_resolved.emit(outcome)

	# Apply hero HP changes from resolver (which works on copies)
	for i in range(GameState.team.size()):
		if i < outcome["final_hero_states"].size():
			GameState.team[i]["hp"] = outcome["final_hero_states"][i]["hp"]
			GameState.team[i]["stamina"] = outcome["final_hero_states"][i]["stamina"]

	var result: Dictionary
	if outcome["result"] == "victory":
		var xp := _xp_with_multiplier(enemy_group.get("xp_reward", 0))
		var level_ups := GameState.add_xp(xp)
		var loot := _roll_loot(enemy_group.get("loot_table", ""))
		GameState.add_resources(loot)
		GameState.apply_healer_passive()
		result = {
			"type": "combat",
			"outcome": "victory",
			"xp": xp,
			"loot": loot,
			"level_ups": level_ups,
		}
	else:
		# Reset explored so combat tile can be re-entered
		GameState.unmark_explored(GameState.team_position)
		GameState.retreat()
		result = {"type": "combat", "outcome": "defeat"}

	for key in context:
		result[key] = context[key]
	event_resolved.emit(result)

func _handle_gather(event: Dictionary) -> void:
	var raw: Dictionary = event.get("resources", {})
	var gained: Dictionary = {}
	for key in raw:
		var rng: Array = raw[key]
		gained[key] = randi_range(int(rng[0]), int(rng[1]))
	GameState.add_resources(gained)
	var xp := _xp_with_multiplier(5)
	GameState.add_xp(xp)
	GameState.apply_healer_passive()
	event_resolved.emit({"type": "gather", "resources": gained, "xp": xp})

func _handle_encounter(event: Dictionary) -> void:
	choice_required.emit(event)
	# Resolution continues in resolve_choice() called by the UI

func resolve_choice(event: Dictionary, choice_index: int) -> void:
	var choices: Array = event.get("choices", [])
	if choice_index < 0 or choice_index >= choices.size():
		event_resolved.emit({"type": "encounter"})
		return
	var outcome: Dictionary = choices[choice_index].get("outcome", {})
	_apply_outcome(outcome)
	var xp := _xp_with_multiplier(10)
	GameState.add_xp(xp)
	GameState.apply_healer_passive()
	event_resolved.emit({"type": "encounter", "choice": choice_index, "outcome": outcome, "xp": xp})

func _apply_outcome(outcome: Dictionary) -> void:
	match outcome.get("type", ""):
		"resource_gain":
			var gains: Dictionary = {}
			for key in outcome:
				if key not in ["type", "xp", "team_morale"]:
					gains[key] = outcome[key]
			GameState.add_resources(gains)
			if outcome.has("xp"):
				GameState.add_xp(_xp_with_multiplier(int(outcome["xp"])))
		"nothing":
			pass

func _handle_hazard(event: Dictionary) -> void:
	var effect: Dictionary = event.get("effect", {})
	match effect.get("type", ""):
		"team_damage":
			var rng: Array = effect.get("amount", [5, 10])
			var dmg := randi_range(int(rng[0]), int(rng[1]))
			GameState.damage_team(dmg)
	GameState.apply_healer_passive()
	event_resolved.emit({"type": "hazard", "effect": effect})

func _handle_quiet(event: Dictionary) -> void:
	event_resolved.emit({"type": "quiet"})

func _handle_win(_event: Dictionary) -> void:
	event_resolved.emit({"type": "win"})

# --- Helpers ---

func _xp_with_multiplier(base_xp: int) -> int:
	if "training_ground" in GameState.camp_upgrades:
		return int(base_xp * 1.2)
	return base_xp

func _roll_loot(table_id: String) -> Dictionary:
	if not DataStore.loot_tables.has(table_id):
		return {}
	var table: Dictionary = DataStore.loot_tables[table_id]
	var result: Dictionary = {}
	for _i in range(table.get("rolls", 1)):
		var entry := _weighted_pick_loot(table.get("entries", []))
		if entry.is_empty():
			continue
		var resource: String = entry["resource"]
		var rng: Array = entry["amount"]
		var amount := randi_range(int(rng[0]), int(rng[1]))
		result[resource] = result.get(resource, 0) + amount
	return result

func _weighted_pick_loot(entries: Array) -> Dictionary:
	if entries.is_empty():
		return {}
	var total := 0.0
	for e in entries:
		total += float(e["weight"])
	var roll := randf() * total
	var acc := 0.0
	for e in entries:
		acc += float(e["weight"])
		if roll <= acc:
			return e
	return entries[-1]
