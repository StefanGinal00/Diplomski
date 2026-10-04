extends "res://tests/preview_characters.gd"
const Layout := preload("res://WorldLayout.gd")

func _render() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_regional_ambient_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.get_node("UI").story_player.cancel()
	paused = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player")
	var camera: Camera2D = player.get_node("Camera2D")
	var finish := game.get_node("WorldPresentationFinish")
	for id in ["training_passage", "shaft_hollow", "shaft_drift", "echo_haven", "ash_hearth", "ash_forge", "starfall_citadel", "starfall_ramparts"]:
		player.process_mode = Node.PROCESS_MODE_DISABLED
		state.set_current_room(id)
		await process_frame
		await process_frame
		finish.finish_room(id)
		game.get_node("UI")._dismiss_zone_title()
		var room: Node2D = game if id == "training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		for node in finish._members(room):
			if node is StaticBody2D: node.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
		var dressing := room.get_node("AmbientCompositions")
		var prop: Node2D = dressing.props[mini(2,dressing.props.size()-1)]
		player.global_position = Vector2(clampf(prop.global_position.x+48, prop.support.position.x+15, prop.support.end.x-15), prop.support.position.y-55)
		player.velocity = Vector2.ZERO
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		for tick in range(60): await physics_frame
		print("AMBIENT SETTLED ",id," ",player.is_on_floor(), " props=",dressing.props.size())
		if not player.is_on_floor():
			push_error("Ambient preview failed native floor contact: "+id)
			state.delete_save()
			quit(1)
			return
		player.process_mode = Node.PROCESS_MODE_DISABLED
		camera.reset_smoothing()
		camera.force_update_scroll()
		finish.background._process(0)
		finish._process(0.2)
		finish.ambience._process(0.11)
		if id == "shaft_hollow":
			var frame := Rect2(player.global_position - Vector2(270,150), Vector2(540,300))
			for node in finish._members(room):
				if not node is Line2D or not node.is_visible_in_tree() or node.points.is_empty(): continue
				var bounds := Rect2(node.to_global(node.points[0]), Vector2.ZERO)
				for point in node.points: bounds = bounds.expand(node.to_global(point))
				if frame.intersects(bounds.grow(1)): print("VISIBLE LINE ", node.get_path(), " textured=",node.texture != null)
		await _capture("ambient_"+id)
		if id == "starfall_citadel":
			for node in finish.ambience.active:
				if node.has_meta("ambient_motion"): node.animate(5.1)
			await _capture("ambient_starfall_wind")
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
