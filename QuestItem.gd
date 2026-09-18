extends Area2D

@export var item_id: String = "old_passage_sigil"
@export_range(0.5, 10.0, 0.5) var bob_speed: float = 3.0
@export_range(0.0, 8.0, 0.5) var bob_height: float = 3.0

var age: float = 0.0

@onready var visual: Node2D = $Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	age += delta
	visual.position.y = sin(age * bob_speed) * bob_height
	visual.rotation += delta * 0.8


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	var quest_manager := get_tree().get_first_node_in_group("quest_manager")
	if quest_manager == null or not quest_manager.has_method("report_item_collected"):
		return

	monitoring = false
	quest_manager.report_item_collected(item_id)
	queue_free()
