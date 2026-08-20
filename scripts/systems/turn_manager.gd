extends Node

enum State { PLAYER_INPUT, ANIMATING, EVENT, CAMP, WORLD_TICK }

signal state_changed(new_state: State)
signal reachable_tiles_updated(tiles: Array)
signal hero_moved(from: Vector2i, to: Vector2i)
signal world_ticked(turn: int)
signal level_up_pending(hero_index: int, perk_options: Array)
signal game_over()
signal game_won()

@onready var world_map: Node = get_node("../WorldMap")
@onready var event_manager: Node = get_node("../EventManager")
@onready var world_tilemap: TileMapLayer = get_node("../WorldMap/WorldTilemap")

var state: State = State.PLAYER_INPUT
var _pending_level_ups: Array = []
var world_events := WorldEvents.new()

func _ready() -> void:
	event_manager.event_resolved.connect(_on_event_resolved)

# --- Public API called by UI ---

func start() -> void:
	world_events.rebuild_from_catalog()
	_reveal_initial()
	_enter_state(State.PLAYER_INPUT)

func request_move(target: Vector2i) -> void:
	if state != State.PLAYER_INPUT:
		return
	if not target in _get_reachable():
		return
	_do_move(target)

func request_camp_action(action: String) -> void:
	if state != State.CAMP:
		return
	match action:
		"rest":   _camp_rest()
		"save":   GameState.save()
		_:        _camp_build(action)

func resolve_perk(hero_index: int, perk: String) -> void:
	GameState.apply_perk(hero_index, perk)
	_pending_level_ups.erase(hero_index)
	if _pending_level_ups.is_empty():
		_continue_after_event()
	else:
		_prompt_next_level_up()

# --- Movement ---

func _get_reachable() -> Array[Vector2i]:
	# Any existing adjacent hex is a legal move. Cost-2 terrain (mountains)
	# must be enterable — it just consumes 2 turns in the world tick.
	var result: Array[Vector2i] = []
	for cell: Vector2i in world_tilemap.get_surrounding_cells(GameState.team_position):
		if world_tilemap.get_cell_source_id(cell) != -1:
			result.append(cell)
	return result

func _do_move(target: Vector2i) -> void:
	var from := GameState.team_position
	_enter_state(State.ANIMATING)
	hero_moved.emit(from, target)
	# Scene's HeroUnit animation calls notify_animation_done() when finished.
	# For immediate (no-animation) moves, call it directly.
	_on_animation_done(target)

func notify_animation_done(target: Vector2i) -> void:
	_on_animation_done(target)

func _on_animation_done(target: Vector2i) -> void:
	var prev := GameState.team_position
	GameState.team_position = target
	var tile_def: Dictionary = world_map.get_tile_def(target)
	var category: String = tile_def.get("category", "")
	var move_cost: int = tile_def.get("movement_cost", 1)

	if category == "camp_player":
		GameState.last_safe_position = target
		_reveal_around(target)
		_enter_state(State.CAMP)
		return

	GameState.last_safe_position = prev
	_reveal_around(target)

	if not GameState.is_explored(target):
		GameState.mark_explored(target)
		_enter_state(State.EVENT)
		event_manager.fire_event(tile_def)
	else:
		_run_world_tick(move_cost)

# --- Event resolution ---

func _on_event_resolved(result: Dictionary) -> void:
	if result.get("type") == "win":
		game_won.emit()
		return

	var level_ups: Array = result.get("level_ups", [])
	if level_ups.size() > 0:
		_pending_level_ups = level_ups.duplicate()
		_prompt_next_level_up()
		return

	# Defeat: team has already been retreated by EventManager
	# ("outcome" is a String in combat results but a Dictionary in encounter results —
	# compare only when it is actually a String)
	var outcome = result.get("outcome", "")
	if outcome is String and outcome == "defeat":
		if not GameState.is_alive():
			game_over.emit()
			return
		_enter_state(State.PLAYER_INPUT)
		_broadcast_reachable()
		return

	var tile_def: Dictionary = world_map.get_tile_def(GameState.team_position)
	_run_world_tick(tile_def.get("movement_cost", 1))

func _continue_after_event() -> void:
	var tile_def: Dictionary = world_map.get_tile_def(GameState.team_position)
	_run_world_tick(tile_def.get("movement_cost", 1))

func _prompt_next_level_up() -> void:
	if _pending_level_ups.is_empty():
		return
	var hero_idx: int = _pending_level_ups[0]
	var hero: Dictionary = GameState.team[hero_idx]
	var level_str := str(hero["level"])
	var def: Dictionary = DataStore.heroes[hero["id"]]
	var perks: Array = def.get("level_perks", {}).get(level_str, [])
	level_up_pending.emit(hero_idx, perks)

# --- World tick ---

func _run_world_tick(times: int) -> void:
	_enter_state(State.WORLD_TICK)
	for _i in range(times):
		_tick_once()

	if not GameState.is_alive():
		game_over.emit()
		return

	_enter_state(State.PLAYER_INPUT)
	_broadcast_reachable()

func _tick_once() -> void:
	GameState.turn += 1
	if GameState.resources["food"] > 0:
		GameState.resources["food"] -= 1
	else:
		GameState.damage_team(GameState.HUNGER_DAMAGE)
	world_events.process_turn(GameState.turn, world_tilemap)
	world_ticked.emit(GameState.turn)

# --- Camp actions ---

func _camp_rest() -> void:
	var base_heal := 0
	for h in GameState.team:
		base_heal += h["max_hp"]
	base_heal = base_heal / GameState.team.size() / 2

	var multiplier := 1.0
	if "healers_tent" in GameState.camp_upgrades:
		multiplier = 1.5
	GameState.heal_team(int(base_heal * multiplier))
	GameState.restore_stamina()
	GameState.save()
	_run_world_tick(1)

func _camp_build(upgrade_id: String) -> void:
	if not DataStore.upgrades.has(upgrade_id):
		return
	if upgrade_id in GameState.camp_upgrades:
		return
	var upgrade: Dictionary = DataStore.upgrades[upgrade_id]
	if not GameState.spend_resources(upgrade["cost"]):
		return
	GameState.camp_upgrades.append(upgrade_id)
	_apply_upgrade_effect(upgrade)
	_run_world_tick(1)

func _apply_upgrade_effect(upgrade: Dictionary) -> void:
	var effect: String = upgrade.get("effect", "")
	var parts := effect.split(": ")
	if parts.size() < 2:
		return
	match parts[0].strip_edges():
		"vision_radius":
			world_map.apply_watchtower()

# --- Vision ---

func _reveal_initial() -> void:
	_reveal_around(GameState.team_position)

func _reveal_around(pos: Vector2i) -> void:
	var radius := 2 if GameState.has_role("scout") else 1
	world_map.reveal_around(pos, radius)

func _broadcast_reachable() -> void:
	reachable_tiles_updated.emit(_get_reachable())

# --- State ---

func _enter_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(new_state)
	if new_state == State.PLAYER_INPUT:
		_broadcast_reachable()
