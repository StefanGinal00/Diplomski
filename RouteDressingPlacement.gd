extends RefCounted
## Read-only world-space placement shared by the richer route layers.
const Support := preload("res://WorldSupport.gd")

static func family(id: String) -> String:
	if id.begins_with("ash_"): return "ash"
	if id.begins_with("starfall_"): return "star"
	if id in ["sunken_shaft","shaft_hollow","shaft_drift","shaft_approach"]: return "mine"
	return "cave"

static func floors(nodes: Array[Node]) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for node in nodes:
		if not is_instance_valid(node) or not node is CollisionShape2D or node.disabled or not node.shape is RectangleShape2D: continue
		var body := node.get_parent()
		if not body is StaticBody2D or body.is_in_group("enemy") or body.is_in_group("breakable") or not is_zero_approx(node.global_rotation): continue
		var named := String(body.name).to_lower()
		if "ceiling" in named or "roof" in named or "topwall" in named: continue
		var rect: Rect2 = node.global_transform*Rect2(-node.shape.size/2,node.shape.size)
		if rect.size.x >= 90 and rect.size.y <= 80 and not rect in result: result.append(rect)
	return result

static func reservations(nodes: Array[Node], ceiling := false) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for node in nodes:
		if not is_instance_valid(node): continue
		if node is CollisionShape2D and not node.disabled and node.shape is RectangleShape2D and node.get_parent() is Area2D:
			var path: String = node.get_parent().get_script().resource_path if node.get_parent().get_script() != null else ""
			if "Hazard" in path or "Spike" in path or "Vent" in path or "CurrentField" in path:
				result.append((node.global_transform*Rect2(-node.shape.size/2,node.shape.size)).grow(12 if not ceiling else 45))
		if not node is Node2D: continue
		if node.has_meta("task_scenery") and node.has_method("painted_bounds"):
			result.append(node.painted_bounds().grow(7))
		if node.has_meta("natural_mound_bounds"): result.append(node.get_meta("natural_mound_bounds"))
		if node.has_node("FinishedDevice"):
			var art := node.get_node("FinishedDevice") as Sprite2D
			result.append(Rect2(node.global_position-Vector2(26,55),Vector2(52,72)))
			if art != null and art.texture != null: result.append((art.global_transform*art.get_rect()).grow(8))
			var gantry := node.get_node_or_null("LiftGantry")
			if gantry != null:
				var volume: Rect2 = gantry.get_meta("clearance_plan",{}).get("volume",Rect2())
				if volume.has_area(): result.append(volume.grow(10))
		if node.is_in_group("breakable") or node.is_in_group("town_service") or node.is_in_group("town_resident") or node.is_in_group("friendly_npc") or node.is_in_group("item_pickup"):
			result.append(Rect2(node.global_position-Vector2(24,50),Vector2(48,66)))
		if ceiling and (node is Marker2D or node.is_in_group("enemy") or node.has_node("FinishedDevice")):
			result.append(Rect2(node.global_position-Vector2(80,195),Vector2(160,230)))
	return result

static func clear(bounds: Rect2, obstacles: Array[Rect2], attachment := Rect2()) -> bool:
	for rect in obstacles:
		if rect != attachment and rect.intersects(bounds): return false
	return true
