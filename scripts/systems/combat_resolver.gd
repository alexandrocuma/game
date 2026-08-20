class_name CombatResolver

# Rule constants live in docs/content/combat-rules.json (DataStore.combat_rules);
# these defaults keep the resolver working if the catalog is missing.
const DEFAULT_RULES := {
	"miss_chance": 0.10,
	"crit_chance": 0.05,
	"crit_multiplier": 2.0,
	"variance": 0.10,
	"enemy_stat_variance": 0.20,
}

# Pure function — takes stat objects, returns outcome. No side effects.
static func resolve(team: Array, enemy_group: Dictionary) -> Dictionary:
	var heroes := _copy_team(team)
	var enemies := _expand_enemies(enemy_group["enemies"])
	var rounds: Array = []

	for _r in range(30):
		if enemies.is_empty() or _all_dead(heroes):
			break

		var hero_log := _heroes_attack(heroes, enemies)
		enemies = _filter_alive(enemies)

		var enemy_log: Array = []
		if not enemies.is_empty() and not _all_dead(heroes):
			enemy_log = _enemies_attack(enemies, heroes)

		_tick_shields(heroes)
		rounds.append({"hero_attacks": hero_log, "enemy_attacks": enemy_log})

	var result := "victory" if not enemies.is_empty() == false or _all_dead(enemies) else "defeat"
	if _all_dead(heroes):
		result = "defeat"
	elif enemies.is_empty():
		result = "victory"

	return {
		"result": result,
		"final_hero_states": heroes,
		"rounds": rounds,
	}

static func _heroes_attack(heroes: Array, enemies: Array) -> Array:
	var log: Array = []
	var target_idx := 0
	for hero in heroes:
		if hero["hp"] <= 0 or target_idx >= enemies.size():
			continue
		var target: Dictionary = enemies[target_idx]

		# Use ability if stamina allows (auto-use in v1)
		var ability: Dictionary = hero.get("ability", {})
		var cost: int = ability.get("stamina_cost", 9999)
		if hero["stamina"] >= cost and ability.get("effect", "") != "":
			hero["stamina"] -= cost
			var mod := _apply_ability(hero, target, heroes, ability)
			if mod["kind"] == "heal":
				# Healing replaces the attack entirely.
				log.append({
					"attacker": hero["id"],
					"target": target["id"],
					"damage": 0,
					"outcome": "heal",
					"healed": mod["amount"],
				})
				continue
			var roll := _roll_damage(mod["attack"], target["defense"])
			target["hp"] -= roll["damage"]
			log.append({
				"attacker": hero["id"],
				"target": target["id"],
				"damage": roll["damage"],
				"outcome": roll["outcome"],
			})
		else:
			var roll := _roll_damage(hero["attack"], target["defense"])
			target["hp"] -= roll["damage"]
			log.append({
				"attacker": hero["id"],
				"target": target["id"],
				"damage": roll["damage"],
				"outcome": roll["outcome"],
			})
		if target["hp"] <= 0:
			target_idx += 1
	return log

static func _enemies_attack(enemies: Array, heroes: Array) -> Array:
	var log: Array = []
	var total_attack := 0
	for e in enemies:
		# Stunned enemies skip this round (stun counter ticks down here).
		if e.get("stun_rounds", 0) > 0:
			e["stun_rounds"] -= 1
			continue
		total_attack += e["attack"]

	var fighter_idx := _find_passive(heroes, "frontline")
	var alive_heroes := heroes.filter(func(h): return h["hp"] > 0)
	if alive_heroes.is_empty() or total_attack <= 0:
		return log

	if fighter_idx >= 0 and heroes[fighter_idx]["hp"] > 0 and alive_heroes.size() > 1:
		var base_share := total_attack / float(alive_heroes.size())
		var fighter_raw := int(base_share * 1.3)
		var rest_raw := total_attack - fighter_raw
		var others := alive_heroes.filter(func(h): return h["id"] != heroes[fighter_idx]["id"])

		var fdmg := _hero_damage(heroes[fighter_idx], fighter_raw)
		heroes[fighter_idx]["hp"] -= fdmg
		log.append({"target": heroes[fighter_idx]["id"], "damage": fdmg, "outcome": "hit"})

		if others.size() > 0:
			var per_other := rest_raw / others.size()
			for h in others:
				var dmg := _hero_damage(h, per_other)
				h["hp"] -= dmg
				log.append({"target": h["id"], "damage": dmg, "outcome": "hit"})
	else:
		var per_hero := total_attack / alive_heroes.size()
		for h in alive_heroes:
			var dmg := _hero_damage(h, per_hero)
			h["hp"] -= dmg
			log.append({"target": h["id"], "damage": dmg, "outcome": "hit"})

	return log

