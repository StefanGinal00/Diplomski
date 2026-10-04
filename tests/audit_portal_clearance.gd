extends "res://tests/visual_style_slice_smoke.gd"
const Layout:=preload("res://WorldLayout.gd")
func _run() -> void:
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_audit_portal_clearance.json"
	state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate()
	root.add_child(game); current_scene=game
	for tick in 3: await process_frame
	game.process_mode=Node.PROCESS_MODE_DISABLED
	var finish:=game.get_node("WorldPresentationFinish")
	for id in ["shaft_hollow","shaft_crossing","shaft_gallery","echo_tide_well","ash_hearth","starfall_citadel"]:
		state.set_current_room(id)
		for tick in 3: await process_frame
		finish.finish_room(id)
		var room: Node2D=game.get_node(str(Layout.ROOM_NODES[id]))
		var nodes: Array[Node]=finish._members(room)
		for node in nodes:
			if not node.has_node("PortalSurround"): continue
			var plan: Dictionary=node.get_node("PortalSurround").get_meta("facade_plan")
			if not plan.compact or plan.height>36: continue
			var support: Rect2=node.get_node("PortalSurround").get_meta("supported_floor")
			print("LOW DOOR ",node.get_path()," ",room.to_local(node.global_position)," floor=",Rect2(room.to_local(support.position),support.size))
			for member in nodes:
				if not member is CollisionShape2D or not member.shape is RectangleShape2D or not member.get_parent() is StaticBody2D: continue
				var rect: Rect2=member.global_transform*Rect2(-member.shape.size/2,member.shape.size)
				if rect.end.x<node.global_position.x-140 or rect.position.x>node.global_position.x+140 or rect.end.y<support.position.y-150 or rect.position.y>support.position.y: continue
				print("  SURFACE ",room.get_path_to(member)," ",Rect2(room.to_local(rect.position),rect.size)," one_way=",member.one_way_collision)
	game.queue_free(); await process_frame; state.delete_save(); quit()
