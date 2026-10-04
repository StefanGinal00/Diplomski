extends "res://tests/gameplay_review_smoke.gd"
const Art := preload("res://EchoDeviceArt.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path="res://_tmp_world_device_finish.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	for i in 3: await process_frame
	game.get_node("UI").story_player.cancel()
	game.process_mode=Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var seen := {}
	for id in preload("res://WorldLayout.gd").ROOM_NODES:
		state.set_current_room(id)
		for i in 3: await process_frame
		finish.finish_room(id)
		var room: Node2D=game.get_node(preload("res://WorldLayout.gd").ROOM_NODES[id])
		for node in finish._members(room):
			if node.get_script()!=Art or not node.bind_native_state: continue
			seen[node.get_parent().get_script().resource_path]=true
			var device_nodes: Array[Node] = [node.get_parent()]
			device_nodes.append_array(node.get_parent().find_children("*","",true,false))
			var before := _collision_snapshot(device_nodes)
			var state_before: Dictionary=state.unlocked_shortcuts.duplicate(true)
			if node.has_meta("support_floor"):
				var foot: Vector2=node.to_global(Vector2(0,node.painted_rect.end.y))
				var support: Rect2=node.get_meta("support_floor")
				_check(absf(foot.y-support.position.y)<0.05,"Device foot is unregistered: "+str(node.get_path()))
				_check(is_equal_approx(node.scale.x,node.scale.y),"Device stretched")
			for child in node.get_parent().get_children():
				if (child is Polygon2D or child is Line2D) and child.get_child_count()==0: _check(child.self_modulate.a==0,"Old device geometry returned")
			node.animate(1)
			_check(not node.is_processing() and not node.is_physics_processing(),"Device has private frame loop")
			_check(state_before==state.unlocked_shortcuts and before==_collision_snapshot(device_nodes),"Device art changes progress/physics")
	_check(seen.size()>=8,"Missing world terminal families: "+str(seen))
	print("WORLD DEVICE COVERAGE ",seen.size()," controller families")
	game.queue_free()
	await process_frame
	state.delete_save()
	print("WORLD DEVICE FINISH TEST PASSED" if failures.is_empty() else "WORLD DEVICE FINISH TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
