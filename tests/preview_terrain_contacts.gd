extends "res://tests/preview_characters.gd"
const Layout := preload("res://WorldLayout.gd")

func _render() -> void:
	root.size = Vector2i(1280,720); root.content_scale_size = root.size
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_terrain_contacts_preview.json"; state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate(); root.add_child(game); current_scene = game
	for tick in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused = false; game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player"); player.test_invincible = true
	var camera: Camera2D = player.get_node("Camera2D")
	var finish := game.get_node("WorldPresentationFinish")
	for id in ["sunken_shaft","echo_depths","ash_barracks","starfall_outskirts"]:
		state.set_current_room(id)
		for tick in 5: await process_frame
		finish.finish_room(id); game.get_node("UI")._dismiss_zone_title()
		var room: Node2D = game.get_node(str(Layout.ROOM_NODES[id]))
		for node in finish._members(room):
			if node is StaticBody2D: node.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if node is Area2D or node.is_in_group("enemy"): node.process_mode = Node.PROCESS_MODE_DISABLED
		var joints: Array = room.get_node("TerrainJoints").details
		if joints.is_empty(): push_error("No wall-foot preview: "+id); quit(1); return
		var joint: Node2D = joints[0]; var side: int = joint.get_meta("joint_side")
		player.global_position = Vector2(joint.global_position.x+side*34,joint.support.position.y-24)
		player.velocity = Vector2.ZERO; player.process_mode = Node.PROCESS_MODE_ALWAYS
		for tick in 30: await physics_frame
		if not player.is_on_floor(): push_error("Unsupported corner preview: "+id); quit(1); return
		player.process_mode = Node.PROCESS_MODE_DISABLED; player.get_node("Appearance")._process(.1)
		camera.offset = Vector2(side*-34,-36); camera.reset_smoothing(); camera.force_update_scroll()
		finish.background._process(0); finish._process(.15); finish.ambience._process(.15)
		await _capture("terrain_joint_"+id)
		print("JOINT_VIEW ",id," position=",room.to_local(joint.global_position))
		if id!="sunken_shaft": continue
		var patch: Node2D = room.get_node("RouteRelief").patches[0]
		player.global_position = Vector2(patch.global_position.x+20,patch.height_at(patch.global_position.x+20)-25)
		player.velocity = Vector2.ZERO; player.process_mode = Node.PROCESS_MODE_ALWAYS
		for tick in 25: await physics_frame
		finish.ambience.clear_brushing(); finish.ambience._physics_process(1.0/60)
		var fx: Node2D = finish.ambience.ground_contacts
		var before_steps: int = fx.step_events
		Input.action_press("ui_right")
		for tick in 70:
			await physics_frame; finish.ambience._physics_process(1.0/60)
			if fx.step_events>before_steps: break
		Input.action_release("ui_right"); player.process_mode = Node.PROCESS_MODE_DISABLED
		for tick in 3: fx.advance(1.0/60)
		camera.offset = Vector2(34,-36); camera.reset_smoothing(); camera.force_update_scroll(); finish.background._process(0)
		await _capture("terrain_contact_step")
		print("LIVE_STEP events=",fx.step_events-before_steps," grains=",fx.grains.size()," material=",fx.last_contact.get("material",""))
		if fx.step_events<=before_steps: push_error("Live footsteps missing"); quit(1); return
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		for tick in 20: await physics_frame; finish.ambience._physics_process(1.0/60)
		var before_landing: int = fx.landing_events
		player.jump_buffer_remaining = .12
		for tick in 100:
			await physics_frame; finish.ambience._physics_process(1.0/60)
			if fx.landing_events>before_landing: break
		player.process_mode = Node.PROCESS_MODE_DISABLED
		for tick in 4: fx.advance(1.0/60)
		camera.reset_smoothing(); camera.force_update_scroll(); finish.background._process(0)
		await _capture("terrain_contact_landing")
		print("LIVE_LANDING events=",fx.landing_events-before_landing," grains=",fx.grains.size())
		if fx.landing_events!=before_landing+1: push_error("Live landing burst missing/duplicated"); quit(1); return
	game.free(); state.delete_save(); quit(0)
