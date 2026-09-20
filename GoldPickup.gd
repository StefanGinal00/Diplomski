extends Area2D

signal collected(amount: int)

@export_range(1, 999, 1) var gold_value: int = 5
@export_range(20.0, 240.0, 5.0) var attraction_radius: float = 80.0
@export_range(20.0, 500.0, 5.0) var attraction_speed: float = 160.0
@export_range(0.0, 1.0, 0.05) var pickup_delay: float = 0.12

var age: float = 0.0
var target_player: Node2D

@onready var visual: Node2D = $Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = false
	target_player = get_tree().get_first_node_in_group("player") as Node2D
	visual.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK)
	get_tree().create_timer(pickup_delay).timeout.connect(_enable_pickup)


func _process(delta: float) -> void:
	age += delta
	visual.position.y = sin(age * 5.0) * 2.0
	visual.rotation += delta * 1.4
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Node2D
	if target_player == null or target_player.get("is_dead") == true:
		return
	if global_position.distance_to(target_player.global_position) <= attraction_radius:
		global_position = global_position.move_toward(target_player.global_position, attraction_speed * delta)


func _enable_pickup() -> void:
	if is_inside_tree():
		monitoring = true


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	set_deferred("monitoring", false)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.add_gold(gold_value):
		collected.emit(gold_value)
		queue_free()
