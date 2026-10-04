extends "res://tests/shaft_hollow_smoke.gd"

const PLACE := preload("res://CrateFloorPlacement.gd")
const ANCHORS := preload("res://CrateSpawnAnchors.gd")
const LAYOUT := preload("res://WorldLayout.gd")


func _rules(crate: Node) -> Array:
	return [crate.name, crate.current_health, crate.rng.state, crate.max_health, crate.min_gold, crate.max_gold, crate.empty_drop_chance, crate.item_drop_chance, crate.common_item_ids.duplicate(), crate.get_signal_connection_list("destroyed").size(), crate.get_node("CollisionShape2D").shape.get_rid()]


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_crate_spawn_anchors_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.get_node("Player").set_physics_process(false)
	await process_frame
	var population := game.get_node("WorldPopulation")
	var tested := 0
	for id in LAYOUT.ROOM_NODES:
		var room_name: String = LAYOUT.ROOM_NODES[id]
		var keys: Array = ANCHORS.ANCHORS.keys().filter(func(key: String) -> bool: return key.begins_with(room_name + "/"))
		if keys.is_empty():
			continue
		state.set_current_room(id)
		var room := game.get_node(room_name) as Node2D
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var rules: Dictionary = {}
		var settled_positions: Dictionary = {}
		for key in keys:
			rules[key] = _rules(game.get_node(key))
		var flags: Dictionary = state.unlocked_shortcuts.duplicate(true)
		PLACE.flush()
		_check(state.unlocked_shortcuts == flags, "Placement changed quest flags")
		for key in keys:
			var crate = game.get_node(key)
			var entry: Array = ANCHORS.ANCHORS[key]
			_check(_rules(crate) == rules[key], "Placement changed loot/health/collider/callbacks: " + key)
			var clearance: Vector2=crate.get_meta("spawn_clearance_offset",Vector2.ZERO)
			_check(absf(clearance.y)<0.01 and absf(clearance.x)<=PLACE.MAX_CLEARANCE,"Unbounded spawn separation: "+key)
			_check(crate.position.distance_to(entry[1]+clearance) < 0.02, "New anchor/clearance missing: " + key)
			if tested == 0:
				var floor_shape := room.get_node(String(entry[2]) + "/CollisionShape2D") as CollisionShape2D
				crate.position = entry[0]
				floor_shape.disabled = true
				_check(not ANCHORS.apply(crate, room), "Disabled support accepted an authored correction")
				floor_shape.disabled = false
				crate.scale = Vector2(2, 2)
				_check(not ANCHORS.apply(crate, room), "Scaled crate accepted unscaled authored correction")
				crate.scale = Vector2.ONE
				crate.get_node("CollisionShape2D").rotation = 0.3
				_check(not ANCHORS.apply(crate, room), "Rotated collider accepted rectangular authored correction")
				crate.get_node("CollisionShape2D").rotation = 0
			# Old streamed coordinates migrate exactly once; unrelated edits survive.
			crate.position = entry[0]
			_check(ANCHORS.apply(crate, room), "Old snapshot anchor did not migrate: " + key)
			_check(not ANCHORS.apply(crate, room), "Anchor correction repeated: " + key)
			crate.position = entry[1] + Vector2(11, 0)
			_check(not ANCHORS.apply(crate, room), "Anchor overwrote unrelated position: " + key)
			crate.position = entry[1]
			crate.current_health = 1
			PLACE.request(crate)
			tested += 1
		PLACE.flush()
		for key in keys:
			var crate: Node2D=game.get_node(key)
			settled_positions[key]=crate.position
			var box:=PLACE.bounds(crate.get_node("CollisionShape2D"))
			for actor_box in PLACE.actor_spawn_rects(room): _check(not box.intersects(actor_box),"Corrected anchor intersects enemy: "+key)
		await process_frame
		state.set_current_room("training_passage")
		population.unload_room_population(room_name)
		await process_frame
		state.set_current_room(id)
		room.process_mode = Node.PROCESS_MODE_DISABLED
		await process_frame
		for key in keys:
			var crate = game.get_node(key)
			_check(crate.position.distance_to(settled_positions[key]) < 0.02 and crate.current_health == 1, "Revisit lost safe position/health: " + key)
			_check(crate.get_node("Visual").damage_fraction > 0, "Revisit lost cracks: " + key)
	_check(tested == 85, "Anchor regression did not cover all 85 exceptions")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("CRATE SPAWN ANCHORS TEST PASSED: 85 explicit sites, unchanged rules, old-state migration, idempotence, unrelated edits and position/health/cracks across unload/reload")
		quit(0)
	else:
		quit(1)
