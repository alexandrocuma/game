class_name HexGrid

# Returns all cells reachable within `steps` movement points from `origin`.
# Reads movement_cost from DataStore via the tile's custom data "tile_id" layer.
static func get_cells_in_range(
		tilemap: TileMapLayer,
		origin: Vector2i,
		steps: int) -> Array[Vector2i]:

	var visited: Dictionary = {origin: 0}
	var result: Array[Vector2i] = []
	var queue: Array = [{"pos": origin, "cost": 0}]

	while queue.size() > 0:
		var current: Dictionary = queue.pop_front()
		var pos: Vector2i = current["pos"]
		var spent: int = current["cost"]

		for nb: Vector2i in tilemap.get_surrounding_cells(pos):
			var cost := get_movement_cost(tilemap, nb)
			var new_cost := spent + cost
			if new_cost > steps:
				continue
			if visited.has(nb) and visited[nb] <= new_cost:
				continue
			if tilemap.get_cell_source_id(nb) == -1:
				continue
			visited[nb] = new_cost
			result.append(nb)
			queue.append({"pos": nb, "cost": new_cost})

	return result

static func get_movement_cost(tilemap: TileMapLayer, pos: Vector2i) -> int:
	var td: TileData = tilemap.get_cell_tile_data(pos)
	if td == null:
		return 1
	var tile_id: String = td.get_custom_data("tile_id")
	if tile_id == "":
		return 1
	var tile_def: Dictionary = DataStore.tiles.get(tile_id, {})
	return tile_def.get("movement_cost", 1)

static func distance(a: Vector2i, b: Vector2i) -> int:
	var c_a := _offset_to_cube(a)
	var c_b := _offset_to_cube(b)
	return (abs(c_a.x - c_b.x) + abs(c_a.y - c_b.y) + abs(c_a.z - c_b.z)) / 2

static func _offset_to_cube(h: Vector2i) -> Vector3i:
	var q := h.x - (h.y - (h.y & 1)) / 2
	var r := h.y
	return Vector3i(q, r, -q - r)

static func _cube_to_offset(c: Vector3i) -> Vector2i:
	return Vector2i(c.x + (c.y - (c.y & 1)) / 2, c.y)

# Cube direction vectors (pointy-top axial, q + r + s = 0).
const CUBE_DIRECTIONS: Array[Vector3i] = [
	Vector3i(1, 0, -1),   # East
	Vector3i(0, 1, -1),   # NorthEast
	Vector3i(-1, 1, 0),   # NorthWest
	Vector3i(-1, 0, 1),   # West
	Vector3i(0, -1, 1),   # SouthWest
	Vector3i(1, -1, 0),   # SouthEast
]

# All cells at exactly `radius` distance from `center` (empty if radius < 0).
static func ring(center: Vector2i, radius: int) -> Array[Vector2i]:
	if radius == 0:
		return [center]
	var current := _offset_to_cube(center) + CUBE_DIRECTIONS[4] * radius
	var result: Array[Vector2i] = []
	for i in range(6):
		for _j in range(radius):
			result.append(_cube_to_offset(current))
			current += CUBE_DIRECTIONS[i]
	return result

# Straight line of cells from `a` to `b` (both endpoints included).
static func line(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var n := distance(a, b)
	if n == 0:
		return [a]
	var c_a := _offset_to_cube(a)
	var c_b := _offset_to_cube(b)
	var result: Array[Vector2i] = []
	for i in range(n + 1):
		var t := float(i) / float(n)
		result.append(_cube_to_offset(_cube_round(_cube_lerp(c_a, c_b, t))))
	return result

static func _cube_lerp(a: Vector3i, b: Vector3i, t: float) -> Vector3:
	return Vector3(
		a.x * (1.0 - t) + b.x * t,
		a.y * (1.0 - t) + b.y * t,
		a.z * (1.0 - t) + b.z * t)

static func _cube_round(c: Vector3) -> Vector3i:
	var rx := roundi(c.x)
	var ry := roundi(c.y)
	var rz := roundi(c.z)
	var x_diff := absf(rx - c.x)
	var y_diff := absf(ry - c.y)
	var z_diff := absf(rz - c.z)
	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return Vector3i(rx, ry, rz)

# A* lowest-cost path from `from` to `to` (both included). Terrain cost comes
# from get_movement_cost(), distance() is the heuristic, empty cells are
# impassable. Returns [] if unreachable or the search exceeds MAX_PATH_NODES.
static func find_path(
		tilemap: TileMapLayer,
		from: Vector2i,
		to: Vector2i) -> Array[Vector2i]:

	const MAX_PATH_NODES := 10000
	if from == to:
		return [from]
	if tilemap.get_cell_source_id(to) == -1:
		return []

	var open: Array = [{"pos": from, "g": 0, "h": distance(from, to)}]
	var best_g: Dictionary = {from: 0}
	var parent: Dictionary = {}
	var closed: Dictionary = {}
	var explored := 0

	while not open.is_empty():
		explored += 1
		if explored > MAX_PATH_NODES:
			return []

		# Pop lowest f = g + h (ties prefer lower h, i.e. closer to target).
		var best := 0
		for i in range(1, open.size()):
			var f_i: int = open[i]["g"] + open[i]["h"]
			var f_b: int = open[best]["g"] + open[best]["h"]
			if f_i < f_b or (f_i == f_b and open[i]["h"] < open[best]["h"]):
				best = i
		var current: Dictionary = open[best]
		open.remove_at(best)

		var pos: Vector2i = current["pos"]
		if closed.has(pos):
			continue
		if pos == to:
			return _reconstruct_path(parent, from, to)
		closed[pos] = true

		for nb: Vector2i in tilemap.get_surrounding_cells(pos):
			if closed.has(nb):
				continue
			if tilemap.get_cell_source_id(nb) == -1:
				closed[nb] = true  # obstacle, never expand
				continue
			var g: int = current["g"] + get_movement_cost(tilemap, nb)
			if best_g.has(nb) and best_g[nb] <= g:
				continue
			best_g[nb] = g
			parent[nb] = pos
			open.append({"pos": nb, "g": g, "h": distance(nb, to)})

	return []

static func _reconstruct_path(
		parent: Dictionary,
		from: Vector2i,
		to: Vector2i) -> Array[Vector2i]:

	var path: Array[Vector2i] = [to]
	var pos := to
	while pos != from:
		pos = parent[pos]
		path.append(pos)
	path.reverse()
	return path

# Total movement cost of walking `path`, excluding the start cell.
static func path_cost(tilemap: TileMapLayer, path: Array[Vector2i]) -> int:
	var total := 0
	for i in range(1, path.size()):
		total += get_movement_cost(tilemap, path[i])
	return total