# Defense, then an active shield, reduce incoming damage. Minimum 1.
static func _hero_damage(hero: Dictionary, raw: int) -> int:
	var dmg: int = raw - hero["defense"]
	var shield: Dictionary = hero.get("shield", {})
	if shield.get("rounds", 0) > 0:
		dmg -= int(shield.get("amount", 0))
	return max(1, dmg)

# Per-attack roll: miss → 0, crit → ×multiplier, otherwise ±variance. Min 1.
static func _roll_damage(attack: int, defense: int) -> Dictionary:
	if randf() < _rule("miss_chance"):
		return {"damage": 0, "outcome": "miss"}
	var base := attack - defense
	if randf() < _rule("crit_chance"):
		return {
			"damage": max(1, int(round(base * _rule("crit_multiplier")))),
			"outcome": "critical",
		}
	var v := _rule("variance")
	return {
		"damage": max(1, int(round(base * randf_range(1.0 - v, 1.0 + v)))),
		"outcome": "hit",
	}

static func _rule(key: String) -> float:
	return float(DataStore.combat_rules.get(key, DEFAULT_RULES[key]))

# Applies the ability's effect and returns how the hero's action proceeds:
# {"kind": "attack", "attack": int} — attack with this value instead of the
# base attack, or {"kind": "heal", "amount": int} — skip attacking.
static func _apply_ability(
		hero: Dictionary,
		target: Dictionary,
		heroes: Array,
		ability: Dictionary) -> Dictionary:

	var effect: String = ability.get("effect", "")
	var parts := effect.split(": ")
	var key := parts[0].strip_edges()
	var val := float(parts[1].strip_edges()) if parts.size() >= 2 else 1.0

	match key:
		"attack_multiplier":
			return {"kind": "attack", "attack": int(hero["attack"] * val)}
		"heal_team":
			var amount := int(val)
			for h in heroes:
				if h["hp"] > 0:
					h["hp"] = min(h["hp"] + amount, h["max_hp"])
			return {"kind": "heal", "amount": amount}
		"stun_enemy":
			# Status lives on the unit copy: target skips its next N rounds.
			target["stun_rounds"] = int(val)
			return {"kind": "attack", "attack": hero["attack"]}
		"shield":
			# Team-wide damage reduction of N for the next N rounds.
			for h in heroes:
				if h["hp"] > 0:
					h["shield"] = {"amount": int(val), "rounds": int(val)}
			return {"kind": "attack", "attack": hero["attack"]}
		_:
			return {"kind": "attack", "attack": hero["attack"]}

static func _tick_shields(heroes: Array) -> void:
	for h in heroes:
		var shield: Dictionary = h.get("shield", {})
		if shield.get("rounds", 0) > 0:
			shield["rounds"] -= 1

static func _copy_team(team: Array) -> Array:
	return team.map(func(h): return h.duplicate(true))

# Each enemy instance rolls hp/attack/defense within ±variance of the
# catalog value (per-entry "variance", else the rules' enemy_stat_variance).
static func _expand_enemies(defs: Array) -> Array:
	var result: Array = []
	for def in defs:
		var v := float(def.get("variance", _rule("enemy_stat_variance")))
		for _i in range(def["count"]):
			var hp := _vary(int(def["hp"]), v)
			result.append({
				"id": def["id"],
				"hp": hp,
				"max_hp": hp,
				"attack": _vary(int(def["attack"]), v),
				"defense": _vary(int(def["defense"]), v),
			})
	return result

static func _vary(stat: int, variance: float) -> int:
	return max(1, int(round(stat * randf_range(1.0 - variance, 1.0 + variance))))

static func _all_dead(units: Array) -> bool:
	for u in units:
		if u["hp"] > 0:
			return false
	return true

static func _filter_alive(units: Array) -> Array:
	return units.filter(func(u): return u["hp"] > 0)

static func _find_passive(heroes: Array, passive: String) -> int:
	for i in range(heroes.size()):
		if heroes[i].get("passive", "") == passive:
			return i
	return -1
