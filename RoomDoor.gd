extends Area2D

@export var target_marker_group: StringName
@export var target_room_id: String = "training_passage"
@export var door_label: String = "RETURN"
@export var first_visit_marker_group: StringName
@export var first_visit_room_id: String = ""
@export var first_visit_label: String = ""
@export var required_item_id: String = ""
@export var required_item_ids: PackedStringArray = []
@export var required_boss_ids: PackedStringArray = []
@export var required_event_ids: PackedStringArray = []
@export var locked_label: String = "SEALED"
@export var locked_hint: String = ""

var transition_in_progress: bool = false
var nearby_player: Player
var encounter_locked: bool = false
var default_frame_color: Color

@onready var status_label: Label = $StatusLabel
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var frame: Polygon2D = $Frame

signal access_denied(message: String)


func _ready() -> void:
	default_frame_color = frame.color
	_update_status_label()
	interaction_prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	input_event.connect(_on_input_event)


func _process(_delta: float) -> void:
	var locked_now := _encounter_locked()
	if locked_now != encounter_locked or not first_visit_room_id.is_empty() or not required_item_id.is_empty() or not required_item_ids.is_empty() or not required_boss_ids.is_empty() or not required_event_ids.is_empty():
		encounter_locked = locked_now
		_update_status_label()


func _unhandled_input(event: InputEvent) -> void:
	if nearby_player == null or transition_in_progress or event.is_echo() or not event.is_action_pressed("interact"):
		return
	activate(nearby_player)
	get_viewport().set_input_as_handled()


func _on_input_event(viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if nearby_player == null or transition_in_progress:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		activate(nearby_player)
		viewport.set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		activate(nearby_player)
		viewport.set_input_as_handled()


func _has_required_item() -> bool:
	return _requirements_met()


func _requirements_met() -> bool:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return false
	if not required_item_id.is_empty() and not game_state.has_item(required_item_id):
		return false
	for item_id in required_item_ids:
		if not game_state.has_item(item_id):
			return false
	for boss_id in required_boss_ids:
		if not bool(game_state.defeated_bosses.get(boss_id, false)):
			return false
	for event_id in required_event_ids:
		if not bool(game_state.unlocked_shortcuts.get(event_id, false)):
			return false
	return true


func _get_lock_reason() -> String:
	if not locked_hint.is_empty():
		return locked_hint
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return "The passage is sealed."
	for boss_id in required_boss_ids:
		if not bool(game_state.defeated_bosses.get(boss_id, false)):
			return "Defeat %s to open this passage." % boss_id.replace("_", " ").capitalize()
	var all_items := PackedStringArray()
	if not required_item_id.is_empty():
		all_items.append(required_item_id)
	all_items.append_array(required_item_ids)
	for item_id in all_items:
		if not game_state.has_item(item_id):
			return "Requires %s." % str(game_state.get_item_definition(item_id).get("name", item_id))
	for event_id in required_event_ids:
		if not bool(game_state.unlocked_shortcuts.get(event_id, false)):
			return "Another path in this area remains unexplored."
	return "The passage is sealed."


func _encounter_locked() -> bool:
	var game_state := get_node_or_null("/root/GameState")
	return game_state != null and game_state.is_boss_encounter_active()


func _uses_first_visit_route() -> bool:
	if first_visit_room_id.is_empty() or first_visit_marker_group == &"":
		return false
	var game_state := get_node_or_null("/root/GameState")
	return game_state != null and not bool(game_state.discovered_rooms.get(target_room_id, false))


func _update_status_label() -> void:
	if _encounter_locked():
		status_label.text = "BATTLE SEALED"
		interaction_prompt.text = "[E / CLICK] BOSS FIGHT"
		frame.color = Color(0.72, 0.24, 0.34, 1.0)
		return
	frame.color = default_frame_color
	var unlocked := _requirements_met()
	status_label.text = (first_visit_label if _uses_first_visit_route() and not first_visit_label.is_empty() else door_label) if unlocked else locked_label
	interaction_prompt.text = "[E / CLICK] ENTER" if unlocked else "[E / CLICK] EXAMINE"


func _on_body_entered(body: Node) -> void:
	if transition_in_progress or not body is Player or not body.is_in_group("player"):
		return
	nearby_player = body
	_update_status_label()
	interaction_prompt.show()
	frame.modulate = Color(1.3, 1.2, 0.85, 1.0)


func activate(player: Player) -> void:
	if transition_in_progress or player == null or player.is_dead:
		return
	if _encounter_locked():
		_update_status_label()
		access_denied.emit("The passage is sealed until the boss fight ends.")
		return
	if not _requirements_met():
		access_denied.emit(_get_lock_reason())
		return
	var first_visit := _uses_first_visit_route()
	var destination_marker: StringName = first_visit_marker_group if first_visit else target_marker_group
	var destination_room: String = first_visit_room_id if first_visit else target_room_id
	var target := get_tree().get_first_node_in_group(destination_marker) as Node2D
	var transition_manager := get_node_or_null("/root/RoomTransition")
	if target == null or transition_manager == null:
		push_warning("Room door could not resolve transition target: " + str(destination_marker))
		return
	transition_in_progress = true
	nearby_player = null
	interaction_prompt.hide()
	frame.modulate = Color.WHITE
	set_deferred("monitoring", false)
	await transition_manager.transition_player(player, target.global_position, destination_room)
	set_deferred("monitoring", true)
	transition_in_progress = false


func _on_body_exited(body: Node) -> void:
	if body == nearby_player:
		nearby_player = null
		interaction_prompt.hide()
		frame.modulate = Color.WHITE
