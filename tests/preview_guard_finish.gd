extends "res://tests/preview_city_architecture_finish.gd"

func _render() -> void:
	root.size=Vector2i(1280,720); root.content_scale_size=root.size
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_guard_finish_preview.json"
	state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate()
	root.add_child(game); current_scene=game
	for i in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused=false
	game.process_mode=Node.PROCESS_MODE_DISABLED
	var player: Player=game.get_node("Player")
	player.test_invincible=true
	var camera: Camera2D=player.get_node("Camera2D")
	var finish:=game.get_node("WorldPresentationFinish")
	var views := {"ash_hearth":[Vector2(4103,350),Vector2(3830,-315)],"starfall_citadel":[Vector2(265,350),Vector2(640,350),Vector2(6108,350)],"sunken_shaft":[],"echo_haven_outskirts":[Vector2(3450,-985)],"shaft_hollow":[],"shaft_crossing":[],"shaft_gallery":[],"echo_tide_well":[]}
	for id in views:
		state.set_current_room(id)
		for i in 5: await process_frame
		finish.finish_room(id); game.get_node("UI")._dismiss_zone_title()
		var room: Node2D=game if id=="training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		var nodes: Array[Node]=finish._members(room)
		if id=="ash_hearth":
			for entry in room.get_node("CivicArt").landmarks:
				views[id].append(entry.bounds.get_center()*Vector2(1,0)+Vector2(0,entry.bounds.end.y-24))
		if views[id].is_empty():
			for node in nodes:
				if not (node is LevelExit or node.is_in_group("room_door")): continue
				if id in ["shaft_hollow","shaft_crossing","shaft_gallery","echo_tide_well"] and node.name not in [&"LowerReturnDoor",&"CisternDoor",&"VaultDoor",&"NestDoor"]: continue
				var support := preload("res://WorldSupport.gd").below(node.global_position,finish.current_surfaces)
				if not support.has_area(): continue
				views[id].append(room.to_local(Vector2(clampf(node.global_position.x-42,support.position.x+14,support.end.x-14),support.position.y-24)))
				if views[id].size()==2: break
		if room.has_node("ApproachGateArt"):
			for piece in room.get_node("ApproachGateArt").pieces: print("GATE PIECE ",piece.name," ",piece.global_position," ",piece.get_meta("support_rect"))
		if room.has_node("GateDoor"):
			var entrance := room.get_node("GateDoor")
			print("GATE SUPPORT ",entrance.global_position," ",entrance.get_node("PortalSurround").get_meta("supported_floor"))
		for n in nodes:
			if n is StaticBody2D: n.disable_mode=CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if n is CharacterBody2D and n!=player:
				n.process_mode=Node.PROCESS_MODE_ALWAYS; n.set_physics_process(true)
		for tick in 90: await physics_frame
		for n in nodes:
			if is_instance_valid(n) and n is CharacterBody2D and n!=player: n.process_mode=Node.PROCESS_MODE_DISABLED
			if n is Polygon2D and n.visible and n.texture!=null and "depth_v1" in n.texture.resource_path: print("VISIBLE DEPTH ",n.get_path()," ",n.texture.resource_path)
		for index in views[id].size():
			player.global_position=room.to_global(views[id][index]); player.velocity=Vector2.ZERO
			player.process_mode=Node.PROCESS_MODE_ALWAYS
			for tick in 45: await physics_frame
			player.process_mode=Node.PROCESS_MODE_DISABLED
			player.get_node("Appearance")._process(0.1)
			camera.offset=Vector2(36,-45); camera.reset_smoothing(); camera.force_update_scroll()
			finish.background._process(0); finish._process(0.15); finish.ambience._process(0.15)
			await _capture("guard_finish_%s_%d"%[id,index])
			print("GUARD VIEW ",id," ",index," ",room.to_local(player.global_position)," grounded=",player.is_on_floor())
	state.delete_save(); quit()
