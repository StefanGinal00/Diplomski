extends Area2D

@export var item_id: String = "healing_herb"
@export var display_name: String = "Healing Herb"
@export_range(1, 99, 1) var amount: int = 1
@export var unique: bool = false
@export var settle_on_ground := true
@export_range(20.0, 160.0, 4.0) var attraction_radius := 84.0
@export var attraction_speed := 170.0

var age: float = 0.0
var claimed: bool = false
var target_player: Node2D
var travel := preload("res://PickupMotion.gd").new()

@onready var label: Label = $Label
@onready var visual: Node2D = $Visual


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if unique and game_state != null and game_state.has_item(item_id):
		queue_free()
		return
	body_entered.connect(_on_body_entered)
	target_player = get_tree().get_first_node_in_group("player") as Node2D
	label.text = display_name
	preload("res://AnimatedPickupArt.gd").configure(visual, item_id)
	visual.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


func _process(delta: float) -> void:
	age += delta
	visual.position.y = sin(age * 3.5) * 1.0
	preload("res://AnimatedPickupArt.gd").animate(visual, age)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target_player): target_player = get_tree().get_first_node_in_group("player") as Node2D
	# Unique authored quest objects retain their intentional placement.
	travel.tick(self, delta, target_player, attraction_radius, attraction_speed, age >= 0.15, settle_on_ground and not unique)
	if age >= 0.15: travel.retry_contacts(self)


func configure(new_item_id: String, new_display_name: String, new_amount: int = 1) -> void:
	item_id = new_item_id
	display_name = new_display_name
	amount = new_amount
	if is_node_ready():
		label.text = display_name
		preload("res://AnimatedPickupArt.gd").configure(visual, item_id)


func _on_body_entered(body: Node) -> void:
	if claimed or is_queued_for_deletion() or not body.is_in_group("player") or body.get("is_dead") == true:
		return
	if not travel.can_collect(self, body): return
	var game_state := get_node_or_null("/root/GameState")
	if unique and game_state != null and game_state.has_item(item_id):
		claimed = true
		set_deferred("monitoring", false)
		queue_free()
		return
	if game_state == null: return
	claimed = true
	if not game_state.add_item(item_id, amount):
		claimed = false
		return
	set_deferred("monitoring", false)
	preload("res://PickupCollectArt.gd").spawn(self, body)
	queue_free()
