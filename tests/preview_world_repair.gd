extends "res://tests/preview_characters.gd"
const Layout := preload("res://WorldLayout.gd")

func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_world_repair_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for i in 5: await process_frame
	game.get_node("UI").story_player.cancel()
	paused = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player")
	var camera: Camera2D = player.get_node("Camera2D")
	var finish := game.get_node("WorldPresentationFinish")
	for id in ["training_passage", "sunken_shaft", "shaft_hollow", "shaft_crossing", "ash_hearth", "starfall_citadel"]:
		player.process_mode = Node.PROCESS_MODE_DISABLED
		state.set_current_room(id)
		for i in 5: await process_frame
		finish.finish_room(id)
		game.get_node("UI")._dismiss_zone_title()
		var room: Node2D = game if id == "training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		var nodes: Array[Node] = finish._members(room)
		var targets: Array[Node2D] = []
		for n in nodes:
			if n is StaticBody2D: n.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if n is LevelExit or n.is_in_group("room_door") or n.is_in_group("checkpoint"): targets.append(n)
			elif String(n.name) in ["Site0", "Site1"] and n.get_parent().get_script() in [load("res://ShaftRouteDressing.gd"), load("res://RouteFieldDressing.gd")]: targets.append(n)
		var count := 0
		for target in targets:
			if count >= 6: break
			var floor_rect := preload("res://WorldSupport.gd").below(target.global_position, finish.current_surfaces, 160)
			if not floor_rect.has_area(): continue
			player.global_position = Vector2(clampf(target.global_position.x - 52, floor_rect.position.x + 14, floor_rect.end.x - 14), floor_rect.position.y - 18)
			player.velocity = Vector2.ZERO
			player.process_mode = Node.PROCESS_MODE_ALWAYS
			for tick in 40: await physics_frame
			for frame in 2: await process_frame
			player.get_node("Appearance")._process(0.1)
			print("REPAIR GROUNDED ",player.is_on_floor())
			player.process_mode = Node.PROCESS_MODE_DISABLED
			camera.offset = Vector2(45, -36)
			camera.reset_smoothing()
			camera.force_update_scroll()
			finish.background._process(0)
			finish._process(0.2)
			finish.ambience._process(0.15)
			await _capture("world_repair_%s_%d" % [id, count])
			if target.is_in_group("checkpoint"):
				target.is_active=true
				target.is_revealed=true
				target.get_node("FinishedDevice/LivingFlame").animate(0.15)
				await _capture("world_repair_%s_%d_lit" % [id,count])
			print("REPAIR VIEW ", id, " ", count, " ", target.get_path(), " floor ", floor_rect)
			count += 1
	state.delete_save()
	quit()
