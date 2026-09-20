extends Area2D

signal relay_activated
signal relay_blocked(message: String)

const SHORTCUT_ID := "shaft_hollow_relay"

var player_in_range: Player
var is_active: bool = false

@onready var core: Polygon2D = $Core
@onready var glow: Polygon2D = $Glow
@onready var status_label: Label = $StatusLabel
@onready var interaction_prompt: Label = $InteractionPrompt


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		is_active = bool(game_state.unlocked_shortcuts.get(SHORTCUT_ID, false))
		game_state.shortcut_changed.connect(_on_shortcut_changed)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visuals()


func _process(_delta: float) -> void:
	glow.modulate.a = 0.55 + 0.25 * sin(Time.get_ticks_msec() * 0.003)
	if player_in_range != null and not is_active:
		_update_visuals()


func _unhandled_input(event: InputEvent) -> void:
	if player_in_range == null or event.is_echo() or not event.is_action_pressed("interact"):
		return
	activate(player_in_range)
	get_viewport().set_input_as_handled()


func activate(player: Player) -> bool:
	if player == null or player.is_dead or is_active:
		return false
	var remaining := _remaining_guardians()
	if remaining > 0:
		relay_blocked.emit("Clear the %d Hollow wisps first." % remaining)
		return false
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or not game_state.unlock_shortcut(SHORTCUT_ID):
		return false
	is_active = true
	_update_visuals()
	relay_activated.emit()
	return true


func _remaining_guardians() -> int:
	var remaining := 0
	for guardian in get_tree().get_nodes_in_group("hollow_guardian"):
		if is_instance_valid(guardian) and not guardian.is_queued_for_deletion() and not bool(guardian.get("is_dead")):
			remaining += 1
	return remaining


func _update_visuals() -> void:
	core.color = Color(0.55, 1.0, 0.86, 1.0) if is_active else Color(0.4, 0.3, 0.7, 1.0)
	glow.color = Color(0.16, 0.95, 0.78, 0.34) if is_active else Color(0.45, 0.2, 0.75, 0.24)
	status_label.text = "RELAY ACTIVE" if is_active else "HOLLOW RELAY"
	if is_active:
		interaction_prompt.text = "LOWER PASSAGE OPEN"
	else:
		var remaining := _remaining_guardians()
		interaction_prompt.text = "CLEAR WISPS %d LEFT" % remaining if remaining > 0 else "[E] ACTIVATE RELAY"
	interaction_prompt.visible = player_in_range != null


func _on_shortcut_changed(shortcut_id: String) -> void:
	if shortcut_id == SHORTCUT_ID:
		is_active = true
		_update_visuals()


func _on_body_entered(body: Node) -> void:
	if body is Player:
		player_in_range = body
		_update_visuals()


func _on_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null
		_update_visuals()
