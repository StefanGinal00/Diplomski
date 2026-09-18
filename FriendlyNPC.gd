extends Area2D

signal interaction_requested(npc: Area2D)

var player_in_range: Node

@onready var interaction_prompt: Label = $InteractionPrompt


func _ready() -> void:
	interaction_prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if player_in_range == null or not event.is_action_pressed("interact"):
		return

	interaction_requested.emit(self)
	get_viewport().set_input_as_handled()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	player_in_range = body
	interaction_prompt.show()


func _on_body_exited(body: Node) -> void:
	if body != player_in_range:
		return

	player_in_range = null
	interaction_prompt.hide()
