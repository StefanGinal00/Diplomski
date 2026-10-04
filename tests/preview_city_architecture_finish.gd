extends "res://tests/preview_characters.gd"
const Layout := preload("res://WorldLayout.gd")

func _render() -> void:
	root.size=Vector2i(1280,720)
	root.content_scale_size=root.size
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_city_architecture_preview.json"
	state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	for i in 5: await process_frame
	game.get_node("UI").story_player.cancel()
	paused=false
	game.process_mode=Node.PROCESS_MODE_DISABLED
	var player: Player=game.get_node("Player")
	player.test_invincible=true
	var camera: Camera2D=player.get_node("Camera2D")
	var finish:=game.get_node("WorldPresentationFinish")
	var views := {
		"starfall_citadel":[Vector2(5750,-1660),Vector2(5170,-1660),Vector2(1660,-345),Vector2(4740,-670),Vector2(3260,-1130),Vector2(3520,350),Vector2(4480,350)],
		"echo_haven":[Vector2(510,-18)],
		"echo_haven_outskirts":[Vector2(900,115)],
		"ash_hearth":[Vector2(500,285),Vector2(1850,0)],
	}
	for id in views:
		state.set_current_room(id)
		for i in 5: await process_frame
		finish.finish_room(id)
		game.get_node("UI")._dismiss_zone_title()
		var room: Node2D=game.get_node(str(Layout.ROOM_NODES[id]))
		var nodes: Array[Node]=finish._members(room)
		for n in nodes:
			if n is StaticBody2D: n.disable_mode=CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if n is CharacterBody2D and n!=player:
				n.process_mode=Node.PROCESS_MODE_ALWAYS
				n.set_physics_process(true)
		for tick in 90: await physics_frame
		for n in nodes:
			if is_instance_valid(n) and n is CharacterBody2D and n!=player: n.process_mode=Node.PROCESS_MODE_DISABLED
		for index in views[id].size():
			player.global_position=room.to_global(views[id][index])
			player.velocity=Vector2.ZERO
			player.process_mode=Node.PROCESS_MODE_ALWAYS
			for tick in 45: await physics_frame
			player.process_mode=Node.PROCESS_MODE_DISABLED
			player.get_node("Appearance")._process(0.1)
			camera.offset=Vector2(36,-45)
			camera.reset_smoothing()
			camera.force_update_scroll()
			finish.background._process(0)
			finish._process(0.15)
			finish.ambience._process(0.15)
			await _capture("city_finish_%s_%d"%[id,index])
			print("CITY FINISH VIEW ",id," ",index," ",room.to_local(player.global_position)," grounded=",player.is_on_floor())
	state.delete_save()
	quit()
