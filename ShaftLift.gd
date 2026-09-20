extends Area2D

signal shortcut_activated(shortcut_id: String)
signal lift_blocked(message: String)

@export var shortcut_id: String = "shaft_lift"
@export var target_marker_group: StringName
@export var activates_shortcut: bool = false
@export var enemy_block_radius: float = 105.0
@export var room_id: String = "sunken_shaft"
@export var enemy_group: StringName = &"shaft_enemy"
@export var lift_label: String = "SHAFT LIFT"

var player_in_range: Player
var in_transit: bool = false

@onready var prompt: Label = $Prompt
@onready var core: Polygon2D = $Core


func _ready() -> void:
	prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visuals()


func _process(_delta: float) -> void:
	core.modulate.a = 0.72 + sin(Time.get_ticks_msec() * 0.004) * 0.22


func _unhandled_input(event: InputEvent) -> void:
	if player_in_range == null or in_transit or event.is_echo() or not event.is_action_pressed("interact"):
		return
	if _has_nearby_enemy():
		lift_blocked.emit("Clear nearby enemies before using the lift.")
		get_viewport().set_input_as_handled()
		return
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return
	if not bool(game_state.unlocked_shortcuts.get(shortcut_id, false)):
		if not activates_shortcut:
			lift_blocked.emit("The lift must be activated from below.")
			get_viewport().set_input_as_handled()
			return
		if game_state.unlock_shortcut(shortcut_id):
			shortcut_activated.emit(shortcut_id)
		_update_visuals()
	_use_lift(player_in_range)
	get_viewport().set_input_as_handled()


func _use_lift(player: Player) -> void:
	var destination := get_tree().get_first_node_in_group(target_marker_group) as Node2D
	var transition_manager := get_node_or_null("/root/RoomTransition")
	if player == null or destination == null or transition_manager == null:
		lift_blocked.emit("The lift mechanism is jammed.")
		return
	in_transit = true
	await transition_manager.transition_player(player, destination.global_position, room_id)
	in_transit = false
	_update_visuals()


func _has_nearby_enemy() -> bool:
	for enemy in get_tree().get_nodes_in_group(enemy_group):
		if enemy is Node2D and is_instance_valid(enemy) and not bool(enemy.get("is_dead")):
			if global_position.distance_to(enemy.global_position) <= enemy_block_radius:
				return true
	return false


func _update_visuals() -> void:
	var game_state := get_node_or_null("/root/GameState")
	var unlocked: bool = game_state != null and bool(game_state.unlocked_shortcuts.get(shortcut_id, false))
	core.color = Color(0.2, 1.0, 0.82, 1.0) if unlocked else Color(0.55, 0.45, 0.68, 1.0)
	prompt.text = "[E] " + lift_label if unlocked else ("[E] ACTIVATE " + lift_label if activates_shortcut else "LIFT LOCKED BELOW")


func _on_body_entered(body: Node) -> void:
	if body is Player:
		player_in_range = body
		_update_visuals()
		prompt.show()


func _on_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null
		prompt.hide()
