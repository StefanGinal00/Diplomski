extends "res://tests/preview_characters.gd"
const Layout := preload("res://WorldLayout.gd")

func _render() -> void:
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_painted_tasks_preview_save.json"; state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate(); root.add_child(game); current_scene = game
	for tick in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused = false; game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player"); player.test_invincible = true
	var camera: Camera2D = player.get_node("Camera2D")
	var finish := game.get_node("WorldPresentationFinish")
	for id in ["starfall_outskirts","starfall_silent_gate","starfall_rooted_hall","starfall_sunless_passage"]:
		state.set_current_room(id)
		for tick in 5: await process_frame
		finish.finish_room(id); game.get_node("UI")._dismiss_zone_title()
		var room: Node2D = game.get_node(str(Layout.ROOM_NODES[id]))
		for node in finish._members(room):
			if node is StaticBody2D: node.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if node is Area2D or node.is_in_group("enemy"): node.process_mode = Node.PROCESS_MODE_DISABLED
		var ops := room.get_node("ExpandedRoute/StarfallDescent/FieldOperations")
		var station: Node2D = ops.controls[0]
		for completed in [false,true]:
			if completed:
				for event_id in station.required_event_ids: state.unlock_shortcut(event_id)
				state.unlock_shortcut(station.shortcut_id)
				for tick in 3: await process_frame
			var art: Node2D = station.get_node("TaskArt")
			player.global_position = Vector2(station.global_position.x+32,art.support.position.y-24)
			player.velocity = Vector2.ZERO; player.process_mode = Node.PROCESS_MODE_ALWAYS
			for tick in 30: await physics_frame
			if not player.is_on_floor(): push_error("Unsupported task preview "+id); quit(1); return
			player.process_mode = Node.PROCESS_MODE_DISABLED; player.get_node("Appearance")._process(.1)
			camera.offset = Vector2(-12,-36); camera.reset_smoothing(); camera.force_update_scroll()
			finish.background._process(0); finish._process(.15); finish.ambience._process(.15)
			station.player_in_range = player; station._update_visuals()
			await _capture("painted_task_%s_%s" % [id,"done" if completed else "initial"])
		if id not in ["starfall_outskirts","starfall_sunless_passage"]: continue
		var register := room.get_node("ExpandedRoute/FieldDressing/Site1/TaskArt")
		player.global_position = Vector2(register.global_position.x-62,register.support.position.y-24)
		player.velocity = Vector2.ZERO; player.process_mode = Node.PROCESS_MODE_ALWAYS
		for tick in 30: await physics_frame
		player.process_mode = Node.PROCESS_MODE_DISABLED; player.get_node("Appearance")._process(.1)
		camera.offset = Vector2(42,-36); camera.reset_smoothing(); camera.force_update_scroll()
		finish.background._process(0); finish._process(.15); finish.ambience._process(.15)
		finish.reader._refresh_nearest()
		await _capture("painted_register_"+id)
		if id=="starfall_outskirts":
			finish.reader.open_nearest()
			for tick in 5: await process_frame
			if not finish.reader.is_open(): push_error("Ledger reading panel failed"); quit(1); return
			await _capture("painted_register_report")
			finish.reader.close()
	game.free(); state.delete_save(); quit(0)
