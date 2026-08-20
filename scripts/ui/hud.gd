extends Control

@onready var turn_manager: Node = get_node("../../TurnManager")

@onready var turn_label: Label = $TurnLabel
@onready var food_label: Label = $ResourceRow/FoodLabel
@onready var gold_label: Label = $ResourceRow/GoldLabel
@onready var materials_label: Label = $ResourceRow/MaterialsLabel
@onready var hero_bars: VBoxContainer = $HeroBars
@onready var camp_panel: Control = $CampPanel
@onready var camp_rest_btn: Button = $CampPanel/RestButton
@onready var camp_build_container: VBoxContainer = $CampPanel/BuildContainer

func _ready() -> void:
	turn_manager.world_ticked.connect(_refresh.unbind(1))
	turn_manager.state_changed.connect(_on_state_changed)
	camp_rest_btn.pressed.connect(func(): turn_manager.request_camp_action("rest"))
	camp_panel.hide()
	_refresh()

func _refresh() -> void:
	turn_label.text = "Turn %d" % GameState.turn
	food_label.text = "Food %d" % GameState.resources.get("food", 0)
	gold_label.text = "Gold %d" % GameState.resources.get("gold", 0)
	materials_label.text = "Mat %d" % GameState.resources.get("materials", 0)
	_refresh_hero_bars()

func _refresh_hero_bars() -> void:
	for child in hero_bars.get_children():
		child.queue_free()
	for hero in GameState.team:
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = hero["max_hp"]
		bar.value = hero["hp"]
		bar.custom_minimum_size = Vector2(0, 20)
		hero_bars.add_child(bar)

func _on_state_changed(new_state: int) -> void:
	_refresh()
	var is_camp := new_state == 3  # State.CAMP
	if is_camp:
		_show_camp_panel()
	else:
		camp_panel.hide()

func _show_camp_panel() -> void:
	camp_panel.show()
	for child in camp_build_container.get_children():
		child.queue_free()

	for id in DataStore.upgrades:
		if id in GameState.camp_upgrades:
			continue
		var upgrade: Dictionary = DataStore.upgrades[id]
		var btn := Button.new()
		btn.text = "Build: %s" % upgrade.get("label", id)
		var uid: String = id
		btn.pressed.connect(func(): turn_manager.request_camp_action(uid))
		camp_build_container.add_child(btn)
