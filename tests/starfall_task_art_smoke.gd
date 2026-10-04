extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_starfall_task_art_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.get_node("Player").set_physics_process(false)
	var registers := 0
	var controls := 0
	for room_name in preload("res://StarfallRouteDressing.gd").PROFILES:
		var profile: Array = preload("res://StarfallRouteDressing.gd").PROFILES[room_name]
		state.set_current_room(profile[0])
		await process_frame
		var room := game.get_node(NodePath(room_name)) as Node2D
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var dressing := room.get_node("FieldDressing" if room_name == "StarfallRamparts" else "ExpandedRoute/FieldDressing")
		var register := dressing.get_node("Site1/TaskArt")
		_check(register.states.size() == dressing._events().size(), "Register lost an objective")
		_check(register.states.all(func(value): return value == "pending"), "New-game register claims completion")
		_check(not register.is_processing(), "Register uses per-frame polling")
		var flags: Dictionary = state.unlocked_shortcuts.duplicate(true)
		register._refresh()
		_check(state.unlocked_shortcuts == flags, "Drawing changed task flags")
		var updates: int = register.refresh_count
		register._on_event("unrelated_room_event")
		await process_frame
		_check(register.refresh_count == updates, "Unrelated events redraw the register")
		registers += 1
		var ops := room.get_node_or_null("ExpandedRoute/StarfallDescent/FieldOperations")
		if ops == null:
			continue
		for station in ops.controls:
			var art: Node2D = station.get_node("TaskArt")
			_check(art.retired.size() == 3 and not art.is_processing(), "Control visual replacement missing/static contract broken")
			_check(art.states == ["pending" if station._requirements_met() else "locked"], "Initial lock status incorrect")
			var physics_before := _physics_snapshot(room)
			var flags_before: Dictionary = state.unlocked_shortcuts.duplicate(true)
			var reach: float = station.get_node("CollisionShape2D").shape.radius
			art._build()
			art._refresh()
			_check(art.retired.size() == 3 and _physics_snapshot(room) == physics_before and reach == 34, "Art changed interaction/collision or duplicated")
			_check(state.unlocked_shortcuts == flags_before, "Control art granted progress")
			updates = art.refresh_count
			art._on_event("unrelated_room_event")
			await process_frame
			_check(art.refresh_count == updates, "Unrelated events redraw station art")
			for event_id in station.required_event_ids:
				state.unlock_shortcut(event_id)
			await process_frame
			_check(art.states == ["pending"], "Prerequisite did not unlock station art")
			state.unlock_shortcut(station.shortcut_id)
			await process_frame
			_check(station.is_active and art.states == ["done"], "Completion did not reach station art")
			_check(station.get_node("StatusLabel").text == station.active_label, "Art overrode authoritative text")
			controls += 1
		for event_id in dressing._events():
			state.unlock_shortcut(event_id)
		await process_frame
		for index in range(ops.landmarks.size()):
			var landmark_art: Node2D = ops.get_node("LandmarkArt%d" % index)
			_check(not ops.landmarks[index].visible and landmark_art.retired.size() == 1, "Large placeholder landmark still visible")
			_check(landmark_art.states == ["done"], "Landmark does not reflect completed control")
		_check(register.states.all(func(value): return value == "done"), "Register did not reflect task flags")
		room.hide()
		_check(not register.is_visible_in_tree(), "Hidden room register is visible")
	_check(registers == 7 and controls == 9, "Missing seven registers/nine stations")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("STARFALL TASK ART TEST PASSED: 7 registers, 9 stations, locked/pending/done, read-only flags, preserved prompts/reach/physics")
		quit(0)
	else:
		quit(1)
