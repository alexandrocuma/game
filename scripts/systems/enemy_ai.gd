class_name EnemyAI
extends RefCounted

# Roaming enemy state machine. Updates GameState.enemy_states in place and
# reports movement/combat events so TurnManager can animate and resolve combat.
#
# States:
#   patrol  — moving between catalog waypoints.
#   chase   — team is inside aggro_radius; path toward team each turn.
#   return  — team escaped; head back to the nearest waypoint/route.
#
# One enemy gets at most one hex movement per world tick. Combat is triggered
# when an enemy ends its move on the team's tile.

signal enemy_moved(id: String, from: Vector2i, to: Vector2i)
signal combat_triggered(id: String, enemy_group: String)

func process_turn(turn: int, tilemap: TileMapLayer) -> void:
	for enemy in GameState.enemy_states:
		if turn < enemy.get("sleep_until_turn", 0):
			continue
		if enemy.get("state", "") == "dead":
			continue

		var def: Dictionary = DataStore.world_enemies.get(enemy["id"], {})
		if def.is_empty():
			continue

		var before: Vector2i = enemy["pos"]
		_tick_enemy(enemy, def, turn, tilemap)
		var after: Vector2i = enemy["pos"]

		if before != after:
			enemy_moved.emit(enemy["id"], before, after)

		if after == GameState.team_position:
			combat_triggered.emit(enemy["id"], def["enemy_group"])

func _tick_enemy(
		enemy: Dictionary,
		def: Dictionary,
		turn: int,
		tilemap: TileMapLayer) -> void:

	var team_pos := GameState.team_position
	var aggro: int = max(0, int(def.get("aggro_radius", 0)))
	var dist := HexGrid.distance(enemy["pos"], team_pos)
	var state: String = enemy.get("state", "patrol")

	# State transitions.
	match state:
		"patrol":
			if dist <= aggro:
				enemy["state"] = "chase"
				_step_toward(enemy, team_pos, tilemap)
			else:
				_move_toward_waypoint(enemy, def, tilemap)
		"chase":
			if dist > aggro + 1:
				enemy["state"] = "return"
			else:
				_step_toward(enemy, team_pos, tilemap)
		"return":
			if dist <= aggro:
				enemy["state"] = "chase"
				_step_toward(enemy, team_pos, tilemap)
			else:
				_move_toward_waypoint(enemy, def, tilemap)
		_:
			_move_toward_waypoint(enemy, def, tilemap)

func _move_toward_waypoint(enemy: Dictionary, def: Dictionary, tilemap: TileMapLayer) -> void:
	var waypoints: Array = def.get("waypoints", [])
	if waypoints.is_empty():
		return

	var idx: int = enemy.get("waypoint_index", 0)
	if idx < 0 or idx >= waypoints.size():
		idx = 0
		enemy["waypoint_index"] = idx

	var target := Vector2i(int(waypoints[idx][0]), int(waypoints[idx][1]))
	if enemy["pos"] == target:
		idx = (idx + 1) % waypoints.size()
		enemy["waypoint_index"] = idx
		target = Vector2i(int(waypoints[idx][0]), int(waypoints[idx][1]))
		# Reached the return destination; resume normal patrol.
		if enemy.get("state", "") == "return":
			enemy["state"] = "patrol"

	_step_toward(enemy, target, tilemap)

func _step_toward(enemy: Dictionary, target: Vector2i, tilemap: TileMapLayer) -> void:
	var path := HexGrid.find_path(tilemap, enemy["pos"], target)
	if path.size() >= 2 and _is_walkable(tilemap, path[1]):
		enemy["pos"] = path[1]
		return

	# Fallback: greedy neighbor if pathfinding is blocked or target unreachable.
	var best := _best_neighbor(enemy["pos"], target, tilemap)
	if best != enemy["pos"]:
		enemy["pos"] = best

func _best_neighbor(from: Vector2i, target: Vector2i, tilemap: TileMapLayer) -> Vector2i:
	var best := from
	var best_dist := HexGrid.distance(from, target)
	for nb: Vector2i in tilemap.get_surrounding_cells(from):
		if not _is_walkable(tilemap, nb):
			continue
		var d := HexGrid.distance(nb, target)
		if d < best_dist:
			best_dist = d
			best = nb
	return best

func _is_walkable(tilemap: TileMapLayer, pos: Vector2i) -> bool:
	if tilemap.get_cell_source_id(pos) == -1:
		return false
	var id: String = _tile_id_at(tilemap, pos)
	var tile_def: Dictionary = DataStore.tiles.get(id, {})
	# Enemies respect terrain movement_cost but never enter the player camp.
	if tile_def.get("category", "") == "camp_player":
		return false
	return tile_def.get("movement_cost", 1) > 0

func _tile_id_at(tilemap: TileMapLayer, pos: Vector2i) -> String:
	var td: TileData = tilemap.get_cell_tile_data(pos)
	if td == null:
		return ""
	var id = td.get_custom_data("tile_id")
	return id if id != null else ""
