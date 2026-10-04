extends "res://tests/preview_characters.gd"
const Layout := preload("res://WorldLayout.gd")
const Support := preload("res://WorldSupport.gd")

func _render() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_settlement_atmosphere_preview.json"
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
	for entry in _targets():
		var id: String = entry[0]
		if OS.get_cmdline_user_args().has("report-only") and entry[2]!="noticeboard": continue
		player.process_mode = Node.PROCESS_MODE_DISABLED
		state.set_current_room(id)
		for frame in 3: await process_frame
		finish.finish_room(id)
		game.get_node("UI")._dismiss_zone_title()
		var room: Node2D = game.get_node(str(Layout.ROOM_NODES[id]))
		var target: Vector2 = room.to_global(entry[1])
		var floor_rect := Support.below(target,finish.current_surfaces,100)
		if not floor_rect.has_area():
			push_error("Preview point unsupported: "+str(entry))
			state.delete_save()
			quit(1)
			return
		for node in finish._members(room):
			if node is StaticBody2D: node.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
		player.global_position = Vector2(clampf(target.x-42,floor_rect.position.x+16,floor_rect.end.x-16),floor_rect.position.y-60)
		player.velocity = Vector2.ZERO
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		for tick in 60: await physics_frame
		for frame in 2: await process_frame
		player.get_node("Appearance")._process(0.1)
		print("ATMOSPHERE PREVIEW SETTLED ",entry[2]," ",player.is_on_floor())
		if not player.is_on_floor():
			state.delete_save()
			quit(1)
			return
		player.process_mode = Node.PROCESS_MODE_DISABLED
		camera.offset = Vector2(45,-28)
		camera.reset_smoothing()
		camera.force_update_scroll()
		finish.background._process(0)
		if room.has_node("ParallaxArchitecture"): room.get_node("ParallaxArchitecture")._process(0)
		finish._process(0.2)
		for detail in room.get_node("SettlementAtmosphere").hangings: detail.animate(2)
		await _capture("atmosphere_"+entry[2])
		if entry[2]=="noticeboard":
			finish.reader.open_nearest()
			if not finish.reader.is_open() or finish.reader.heading.text!="CITADEL FIELD OFFICE":
				push_error("Preview field report did not open")
				state.delete_save()
				quit(1)
				return
			await _capture("atmosphere_field_report")
			for step in 8: await process_frame
			await _capture("atmosphere_field_report_settled")
			print("FIELD REPORT LAYOUT ",finish.reader.panel.get_rect()," minimum ",finish.reader.panel.get_combined_minimum_size()," viewport ",root.get_visible_rect())
			if not root.get_visible_rect().encloses(finish.reader.panel.get_rect()):
				push_error("Native field report exceeds viewport")
				state.delete_save()
				quit(1)
				return
			finish.reader.close()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit()

func _targets() -> Array:
	return [["echo_haven",Vector2(1250,157),"echo_terrace"],["ash_hearth",Vector2(900,380),"smithy_lantern"],["ash_hearth",Vector2(1700,380),"cinder_joinery"],["starfall_citadel",Vector2(2557,390),"fountain"],["starfall_citadel",Vector2(2773,390),"noticeboard"],["starfall_citadel",Vector2(5050,390),"garden"],["starfall_citadel",Vector2(5750,390),"observatory"]]
