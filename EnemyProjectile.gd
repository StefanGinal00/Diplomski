extends Area2D

@export var speed: float = 125.0
@export var damage: int = 1
@export var lifetime: float = 4.0
@export var player_knockback: float = 120.0

var direction: Vector2 = Vector2.LEFT
var source: Node


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(new_direction: Vector2, projectile_source: Node) -> void:
	direction = new_direction.normalized()
	source = projectile_source
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body == source:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(
			damage,
			Vector2(direction.x * player_knockback, -80.0)
		)
	queue_free()
