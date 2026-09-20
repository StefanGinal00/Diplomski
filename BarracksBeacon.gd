extends Area2D

@export var inactive_prompt: String = "[E] START BARRACKS TRIAL"
@export var completed_prompt: String = "SIGNAL COMPLETE"
@export var total_waves: int = 2

var player_in_range: Player

@onready var glow: Polygon2D = $Glow
@onready var core: Polygon2D = $Core
@onready var prompt: Label = $Prompt


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if player_in_range == null or event.is_echo() or not event.is_action_pressed("interact"):
		return
	var trial := get_parent()
	if trial.start_trial(player_in_range):
		get_viewport().set_input_as_handled()


func refresh() -> void:
	if prompt == null:
		return
	var trial := get_parent()
	if trial.completed:
		prompt.text = completed_prompt
		core.color = Color(0.38, 0.88, 0.65, 1)
		glow.color = Color(0.17, 0.7, 0.45, 0.24)
	elif trial.active:
		prompt.text = "WAVE %d/%d  •  %d LEFT" % [trial.wave, total_waves, trial.enemies_remaining]
		core.color = Color(1, 0.58, 0.18, 1)
		glow.color = Color(0.95, 0.33, 0.1, 0.38)
	else:
		prompt.text = inactive_prompt
		core.color = Color(0.96, 0.33, 0.17, 1)
		glow.color = Color(0.9, 0.24, 0.13, 0.25)
	prompt.visible = player_in_range != null


func _on_body_entered(body: Node) -> void:
	if body is Player:
		player_in_range = body
		refresh()


func _on_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null
		refresh()
