extends Area2D

signal collected(amount: int)

@export_range(1, 999, 1) var gold_value: int = 5
@export_range(20.0, 240.0, 5.0) var attraction_radius: float = 80.0
@export_range(20.0, 500.0, 5.0) var attraction_speed: float = 160.0
@export_range(0.0, 1.0, 0.05) var pickup_delay: float = 0.12

var age: float = 0.0
var claimed: bool = false
var target_player: Node2D
var travel := preload("res://PickupMotion.gd").new()

@onready var visual: Node2D = $Visual


func _ready() -> void:
	preload("res://AnimatedPickupArt.gd").configure(visual, "gold")
	preload("res://PickupMaterialArt.gd").retire_shapes(visual)
	body_entered.connect(_on_body_entered)
	monitoring = false
	target_player = get_tree().get_first_node_in_group("player") as Node2D
	visual.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK)
	get_tree().create_timer(pickup_delay).timeout.connect(_enable_pickup)


func _process(delta: float) -> void:
	age += delta
	visual.position.y = sin(age * 5.0) * 1.0
	visual.rotation = sin(age * 2.0) * 0.08
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
	if claimed or is_queued_for_deletion() or not body.is_in_group("player") or body.get("is_dead") == true:
		return
	if not travel.can_collect(self, body): return
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null: return
	# Lock before inventory signals: their listeners may reenter this callback.
	claimed = true
	if not game_state.add_gold(gold_value):
		claimed = false
		return
	set_deferred("monitoring", false)
	collected.emit(gold_value)
	preload("res://PickupCollectArt.gd").spawn(self, body)
	queue_free()
