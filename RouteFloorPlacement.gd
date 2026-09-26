@tool
extends RefCounted

# Semantic route anchors describe a chamber, not its solid floor. Resolve them
# before adding actors to the tree so their patrol origins use the final point.
static func on_floor(parent: Node2D, prefix: String, desired_x: float, clearance: float = 33.0, margin: float = 125.0) -> Vector2:
	var best := Vector2.INF
	var distance := INF
	for body in parent.get_children():
		if not body is StaticBody2D or not String(body.name).begins_with(prefix):
			continue
		var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or collision.disabled or not collision.shape is RectangleShape2D:
			continue
		var half_width := (collision.shape as RectangleShape2D).size.x * 0.5
		if half_width < margin:
			continue
		var x := clampf(desired_x, body.position.x - half_width + margin, body.position.x + half_width - margin)
		if absf(x - desired_x) < distance:
			distance = absf(x - desired_x)
			best = Vector2(x, body.position.y - clearance)
	assert(best.is_finite(), "No supported route floor: %s/%s" % [parent.name, prefix])
	return best
