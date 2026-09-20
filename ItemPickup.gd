extends Area2D

@export var item_id: String = "healing_herb"
@export var display_name: String = "Healing Herb"
@export_range(1, 99, 1) var amount: int = 1
@export var unique: bool = false

var age: float = 0.0

@onready var label: Label = $Label
@onready var visual: Node2D = $Visual


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if unique and game_state != null and game_state.has_item(item_id):
		queue_free()
		return
	body_entered.connect(_on_body_entered)
	label.text = display_name
	visual.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


func _process(delta: float) -> void:
	age += delta
	visual.position.y = sin(age * 3.5) * 3.0


func configure(new_item_id: String, new_display_name: String, new_amount: int = 1) -> void:
	item_id = new_item_id
	display_name = new_display_name
	amount = new_amount
	if is_node_ready():
		label.text = display_name


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var game_state := get_node_or_null("/root/GameState")
	if unique and game_state != null and game_state.has_item(item_id):
		set_deferred("monitoring", false)
		queue_free()
		return
	if game_state == null or not game_state.add_item(item_id, amount):
		return
	set_deferred("monitoring", false)
	queue_free()
