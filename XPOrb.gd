extends Area2D

@export var xp_value: int = 1
@export_range(20.0, 240.0, 5.0) var attraction_radius: float = 90.0
@export_range(20.0, 500.0, 5.0) var attraction_speed: float = 180.0
@export_range(0.0, 1.0, 0.05) var pickup_delay: float = 0.15
@export_range(0.0, 8.0, 0.5) var bob_amplitude: float = 2.5
@export_range(0.5, 10.0, 0.5) var bob_speed: float = 4.0

var age: float = 0.0
var target_player: Node2D

@onready var visual: Node2D = $Visual

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	monitoring = false
	target_player = get_tree().get_first_node_in_group("player") as Node2D

	var spawn_tween := create_tween()
	visual.scale = Vector2.ZERO
	spawn_tween.tween_property(visual, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if is_zero_approx(pickup_delay):
		_enable_pickup()
	else:
		get_tree().create_timer(pickup_delay).timeout.connect(_enable_pickup)


func _process(delta: float) -> void:
	age += delta
	visual.position.y = sin(age * bob_speed) * bob_amplitude
	visual.rotation = sin(age * bob_speed * 0.5) * 0.12

	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Node2D
	if target_player == null or target_player.get("is_dead") == true:
		return

	if global_position.distance_to(target_player.global_position) <= attraction_radius:
		global_position = global_position.move_toward(
			target_player.global_position,
			attraction_speed * delta
		)


func _enable_pickup() -> void:
	if is_inside_tree():
		monitoring = true

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player") or not body.has_method("add_xp"):
		return

	set_deferred("monitoring", false)
	body.add_xp(xp_value)
	queue_free()
