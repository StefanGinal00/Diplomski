extends Area2D

@export var crystal_id: String = "lower"
@export var crystal_name: String = "Lower Resonator"

var player_in_range: Player
var age: float = 0.0

@onready var core: Polygon2D = $Core
@onready var glow: Polygon2D = $Glow
@onready var prompt: Label = $Prompt


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visuals()
	prompt.hide()


func _process(delta: float) -> void:
	age += delta
	glow.modulate.a = 0.68 + sin(age * 2.8) * 0.22
	glow.rotation += delta * 0.35


func _unhandled_input(event: InputEvent) -> void:
	if player_in_range == null or player_in_range.is_dead or event.is_echo() or not event.is_action_pressed("interact"):
		return
	attune(player_in_range)
	get_viewport().set_input_as_handled()


func attune(player: Player) -> bool:
	if player == null or player.is_dead:
		return false
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return false
	if not game_state.unlock_shortcut("echo_resonator_" + crystal_id):
		return false
	if _both_resonators_active(game_state) and not game_state.has_item("echo_charm"):
		game_state.add_item("echo_charm")
	_update_visuals()
	return true


func _both_resonators_active(game_state: Node) -> bool:
	return bool(game_state.unlocked_shortcuts.get("echo_resonator_lower", false)) and bool(game_state.unlocked_shortcuts.get("echo_resonator_upper", false))


func _update_visuals() -> void:
	var game_state := get_node_or_null("/root/GameState")
	var active: bool = game_state != null and bool(game_state.unlocked_shortcuts.get("echo_resonator_" + crystal_id, false))
	core.color = Color(0.48, 1.0, 0.72, 1.0) if active else Color(0.37, 0.67, 0.95, 1.0)
	glow.color = Color(0.22, 1.0, 0.62, 0.42) if active else Color(0.2, 0.68, 1.0, 0.3)
	prompt.text = "RESONATOR ACTIVE" if active else "[E] ATTUNE " + crystal_name.to_upper()


func _on_body_entered(body: Node) -> void:
	if body is Player:
		player_in_range = body
		_update_visuals()
		prompt.show()


func _on_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null
		prompt.hide()
