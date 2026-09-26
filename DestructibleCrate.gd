extends StaticBody2D

signal destroyed

@export_range(1, 10, 1) var max_health: int = 2
@export var gold_pickup_scene: PackedScene
@export var item_pickup_scene: PackedScene
@export_range(1, 999, 1) var min_gold: int = 3
@export_range(1, 999, 1) var max_gold: int = 12
@export_range(0.0, 1.0, 0.05) var item_drop_chance: float = 0.3
@export_range(0.0, 1.0, 0.05) var empty_drop_chance: float = 0.0
@export var common_item_ids: PackedStringArray = ["healing_herb", "iron_fragment", "ether_dust"]
@export var random_seed: int = 0

var current_health: int
var is_destroyed: bool = false
var rng := RandomNumberGenerator.new()

@onready var visual: Node2D = $Visual


func _ready() -> void:
	current_health = max_health
	if random_seed == 0:
		rng.randomize()
	else:
		rng.seed = random_seed


func take_damage(amount: int, _knockback: Vector2 = Vector2.ZERO) -> void:
	if is_destroyed or amount <= 0:
		return
	current_health = maxi(current_health - amount, 0)
	if current_health <= 0:
		_destroy()
		return
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color(1.8, 1.8, 1.8, 1.0), 0.05)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.08)


func _destroy() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	_drop_random_loot()
	destroyed.emit()
	queue_free()


func _drop_random_loot() -> void:
	if rng.randf() < empty_drop_chance:
		return
	if rng.randf() < item_drop_chance and not common_item_ids.is_empty():
		_drop_item()
	else:
		_drop_gold()


func _drop_gold() -> void:
	var drop_parent := get_parent() as Node2D
	if gold_pickup_scene == null or drop_parent == null:
		return
	var pickup := gold_pickup_scene.instantiate() as Area2D
	pickup.set("gold_value", rng.randi_range(min_gold, maxi(min_gold, max_gold)))
	pickup.position = drop_parent.to_local(global_position + Vector2(0.0, -14.0))
	drop_parent.call_deferred("add_child", pickup)


func _drop_item() -> void:
	var drop_parent := get_parent() as Node2D
	if item_pickup_scene == null or drop_parent == null:
		return
	var item_id := common_item_ids[rng.randi_range(0, common_item_ids.size() - 1)]
	var pickup := item_pickup_scene.instantiate() as Area2D
	pickup.configure(item_id, item_id.replace("_", " ").capitalize())
	pickup.position = drop_parent.to_local(global_position + Vector2(0.0, -14.0))
	drop_parent.call_deferred("add_child", pickup)
