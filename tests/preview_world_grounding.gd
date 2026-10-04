extends "res://tests/preview_characters.gd"

func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_world_grounding_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.get_node("UI").story_player.cancel()
	paused = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player")
	var camera: Camera2D = player.get_node("Camera2D")
	var finish := game.get_node("WorldPresentationFinish")
	for shot in [
		["training_passage", "", Vector2(580, 345), "lamp"],
		["training_passage", "", Vector2(1290, 345), "exit"],
		["training_passage", "", Vector2(200, 345), "camp"],
		["sunken_shaft", "VerticalChamber", Vector2(735, 612), "shaft_gate"],
		["shaft_hollow", "ShaftHollow", Vector2(180, 270), "side_passage"],
		["sunken_shaft", "VerticalChamber", Vector2(138, 40), "lift"],
		["ash_arena", "AshArena", Vector2(1230, 370), "ash_gate"],
		["starfall_empty_court", "StarfallEmptyCourt", Vector2(80, 335), "court_return"],
	]:
		if "--lift-only" in OS.get_cmdline_user_args() and shot[3] != "lift": continue
		player.process_mode = Node.PROCESS_MODE_DISABLED
		state.set_current_room(shot[0])
		await process_frame
		await process_frame
		finish.finish_room(shot[0])
		game.get_node("UI")._dismiss_zone_title()
		var room: Node2D = game if shot[1] == "" else game.get_node(shot[1])
		for node in finish._members(room):
			if node is StaticBody2D: node.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
		player.global_position = room.to_global(shot[2])
		player.velocity = Vector2.ZERO
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		for tick in range(50): await physics_frame
		print("SETTLED ", shot[3], " ", player.is_on_floor(), " at=", room.to_local(player.global_position))
		if not player.is_on_floor():
			push_error("Preview did not reach real floor: " + str(shot[3]))
			state.delete_save()
			quit(1)
			return
		player.process_mode = Node.PROCESS_MODE_DISABLED
		camera.reset_smoothing()
		camera.force_update_scroll()
		finish.background._process(0)
		finish._process(0.2)
		await _capture("grounding_" + shot[3])
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
