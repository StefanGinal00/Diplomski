extends "res://tests/preview_characters.gd"
const Layout := preload("res://WorldLayout.gd")

func _render() -> void:
	root.size=Vector2i(1280,720); root.content_scale_size=root.size
	var state := root.get_node("GameState")
	state.save_path="res://_tmp_ground_dust_preview.json"; state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate(); root.add_child(game); current_scene=game
	for tick in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused=false; game.process_mode=Node.PROCESS_MODE_DISABLED
	var player: Player=game.get_node("Player"); player.test_invincible=true
	var camera: Camera2D=player.get_node("Camera2D")
	var finish := game.get_node("WorldPresentationFinish")
	for id in ["echo_depths","sunken_shaft","ash_barracks","starfall_citadel"]:
		state.set_current_room(id)
		for tick in 5: await process_frame
		finish.finish_room(id); game.get_node("UI")._dismiss_zone_title()
		var room: Node2D=game.get_node(str(Layout.ROOM_NODES[id]))
		for node in finish._members(room):
			if node is CollisionObject2D:
				node.disable_mode=CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
				if node is Area2D or node.is_in_group("enemy") or node.is_in_group("neutral_creature"):
					node.collision_layer=0; node.collision_mask=0
		var at := Vector2.ZERO
		var patches: Array=room.get_node("RouteRelief").patches
		if not patches.is_empty():
			var patch: Node2D=patches[0]
			var x: float=patch.global_position.x+patch.plan.width*.35
			at=Vector2(x,patch.height_at(x)-25)
		else:
			var roost: Node2D=room.get_node("AmbientFauna").roosts[0]
			at=Vector2(roost.global_position.x,roost.support.position.y-25)
		player.global_position=at; player.velocity=Vector2.ZERO; player.process_mode=Node.PROCESS_MODE_ALWAYS
		for tick in 30: await physics_frame
		if not player.is_on_floor(): push_error("Dust preview missing real floor: "+id); quit(1); return
		player.process_mode=Node.PROCESS_MODE_DISABLED; player.get_node("Appearance")._process(.1)
		camera.offset=Vector2(0,-28); camera.reset_smoothing(); camera.force_update_scroll()
		finish.background._process(0); finish._process(.15)
		var ambience: Node=finish.ambience
		var fx: Node2D=ambience.ground_contacts
		ambience.clear_brushing(); fx.set_low_quality(false)
		await _capture("ground_dust_"+id+"_idle")
		var before: int=fx.step_events
		player.process_mode=Node.PROCESS_MODE_ALWAYS; Input.action_press("ui_right")
		for tick in 18:
			await physics_frame; ambience._physics_process(1.0/60); ambience._process(1.0/60)
		Input.action_release("ui_right"); player.process_mode=Node.PROCESS_MODE_DISABLED
		player.get_node("Appearance")._process(.1)
		if fx.step_events<=before or fx.puffs.is_empty(): push_error("Native walk fails to produce dust: "+id); quit(1); return
		await _capture("ground_dust_"+id+"_step")
		print("DUST_NATIVE_STEP ",id," material=",fx.last_contact.material," normal=",fx.last_contact.normal," at=",fx.last_contact.position," puffs=",fx.puffs.size())
		player.velocity=Vector2.ZERO; player.process_mode=Node.PROCESS_MODE_ALWAYS
		fx.clear(); fx.track(player,1.0/60,ambience.brush_palette)
		var landings: int=fx.landing_events
		player.jump_buffer_remaining=.12
		for tick in 150:
			await physics_frame; ambience._physics_process(1.0/60); ambience._process(1.0/60)
			if fx.landing_events>landings: break
		if fx.landing_events!=landings+1 or not player.is_on_floor(): push_error("Native landing not registered: "+id); quit(1); return
		player.process_mode=Node.PROCESS_MODE_DISABLED; player.get_node("Appearance")._process(.1)
		for tick in 12: fx.advance(1.0/60)
		await _capture("ground_dust_"+id+"_landing")
		print("DUST_NATIVE_LANDING ",id," grounded=",player.is_on_floor()," puffs=",fx.puffs.size())
		for tick in 45: fx.advance(1.0/60)
		if not fx.puffs.is_empty(): push_error("Native dust never settles"); quit(1); return
		await _capture("ground_dust_"+id+"_settled")
	game.free(); state.delete_save(); quit(0)
