extends Area2D

@export var damage: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	print("Trap touched by: ", body.name)

	if body.has_method("take_damage"):
		body.take_damage(damage)
