extends Area2D

@export var xp_value: int = 1
@export_range(20.0, 240.0, 5.0) var attraction_radius: float = 90.0
@export_range(20.0, 500.0, 5.0) var attraction_speed: float = 180.0
@export_range(0.0, 1.0, 0.05) var pickup_delay: float = 0.15
@export_range(0.0, 8.0, 0.5) var bob_amplitude: float = 1.5
@export_range(0.5, 10.0, 0.5) var bob_speed: float = 4.0

var age: float = 0.0
var claimed: bool = false
var target_player: Node2D
var travel := preload("res://PickupMotion.gd").new()

@onready var visual: Node2D = $Visual

func _ready() -> void:
	preload("res://AnimatedPickupArt.gd").configure(visual, "xp")
	$Visual/Sprite2D.hide()
	$Visual/Glow.hide()
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
	preload("res://AnimatedPickupArt.gd").animate(visual, age)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Node2D
	travel.tick(self, delta, target_player, attraction_radius, attraction_speed, age >= pickup_delay)
	if age >= pickup_delay: travel.retry_contacts(self)


func _enable_pickup() -> void:
	if is_inside_tree() and not claimed and not is_queued_for_deletion():
		monitoring = true

func _on_body_entered(body: Node) -> void:
	if claimed or is_queued_for_deletion() or not body.is_in_group("player") or not body.has_method("add_xp") or body.get("is_dead") == true or xp_value <= 0:
		return
	if not travel.can_collect(self, body): return

	claimed = true
	set_deferred("monitoring", false)
	body.add_xp(xp_value)
	preload("res://PickupCollectArt.gd").spawn(self, body)
	queue_free()
