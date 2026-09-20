extends Area2D

signal valve_activated

@export var shortcut_id: String = "shaft_sluice_valve"
@export var inactive_label: String = "SLUICE VALVE"
@export var active_label: String = "SLUICE DRAINED"
@export var inactive_prompt: String = "[E] DRAIN THE CROSSING"
@export var active_prompt: String = "CURRENT STOPPED"

var player_in_range: Player
var is_active: bool = false

@onready var core: Polygon2D = $Core
@onready var glow: Polygon2D = $Glow
@onready var status_label: Label = $StatusLabel
@onready var interaction_prompt: Label = $InteractionPrompt


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		is_active = bool(game_state.unlocked_shortcuts.get(shortcut_id, false))
		game_state.shortcut_changed.connect(_on_shortcut_changed)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visuals()


func _process(_delta: float) -> void:
	glow.modulate.a = 0.55 + 0.2 * sin(Time.get_ticks_msec() * 0.003)


func _unhandled_input(event: InputEvent) -> void:
	if player_in_range == null or event.is_echo() or not event.is_action_pressed("interact"):
		return
	activate(player_in_range)
	get_viewport().set_input_as_handled()


func activate(player: Player) -> bool:
	if player == null or player.is_dead or is_active:
		return false
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or not game_state.unlock_shortcut(shortcut_id):
		return false
	is_active = true
	_update_visuals()
	valve_activated.emit()
	return true


func _on_shortcut_changed(shortcut_id: String) -> void:
	if shortcut_id == self.shortcut_id:
		is_active = true
		_update_visuals()


func _update_visuals() -> void:
	core.color = Color(0.34, 0.96, 0.7, 1.0) if is_active else Color(0.3, 0.72, 0.95, 1.0)
	glow.color = Color(0.2, 0.85, 0.56, 0.26) if is_active else Color(0.16, 0.66, 0.96, 0.34)
	status_label.text = active_label if is_active else inactive_label
	interaction_prompt.text = active_prompt if is_active else inactive_prompt
	interaction_prompt.visible = player_in_range != null


func _on_body_entered(body: Node) -> void:
	if body is Player:
		player_in_range = body
		_update_visuals()


func _on_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null
		_update_visuals()
