extends Area2D

@export var xp_value: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		if body.has_method("add_xp"):
			body.add_xp(xp_value)
		queue_free()
