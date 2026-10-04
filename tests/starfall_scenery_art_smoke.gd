extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_starfall_scenery_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.get_node("Player").set_physics_process(false)
	var compact_signs := 0
	var full_signs := 0
	for named in preload("res://StarfallRoomExpansion.gd").STAR_IDENTITIES:
		var room := game.get_node(NodePath(named)) as Node2D
		var route := room.get_node("ExpandedRoute")
		state.set_current_room(route.plan.id)
		await process_frame
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var generated := route.get_node("StarfallDescent")
		var art := generated.get_node("SceneryArt")
		for node in art.retired:
			node.show()
		for collection in [art.retired, art.surfaces, art.quiet_lines, art.roots, art.masks, art.quiet_strokes]:
			collection.clear()
		# Painted tapered root ribbons replace the old three-color draw strokes.
		# This test deliberately forces a rebuild; clear only generated art first.
		for child in art.get_children():
			_check(child is Line2D and child.has_meta("painted_root_ribbon"),"Unexpected scenery child")
			child.free()
		art.built = false
		var before := _physics_snapshot(room)
		var flags: Dictionary = state.unlocked_shortcuts.duplicate(true)
		var originals := {}
		for node in generated.find_children("*", "Node2D", true, false):
			originals[node] = [node.transform, node.z_index, node.visible, node.polygon.duplicate() if node is Polygon2D else (node.points.duplicate() if node is Line2D else null)]
		art._build()
		_check(art.built and not art.is_processing() and art.get_child_count() == art.roots.size(), "Scenery processing/root count changed")
		for child in art.get_children():
			_check(child is Line2D and child.texture!=null and not child.is_processing(),"Root ribbon lacks paint or adds processing")
			_check(child.width<=4 and child.default_color.a<.5,"Root reads as an opaque false platform")
		_check(_physics_snapshot(room) == before and state.unlocked_shortcuts == flags, "Scenery changes gameplay")
		for node in originals:
			var old: Array = originals[node]
			_check(node.transform == old[0] and node.z_index == old[1], "Scenery changes original placement/depth")
			_check(node.visible == (false if node in art.retired else old[2]), "Scenery hides unrelated content")
			if node is Polygon2D:
				_check(node.polygon == old[3], "Scenery rewrites original silhouette")
			elif node is Line2D:
				_check(node.points == old[3], "Scenery moves source lines")
		for node in art.retired:
			_check(node.get_child_count() == 0 and (node is Polygon2D or node is Line2D), "Scenery hides gameplay subtree")
		for plate in art.surfaces:
			_check(plate.texture != null and plate.uv.size() == plate.polygon.size(), "Missing scenery texture/UVs")
		for stroke in art.roots:
			for point in stroke:
				_check(art._inside(point), "Root drawing escapes authored room masks")
		for stroke in art.quiet_strokes:
			for point in stroke.points:
				_check(art._inside(point), "Decorative line escapes authored room masks")
		if named == "StarfallRootedHall":
			_check(art.roots.size() > 70 and art.retired.size() > 40, "Flat root masses were not replaced")
		elif named != "StarfallOutskirts":
			_check(art.surfaces.size() >= 20, "Deep-route silhouettes remain flat")
		var counts := [art.retired.size(), art.roots.size(), art.surfaces.size()]
		art._build()
		_check(counts == [art.retired.size(), art.roots.size(), art.surfaces.size()], "Scenery rebuild duplicates detail")
		var ops := generated.get_node("FieldOperations")
		for sign in ops.signs:
			_check(sign.get_minimum_size().y <= sign.size.y, "Field instruction overflow")
			if sign.get_meta("compact_field_sign", false):
				compact_signs += 1
				_check("PROGRESS" in sign.text and "SAVE AT A LAMP" in sign.text, "Compact sign lost progress/save guidance")
				_check("AFTER THE SOVEREIGN" not in sign.text, "Local board repeats distant return instructions")
			else:
				full_signs += 1
				_check("OPTIONAL DISCOVERY" in sign.text and "AFTER THE SOVEREIGN" in sign.text, "Full instructions lost optional/return context")
		_check(not ops.signs[-1].get_global_rect().intersects(generated.get_node("HiddenStarAmbush").status_label.get_global_rect()), "Reserve text overlaps guardian status")
		print("SCENERY COVERAGE ", named, ": retired/roots/materials=", counts, " quiet lines=", art.quiet_lines.size())
		room.hide()
		_check(not art.is_visible_in_tree(), "Off-room scenery is visible")
	_check(compact_signs == 14 and full_signs == 12, "Local/global sign coverage changed")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("STARFALL SCENERY ART TEST PASSED: six routes, static cosmetic leaves, preserved geometry/physics/state, 14 compact and 12 full instruction signs")
		quit(0)
	else:
		quit(1)
