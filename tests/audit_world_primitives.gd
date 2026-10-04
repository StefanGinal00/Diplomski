extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_world_primitive_audit.json"
	state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate()
	root.add_child(game)
	for i in 5: await process_frame
	game.get_node("UI").story_player.cancel()
	paused=false
	game.process_mode=Node.PROCESS_MODE_DISABLED
	var finish:=game.get_node("WorldPresentationFinish")
	var layout:=preload("res://WorldLayout.gd")
	var report: Array=[]
	for id in ["training_passage"]+layout.ROOM_NODES.keys():
		state.set_current_room(id)
		for i in 2: await process_frame
		finish.finish_room(id)
		var room: Node2D=game if id=="training_passage" else game.get_node(layout.ROOM_NODES[id])
		for node in finish._members(room):
			if node is Label and node.is_visible_in_tree() and node.modulate.a>0.1 and node.text.length()>75:
				report.append({"room":id,"node":str(room.get_path_to(node)),"kind":"Label","text":node.text})
				continue
			if not (node is Polygon2D or node is Line2D) or node.texture!=null or not node.is_visible_in_tree(): continue
			var color: Color=node.color if node is Polygon2D else node.default_color
			if color.a*node.modulate.a*node.self_modulate.a<0.15: continue
			var points: PackedVector2Array=node.polygon if node is Polygon2D else node.points
			if points.size()<2: continue
			var rect:=Rect2(node.to_global(points[0]),Vector2.ZERO)
			for p in points: rect=rect.expand(node.to_global(p))
			if rect.size.x<60 and rect.size.y<60: continue
			if color.v<0.22: continue
			var nearest: Node=node
			while nearest.get_script()==null and nearest!=room: nearest=nearest.get_parent()
			report.append({"room":id,"node":str(room.get_path_to(node)),"size":str(rect.size),"kind":node.get_class(),"color":str(color),"script":nearest.get_script().resource_path if nearest.get_script()!=null else ""})
	print("PRIMITIVE_AUDIT ",JSON.stringify(report))
	state.delete_save()
	quit()
