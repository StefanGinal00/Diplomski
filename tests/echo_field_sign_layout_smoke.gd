extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_field_sign_layout_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.get_node("Player").set_physics_process(false)
	await process_frame
	await process_frame
	var routes := 0
	var count := 0
	for layout in game.find_children("FieldSignLayout", "Node2D", true, false):
		routes += 1
		var dressing := layout.get_parent()
		var physics := _physics_snapshot(dressing.room)
		var flags: Dictionary = state.unlocked_shortcuts.duplicate(true)
		var texts: Array[String] = []
		var positions: Array[Vector2] = []
		for label in layout.labels:
			texts.append(label.text)
			positions.append(label.global_position)
		layout._layout()
		_check(not layout.is_processing(), "Field signs poll every frame")
		_check(layout.unresolved.is_empty(), "Unresolved signs: " + str(layout.unresolved))
		for index in range(layout.labels.size()):
			var label: Label = layout.labels[index]
			_check(label.text == texts[index], "Layout rewrote a discovery clue")
			_check(label.global_position == positions[index], "Sign layout drifts on repeat")
			_check(label.z_index == 5 and not label.z_as_relative, "Clue can be occluded by terrain")
			_check(layout._band(index).encloses(layout._world_rect(label)), "Clue leaves its chamber headroom")
			count += 1
		_check(_physics_snapshot(dressing.room) == physics and state.unlocked_shortcuts == flags, "Sign layout changed gameplay")
		print("SIGN LAYOUT ", dressing.region, " ", layout.labels.size(), " unresolved=", layout.unresolved.size())
		for label in layout.labels:
			if str(label.get_path()) in layout.unresolved:
				print("SIGN UNRESOLVED ", label.get_path(), " rect=", layout._world_rect(label))
	_check(routes == 8 and count == 75, "Unexpected Echo sign coverage")
	_check(game.get_node("BrokenCauseway").find_children("FieldSignLayout", "Node2D", true, false).is_empty(), "Echo layout leaked into Ash")
	# Live text updates retain controller authority and trigger size-based reflow.
	state.unlock_shortcut("echo_gallery_witness_0")
	state.unlock_shortcut("echo_archive_field_complete")
	await process_frame
	await process_frame
	var archive: Label = game.get_node("PrismArchive/LongTraversal/FieldDressing/Site1/RouteClue")
	_check("RECORD RESTORED" in archive.text, "Record status no longer updates")
	var stable_counts: Array[int] = []
	var layouts := game.find_children("FieldSignLayout", "Node2D", true, false)
	for layout in layouts:
		_check(layout.unresolved.is_empty(), "Status update introduced a layout conflict")
		stable_counts.append(layout.layout_count)
	for frame in range(5):
		await process_frame
	for index in range(layouts.size()):
		_check(layouts[index].layout_count == stable_counts[index], "Stable labels continuously reflow")
	print("ECHO SIGN COVERAGE ", count)
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("ECHO FIELD SIGN LAYOUT TEST PASSED")
		quit(0)
	else:
		quit(1)
