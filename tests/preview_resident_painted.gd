extends "res://tests/preview_characters.gd"
const Layout := preload("res://WorldLayout.gd")
const Support := preload("res://WorldSupport.gd")

func _render() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_resident_painted_preview.json"
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
	var cases := [["echo_haven","Neris"], ["ash_hearth","Dara"], ["starfall_citadel","Liora"], ["ash_forge","AshSwitchback/FieldDressing/Site3/IndustrialLandmark"], ["ash_barracks","AshSwitchback/FieldDressing/Site3/IndustrialLandmark"], ["ash_hearth_outskirts","AshSwitchback/FieldDressing/Site2/IndustrialLandmark"]]
	for entry in cases:
		var id: String = entry[0]
		player.process_mode = Node.PROCESS_MODE_DISABLED
		state.set_current_room(id)
		await process_frame
		await process_frame
		finish.finish_room(id)
		game.get_node("UI")._dismiss_zone_title()
		var room: Node2D = game.get_node(str(Layout.ROOM_NODES[id]))
		var target: Node2D = room.get_node(entry[1])
		var floor_rect := Support.below(target.global_position-Vector2(0,2), finish.current_surfaces)
		for node in finish._members(room):
			if node is StaticBody2D: node.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
		var spacing := 130 if id=="ash_hearth_outskirts" else 52
		player.global_position = Vector2(clampf(target.global_position.x-spacing,floor_rect.position.x+16,floor_rect.end.x-16),floor_rect.position.y-60)
		player.velocity = Vector2.ZERO
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		for tick in range(60): await physics_frame
		await process_frame
		await process_frame
		# Let the appearance consume the last landing before freezing the frame.
		player.get_node("Appearance")._process(0.1)
		print("RESIDENT PREVIEW SETTLED ",id," ",player.is_on_floor())
		if not player.is_on_floor():
			push_error("No native preview floor: "+id)
			state.delete_save()
			quit(1)
			return
		player.process_mode = Node.PROCESS_MODE_DISABLED
		camera.offset = Vector2(48,-24)
		camera.reset_smoothing()
		camera.force_update_scroll()
		finish.background._process(0)
		finish._process(0.2)
		await _capture("resident_"+id+"_idle")
		if target.has_node("ResidentMotion"):
			var motion := target.get_node("ResidentMotion")
			motion.facing = -1
			target.set_player_dialogue_active(true)
			motion._update_paint()
			await _capture("resident_"+id+"_talk")
			target.set_player_dialogue_active(false)
			motion.painted.show_pose(1,1,motion.foot_y,1)
			await _capture("resident_"+id+"_stride")
		elif id=="ash_forge":
			state.unlock_shortcut("ash_forge_fan")
			target.animate(1.5)
			await _capture("resident_ash_forge_active")
	game.queue_free()
	await process_frame
	state.delete_save()
	quit()
