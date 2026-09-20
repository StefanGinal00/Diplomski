extends Area2D

@export var item_id: String = "old_passage_sigil"
@export_range(0.5, 10.0, 0.5) var bob_speed: float = 3.0
@export_range(0.0, 8.0, 0.5) var bob_height: float = 3.0

var age: float = 0.0
var is_collected: bool = false

@onready var visual: Node2D = $Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	call_deferred("_sync_collected_state")


func _sync_collected_state() -> void:
	var quest_manager := get_tree().get_first_node_in_group("quest_manager")
	if quest_manager != null and quest_manager.has_method("has_collected_quest_item") and quest_manager.has_collected_quest_item(item_id):
		is_collected = true
		set_deferred("monitoring", false)
		queue_free()


func _process(delta: float) -> void:
	age += delta
	visual.position.y = sin(age * bob_speed) * bob_height
	visual.rotation += delta * 0.8


func _on_body_entered(body: Node) -> void:
	if is_collected or not body.is_in_group("player"):
		return

	var quest_manager := get_tree().get_first_node_in_group("quest_manager")
	if quest_manager == null or not quest_manager.has_method("report_item_collected"):
		return

	is_collected = true
	set_deferred("monitoring", false)
	quest_manager.report_item_collected(item_id)
	queue_free()
