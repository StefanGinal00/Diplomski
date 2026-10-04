extends "res://tests/shaft_hollow_smoke.gd"
## Offline inspection only: proposes explicit anchors, never writes assets.
const PLACE := preload("res://CrateFloorPlacement.gd")
const LAYOUT := preload("res://WorldLayout.gd")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_crate_anchor_audit_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.get_node("Player").set_physics_process(false)
	await process_frame
	var proposals: Array = []
	for id in LAYOUT.ROOM_NODES:
		state.set_current_room(id)
		var room := game.get_node(LAYOUT.ROOM_NODES[id]) as Node2D
		room.process_mode = Node.PROCESS_MODE_DISABLED
		PLACE.flush()
		var terrain := PLACE.terrain_rects(room)
		var obstacles := PLACE.other_obstacles(room)
		var crates: Array[Node] = room.find_children("*", "StaticBody2D", true, false).filter(func(n: Node) -> bool: return n.get_script() == load("res://DestructibleCrate.gd") and not n.is_queued_for_deletion())
		var unsupported: Array[Node] = []
		for crate in crates:
			var box := PLACE.bounds(crate.get_node("CollisionShape2D"))
			var supported := false
			for floor_rect in terrain:
				if absf(box.end.y - floor_rect.position.y) < 0.1 and box.position.x >= floor_rect.position.x and box.end.x <= floor_rect.end.x:
					supported = true
			if not supported:
				unsupported.append(crate)
		for crate in unsupported:
			var before: Vector2 = crate.position
			var original: Vector2 = crate.global_position
			var best := Vector2.INF
			var score := INF
			var support_name := ""
			var blocking: Array[String] = []
			for shape in room.find_children("*", "CollisionShape2D", true, false):
				var body := shape.get_parent() as StaticBody2D
				if body == null or body.is_in_group("breakable") or not body.get_collision_layer_value(1):
					continue
				var floor_rect := PLACE.bounds(shape)
				if floor_rect.has_area() and PLACE.bounds(crate.get_node("CollisionShape2D")).grow(1).intersects(floor_rect):
					blocking.append(String(room.get_path_to(body)))
				if floor_rect.size.x < 100 or floor_rect.size.x < floor_rect.size.y:
					continue
				if "Step" in String(body.name) or "Crossing" in String(body.name):
					continue
				var y := floor_rect.position.y - 12
				if y < original.y - 24 or y > original.y + PLACE.MAX_DROP:
					continue
				for dx in range(-800, 801, 8):
					var candidate := Vector2(original.x + dx, y)
					if candidate.x < floor_rect.position.x + 40 or candidate.x > floor_rect.end.x - 40:
						continue
					# Clear headroom beside the box; avoid stair lips and tight gaps.
					var space := Rect2(candidate - Vector2(24, 52), Vector2(48, 64)).grow(-0.05)
					var clear := true
					for obstacle in terrain + obstacles:
						if space.intersects(obstacle):
							clear = false
							break
					if not clear:
						continue
					for other in crates:
						if other != crate and space.grow(8).intersects(PLACE.bounds(other.get_node("CollisionShape2D"))):
							clear = false
							break
					if not clear:
						continue
					var candidate_score := absf(dx) + absf(y - original.y) * 4
					if candidate_score < score:
						score = candidate_score
						best = candidate
						support_name = String(room.get_path_to(body))
			var path := String(game.get_path_to(crate))
			if best.is_finite():
				crate.global_position = best
				proposals.append({"path": path, "old": [before.x, before.y], "new": [crate.position.x, crate.position.y], "floor": support_name, "blocking": blocking})
			else:
				proposals.append({"path": path, "old": [before.x, before.y], "missing": true, "blocking": blocking})
		await process_frame
	print("ANCHOR_PROPOSALS=" + JSON.stringify(proposals))
	game.queue_free()
	await process_frame
	state.delete_save()
	print("CRATE ANCHOR AUDIT TEST PASSED")
	quit(0)
