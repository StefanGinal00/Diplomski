extends "res://tests/preview_characters.gd"
const Layout:=preload("res://WorldLayout.gd")

func _render() -> void:
	root.size=Vector2i(1280,720)
	root.content_scale_size=root.size
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_corridor_preview.json"
	state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	for i in 5: await process_frame
	game.get_node("UI").story_player.cancel()
	paused=false
	game.process_mode=Node.PROCESS_MODE_DISABLED
	var p: Player=game.get_node("Player")
	var camera: Camera2D=p.get_node("Camera2D")
	var finish:=game.get_node("WorldPresentationFinish")
	for id in ["training_passage","sunken_shaft","shaft_hollow","ash_hearth","starfall_citadel"]:
		state.set_current_room(id)
		for i in 5: await process_frame
		finish.finish_room(id)
		game.get_node("UI")._dismiss_zone_title()
		var room: Node2D=game if id=="training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		var nodes: Array[Node]=finish._members(room)
		for n in nodes:
			if n is StaticBody2D: n.disable_mode=CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
		var targets: Array[Vector2]=[]
		if id=="training_passage": targets=[Vector2(78,360),Vector2(1310,360)]
		elif id=="sunken_shaft": targets=[Vector2(-3350,680),Vector2(-1900,630),Vector2(-900,630),Vector2(-2300,630),Vector2(-1420,630)]
		else:
			for n in room.get_node("CorridorDressing").clusters:
				if n.visible: targets.append(room.to_local(n.get_meta("ground_contact"))-Vector2(30,20));break
		for n in nodes:
			if n.is_in_group("shaft_lift") and targets.size()<7: targets.append(room.to_local(n.global_position)-Vector2(38,4))
		for index in targets.size():
			p.global_position=room.to_global(targets[index])
			p.velocity=Vector2.ZERO
			p.process_mode=Node.PROCESS_MODE_ALWAYS
			for tick in 35: await physics_frame
			p.process_mode=Node.PROCESS_MODE_DISABLED
			p.get_node("Appearance")._process(0.1)
			camera.offset=Vector2(36,-35)
			camera.reset_smoothing()
			camera.force_update_scroll()
			finish.background._process(0)
			finish._process(0.15)
			finish.ambience._process(0.15)
			await _capture("corridor_%s_%d"%[id,index])
			print("CORRIDOR VIEW ",id," ",index," ",p.global_position-room.global_position," grounded ",p.is_on_floor())
		if id=="sunken_shaft":
			game.get_node("TestingTools").toggle()
			await _capture("testing_tools")
			game.get_node("TestingTools").toggle()
	state.delete_save()
	quit()
