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

static func clear_passage(parent: Node2D, at: Vector2) -> Vector2:
	# Resolve authored entrances BEFORE population and paired arrival markers.
	# Stay on the same existing floor; never invent terrain or move a checkpoint.
	var floors: Array[Rect2]=[]
	for body in parent.get_children():
		if not body is StaticBody2D or body.is_in_group("enemy") or body.is_in_group("breakable"): continue
		var collision:=body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision==null or collision.disabled or not collision.shape is RectangleShape2D: continue
		var rect: Rect2=(parent.global_transform.affine_inverse()*collision.global_transform)*Rect2(-collision.shape.size/2,collision.shape.size)
		if rect.size.x>rect.size.y: floors.append(rect)
	var support:=preload("res://WorldSupport.gd").below(at,floors,40)
	if not support.has_area(): return at
	var compact:=preload("res://CompactPassageAtlas.gd")
	if compact.headroom(at.x,68,support,floors)>=72: return at
	for height in [100,72]:
		for distance in range(16,161,16):
			for side in [1,-1]:
				var x: float=at.x+distance*side
				if x<support.position.x+42 or x>support.end.x-42: continue
				if compact.headroom(x,68,support,floors)>=height: return Vector2(x,at.y)
	return at
