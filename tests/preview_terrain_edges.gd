extends "res://tests/preview_characters.gd"
const Layout:=preload("res://WorldLayout.gd")

func _render() -> void:
	root.size=Vector2i(1280,720)
	root.content_scale_size=root.size
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_terrain_edge_preview.json"
	state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	for i in 5: await process_frame
	game.get_node("UI").story_player.cancel()
	paused=false
	game.process_mode=Node.PROCESS_MODE_DISABLED
	var p: Player=game.get_node("Player")
	p.test_invincible=true
	var camera: Camera2D=p.get_node("Camera2D")
	var finish:=game.get_node("WorldPresentationFinish")
	var rooms := ["training_passage","sunken_shaft","shaft_hollow","ash_hearth","ash_forge","starfall_citadel"]
	var requested := OS.get_cmdline_user_args()
	if not requested.is_empty(): rooms = rooms.filter(func(id): return id in requested)
	for id in rooms:
		state.set_current_room(id)
		for i in 5: await process_frame
		finish.finish_room(id)
		game.get_node("UI")._dismiss_zone_title()
		var room: Node2D=game if id=="training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		var nodes: Array[Node]=finish._members(room)
		for n in nodes:
			if n is StaticBody2D: n.disable_mode=CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
		# Frozen scene previews used to freeze authored spawn heights too,
		# showing ground creatures hovering before their first gravity tick.
		# Settle actual physics before freezing the screenshot composition.
		for n in nodes:
			if n is CharacterBody2D and n!=p:
				n.process_mode=Node.PROCESS_MODE_ALWAYS
				n.set_physics_process(true)
		for tick in 90: await physics_frame
		for n in nodes:
			if is_instance_valid(n) and n is CharacterBody2D and n!=p:
				n.process_mode=Node.PROCESS_MODE_DISABLED
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
			await _capture("terrain_edges_%s_%d"%[id,index])
			print("TERRAIN EDGE VIEW ",id," ",index," ",p.global_position-room.global_position," grounded ",p.is_on_floor())
	state.delete_save()
	quit()
