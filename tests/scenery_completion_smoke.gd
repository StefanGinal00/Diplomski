extends "res://tests/gameplay_review_smoke.gd"

func _run() -> void:
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_scenery_completion.json"
	state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	for i in 5: await process_frame
	game.get_node("UI").story_player.cancel()
	paused=false
	game.process_mode=Node.PROCESS_MODE_DISABLED
	var finish:=game.get_node("WorldPresentationFinish")
	var painted:=0
	var water:=0
	var roots:=0
	var reports:=0
	var retired_marks:=0
	var pressure_pipes:=0
	var return_markers:=0
	var native_counts: Dictionary={}
	for id in ["training_passage"]+Layout.ROOM_NODES.keys():
		state.set_current_room(id)
		for i in 3: await process_frame
		finish.finish_room(id)
		var room: Node2D=game if id=="training_passage" else game.get_node(Layout.ROOM_NODES[id])
		var before:=0
		for node in finish._members(room):
			if node is CollisionObject2D: before+=1
			if node is Label and finish.reader._is_operation_notice(node):
				reports+=1
				_check(node.has_meta("world_readable") and node.modulate.a==0,"Anonymous task notice escaped reader")
			if node is Sprite2D and node.name=="SceneryPainting":
				painted+=1
				_check(node.texture!=null and not node.is_processing() and node.z_index<0,"Missing/foreground/polling scenery")
				_check((node.global_transform*node.get_rect()).size.y<180,"Oversized modular scenery")
				_check(node.get_parent() is Node2D,"Detached scenery anchor")
			if node is Polygon2D and node.has_meta("scenery_completed") and node.texture!=null and node.material!=null:
				water+=1
				_check(node.material.shader==preload("res://shaders/ambient_water_surface.gdshader"),"Water material lost")
			if node is Line2D and node.has_meta("painted_root_ribbon"):
				roots+=1
				_check(node.texture!=null and node.width<=7 and node.width_curve!=null,"Root silhouette not textured/tapered")
			if node is Line2D and node.has_meta("painted_pressure_pipe"):
				pressure_pipes+=1
				_check(node.texture!=null and node.width<=5.5 and node.material.shader==preload("res://shaders/aged_conduit.gdshader"),"Unfinished pressure pipe")
			if node is Line2D and node.has_meta("compact_return_marker"):
				return_markers+=1
				_check(node.self_modulate.a==0 and node.has_node("PaintedDetailAnchor/SceneryPainting"),"Floating return ring survives")
				var marker: Sprite2D = node.get_node("PaintedDetailAnchor/SceneryPainting")
				_check((marker.global_transform*marker.get_rect()).size.y<=17,"Return marker exceeds compact scale")
			if node is Line2D and String(node.name).begins_with("Mark") and String(node.name).trim_prefix("Mark").is_valid_int():
				retired_marks+=1
				_check(not node.visible or node.self_modulate.a==0,"Old waystone chevron survives above painted clue: "+str(node.get_path())+" texture="+str(node.texture))
		var art_count:=room.find_children("SceneryPainting","Sprite2D",true,false).size()
		finish.finish_room(id)
		var after:=0
		for node in finish._members(room):
			if node is CollisionObject2D: after+=1
		_check(before==after,"Art pass changes collision object count")
		_check(room.find_children("SceneryPainting","Sprite2D",true,false).size()==art_count,"Revisit duplicates painted scenery")
		native_counts[id]=after
		if id=="starfall_soul_crucible":
			var heart:=room.get_node("Heart")
			var art:=heart.get_node("PaintedDetailAnchor/SceneryPainting")
			var previous: Color=art.modulate
			state.unlock_shortcut("starfall_crucible_high")
			state.unlock_shortcut("starfall_crucible_low")
			for tick in 3: await process_frame
			_check(art.modulate!=previous and bool(state.unlocked_shortcuts.get("starfall_crucible_stabilized",false)),"Live crucible paint ignores native state")
	_check(painted>90 and water>15 and roots>20 and reports>60,"Incomplete late-scenery coverage")
	_check(retired_marks>=30,"Waystone arrow coverage incomplete")
	_check(pressure_pipes==9 and return_markers==6,"Missing pressure/return sketch coverage")
	print("SCENERY_COUNTS ",JSON.stringify({"painted":painted,"water":water,"roots":roots,"reports":reports,"retired_marks":retired_marks,"rooms":native_counts.size()}))
	game.queue_free()
	await process_frame
	state.delete_save()
	print("SCENERY COMPLETION TEST PASSED" if failures.is_empty() else "TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
