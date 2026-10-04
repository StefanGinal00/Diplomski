extends SceneTree
var audit_save_path := "res://_tmp_actor_obstruction_audit.json"
func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = audit_save_path
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	for i in 5: await process_frame
	game.get_node("UI").story_player.cancel()
	paused = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var layout := preload("res://WorldLayout.gd")
	var report := []
	for id in layout.ROOM_NODES:
		state.set_current_room(id)
		for i in 4: await process_frame
		var room: Node2D = game.get_node(layout.ROOM_NODES[id])
		var nodes := room.find_children("*", "", true, false)
		var floors := preload("res://WorldSupport.gd").floors(nodes)
		var crates := nodes.filter(func(n): return n.is_in_group("breakable"))
		for node in nodes:
			if not node.is_in_group("enemy"): continue
			var col := node.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if col == null or col.shape == null: continue
			var bounds: Rect2 = col.global_transform * col.shape.get_rect()
			for crate in crates:
				var shape := crate.get_node_or_null("CollisionShape2D") as CollisionShape2D
				if shape == null: continue
				var other: Rect2 = shape.global_transform * shape.shape.get_rect()
				if bounds.grow(3).intersects(other): report.append({"enemy":str(game.get_path_to(node)), "crate":str(game.get_path_to(crate)), "enemy_at":str(node.position), "crate_at":str(crate.position), "crate_box":str(other), "settle":crate.get("settle_on_floor"), "clear_offsets":_clear_offsets(crate,room)})
			if not node is StaticBody2D: continue
			var gap := INF
			var nearest := Rect2()
			for floor_rect in floors:
				if bounds.get_center().x < floor_rect.position.x or bounds.get_center().x > floor_rect.end.x: continue
				if absf(bounds.end.y - floor_rect.position.y) < absf(gap):
					gap = bounds.end.y - floor_rect.position.y
					nearest = floor_rect
			if absf(gap) > 2:
				var terrain := preload("res://CrateFloorPlacement.gd").terrain_rects(room)
				var blockers := []
				for rect in terrain:
					if Rect2(bounds.position,bounds.size+Vector2(0,absf(gap))).grow(-0.05).intersects(rect): blockers.append(str(rect))
				report.append({"sentry":str(game.get_path_to(node)), "at":str(node.position), "floor_gap":gap, "body":str(bounds), "support":str(nearest), "blockers":blockers})
	print("ACTOR_OBSTRUCTIONS ", JSON.stringify(report))
	state.delete_save()
	_done(report)

func _done(_report: Array) -> void:
	quit()

func _clear_offsets(crate: Node2D,room: Node2D) -> Array:
	var helper := preload("res://CrateFloorPlacement.gd")
	var box := helper.bounds(crate.get_node("CollisionShape2D"))
	var terrain := helper.terrain_rects(room)
	var obstacles := helper.other_obstacles(room)+helper.actor_spawn_rects(room)
	for other in room.find_children("*","StaticBody2D",true,false):
		if other.is_in_group("breakable") and other!=crate: obstacles.append(helper.bounds(other.get_node("CollisionShape2D")))
	var offsets := []
	for x in range(-480,481,8):
		var moved := Rect2(box.position+Vector2(x,0),box.size)
		var supported := false
		for floor_rect in terrain:
			if absf(floor_rect.position.y-moved.end.y)<0.1 and moved.position.x>floor_rect.position.x+4 and moved.end.x<floor_rect.end.x-4: supported=true
		if not supported: continue
		var headroom := Rect2(moved.position-Vector2(12,40),moved.size+Vector2(24,40)).grow(-0.05)
		var clear := true
		for rect in terrain+obstacles:
			if headroom.intersects(rect): clear=false;break
		if clear: offsets.append(x)
	return offsets
