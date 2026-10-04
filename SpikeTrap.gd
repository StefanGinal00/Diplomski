extends Area2D

@export var damage: int = 1

func _ready() -> void:
	for child in get_children():
		if not child is Polygon2D or child.polygon.is_empty(): continue
		var bounds := Rect2(child.polygon[0], Vector2.ZERO)
		for point in child.polygon: bounds = bounds.expand(point)
		var art := preload("res://PickupMaterialArt.gd").attach(self, 3, bounds.size * child.scale, child.position + bounds.get_center() * child.scale)
		art.rotation = child.rotation
		child.hide()
		break
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
