extends "res://tests/preview_characters.gd"
const Layout := preload("res://WorldLayout.gd")

func _render() -> void:
	root.size=Vector2i(1280,720); root.content_scale_size=root.size
	var state := root.get_node("GameState")
	state.save_path="res://_tmp_ambient_fauna_preview.json"; state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate(); root.add_child(game); current_scene=game
	for tick in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused=false; game.process_mode=Node.PROCESS_MODE_DISABLED
	var player: Player=game.get_node("Player"); player.test_invincible=true
	var camera: Camera2D=player.get_node("Camera2D")
	var finish := game.get_node("WorldPresentationFinish")
	for id in ["echo_depths","shaft_drift","ash_emberspine","starfall_rooted_hall"]:
		state.set_current_room(id)
		for tick in 5: await process_frame
		finish.finish_room(id); game.get_node("UI")._dismiss_zone_title()
		var room: Node2D=game.get_node(str(Layout.ROOM_NODES[id]))
		for node in finish._members(room):
			if node is CollisionObject2D:
				node.disable_mode=CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
				# Scenery review only; encounters remain frozen, native floors live.
				if node is Area2D or node.is_in_group("enemy") or node.is_in_group("neutral_creature"):
					node.collision_layer=0; node.collision_mask=0
		var flock: Node2D
		for candidate in room.get_node("AmbientFauna").roosts:
			if candidate.global_position.x-candidate.support.position.x>100 and candidate.support.end.x-candidate.global_position.x>150:
				flock=candidate; break
		if flock==null: push_error("Missing preview habitat: "+id); quit(1); return
		player.global_position=Vector2(flock.global_position.x-80,flock.support.position.y-25)
		player.velocity=Vector2.ZERO; player.process_mode=Node.PROCESS_MODE_ALWAYS
		for tick in 30: await physics_frame
		if not player.is_on_floor(): push_error("Fauna preview lacks native floor: "+id); quit(1); return
		player.process_mode=Node.PROCESS_MODE_DISABLED; player.get_node("Appearance")._process(.1)
		camera.offset=Vector2(80,-26); camera.reset_smoothing(); camera.force_update_scroll()
		finish.background._process(0); finish._process(.15)
		var ambience: Node=finish.ambience
		ambience.clear_brushing()
		for tick in 30: ambience._process(1.0/30)
		await _capture("ambient_fauna_"+id+"_calm")
		player.process_mode=Node.PROCESS_MODE_ALWAYS; Input.action_press("ui_right")
		for tick in 30:
			await physics_frame
			ambience._physics_process(1.0/60); ambience._process(1.0/60)
		Input.action_release("ui_right"); player.process_mode=Node.PROCESS_MODE_DISABLED
		player.get_node("Appearance")._process(.1)
		if flock.flight<.1: push_error("Actual controller did not disturb moths: "+id); quit(1); return
		await _capture("ambient_fauna_"+id+"_startled")
		print("FAUNA_NATIVE_CONTACT ",id," flight=",flock.flight," grounded=",player.is_on_floor()," active=",ambience.active.size())
		for tick in 150:
			ambience.sample_brushing(player.global_position,player.global_position,Vector2.ZERO,1.0/60)
			ambience._process(1.0/60)
		await _capture("ambient_fauna_"+id+"_settled")
	game.free(); state.delete_save(); quit(0)
