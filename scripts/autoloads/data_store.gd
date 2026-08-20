extends Node

var tiles: Dictionary = {}
var events: Dictionary = {}
var event_tables: Dictionary = {}
var heroes: Dictionary = {}
var enemies: Dictionary = {}
var loot_tables: Dictionary = {}
var upgrades: Dictionary = {}
var combat_rules: Dictionary = {}
var world_events: Dictionary = {}
var world_enemies: Dictionary = {}

const DATA_DIR := "res://docs/content/"
const THEME_DIR := "res://themes/"
const VISUAL_KEYS := ["label", "name", "sprite", "title", "description"]

var active_theme: String = "fantasy"

func _ready() -> void:
	_load_all()
	_flatten_theme_variants()

func _load_all() -> void:
	for entry in _read_json(DATA_DIR + "tile-catalog.json"):
		tiles[entry["id"]] = entry
	for entry in _read_json(DATA_DIR + "event-catalog.json"):
		events[entry["id"]] = entry
	for entry in _read_json(DATA_DIR + "event-tables-catalog.json"):
		event_tables[entry["id"]] = entry
	for entry in _read_json(DATA_DIR + "hero-catalog.json"):
		heroes[entry["id"]] = entry
	for entry in _read_json(DATA_DIR + "enemy-catalog.json"):
		enemies[entry["id"]] = entry
	for entry in _read_json(DATA_DIR + "loot-tables-catalog.json"):
		loot_tables[entry["id"]] = entry
	for entry in _read_json(DATA_DIR + "camp-upgrades-catalog.json"):
		upgrades[entry["id"]] = entry
	combat_rules = _read_json_dict(DATA_DIR + "combat-rules.json")
	for entry in _read_json(DATA_DIR + "world-events.json"):
		world_events[entry["id"]] = entry
	for entry in _read_json(DATA_DIR + "world-enemies.json"):
		world_enemies[entry["id"]] = entry

func _flatten_theme_variants() -> void:
	for store in [tiles, events, heroes, enemies, upgrades]:
		for id in store:
			var entry: Dictionary = store[id]
			var variant: Dictionary = entry.get("theme_variants", {}).get(active_theme, {})
			for key in variant:
				entry[key] = variant[key]
	_apply_file_overrides()

func _apply_file_overrides() -> void:
	var base := THEME_DIR + active_theme + "/"
	_merge_overrides(base + "tile_overrides.json", tiles)
	_merge_overrides(base + "hero_overrides.json", heroes)
	_merge_overrides(base + "enemy_overrides.json", enemies)
	_merge_overrides(base + "upgrade_overrides.json", upgrades)

func _merge_overrides(path: String, target: Dictionary) -> void:
	if not FileAccess.file_exists(path):
		return
	for entry in _read_json(path):
		var id: String = entry.get("id", "")
		if not target.has(id):
			continue
		for key in VISUAL_KEYS:
			if entry.has(key):
				target[id][key] = entry[key]

func _read_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("DataStore: missing file %s" % path)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var result = JSON.parse_string(f.get_as_text())
	if not result is Dictionary:
		push_error("DataStore: failed to parse %s" % path)
		return {}
	return result

func _read_json(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("DataStore: missing file %s" % path)
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	var result = JSON.parse_string(f.get_as_text())
	if result == null:
		push_error("DataStore: failed to parse %s" % path)
		return []
	return result
