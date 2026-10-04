extends "res://tests/preview_characters.gd"
const Layout := preload("res://WorldLayout.gd")
const Support := preload("res://WorldSupport.gd")

func _render() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_service_painted_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for frame in 3: await process_frame
	game.get_node("UI").story_player.cancel()
	paused = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player")
	var camera: Camera2D = player.get_node("Camera2D")
	var finish := game.get_node("WorldPresentationFinish")
	for entry in [["echo_haven","GlowmarketTrader"],["echo_haven","CrystalAnvil"],["echo_haven","NewDistricts/CanalTrader"],["echo_haven","NewDistricts/MoonSmith"],["ash_hearth","Quartermaster"],["ash_hearth","Anvil"],["starfall_citadel","WardDistrict/SupplyStall"],["starfall_citadel","WardDistrict/WardAnvil"],["starfall_citadel","MarketTrader"],["starfall_citadel","Apothecary"]]:
		var id: String = entry[0]
		player.process_mode = Node.PROCESS_MODE_DISABLED
		state.set_current_room(id)
		for frame in 3: await process_frame
		finish.finish_room(id)
		game.get_node("UI")._dismiss_zone_title()
		var room: Node2D = game.get_node(str(Layout.ROOM_NODES[id]))
		var target: Node2D = room.get_node(entry[1])
		var floor_rect := Support.below(target.global_position,finish.current_surfaces)
		for node in finish._members(room):
			if node is StaticBody2D: node.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
		player.global_position = Vector2(clampf(target.global_position.x-48,floor_rect.position.x+16,floor_rect.end.x-16),floor_rect.position.y-60)
		player.velocity = Vector2.ZERO
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		for tick in 60: await physics_frame
		for frame in 2: await process_frame
		player.get_node("Appearance")._process(0.1)
		print("SERVICE PREVIEW SETTLED ",id,"/",entry[1]," ",player.is_on_floor())
		if not player.is_on_floor():
			state.delete_save()
			quit(1)
			return
		player.process_mode = Node.PROCESS_MODE_DISABLED
		camera.offset = Vector2(52,-26)
		camera.reset_smoothing()
		camera.force_update_scroll()
		finish.background._process(0)
		finish._process(0.2)
		var art := target.get_node("ServicePainting")
		for pose in 3:
			art.show_pose(pose,art.direction if pose!=2 else -1)
			await _capture("service_"+String(entry[1]).replace("/","_")+"_"+str(pose))
	game.queue_free()
	await process_frame
	state.delete_save()
	quit()
