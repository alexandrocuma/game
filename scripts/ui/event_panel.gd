extends Control

@onready var event_manager: Node = get_node("../../EventManager")
@onready var turn_manager: Node = get_node("../../TurnManager")

@onready var title_label: Label = $TitleLabel
@onready var desc_label: Label = $DescLabel
@onready var choices_box: VBoxContainer = $ChoicesBox
@onready var continue_btn: Button = $ContinueButton
@onready var result_label: Label = $ResultLabel

var _current_event: Dictionary = {}

func _ready() -> void:
	event_manager.event_started.connect(_on_event_started)
	event_manager.choice_required.connect(_on_choice_required)
	event_manager.combat_resolved.connect(_on_combat_resolved)
	event_manager.event_resolved.connect(_on_event_resolved)
	continue_btn.pressed.connect(_on_continue_pressed)
	turn_manager.level_up_pending.connect(_on_level_up_pending)
	hide()

func _on_event_started(event: Dictionary) -> void:
	_current_event = event
	_populate_header(event)
	_clear_choices()
	result_label.text = ""
	continue_btn.show()
	choices_box.hide()
	show()

func _on_choice_required(event: Dictionary) -> void:
	_current_event = event
	_populate_header(event)
	_clear_choices()
	result_label.text = ""
	continue_btn.hide()
	choices_box.show()

	var choices: Array = event.get("choices", [])
	for i in range(choices.size()):
		var btn := Button.new()
		btn.text = _choice_label(choices[i], i)
		var idx := i
		btn.pressed.connect(func(): _pick_choice(idx))
		choices_box.add_child(btn)

# Appends an outcome hint to a choice label, generated from the outcome data
# itself — so any encounter added to event-catalog.json explains itself.
func _choice_label(choice: Dictionary, index: int) -> String:
	var label: String = choice.get("label", "Option %d" % index)
	var hint: String = _outcome_hint(choice.get("outcome", {}))
	return label if hint == "" else "%s (%s)" % [label, hint]

func _outcome_hint(outcome: Dictionary) -> String:
	var outcome_type: String = outcome.get("type", "")
	if outcome_type == "nothing":
		return "nothing happens"
	if outcome_type != "resource_gain":
		return ""
	var parts: Array[String] = []
	for key: String in outcome:
		if key in ["type", "team_morale"]:
			continue
		var val: int = int(outcome[key])
		parts.append("%+d %s" % [val, key])
	return ", ".join(parts)

func _on_combat_resolved(outcome: Dictionary) -> void:
	var res: String = outcome.get("result", "")
	result_label.text = "Victory!" if res == "victory" else "Defeated — retreating..."

func _on_event_resolved(result: Dictionary) -> void:
	var type: String = result.get("type", "")
	match type:
		"gather":
			var gained: Dictionary = result.get("resources", {})
			result_label.text = "Found: " + _format_resources(gained)
		"quiet":
			result_label.text = "Nothing happened."
		"win":
			result_label.text = "You reached the destination!"
	_clear_choices()
	choices_box.hide()
	continue_btn.show()

func _on_level_up_pending(hero_index: int, perks: Array) -> void:
	var hero: Dictionary = GameState.team[hero_index]
	title_label.text = "Level Up! — %s (Lv %d)" % [hero["id"], hero["level"]]
	desc_label.text = "Choose a perk:"
	_clear_choices()
	choices_box.show()
	continue_btn.hide()
	result_label.text = ""

	for perk in perks:
		var btn := Button.new()
		btn.text = perk
		var p: String = perk
		btn.pressed.connect(func(): _pick_perk(hero_index, p))
		choices_box.add_child(btn)
	show()

func _pick_choice(index: int) -> void:
	_clear_choices()
	choices_box.hide()
	event_manager.resolve_choice(_current_event, index)

func _pick_perk(hero_index: int, perk: String) -> void:
	_clear_choices()
	choices_box.hide()
	turn_manager.resolve_perk(hero_index, perk)
	hide()

func _on_continue_pressed() -> void:
	hide()

func _populate_header(event: Dictionary) -> void:
	var theme := DataStore.active_theme
	var variant: Dictionary = event.get("theme_variants", {}).get(theme, {})
	title_label.text = event.get("title", variant.get("title", event.get("id", "Event")))
	desc_label.text = event.get("description", variant.get("description", ""))

func _clear_choices() -> void:
	for child in choices_box.get_children():
		child.queue_free()

func _format_resources(res: Dictionary) -> String:
	var parts: Array = []
	for key in res:
		parts.append("%s +%d" % [key, res[key]])
	return ", ".join(parts)
