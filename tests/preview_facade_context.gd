extends "res://tests/preview_city_architecture_finish.gd"

func _render() -> void:
	root.size = Vector2i(1280,720); root.content_scale_size = root.size
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_facade_context_preview.json"; state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game); current_scene = game
	for frame in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player"); player.test_invincible = true
	var camera: Camera2D = player.get_node("Camera2D")
	var finish := game.get_node("WorldPresentationFinish")
	var views := {"echo_haven":[Vector2(510,-18)],"echo_haven_outskirts":[],"ash_hearth":[Vector2(500,285),Vector2(4103,350)]}
	for id in views:
		state.set_current_room(id)
		for frame in 5: await process_frame
		finish.finish_room(id); game.get_node("UI")._dismiss_zone_title()
		var room: Node2D = game.get_node(str(Layout.ROOM_NODES[id]))
		if id.begins_with("echo_haven"):
			var district := room.get_node("NewDistricts" if id == "echo_haven" else "GateApproach")
			for at in [district.ledges[0][1],district.ledges[1][1],district.ledges[4][2]]:
				views[id].append(room.to_local(district.to_global(at))-Vector2(0,35))
		var nodes: Array[Node] = finish._members(room)
		for node in nodes:
			if node is StaticBody2D: node.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if node is CharacterBody2D and node != player:
				node.process_mode = Node.PROCESS_MODE_ALWAYS; node.set_physics_process(true)
		for tick in 70: await physics_frame
		for node in nodes:
			if is_instance_valid(node) and node is CharacterBody2D and node != player: node.process_mode = Node.PROCESS_MODE_DISABLED
		for index in views[id].size():
			player.global_position = room.to_global(views[id][index]); player.velocity = Vector2.ZERO
			player.process_mode = Node.PROCESS_MODE_ALWAYS
			for tick in 40: await physics_frame
			player.process_mode = Node.PROCESS_MODE_DISABLED
			if not player.is_on_floor(): push_error("Facade preview lacks real floor: " + id); state.delete_save(); quit(1); return
			player.get_node("Appearance")._process(0.1)
			camera.offset = Vector2(40,-28); camera.reset_smoothing(); camera.force_update_scroll()
			finish.background._process(0); finish._process(0.15); finish.ambience._process(0.15)
			await _capture("facade_context_%s_%d" % [id,index])
			print("FACADE CONTEXT VIEW ",id," ",index," grounded=",player.is_on_floor())
	game.free(); state.delete_save(); quit(0)
