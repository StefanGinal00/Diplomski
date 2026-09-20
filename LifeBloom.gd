extends Area2D

signal collected

@export var float_height: float = 5.0
@export var float_speed: float = 2.2

var start_y: float
var elapsed: float = 0.0

@onready var bloom: Polygon2D = $Bloom
@onready var glow: Polygon2D = $Glow


func _ready() -> void:
	start_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	elapsed += delta
	position.y = start_y + sin(elapsed * float_speed) * float_height
	bloom.rotation += delta * 0.7
	glow.rotation -= delta * 0.35


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if body.get("is_dead") == true:
		return

	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or not game_state.add_item("life_bloom", 1):
		return
	collected.emit()
	queue_free()
