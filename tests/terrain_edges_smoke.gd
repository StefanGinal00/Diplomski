extends "res://tests/gameplay_review_smoke.gd"

const Edges := preload("res://TerrainEdgeArt.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_terrain_edges.json"
	state.start_new_game("normal")
	print("TERRAIN EDGE AUDIT loading game")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for i in 5: await process_frame
	print("TERRAIN EDGE AUDIT checking rooms")
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var counts := []
	var families := {}
	var total := 0
	for id in ["training_passage"] + Layout.ROOM_NODES.keys():
		state.set_current_room(id)
		for i in 3: await process_frame
		finish.finish_room(id)
		var room: Node2D = game if id == "training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		var nodes: Array[Node] = finish._members(room)
		var collisions := _collision_snapshot(nodes)
		var count := 0
		for node in nodes:
			if node.get_script() != Edges: continue
			count += 1
			total += 1
			families[node.family] = int(families.get(node.family, 0)) + 1
			_check(not node.is_processing() and not node.is_physics_processing(), "Animated static terrain edge " + str(node.get_path()))
			_check(node.get_child_count() == 0, "Edge created per-tile nodes")
			_check(node.pieces.size() > 2 and node.pieces.size() <= 80, "Missing/unbounded edge draw list")
			var cursor: float = node.surface_rect.position.x
			var scale_factor := -1.0
			var source_ratio: Vector2 = node.sheet.get_size() / Edges.SOURCE_SIZE
			for piece in node.pieces:
				var src: Rect2 = piece.source
				var dest: Rect2 = piece.destination
				_check(absf(dest.position.x-cursor)<0.01, "Gap between edge sections in " + id)
				cursor = dest.end.x
				_check(Rect2(Vector2.ZERO,node.sheet.get_size()).encloses(src), "Source rectangle leaves atlas")
				var factor: Vector2 = dest.size / (src.size / source_ratio)
				_check(absf(factor.x-factor.y)<0.001, "Stretched material in " + id)
				scale_factor = factor.y
			_check(absf(cursor-node.surface_rect.end.x)<0.01, "Terrain width differs from collision")
			var entry: Array = Edges.DATA[node.family][node.variant]
			var contact_y: float = node.visual_bounds.position.y+(float(entry[1])-entry[0].position.y)*scale_factor
			_check(absf(contact_y-node.surface_rect.position.y)<0.01, "Painted top does not match collision")
			_check(node.visual_bounds.end.y-node.surface_rect.end.y<=5.01, "Artwork extends too far under platform")
		counts.append({"room":id,"edges":count})
		print("TERRAIN EDGE ROOM ",id," ",count)
		_check(count>0, "No terrain edge coverage in " + id)
		finish.finish_room(id)
		_check(collisions==_collision_snapshot(finish._members(room)), "Edge art changed collision in " + id)
		_check(finish._members(room).size()==nodes.size(), "Repeated finish adds duplicate edges in " + id)
	for family in Edges.DATA:
		_check(families.has(family), "Unused material " + family)
		var tex: Texture2D = load("res://art/visual_slice/terrain_edge_%s_v1.png" % family)
		var pixels := tex.get_image()
		_check(tex.get_width()<=1024 and pixels.has_mipmaps(), "Import exceeds edge texture budget")
		_check(pixels.get_pixel(0,0).a<0.01, "Opaque atlas backdrop")
	_check(total>500, "Terrain edge coverage incomplete")
	print("TERRAIN_EDGE_COUNTS ", JSON.stringify({"total":total,"families":families,"rooms":counts}))
	game.free()
	state.delete_save()
	print("TERRAIN EDGES TEST PASSED" if failures.is_empty() else "TERRAIN EDGES TEST FAILED " + str(failures))
	quit(0 if failures.is_empty() else 1)
