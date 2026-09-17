extends CharacterBody2D

@export var move_speed: float = 80.0
@export var gravity: float = 1000.0
@export var damage: int = 1
@export var stomp_bounce_force: float = -300.0
@export var max_health: int = 1

var current_health: int
var direction: int = 1
var left_limit: float
var right_limit: float
var is_dead: bool = false

func _ready() -> void:
	current_health = max_health

	left_limit = global_position.x + $LeftPoint.position.x
	right_limit = global_position.x + $RightPoint.position.x

	$DetectionArea.body_entered.connect(_on_detection_area_body_entered)
	$TopHitbox.body_entered.connect(_on_top_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	velocity.x = direction * move_speed
	move_and_slide()

	if global_position.x >= right_limit:
		direction = -1
		$Sprite2D.flip_h = true
	elif global_position.x <= left_limit:
		direction = 1
		$Sprite2D.flip_h = false

func _on_detection_area_body_entered(body: Node) -> void:
	if is_dead:
		return

	if body == self:
		return

	if body.name == "Player":
		if _is_player_above(body):
			return

		print("SIDE HIT PLAYER")
		body.take_damage(damage)

func _on_top_hitbox_body_entered(body: Node) -> void:
	if is_dead:
		return

	if body == self:
		return

	if body.name == "Player" and body is CharacterBody2D:
		if _is_player_above(body):
			print("STOMP HIT")
			body.velocity.y = stomp_bounce_force
			take_damage(1)

func _is_player_above(body: Node) -> bool:
	if body is Node2D:
		return body.global_position.y < global_position.y - 8.0
	return false

func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_health -= amount

	if current_health <= 0:
		die()

func die() -> void:
	print("ENEMY DIED")
	is_dead = true
	queue_free()
