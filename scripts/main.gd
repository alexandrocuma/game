extends Node2D

@onready var world_map_node: Node = $WorldMap
@onready var turn_manager_node: Node = $TurnManager
@onready var event_panel_node: Control = $UI/EventPanel
@onready var world_tilemap: TileMapLayer = $WorldMap/WorldTilemap
@onready var hero_unit: Node2D = $HeroUnit

const DEFAULT_TEAM := ["fighter", "healer"]
const CAMP_TILE_POS := Vector2i(0, 0)  # Set to your camp tile's map coords

func _ready() -> void:
	GameState.init_run(DEFAULT_TEAM, CAMP_TILE_POS)
	world_map_node.setup_fog()
	_position_hero(CAMP_TILE_POS)
	turn_manager_node.start()
	turn_manager_node.hero_moved.connect(_on_hero_moved)
	turn_manager_node.game_over.connect(_on_game_over)
	turn_manager_node.game_won.connect(_on_game_won)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := world_tilemap.local_to_map(world_tilemap.get_global_mouse_position())
		turn_manager_node.request_move(cell)

func _on_hero_moved(_from: Vector2i, to: Vector2i) -> void:
	_position_hero(to)
	# Animate here if desired, then call:
	# turn_manager_node.notify_animation_done(to)
	# For now movement is instant — TurnManager._do_move() calls _on_animation_done directly.

func _position_hero(map_pos: Vector2i) -> void:
	if hero_unit and world_tilemap:
		hero_unit.position = world_tilemap.map_to_local(map_pos)

func _on_game_over() -> void:
	# TODO: show game over screen
	print("Game over")

func _on_game_won() -> void:
	# TODO: show win screen
	print("You won!")
