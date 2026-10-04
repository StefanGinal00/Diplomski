@tool
extends Node2D
## Presentation only. Reflow on size changes; no per-frame polling or text edits.
var pending := false
var labels: Array[Label] = []
var unresolved: Array[String] = []
var layout_count := 0
var maximum_width := 300.0


func _ready() -> void:
	set_process(false)
	var dressing := get_parent()
	for site in dressing.get_children():
		var clue := site.get_node_or_null("RouteClue") as Label
		if clue == null:
			continue
		labels.append(clue)
		clue.set_meta("original_clue_position", clue.position)
		clue.z_as_relative = false
		clue.z_index = 5
		clue.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clue.add_theme_color_override("font_outline_color", Color("09131c"))
		clue.add_theme_constant_override("outline_size", 3)
		clue.minimum_size_changed.connect(_schedule)
	_schedule()


func _schedule() -> void:
	if pending:
		return
	pending = true
	call_deferred("_layout")


func _world_rect(item: Control) -> Rect2:
	return item.get_global_transform() * Rect2(Vector2.ZERO, item.size)


func _terrain() -> Array[Rect2]:
	var result: Array[Rect2] = []
	var room: Node2D = get_parent().room
	for body in room.find_children("*", "StaticBody2D", true, false):
		if body.is_in_group("breakable"):
			continue
		var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or collision.disabled or not collision.shape is RectangleShape2D:
			continue
		var size: Vector2 = collision.shape.size
		result.append(collision.global_transform * Rect2(-size * 0.5, size))
	return result


func _reserved_signs() -> Array[Rect2]:
	var result: Array[Rect2] = []
	var room: Node2D = get_parent().room
	for label in room.find_children("*", "Label", true, false):
		# Even hidden rooms need a stable layout before the player enters.
		if label.has_meta("station_index") or String(label.name) in ["RouteTitle", "RouteHint"]:
			if not label.minimum_size_changed.is_connected(_schedule):
				label.minimum_size_changed.connect(_schedule)
			# Labels often reserve much more height than their rendered text.
			# Reserve the text, not an invisible 95 px panel.
			result.append((label.get_global_transform() * Rect2(Vector2.ZERO, Vector2(label.size.x, label.get_minimum_size().y))).grow(6))
	return result


func _band(index: int) -> Rect2:
	var dressing := get_parent()
	var route: Node2D = dressing.expansion
	var data: Array = dressing._sites()[index]
	var chamber: Rect2 = route._main_rect(int(data[0])) if dressing.region == "depths" else route._chamber_rect(int(data[0]))
	# Keep the clue inside its own chamber, above furniture and NPC heads.
	var band := Rect2(chamber.position + Vector2(16, 10), Vector2(chamber.size.x - 32, chamber.size.y - 158))
	return route.global_transform * band


func _overlap(candidate: Rect2, obstacles: Array[Rect2]) -> float:
	var area := 0.0
	for obstacle in obstacles:
		var overlap := candidate.intersection(obstacle)
		if overlap.has_area():
			area += overlap.get_area()
	return area


func _layout() -> void:
	pending = false
	if not is_inside_tree():
		return
	layout_count += 1
	unresolved.clear()
	var obstacles := _terrain()
	obstacles.append_array(_reserved_signs())
	for index in range(labels.size()):
		var clue := labels[index]
		var band := _band(index)
		clue.size.x = minf(maximum_width, band.size.x)
		clue.size.y = maxf(32, clue.get_minimum_size().y + 4)
		var desired: Vector2 = clue.get_parent().to_global(clue.get_meta("original_clue_position"))
		var size := clue.size
		var best := desired
		var best_score := INF
		var best_overlap := INF
		# Grid search occurs only on construction or changed text dimensions.
		# Distance is a tie-breaker; obstruction always costs more than movement.
		for y in range(int(band.position.y), int(band.end.y - size.y) + 1, 12):
			for x in range(int(band.position.x), int(band.end.x - size.x) + 1, 20):
				var at := Vector2(x, y)
				var blocked := _overlap(Rect2(at, size).grow(3), obstacles)
				var score := blocked * 10000 + at.distance_squared_to(desired)
				if score < best_score:
					best = at
					best_score = score
					best_overlap = blocked
		if best_overlap > 0.01:
			unresolved.append(str(clue.get_path()))
		clue.global_position = best
		obstacles.append(_world_rect(clue).grow(6))
