extends Node

@onready var world_tilemap: TileMapLayer = $WorldTilemap
@onready var fog_tilemap: TileMapLayer = $FogTilemap

# Tiles are 120x140 pointy-top hexes (Kenney Hexagon Pack).
const TILE_SIZE := Vector2i(120, 140)
const MAP_LAYOUT_PATH := "res://docs/content/world-map.json"
const FOG_TEXTURE_PATH := "res://themes/fantasy/assets/fog_hex.png"
const FOG_SOURCE_ID := 0
const FOG_ATLAS_COORDS := Vector2i(0, 0)

var _tile_sources: Dictionary = {}  # tile_id -> atlas source id

func _ready() -> void:
	_build_tilesets()
	_place_map()

# Builds both TileSets at runtime from theme sprite paths, so the map
# is data (world-map.json + tile_overrides.json), not editor-painted binary.
func _build_tilesets() -> void:
	var ts := _new_hex_tileset()
	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(0, "tile_id")
	ts.set_custom_data_layer_type(0, TYPE_STRING)

	var source_id := 0
	for tile_id: String in DataStore.tiles:
		var sprite: String = DataStore.tiles[tile_id].get("sprite", "")
		if sprite == "" or not ResourceLoader.exists(sprite):
			push_warning("WorldMap: no sprite for tile '%s'" % tile_id)
			continue
		var src := TileSetAtlasSource.new()
		src.texture = load(sprite)
		src.texture_region_size = TILE_SIZE
		src.create_tile(Vector2i.ZERO)
		ts.add_source(src, source_id)
		src.get_tile_data(Vector2i.ZERO, 0).set_custom_data("tile_id", tile_id)
		_tile_sources[tile_id] = source_id
		source_id += 1
	world_tilemap.tile_set = ts

	var fog_ts := _new_hex_tileset()
	var fog_src := TileSetAtlasSource.new()
	fog_src.texture = load(FOG_TEXTURE_PATH)
	fog_src.texture_region_size = TILE_SIZE
	fog_src.create_tile(Vector2i.ZERO)
	fog_ts.add_source(fog_src, FOG_SOURCE_ID)
	fog_tilemap.tile_set = fog_ts

func _new_hex_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_HEXAGON
	ts.tile_layout = TileSet.TILE_LAYOUT_STACKED
	ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	ts.tile_size = TILE_SIZE
	return ts

func _place_map() -> void:
	if not FileAccess.file_exists(MAP_LAYOUT_PATH):
		push_error("WorldMap: missing map layout %s" % MAP_LAYOUT_PATH)
		return
	var f := FileAccess.open(MAP_LAYOUT_PATH, FileAccess.READ)
	var layout = JSON.parse_string(f.get_as_text())
	if layout == null:
		push_error("WorldMap: failed to parse %s" % MAP_LAYOUT_PATH)
		return
	for entry: Dictionary in layout:
		var tile_id: String = entry["tile"]
		if not _tile_sources.has(tile_id):
			push_warning("WorldMap: unknown tile '%s' in map layout" % tile_id)
			continue
		var pos := Vector2i(int(entry["pos"][0]), int(entry["pos"][1]))
		world_tilemap.set_cell(pos, _tile_sources[tile_id], Vector2i.ZERO)

func setup_fog() -> void:
	for cell: Vector2i in world_tilemap.get_used_cells():
		fog_tilemap.set_cell(cell, FOG_SOURCE_ID, FOG_ATLAS_COORDS)

func reveal_around(center: Vector2i, radius: int) -> void:
	# Fog clearing only — do NOT mark explored here. "Explored" means
	# "visited by the team" (GameState.mark_explored on entry); revealed
	# tiles around the team are visible but their events must still fire.
	for pos in _cells_within_radius(center, radius):
		fog_tilemap.erase_cell(pos)

func get_tile_id(pos: Vector2i) -> String:
	var td: TileData = world_tilemap.get_cell_tile_data(pos)
	if td == null:
		return ""
	var id = td.get_custom_data("tile_id")
	return id if id != null else ""

func get_tile_def(pos: Vector2i) -> Dictionary:
	var id := get_tile_id(pos)
	return DataStore.tiles.get(id, {})

func apply_watchtower() -> void:
	reveal_around(GameState.camp_position, 2)

func _cells_within_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var seen: Dictionary = {center: true}
	var result: Array[Vector2i] = [center]
	var queue: Array = [{"pos": center, "depth": 0}]
	while queue.size() > 0:
		var cur: Dictionary = queue.pop_front()
		if cur["depth"] >= radius:
			continue
		for nb: Vector2i in world_tilemap.get_surrounding_cells(cur["pos"]):
			if seen.has(nb):
				continue
			if world_tilemap.get_cell_source_id(nb) == -1:
				continue
			seen[nb] = true
			result.append(nb)
			queue.append({"pos": nb, "depth": cur["depth"] + 1})
	return result
