extends "res://tests/visual_style_slice_smoke.gd"

const ROOMS := ["StarfallOutskirts", "StarfallSilentGate", "StarfallMemoryVault", "StarfallRootedHall", "StarfallSoulCrucible", "StarfallSunlessPassage"]


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_starfall_branch_art_save.json"
	state.start_new_game("normal")
	for named in ROOMS:
		var room: Node2D = load("res://%s.tscn" % named).instantiate()
		room.position = Vector2(25000, -9000)
		root.add_child(room)
		await process_frame
		await process_frame
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var route := room.get_node("ExpandedRoute/StarfallDescent")
		var art := route.get_node("BranchArt")
		var paint := room.get_node("PaintedDepth")
		for label in art.retired:
			label.show()
		art.retired.clear()
		art.pockets.clear()
		art.built = false
		var before := _physics_snapshot(room)
		var flags: Dictionary = state.unlocked_shortcuts.duplicate(true)
		var originals := {}
		for node in room.find_children("*", "Node2D", true, false):
			originals[node] = [node.transform, node.z_index, node.visible, node.polygon.duplicate() if node is Polygon2D else null]
		art._build()
		_check(art.theme == named and art.pockets.size() == 5 and art.retired.size() == 5, "Branch identity/coverage mismatch: " + named)
		_check(not art.is_processing() and art.get_child_count() == 0, "Static branch dressing creates update/node overhead")
		for path in ["Branch1_Shadow", "Branch3_Shadow", "Branch5_Shadow", "Niche1_Alcove", "Niche4_Alcove"]:
			var plate: Polygon2D = route.get_node(path)
			_check(plate in paint.plates and plate.texture != null and plate.material == paint.material_shared, "Unpainted or duplicate-material pocket: " + named + "/" + path)
		_check(_physics_snapshot(room) == before and state.unlocked_shortcuts == flags, "Branch art changed gameplay")
		for node in originals:
			var old: Array = originals[node]
			_check(node.transform == old[0] and node.z_index == old[1] and node.visible == old[2], "Branch dressing moved or hid a gameplay node")
			if node is Polygon2D:
				_check(node.polygon == old[3], "Branch dressing changed silhouette")
		for label in art.retired:
			_check(not label.visible and label.get_child_count() == 0, "Invalid technical-label retirement")
		art._build()
		_check(art.pockets.size() == 5 and art.retired.size() == 5, "Duplicate branch details")
		room.hide()
		_check(not art.is_visible_in_tree(), "Branch details escape hidden room")
		room.queue_free()
		await process_frame
	state.delete_save()
	if failures.is_empty():
		print("STARFALL BRANCH ART TEST PASSED: six identities / 30 pockets / 30 technical labels; single painting material, unchanged gameplay")
		quit(0)
	else:
		quit(1)
