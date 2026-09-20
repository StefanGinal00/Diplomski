extends Area2D

@export var target_marker_group: StringName
@export var target_room_id: String = "training_passage"
@export var door_label: String = "RETURN"
@export var required_item_id: String = ""
@export var required_item_ids: PackedStringArray = []
@export var required_boss_ids: PackedStringArray = []
@export var required_event_ids: PackedStringArray = []
@export var locked_label: String = "SEALED"
@export var locked_hint: String = ""

var transition_in_progress: bool = false
var blocked_player: Player

@onready var status_label: Label = $StatusLabel

signal access_denied(message: String)


func _ready() -> void:
	_update_status_label()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if not required_item_id.is_empty() or not required_item_ids.is_empty() or not required_boss_ids.is_empty() or not required_event_ids.is_empty():
		_update_status_label()


func _unhandled_input(event: InputEvent) -> void:
	if blocked_player == null or event.is_echo() or not event.is_action_pressed("interact"):
		return
	if _requirements_met():
		var player := blocked_player
		blocked_player = null
		_on_body_entered(player)
	else:
		access_denied.emit(_get_lock_reason())
	get_viewport().set_input_as_handled()


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


func _update_status_label() -> void:
	status_label.text = door_label if _requirements_met() else locked_label


func _on_body_entered(body: Node) -> void:
	if transition_in_progress or not body.is_in_group("player") or not body is Player:
		return
	if not _requirements_met():
		blocked_player = body
		access_denied.emit(_get_lock_reason())
		return
	var target := get_tree().get_first_node_in_group(target_marker_group) as Node2D
	var transition_manager := get_node_or_null("/root/RoomTransition")
	if target == null or transition_manager == null:
		push_warning("Room door could not resolve transition target: " + str(target_marker_group))
		return
	transition_in_progress = true
	set_deferred("monitoring", false)
	await transition_manager.transition_player(body, target.global_position, target_room_id)
	set_deferred("monitoring", true)
	transition_in_progress = false


func _on_body_exited(body: Node) -> void:
	if body == blocked_player:
		blocked_player = null
