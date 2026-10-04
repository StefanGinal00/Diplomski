extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_world_sketch_audit.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	for i in 5: await process_frame
	game.get_node("UI").story_player.cancel()
	paused=false
	game.process_mode=Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var report := []
	for id in preload("res://WorldLayout.gd").ROOM_NODES:
		state.set_current_room(id)
		for i in 4: await process_frame
		finish.finish_room(id)
		var room: Node2D = game.get_node(preload("res://WorldLayout.gd").ROOM_NODES[id])
		for node in finish._members(room):
			if not (node is Polygon2D or node is Line2D) or not node.is_visible_in_tree() or node.self_modulate.a*node.modulate.a<0.01: continue
			if node.get_script()!=null: continue
			var points: PackedVector2Array = node.polygon if node is Polygon2D else node.points
			if points.is_empty(): continue
			var rect := Rect2(points[0],Vector2.ZERO)
			for point in points: rect=rect.expand(point)
			if rect.get_area()<1300: continue
			if "TerrainEnvelope" in str(node.get_path()): continue
			var color: Color = node.color if node is Polygon2D else node.default_color
			report.append({"path":str(game.get_path_to(node)),"rect":str(rect),"color":str(color),"owner_script":str(node.get_parent().get_script().resource_path) if node.get_parent().get_script()!=null else ""})
	print("WORLD_SKETCHES ",JSON.stringify(report))
	state.delete_save()
	quit()
