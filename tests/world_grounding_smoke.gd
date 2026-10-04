extends "res://tests/boss_combat_presentation_smoke.gd"
const Layout = preload("res://WorldLayout.gd")
const Support = preload("res://WorldSupport.gd")

func _arrival_marker(node: Node) -> bool:
	if not node is Marker2D: return false
	# Internal AI patrol endpoints are not player spawn/portal destinations.
	# Preserve their transforms, but do not require the map wall to admit them.
	var ancestor := node.get_parent()
	while ancestor != null:
		if ancestor is CharacterBody2D: return false
		ancestor = ancestor.get_parent()
	return true

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_world_grounding.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var rooms: Array = ["training_passage"] + Layout.ROOM_NODES.keys()
	var seen := {}
	var contacts := 0
	var portals := 0
	var boundaries := 0
	var registered := 0
	for id in rooms:
		var room: Node2D = game if id == "training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		if seen.has(room.get_instance_id()): continue
		seen[room.get_instance_id()] = true
		state.set_current_room(id)
		await process_frame
		await process_frame
		finish.finish_room(id)
		var nodes: Array[Node] = finish._members(room)
		var actor_positions := {}
		for node in nodes:
			if node is Area2D or node is CharacterBody2D or node is Marker2D: actor_positions[node] = node.global_transform
		for node in nodes:
			if node.is_in_group("shaft_lift") and node.has_node("FinishedDevice") and node.get_node("FinishedDevice").has_meta("contact_floor"):
				_check(node.has_node("LiftGantry"), "Lift chains have no structural support: " + str(node.get_path()))
				if node.has_node("LiftGantry"):
					_check(absf(node.get_node("LiftGantry").global_position.y - float(node.get_node("FinishedDevice").get_meta("contact_floor"))) < 0.01, "Lift support floats above floor")
			if node is Polygon2D and node.has_meta("collision_registered"):
				registered += 1
				var col: CollisionShape2D
				for child in node.get_parent().get_children():
					if child is CollisionShape2D: col = child; break
				var visual_bounds := Rect2(node.to_global(node.polygon[0]), Vector2.ZERO)
				for point in node.polygon: visual_bounds = visual_bounds.expand(node.to_global(point))
				var solid: Rect2 = col.global_transform * Rect2(-col.shape.size / 2, col.shape.size)
				_check((visual_bounds.position - solid.position).length() < 0.04 and (visual_bounds.end - solid.end).length() < 0.04, "Paint/collision discrepancy: " + str(node.get_path()) + " " + str(visual_bounds) + " vs " + str(solid))
			if node is Sprite2D and node.has_meta("contact_floor"):
				contacts += 1
				var foot: Vector2 = node.to_global(Vector2(0, node.offset.y - node.texture.get_height() / float(node.vframes) / 2 + float(node.get_meta("contact_row"))))
				_check(absf(foot.y - float(node.get_meta("contact_floor"))) < 0.01, "Floating registered prop: " + str(node.get_path()))
			if node is Sprite2D and node.has_meta("contact_floor_local"):
				contacts += 1
				var foot: Vector2=node.to_global(Vector2(0,node.offset.y-node.texture.get_height()/float(node.vframes)/2+float(node.get_meta("contact_row"))))
				var expected: Vector2=node.get_parent().to_global(Vector2(0,float(node.get_meta("contact_floor_local"))))
				_check(absf(foot.y-expected.y)<0.01,"Actor foot registration drift: "+str(node.get_path()))
			if node is LevelExit or node.is_in_group("room_door"):
				portals += 1
				_check(node.has_node("PortalSurround/RockFace"), "Isolated portal: " + str(node.get_path()))
				if node.has_node("PortalSurround"):
					var surround: Node2D = node.get_node("PortalSurround")
					var support: Rect2 = surround.get_meta("supported_floor")
					_check(is_equal_approx(surround.global_position.y, support.position.y), "Portal context floats")
			if node is StaticBody2D and node.has_meta("portal_boundary"):
				boundaries += 1
				var col: CollisionShape2D = node.get_node("CollisionShape2D")
				var rect: Rect2 = col.global_transform * Rect2(-col.shape.size / 2, col.shape.size)
				for actor in actor_positions:
					if _arrival_marker(actor) or actor.is_in_group("room_door") or actor is LevelExit:
						_check(not rect.grow(10).has_point(actor.global_position), "Boundary blocks arrival/door: " + str(actor.get_path()))
		var count := nodes.size()
		finish.finish_room(id)
		finish._ground_residents()
		_check(count == finish._members(room).size(), "Repeated registration duplicates context: " + id)
		for actor in actor_positions: _check(actor.global_transform == actor_positions[actor], "Presentation moved an actor/arrival: " + str(actor.get_path()))
	_check(registered > 500 and contacts > 100 and portals > 50 and boundaries > 10, "Incomplete world grounding coverage")
	var pixels: Image = preload("res://PortalContextArt.gd").SHEET.get_image()
	_check(pixels.get_width() <= 1024 and pixels.has_mipmaps() and pixels.get_pixel(0, 0).a < 0.01, "Portal atlas lacks alpha, mipmaps or mobile cap")
	# Actually settle under gravity. A screenshot of a frozen, manually placed
	# actor does not establish real floor contact.
	state.set_current_room("training_passage")
	await process_frame
	await process_frame
	var player: Player = game.get_node("Player")
	game.get_node("UI").story_player.cancel()
	paused = false
	# PROCESS_MODE_DISABLED normally removes CollisionObject2D from physics.
	# Keep the real ground active while only the test player is processing.
	for node in finish._members(game):
		if node is StaticBody2D: node.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.global_position = Vector2(600, 345)
	player.velocity = Vector2.ZERO
	for tick in range(45): await physics_frame
	var art: Sprite2D = player.get_node("Appearance")
	_check(player.is_on_floor(), "Native player did not settle on opening floor")
	var floor_rect := Support.below(player.global_position, Support.floors(finish._members(game)))
	for pose in [art.Pose.IDLE, art.Pose.WALK_A, art.Pose.WALK_B, art.Pose.CROUCH, art.Pose.LAND]:
		for left in [false, true]:
			art._apply_pose(pose, left, pose == art.Pose.CROUCH)
			var row: float = art.GROUND_ROWS[pose] if pose <= art.Pose.WALK_B else art.MOVEMENT_GROUND_ROWS[pose - art.Pose.CROUCH]
			var foot := art.to_global(Vector2(0, art.offset.y - art.texture.get_height() / float(art.vframes) / 2 + row))
			_check(absf(foot.y - floor_rect.position.y) < 0.15, "Grounded pose floats/sinks: " + str(pose))
	for kind in ["sword", "bow", "staff"]:
		for follow in [false, true]:
			art._apply_attack_pose(kind, follow, true, true)
			var foot := art.to_global(Vector2(0, art.offset.y - 256 + art.COMBAT_GROUND_ROWS[art.frame]))
			_check(absf(foot.y - floor_rect.position.y) < 0.15, "Attack pose foot drift: " + kind)
	player.global_position = Vector2(1360, 360)
	player.velocity = Vector2.ZERO
	Input.action_press("ui_right")
	for tick in range(90): await physics_frame
	Input.action_release("ui_right")
	_check(player.global_position.x <= 1388.1 and player.is_on_floor(), "Player walks beyond the opening exit into empty space")
	player.jump_buffer_remaining = 0.12
	for tick in range(4): await physics_frame
	_check(not player.is_on_floor() and player.velocity.y < 0, "Grounding interferes with native jumping")
	print("WORLD GROUNDING COVERAGE: ", seen.size(), " rooms, ", registered, " registered surfaces, ", contacts, " contacts, ", portals, " portals, ", boundaries, " outer boundaries; atlas bytes=", pixels.get_data_size())
	game.queue_free()
	await process_frame
	state.delete_save()
	print("WORLD GROUNDING TEST PASSED" if failures.is_empty() else "TEST FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)
