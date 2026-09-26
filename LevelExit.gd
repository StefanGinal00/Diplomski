class_name LevelExit
extends Area2D

signal unlocked
signal level_completed
signal access_denied(message: String)

@export var locked_color: Color = Color(0.38, 0.42, 0.5, 1.0)
@export var unlocked_color: Color = Color(0.18, 0.95, 0.78, 1.0)
@export_range(0.1, 10.0, 0.1) var pulse_speed: float = 3.0
@export var target_marker_group: StringName
@export var target_room_id: String = ""
@export var required_enemy_group: StringName = &"enemy"

var is_unlocked: bool = false
var remaining_enemies: int = 0
var pulse_time: float = 0.0
var transition_in_progress: bool = false
var nearby_player: Player

@onready var frame: Polygon2D = $Frame
@onready var core: Polygon2D = $Core
@onready var status_label: Label = $StatusLabel
@onready var interaction_prompt: Label = $InteractionPrompt


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	input_event.connect(_on_input_event)
	interaction_prompt.hide()
	_set_locked_visuals()
	call_deferred("_track_enemies")


func _process(delta: float) -> void:
	if not is_unlocked:
		return

	pulse_time += delta
	core.modulate.a = 0.55 + sin(pulse_time * pulse_speed) * 0.25


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


func _track_enemies() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if target_room_id == "sunken_shaft" and game_state != null and bool(game_state.defeated_bosses.get("void_sentinel", false)):
		unlock_exit()
		return
	var enemies := get_tree().get_nodes_in_group(required_enemy_group)
	remaining_enemies = enemies.size()
	for enemy in enemies:
		var callback := Callable(self, "_on_enemy_defeated")
		if enemy.has_signal("defeated") and not enemy.is_connected("defeated", callback):
			enemy.connect("defeated", callback)

	if remaining_enemies == 0:
		unlock_exit()


func _on_enemy_defeated() -> void:
	remaining_enemies = maxi(remaining_enemies - 1, 0)
	if remaining_enemies == 0:
		unlock_exit()


func unlock_exit() -> void:
	if is_unlocked:
		return

	is_unlocked = true
	frame.color = unlocked_color
	core.color = Color(unlocked_color.r, unlocked_color.g, unlocked_color.b, 0.7)
	status_label.text = "ENTER" if not target_marker_group.is_empty() else "EXIT"
	status_label.modulate = unlocked_color
	interaction_prompt.text = "[E / CLICK] ENTER"
	unlocked.emit()


func _set_locked_visuals() -> void:
	frame.color = locked_color
	core.color = Color(0.2, 0.08, 0.12, 0.75)
	core.modulate.a = 1.0
	status_label.text = "LOCKED"
	status_label.modulate = Color(1.0, 0.42, 0.38, 1.0)
	interaction_prompt.text = "DEFEAT ENEMIES"


func _on_body_entered(body: Node) -> void:
	if transition_in_progress or not body is Player or not body.is_in_group("player"):
		return
	nearby_player = body
	interaction_prompt.show()
	frame.modulate = Color(1.3, 1.2, 0.85, 1.0)


func _on_body_exited(body: Node) -> void:
	if body == nearby_player:
		nearby_player = null
		interaction_prompt.hide()
		frame.modulate = Color.WHITE


func activate(player: Player) -> void:
	if transition_in_progress or player == null or player.is_dead:
		return
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.is_boss_encounter_active():
		access_denied.emit("The passage is sealed until the boss fight ends.")
		return
	if not is_unlocked:
		access_denied.emit("Defeat the remaining enemies before entering.")
		return
	nearby_player = null
	interaction_prompt.hide()
	frame.modulate = Color.WHITE

	if target_marker_group.is_empty():
		transition_in_progress = true
		set_deferred("monitoring", false)
		level_completed.emit()
		return

	var target := get_tree().get_first_node_in_group(target_marker_group) as Node2D
	var transition_manager := get_node_or_null("/root/RoomTransition")
	if target == null or transition_manager == null:
		push_warning("Level exit could not resolve transition target: " + str(target_marker_group))
		return
	transition_in_progress = true
	set_deferred("monitoring", false)
	await transition_manager.transition_player(player, target.global_position, target_room_id)
	set_deferred("monitoring", true)
	transition_in_progress = false
