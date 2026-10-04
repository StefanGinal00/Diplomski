extends "res://tests/preview_city_architecture_finish.gd"

func _render() -> void:
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_body_city_preview.json";state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate();root.add_child(game);current_scene=game
	for tick in 5: await process_frame
	game.get_node("UI").story_player.cancel();paused=false
	game.process_mode=Node.PROCESS_MODE_DISABLED
	var player: Player=game.get_node("Player");player.test_invincible=true
	var camera: Camera2D=player.get_node("Camera2D")
	var finish:=game.get_node("WorldPresentationFinish")
	var views: Dictionary={"training_passage":[Vector2(540,350)],"echo_haven":[],"echo_haven_outskirts":[],"ash_hearth":[Vector2(4103,350)],"starfall_citadel":[Vector2(265,350),Vector2(3500,350)],"sunken_shaft":[],"echo_tide_well":[]}
	for id in views:
		state.set_current_room(id)
		for tick in 5: await process_frame
		finish.finish_room(id);game.get_node("UI")._dismiss_zone_title()
		var room: Node2D=game if id=="training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		var nodes: Array[Node]=finish._members(room)
		if id=="echo_haven":
			var district:=room.get_node("NewDistricts")
			for at in [district.ledges[0][1],district.ledges[1][1],district.ledges[4][2]]: views[id].append(room.to_local(district.to_global(at))+Vector2(0,-35))
			var support:=preload("res://WorldSupport.gd").below(room.to_global(Vector2(4260,-4000)),finish.current_surfaces,6000)
			if support.has_area(): views[id].append(room.to_local(Vector2(room.to_global(Vector2(4260,0)).x,support.position.y-32)))
		if id=="echo_haven_outskirts":
			var district:=room.get_node("GateApproach")
			views[id].append(room.to_local(district.to_global(Vector2(district.start_x+380,district.base_y-32))))
		if id=="sunken_shaft":
			var boss:=room.get_node("AbyssWarden")
			views[id].append(room.to_local(boss.global_position)+Vector2(-95,-10))
		if id=="echo_tide_well":
			for node in nodes:
				if node.name in [&"VaultDoor",&"NestDoor"]: views[id].append(room.to_local(node.global_position)+Vector2(-45,-10))
		for node in nodes:
			if node is StaticBody2D: node.disable_mode=CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if node is CharacterBody2D and node!=player:
				node.process_mode=Node.PROCESS_MODE_ALWAYS;node.set_physics_process(true)
		for tick in 90: await physics_frame
		for node in nodes:
			if is_instance_valid(node) and node is CharacterBody2D and node!=player: node.process_mode=Node.PROCESS_MODE_DISABLED
		for index in views[id].size():
			player.global_position=room.to_global(views[id][index]);player.velocity=Vector2.ZERO;player.process_mode=Node.PROCESS_MODE_ALWAYS
			for tick in 35: await physics_frame
			player.process_mode=Node.PROCESS_MODE_DISABLED;player.get_node("Appearance")._process(0.1)
			camera.offset=Vector2(50,-45);camera.reset_smoothing();camera.force_update_scroll()
			finish.background._process(0);finish._process(0.15);finish.ambience._process(0.15)
			if id=="sunken_shaft":
				var boss:=room.get_node("AbyssWarden");boss.get_node("PaintedAppearance")._process(0.1)
			if id=="echo_tide_well" and index==1:
				_audit_visible_primitives(nodes)
			await _capture("body_city_%s_%d"%[id,index])
			print("BODY CITY VIEW ",id," ",index," ",room.to_local(player.global_position)," grounded=",player.is_on_floor())
	state.delete_save();quit()

func _audit_visible_primitives(nodes: Array[Node]) -> void:
	var view:=Rect2(Vector2.ZERO,Vector2(root.size))
	for node in nodes:
		if not (node is Polygon2D or node is Line2D) or not node.is_visible_in_tree() or node.self_modulate.a<0.05: continue
		var points: PackedVector2Array=node.polygon if node is Polygon2D else node.points
		if points.is_empty(): continue
		var tint: Color=node.color if node is Polygon2D else node.default_color
		if tint.a<0.12 or tint.r>0.7 or tint.b<tint.r*1.15: continue
		var transform: Transform2D=node.get_global_transform_with_canvas()
		var rect:=Rect2(transform*points[0],Vector2.ZERO)
		for point in points: rect=rect.expand(transform*point)
		if rect.intersects(view): print("VISIBLE PRIMITIVE ",node.get_path()," rect=",rect," tint=",tint," textured=",node is Polygon2D and node.texture!=null)
