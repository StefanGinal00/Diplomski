extends Area2D

@export var event_id: String = ""
@export var relay_name: String = "WARD RELAY"

var nearby_player: Player

@onready var core: Polygon2D = $Core
@onready var glow: Polygon2D = $Glow
@onready var status_label: Label = $StatusLabel
@onready var interaction_prompt: Label = $InteractionPrompt


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	input_event.connect(_on_input_event)
	interaction_prompt.hide()
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.shortcut_changed.connect(_on_shortcut_changed)
	_refresh()


func _process(_delta: float) -> void:
	glow.modulate.a = 0.55 + 0.2 * sin(Time.get_ticks_msec() * 0.004)


func _unhandled_input(event: InputEvent) -> void:
	if nearby_player == null or event.is_echo() or not event.is_action_pressed("interact"):
		return
	activate(nearby_player)
	get_viewport().set_input_as_handled()


func _on_input_event(viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if nearby_player == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		activate(nearby_player)
		viewport.set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		activate(nearby_player)
		viewport.set_input_as_handled()


func activate(player: Player) -> bool:
	if player == null or player.is_dead or event_id.is_empty():
		return false
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return false
	return game_state.unlock_shortcut(event_id)


func _on_body_entered(body: Node) -> void:
	if body is Player:
		nearby_player = body
		interaction_prompt.show()


func _on_body_exited(body: Node) -> void:
	if body == nearby_player:
		nearby_player = null
		interaction_prompt.hide()


func _on_shortcut_changed(shortcut_id: String) -> void:
	if shortcut_id == event_id:
		_refresh()


func _refresh() -> void:
	var game_state := get_node_or_null("/root/GameState")
	var active := game_state != null and bool(game_state.unlocked_shortcuts.get(event_id, false))
	core.color = Color(0.44, 1.0, 0.78, 1.0) if active else Color(0.75, 0.62, 0.98, 1.0)
	glow.color = Color(0.3, 0.95, 0.7, 0.35) if active else Color(0.62, 0.41, 0.9, 0.28)
	status_label.text = relay_name + ("  ACTIVE" if active else "  DORMANT")
	interaction_prompt.text = "RELAY ATTUNED" if active else "[E / CLICK] ATTUNE"
