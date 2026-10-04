extends "res://tests/visual_style_slice_smoke.gd"


func _verify(layout: Node) -> void:
	for label in layout.labels:
		if str(label.get_path()) in layout.unresolved:
			print("BLOCKED ", label.get_path(), " at=", layout._world_rect(label), " band=", layout._band(layout.labels.find(label)))
			for rect in layout._terrain():
				if layout._band(layout.labels.find(label)).intersects(rect): print("TERRAIN ", rect)
	_check(layout.unresolved.is_empty(), "Unresolved regional signs: " + str(layout.unresolved))
	var positions: Array[Vector2] = []
	var texts: Array[String] = []
	for label in layout.labels:
		positions.append(label.global_position)
		texts.append(label.text)
	layout._layout()
	_check(layout.unresolved.is_empty(), "Live operations overlap regional signs: " + str(layout.unresolved))
	for index in range(layout.labels.size()):
		var label: Label = layout.labels[index]
		_check(label.global_position == positions[index], "Regional sign drifts")
		_check(label.text == texts[index], "Layout rewrote clue")
		_check(layout._band(index).encloses(layout._world_rect(label)), "Regional clue outside its chamber: " + str(label.get_path()))
		_check(label.z_index == 5 and not label.z_as_relative, "Regional clue hidden behind terrain")
	_check(not layout.is_processing(), "Regional signs poll each frame")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_regional_sign_layout_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.get_node("Player").set_physics_process(false)
	await process_frame
	await process_frame
	var layouts := game.find_children("RegionalSignLayout", "Node2D", true, false)
	var count := 0
	for layout in layouts:
		var before := _physics_snapshot(layout.get_parent().room)
		_verify(layout)
		_check(_physics_snapshot(layout.get_parent().room) == before, "Sign layout changed collision")
		count += layout.labels.size()
		print("REGIONAL SIGNS ", layout.get_parent().region, " ", layout.labels.size(), " unresolved=", layout.unresolved.size())
	_check(layouts.size() == 18 and count == 126, "Expected 126 signs in 18 Shaft/Ash/Starfall routes")
	# Exercise live state-driven caption sizes, without claiming rewards.
	for route in preload("res://ExplorationLedger.gd").ROUTES:
		if route[2] == "echo_grotto": continue
		state.set_current_room(route[0])
		await process_frame
		await process_frame
		state.unlock_shortcut(str(route[1]) + "_field_complete")
		state.unlock_shortcut(str(route[1]) + "_hidden_depth_cleared")
		state.unlock_shortcut(str(route[1]) + "_guarded_niche_cleared")
		state.unlock_shortcut(str(route[1]) + "_niche_cleared")
		state.unlock_shortcut(preload("res://ExplorationLedger.gd").completion_id(route))
		state.open_cache(preload("res://ExplorationLedger.gd").cache_id(route))
	await process_frame
	await process_frame
	for layout in layouts: _verify(layout)
	var counts: Array[int] = []
	for layout in layouts: counts.append(layout.layout_count)
	for frame in range(5): await process_frame
	for index in range(layouts.size()):
		_check(layouts[index].layout_count == counts[index], "Regional layout keeps reflowing")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty(): print("REGIONAL SIGN LAYOUT TEST PASSED")
	quit(0 if failures.is_empty() else 1)
