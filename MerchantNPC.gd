extends Area2D

signal interaction_requested(npc: Area2D)

var player_in_range: Player

@onready var interaction_prompt: Label = $InteractionPrompt
@onready var body_visual: Polygon2D = $BodyVisual


func _ready() -> void:
	interaction_prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	body_visual.modulate.a = 0.88 + sin(Time.get_ticks_msec() * 0.003) * 0.12


func _unhandled_input(event: InputEvent) -> void:
	if player_in_range == null or event.is_echo() or not event.is_action_pressed("interact"):
		return
	interaction_requested.emit(self)
	get_viewport().set_input_as_handled()


func _on_body_entered(body: Node) -> void:
	if body is Player:
		player_in_range = body
		interaction_prompt.show()


func _on_body_exited(body: Node) -> void:
	if body != player_in_range:
		return
	player_in_range = null
	interaction_prompt.hide()
