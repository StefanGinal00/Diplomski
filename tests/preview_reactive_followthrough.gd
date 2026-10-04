extends "res://tests/preview_characters.gd"
const Layout := preload("res://WorldLayout.gd")

func _render() -> void:
	root.size = Vector2i(1280,720); root.content_scale_size = root.size
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_reactive_followthrough_preview.json"; state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate(); root.add_child(game); current_scene = game
	for tick in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused = false; game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player"); player.test_invincible = true
	var camera: Camera2D = player.get_node("Camera2D")
	var finish := game.get_node("WorldPresentationFinish")
	for id in ["shaft_gallery","echo_depths","starfall_rooted_hall"]:
		state.set_current_room(id)
		for tick in 5: await process_frame
		finish.finish_room(id); game.get_node("UI")._dismiss_zone_title()
		var room: Node2D = game.get_node(str(Layout.ROOM_NODES[id]))
		for node in finish._members(room):
			if node is CollisionObject2D:
				node.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
				if node is Area2D or node.is_in_group("enemy") or node.is_in_group("neutral_creature"):
					node.collision_layer = 0; node.collision_mask = 0
		var seep: Node2D
		for candidate in room.get_node("PathDressing").seeps:
			if candidate.visible and candidate.fall_distance<220 and candidate.support.size.x>350:
				seep = candidate; break
		if seep==null: push_error("No supported drip preview: "+id); quit(1); return
		# Leave the source ray clear and avoid the frozen Gallery guard's pose.
		player.global_position = Vector2(seep.global_position.x+62,seep.support.position.y-25)
		player.velocity = Vector2.ZERO; player.process_mode = Node.PROCESS_MODE_ALWAYS
		for tick in 30: await physics_frame
		if not player.is_on_floor(): push_error("Unsupported preview player: "+id); quit(1); return
		player.process_mode = Node.PROCESS_MODE_DISABLED; player.get_node("Appearance")._process(.1)
		camera.offset = Vector2(-62,-54); camera.reset_smoothing(); camera.force_update_scroll()
		finish.background._process(0); finish._process(.15); finish.ambience._process(.15)
		seep.source.animate(2.7)
		for sample in [["release",.03],["fall",.54],["splash",.91]]:
			seep.animate(6.8-seep.phase+sample[1])
			await _capture("reactive_drip_"+id+"_"+sample[0])
		print("REACTIVE_DRIP_VIEW ",id," source=",room.to_local(seep.global_position)," fall=",seep.fall_distance," foreground=",room.get_node("ForegroundGrowth").plants.size())
	state.set_current_room("training_passage")
	for tick in 5: await process_frame
	finish.finish_room("training_passage"); game.get_node("UI")._dismiss_zone_title()
	for node in finish._members(game):
		if node is CollisionObject2D:
			node.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if node is Area2D or node.is_in_group("enemy"):
				node.collision_layer = 0; node.collision_mask = 0
	var lamp: Node2D = game.get_node("Checkpoint")
	var floor_rect := preload("res://WorldSupport.gd").below(lamp.global_position-Vector2(0,12),finish.current_surfaces,100)
	if not floor_rect.has_area(): push_error("Opening lamp preview lacks support"); quit(1); return
	# The frozen opening enemy occupies the left side; use the clear right
	# landing so its sprite cannot conceal the grounded player in this fixture.
	player.global_position = Vector2(lamp.global_position.x+38,floor_rect.position.y-25)
	player.velocity = Vector2.ZERO; player.process_mode = Node.PROCESS_MODE_ALWAYS
	for tick in 30: await physics_frame
	if not player.is_on_floor(): push_error("Lamp preview player not grounded"); quit(1); return
	player.process_mode = Node.PROCESS_MODE_DISABLED; player.get_node("Appearance")._process(.1)
	camera.offset = Vector2(24,-32); camera.reset_smoothing(); camera.force_update_scroll()
	finish.background._process(0); finish._process(.15)
	# State changes must reach the real painted lamp even when it has no
	# camera animation slot; no manual call to its animator is made here.
	finish.ambience.select_visible(Rect2(900000,900000,20,20))
	lamp.is_active = false; lamp.is_resting = false
	await _capture("reactive_lamp_culled_unlit")
	lamp.activate_from_travel()
	await _capture("reactive_lamp_culled_lit")
	lamp.is_resting = true
	await _capture("reactive_lamp_culled_resting")
	print("REACTIVE_LAMP_VIEW active_slots=",finish.ambience.active.size()," flame=",lamp.get_node("FinishedDevice/LivingFlame/Flame").visible)
	game.free(); state.delete_save(); quit(0)
