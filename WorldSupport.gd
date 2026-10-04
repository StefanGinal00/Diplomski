extends RefCounted
## Shared visual contact queries. Never moves actors, colliders or arrival markers.

static func solids(nodes: Array[Node]) -> Array[Rect2]:
	# Placement must see vertical walls as well as walkable floor rectangles.
	# Polygon/rotated terrain uses a conservative world-space envelope; art
	# may be omitted there, but never changes or guesses the physical surface.
	var result: Array[Rect2] = []
	for node in nodes:
		if not is_instance_valid(node): continue
		if not (node is CollisionShape2D or node is CollisionPolygon2D) or node.disabled: continue
		var body := node.get_parent()
		if not body is StaticBody2D or body.is_in_group("breakable") or body.is_in_group("enemy"): continue
		if node is CollisionShape2D and node.shape is RectangleShape2D:
			result.append(node.global_transform * Rect2(-node.shape.size / 2,node.shape.size))
		elif node is CollisionPolygon2D and not node.polygon.is_empty():
			var bounds := Rect2(node.to_global(node.polygon[0]),Vector2.ZERO)
			for point in node.polygon: bounds = bounds.expand(node.to_global(point))
			if bounds.has_area(): result.append(bounds)
	return result

static func floors(nodes: Array[Node]) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for node in nodes:
		if not node is CollisionShape2D or node.disabled or not node.shape is RectangleShape2D: continue
		var body := node.get_parent()
		if not body is StaticBody2D or body.is_in_group("breakable") or body.is_in_group("enemy"): continue
		if not is_zero_approx(node.global_rotation): continue
		var rect: Rect2 = node.global_transform * Rect2(-node.shape.size / 2, node.shape.size)
		if rect.size.x > rect.size.y: result.append(rect)
	return result

static func below(at: Vector2, surfaces: Array[Rect2], reach: float = 80) -> Rect2:
	var selected := Rect2()
	var top := at.y + reach
	for rect in surfaces:
		if at.x < rect.position.x or at.x > rect.end.x: continue
		if rect.position.y >= at.y - 2 and rect.position.y < top:
			selected = rect
			top = rect.position.y
	return selected

static func plant(art: Sprite2D, opaque_bottom: float, floor_y: float) -> void:
	var frame_height := art.texture.get_height() / float(art.vframes)
	var foot := art.to_global(Vector2(0, art.offset.y - frame_height / 2 + opaque_bottom))
	art.global_position.y += floor_y - foot.y
	art.set_meta("contact_row", opaque_bottom)
	art.set_meta("contact_floor", floor_y)

static func align_rectangle(visual: Polygon2D, collision: CollisionShape2D) -> bool:
	# Respect authored irregular cliffs. Only rectangular faces that already
	# describe this collider are registered to its exact four corners.
	if visual.polygon.size() != 4: return false
	var bounds := Rect2(visual.polygon[0], Vector2.ZERO)
	for point in visual.polygon: bounds = bounds.expand(point)
	for point in visual.polygon:
		if not (is_equal_approx(point.x, bounds.position.x) or is_equal_approx(point.x, bounds.end.x)): return false
		if not (is_equal_approx(point.y, bounds.position.y) or is_equal_approx(point.y, bounds.end.y)): return false
	var half: Vector2 = collision.shape.size / 2
	var corners := PackedVector2Array()
	var into_visual := visual.transform.affine_inverse() * collision.transform
	for point in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)]:
		corners.append(into_visual * point)
	var target := Rect2(corners[0], corners[2] - corners[0])
	if (target.position - bounds.position).length() > 16 or (target.end - bounds.end).length() > 16: return false
	visual.polygon = corners
	if visual.texture != null:
		preload("res://RoomArtFinish.gd")._material(visual, visual.texture, visual.color)
	visual.set_meta("collision_registered", true)
	return true
