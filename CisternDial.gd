extends Area2D

@export_range(0, 2) var dial_index: int = 0
@export var dial_name: String = "NEAR DIAL"
@export var activation_prompt: String = "[E] TURN DIAL"
@export var complete_prompt: String = "PUMP RUNNING"

var player_in_range: Player

@onready var core: Polygon2D = $Core
@onready var glow: Polygon2D = $Glow
@onready var status_label: Label = $StatusLabel
@onready var interaction_prompt: Label = $InteractionPrompt


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	interaction_prompt.hide()


func _process(_delta: float) -> void:
	glow.modulate.a = 0.5 + 0.2 * sin(Time.get_ticks_msec() * 0.004 + dial_index)


func _unhandled_input(event: InputEvent) -> void:
	if player_in_range == null or event.is_echo() or not event.is_action_pressed("interact"):
		return
	activate(player_in_range)
	get_viewport().set_input_as_handled()


func activate(player: Player) -> bool:
	if player == null or player.is_dead:
		return false
	return get_parent().attempt_dial(dial_index, player)


func set_progress(progress: int, completed: bool) -> void:
	var attuned := completed or dial_index < progress
	var next_dial := not completed and dial_index == progress
	core.color = Color(0.27, 0.94, 0.65, 1.0) if attuned else (Color(0.32, 0.8, 0.94, 1.0) if next_dial else Color(0.32, 0.51, 0.65, 1.0))
	glow.color = Color(0.25, 0.9, 0.62, 0.34) if attuned else (Color(0.3, 0.78, 0.95, 0.38) if next_dial else Color(0.15, 0.43, 0.6, 0.2))
	status_label.text = "%s  %d/3" % [dial_name, dial_index + 1]
	interaction_prompt.text = complete_prompt if completed else ("ALREADY SET" if attuned else (activation_prompt if next_dial else "WRONG ORDER RESETS"))
	interaction_prompt.visible = player_in_range != null


func _on_body_entered(body: Node) -> void:
	if body is Player:
		player_in_range = body
		interaction_prompt.show()


func _on_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null
		interaction_prompt.hide()
