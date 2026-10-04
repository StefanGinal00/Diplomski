extends "res://tests/preview_characters.gd"
const Layout := preload("res://WorldLayout.gd")

func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_ambient_continuity_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game); current_scene = game
	for frame in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player")
	player.test_invincible = true
	var camera: Camera2D = player.get_node("Camera2D")
	var finish := game.get_node("WorldPresentationFinish")
	for id in ["training_passage", "echo_haven", "starfall_citadel"]:
		state.set_current_room(id)
		for frame in 5: await process_frame
		finish.finish_room(id)
		game.get_node("UI")._dismiss_zone_title()
		var room: Node2D = game if id == "training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		var nodes: Array[Node] = finish._members(room)
		for node in nodes:
			if node is StaticBody2D: node.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if node is CharacterBody2D:
				node.process_mode = Node.PROCESS_MODE_ALWAYS
				node.set_physics_process(true)
		for tick in 70: await physics_frame
		for node in nodes:
			if is_instance_valid(node) and node is CharacterBody2D: node.process_mode = Node.PROCESS_MODE_DISABLED
		var focus := room.to_global(Vector2(540, 350) if id == "training_passage" else Vector2(3500, 350))
		if id == "echo_haven":
			var district := room.get_node("NewDistricts")
			focus = district.to_global(district.ledges[4][2]) - Vector2(0, 20)
		var floor_rect := preload("res://WorldSupport.gd").below(focus - Vector2(0, 50), finish.current_surfaces, 150)
		if not floor_rect.has_area():
			push_error("Ambient continuity preview lacks native support: " + id)
			state.delete_save(); quit(1); return
		player.global_position = Vector2(focus.x, floor_rect.position.y - 32)
		player.velocity = Vector2.ZERO
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		for tick in 40: await physics_frame
		player.process_mode = Node.PROCESS_MODE_DISABLED
		if not player.is_on_floor():
			push_error("Ambient continuity preview did not settle: " + id)
			state.delete_save(); quit(1); return
		player.get_node("Appearance")._process(0.1)
		camera.offset = Vector2(40, -40)
		camera.reset_smoothing(); camera.force_update_scroll()
		finish.background._process(0); finish._process(0.15)
		var ambience: Node = finish.ambience
		ambience.set_low_quality(true)
		for sample in 2:
			# Drive the real shared tick, including its quarter-second selection.
			for tick in 19: ambience._process(1.0 / 30.0)
			await _capture("ambient_continuity_%s_%d" % [id, sample])
			if id == "starfall_citadel" and sample == 1: _audit_rects(nodes)
			print("AMBIENT CONTINUITY VIEW ", id, " sample=", sample, " grounded=", player.is_on_floor(),
				" active=", ambience.active.size(), " age=", ambience.age)
	game.free(); state.delete_save(); quit(0)

func _audit_rects(nodes: Array[Node]) -> void:
	for node in nodes:
		if not node is CanvasItem or not node.is_visible_in_tree() or node.self_modulate.a < 0.1: continue
		var local := Rect2()
		if node is Sprite2D: local = node.get_rect()
		elif node is ColorRect: local = Rect2(Vector2.ZERO, node.size)
		elif node is Polygon2D and not node.polygon.is_empty():
			local = Rect2(node.polygon[0], Vector2.ZERO)
			for point in node.polygon: local = local.expand(point)
		else: continue
		var rect: Rect2 = node.get_global_transform_with_canvas() * local
		for at in [Vector2(423, 50), Vector2(457, 463)]:
			if rect.has_point(at): print("AMBIENT PIXEL OWNER ", at, " ", node.get_path(), " rect=", rect, " type=", node.get_class())
