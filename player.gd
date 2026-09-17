extends CharacterBody2D

@export var move_speed: float = 220.0
@export var acceleration: float = 1200.0
@export var friction: float = 1400.0
@export var crouch_speed_multiplier: float = 0.45

@export var jump_force: float = -420.0
@export var gravity: float = 1000.0
@export var fall_gravity_multiplier: float = 1.4

@export var unlock_double_jump: bool = false

@export var max_health: int = 5
var current_health: int = 5
var is_invulnerable: bool = false

var jump_count: int = 0
var is_crouching: bool = false

@export var xp: int = 0
@export var xp_per_level: int = 3
var level_points: int = 0

@onready var health_bar: ProgressBar = $"../UI/HealthBar"
@onready var health_label: Label = $"../UI/HealthBar/HealthLabel"

func _ready() -> void:
	current_health = max_health
	update_health_ui()
	print_health()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		if velocity.y > 0:
			velocity.y += gravity * fall_gravity_multiplier * delta
		else:
			velocity.y += gravity * delta
	else:
		jump_count = 0

	is_crouching = is_on_floor() and Input.is_action_pressed("ui_down")

	var direction := Input.get_axis("ui_left", "ui_right")
	var current_speed := move_speed

	if is_crouching:
		current_speed *= crouch_speed_multiplier

	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * current_speed, acceleration * delta)
		if direction < 0:
			$Sprite2D.flip_h = true
		elif direction > 0:
			$Sprite2D.flip_h = false
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if is_crouching:
		$Sprite2D.scale.y = 0.2
	else:
		$Sprite2D.scale.y = 0.3

	if Input.is_action_just_pressed("ui_accept") and not is_crouching:
		if is_on_floor():
			velocity.y = jump_force
			jump_count = 1
		elif unlock_double_jump and jump_count == 1:
			velocity.y = jump_force
			jump_count = 2

	move_and_slide()

func take_damage(amount: int) -> void:
	if is_invulnerable:
		return
		
	print("PLAYER TOOK DAMAGE: ", amount)

	current_health -= amount
	current_health = max(current_health, 0)
	update_health_ui()
	print_health()

	if current_health <= 0:
		die()
		return

	is_invulnerable = true
	modulate.a = 0.5
	$InvulnerabilityTimer.start()

func die() -> void:
	print("PLAYER DIED")
	queue_free()

func print_health() -> void:
	print("Health: ", current_health, "/", max_health)

func _on_invulnerability_timer_timeout() -> void:
	is_invulnerable = false
	modulate.a = 1.0
	
func update_health_ui() -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_label.text = "HP: " + str(current_health) + "/" + str(max_health)

func add_xp(amount: int) -> void:
	xp += amount
	print("XP: ", xp)

	if xp >= xp_per_level:
		xp -= xp_per_level
		level_points += 1
		print("LEVEL UP! Skill points: ", level_points)
