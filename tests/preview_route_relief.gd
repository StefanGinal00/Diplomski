extends "res://tests/preview_characters.gd"
const Layout := preload("res://WorldLayout.gd")

func _render() -> void:
	root.size = Vector2i(1280,720); root.content_scale_size = root.size
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_route_relief_preview.json"; state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate(); root.add_child(game); current_scene = game
	for tick in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused = false; game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player"); player.test_invincible = true
	var camera: Camera2D = player.get_node("Camera2D")
	var finish := game.get_node("WorldPresentationFinish")
	for id in ["sunken_shaft","echo_depths","ash_barracks","starfall_sunless_passage"]:
		state.set_current_room(id)
		for tick in 5: await process_frame
		finish.finish_room(id); game.get_node("UI")._dismiss_zone_title()
		var room: Node2D = game if id=="training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		for node in finish._members(room):
			if node is StaticBody2D: node.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
		var patches: Array = room.get_node("RouteRelief").patches
		if patches.is_empty(): print("NO_RELIEF_PREVIEW ",id); continue
		var patch: Node2D = patches[0]
		player.global_position = Vector2(patch.global_position.x+patch.plan.width*.4,patch.height_at(patch.global_position.x+patch.plan.width*.4)-25)
		player.velocity = Vector2.ZERO; player.process_mode = Node.PROCESS_MODE_ALWAYS
		for tick in 30: await physics_frame
		if not player.is_on_floor(): push_error("Relief preview lacks physical support: "+id); state.delete_save(); quit(1); return
		player.process_mode = Node.PROCESS_MODE_DISABLED
		player.get_node("Appearance")._process(.1)
		camera.offset = Vector2(0,-36); camera.reset_smoothing(); camera.force_update_scroll()
		finish.background._process(0); finish._process(.15); finish.ambience._process(.15)
		await _capture("route_relief_"+id)
		print("RELIEF_VIEW ",id," at=",room.to_local(player.global_position)," patches=",patches.size())
		if id=="sunken_shaft":
			var grass: Node2D = patch.plants[1]
			player.global_position = Vector2(grass.global_position.x-34,patch.height_at(grass.global_position.x-34)-25)
			player.velocity = Vector2.ZERO; player.process_mode = Node.PROCESS_MODE_ALWAYS
			for tick in 24: await physics_frame
			finish.ambience.clear_brushing()
			finish.ambience._physics_process(1.0/60)
			Input.action_press("ui_right")
			for tick in 24:
				await physics_frame
				finish.ambience._physics_process(1.0/60)
			Input.action_release("ui_right"); player.process_mode = Node.PROCESS_MODE_DISABLED
			camera.reset_smoothing(); camera.force_update_scroll(); finish.background._process(0)
			await _capture("route_reaction_brush")
			print("LIVE_BRUSH contacts=",finish.ambience.brush_contacts," bend=",grass.response.bend," motes=",finish.ambience.brush_motes.motes.size())
			if grass.response.bend<=.03: push_error("Real walking did not brush grass")
			for tick in 200: finish.ambience._physics_process(1.0/60)
			await _capture("route_reaction_recovered")
			print("LIVE_BRUSH_RECOVERED bend=",grass.response.bend)
	game.free(); state.delete_save(); quit(0)
