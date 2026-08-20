class_name WorldEvents
extends RefCounted

# Turn-scheduled event queue, owned by TurnManager and processed during the
# WORLD_TICK phase. Ported from rpg-game's WorldEvent service, adapted from
# real-time ticks to game turns.
#
# Queue entries: {id, event_type, type, trigger_turn, interval_turns, payload, status}
# - event_type: "immediate" | "scheduled" | "periodic"
# - type:       handler key dispatched in _dispatch() (same pattern as EventManager)
# - status:     "pending" | "executed"
#
# The queue is rebuilt from the world-events.json catalog on TurnManager.start()
# (TurnManager is not serialized). trigger_turn is an absolute run turn, so after
# loading a save, periodic events simply catch up via the missed-cycles logic.

var queue: Array = []

func rebuild_from_catalog() -> void:
	queue.clear()
	for id in DataStore.world_events:
		var entry: Dictionary = DataStore.world_events[id]
		queue.append({
			"id": entry["id"],
			"event_type": entry.get("event_type", "immediate"),
			"type": entry.get("type", ""),
			"trigger_turn": int(entry.get("trigger_turn", 0)),
			"interval_turns": int(entry.get("interval_turns", 0)),
			"payload": entry.get("payload", {}),
			"status": "pending",
		})

func process_turn(turn: int, tilemap: TileMapLayer) -> void:
	for ev in queue:
		if ev["status"] != "pending":
			continue
		if turn < ev["trigger_turn"]:
			continue
		if ev["event_type"] == "periodic":
			# Catch-up cycles: apply the effect once per missed interval.
			var interval: int = max(1, ev["interval_turns"])
			var missed: int = (turn - ev["trigger_turn"]) / interval + 1
			_dispatch(ev, tilemap, missed)
			ev["trigger_turn"] += missed * interval
		else:  # immediate, scheduled
			_dispatch(ev, tilemap, 1)
			ev["status"] = "executed"

func _dispatch(ev: Dictionary, tilemap: TileMapLayer, cycles: int) -> void:
	match ev["type"]:
		"hazard_regrowth":
			_hazard_regrowth(ev["payload"], tilemap, cycles)
		_:
			push_warning("WorldEvents: unknown event type '%s'" % ev["type"])

# Re-arms random explored tiles in the payload's categories (once per cycle)
# by unmarking them explored, so their event fires again on the next visit.
func _hazard_regrowth(payload: Dictionary, tilemap: TileMapLayer, cycles: int) -> void:
	var categories: Array = payload.get("categories", [])
	var candidates: Array = []
	for pos in GameState.explored_tiles:
		var td: TileData = tilemap.get_cell_tile_data(pos)
		if td == null:
			continue
		var tile_def: Dictionary = DataStore.tiles.get(td.get_custom_data("tile_id"), {})
		if categories.has(tile_def.get("category", "")):
			candidates.append(pos)
	for _i in range(cycles):
		if candidates.is_empty():
			return
		var pos: Vector2i = candidates[randi() % candidates.size()]
		GameState.unmark_explored(pos)
