extends RefCounted
## Real closure for already-authored outer walls. Never closes individual ledge
## edges or interior shafts; no extra floor and no change to portal positions.
static func install(room: Node2D, nodes: Array[Node], surfaces: Array[Rect2]) -> Array[StaticBody2D]:
	var added: Array[StaticBody2D] = []
	if surfaces.is_empty(): return added
	var extent := surfaces[0]
	for rect in surfaces: extent = extent.merge(rect)
	for node in nodes:
		if not node is CollisionShape2D or node.disabled or node.one_way_collision or not node.shape is RectangleShape2D: continue
		var owner_body := node.get_parent() as StaticBody2D
		if owner_body == null or owner_body.is_in_group("enemy") or owner_body.is_in_group("breakable") or owner_body.has_meta("map_boundary_extension"): continue
		if not is_zero_approx(node.global_rotation): continue
		var rect: Rect2 = node.global_transform * Rect2(-node.shape.size/2, node.shape.size)
		if rect.size.x > 90 or rect.size.y < 100: continue
		var west := rect.end.x <= extent.position.x+85
		var east := rect.position.x >= extent.end.x-85
		if not west and not east: continue
		var name_id := "ClosedMapBoundaryWest" if west else "ClosedMapBoundaryEast"
		if room.has_node(name_id):
			node.set_meta("boundary_envelope_superseded", true)
			continue
		var top := minf(rect.position.y, extent.position.y-560)
		var bottom := maxf(rect.end.y, extent.end.y+360)
		var body := StaticBody2D.new()
		body.name = name_id
		body.collision_layer = owner_body.collision_layer
		body.collision_mask = owner_body.collision_mask
		body.set_meta("map_boundary_extension", true)
		body.set_meta("portal_boundary", true)
		room.add_child(body)
		body.global_position = Vector2(rect.get_center().x, (top+bottom)/2)
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		shape.shape = RectangleShape2D.new()
		shape.shape.size = Vector2(rect.size.x, bottom-top)/body.global_scale.abs()
		body.add_child(shape)
		node.set_meta("boundary_envelope_superseded", true)
		added.append(body)
	return added
