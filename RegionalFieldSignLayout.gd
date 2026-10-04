@tool
extends "res://EchoFieldSignLayout.gd"
## Reuse Echo's event-driven collision-aware layout for the other field routes.


func _ready() -> void:
	maximum_width = 360.0
	super._ready()
	if not Engine.is_editor_hint():
		get_node("/root/GameState").room_changed.connect(_on_room_changed)


func _on_room_changed(_room_id: String) -> void:
	if str(preload("res://WorldLayout.gd").ROOM_NODES.get(_room_id, "")) == str(get_parent().room.name):
		_schedule()


func _reserved_signs() -> Array[Rect2]:
	var result := super._reserved_signs()
	for label in get_parent().room.find_children("*", "Label", true, false):
		var host: Node = label.get_parent()
		if str(host.name) != "FieldOperations" and host.get_script() != preload("res://LocalizedEncounter.gd"):
			continue
		if not label.minimum_size_changed.is_connected(_schedule):
			label.minimum_size_changed.connect(_schedule)
		result.append((label.get_global_transform() * Rect2(Vector2.ZERO, Vector2(label.size.x, label.get_minimum_size().y))).grow(6))
	return result


func _band(index: int) -> Rect2:
	var dressing := get_parent()
	var route: Node2D = dressing.expansion
	var data: Array = dressing._sites()[index]
	var chamber: Rect2
	if int(data[0]) < 0:
		# The niche is a small open ledge, not an enclosed 240px room.
		# Put its shelter caption at the approach in the actual parent gallery.
		chamber = route._chamber_rect(1 if int(data[0]) == -1 else 4)
	elif dressing.region == "StarfallRamparts":
		chamber = route._main_rect(int(data[0]))
	else:
		chamber = route._chamber_rect(int(data[0]))
	var clearance := 124 if dressing._zone() == "ashen_bastion" else 158
	return route.global_transform * Rect2(chamber.position + Vector2(16, 10), Vector2(chamber.size.x - 32, chamber.size.y - clearance))
