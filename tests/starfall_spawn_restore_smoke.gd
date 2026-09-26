extends "res://tests/ash_field_operations_smoke.gd"

const CASES := [["starfall_outskirts", "StarfallOutskirts", "LostWatch"], ["starfall_memory_vault", "StarfallMemoryVault", "PitShade"], ["starfall_rooted_hall", "StarfallRootedHall", "FarStalker"]]


func _freeze(room: Node) -> void:
	for enemy in get_nodes_in_group("enemy"):
		if room.is_ancestor_of(enemy):
			enemy.set_physics_process(false)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_star_spawn_restore_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	game.get_node("Player").set_physics_process(false)
	var population := game.get_node("WorldPopulation")
	for entry in CASES:
		state.set_current_room(entry[0])
		var room := game.get_node(entry[1])
		_freeze(room)
		var enemy := room.get_node(entry[2]) as Node2D
		var original := enemy.position
		var expected_anchor := enemy.global_position.x
		if entry[2] != "LostWatch":
			_check(is_equal_approx(float(enemy.get("anchor_x")), expected_anchor), "Relocated enemy patrol anchored to obsolete room position")
		enemy.position.x -= 24
		enemy.set("current_health", int(enemy.get("max_health")) - 1)
		var stored := enemy.position
		var health := int(enemy.get("current_health"))
		state.set_current_room("training_passage")
		state.set_current_room(entry[0])
		_freeze(room)
		_check(enemy.position.is_equal_approx(stored), "Quick room re-entry teleported live authored enemy")
		state.set_current_room("training_passage")
		population.unload_room_population(entry[1])
		await process_frame
		_check(not room.has_node(entry[2]), "Starfall authored actor did not unload")
		state.set_current_room(entry[0])
		_freeze(room)
		enemy = room.get_node(entry[2]) as Node2D
		_check(enemy.position.is_equal_approx(stored) and int(enemy.get("current_health")) == health, "Streaming restoration was overwritten by layout relocation")
		if entry[2] != "LostWatch":
			_check(is_equal_approx(float(enemy.get("anchor_x")), expected_anchor), "Restored patrol lost its supported spawn anchor")
		_check(not enemy.position.is_equal_approx(original), "Runtime movement was discarded on revisit")
	# A rebuilt scene starts a fresh encounter at the new authored floor point.
	game.queue_free()
	await process_frame
	state.start_new_game("normal")
	game = _world()
	await process_frame
	for entry in CASES:
		state.set_current_room(entry[0])
		var room := game.get_node(entry[1])
		_freeze(room)
		var enemy := room.get_node(entry[2])
		var expansion := room.get_node("ExpandedRoute")
		var slot: Array = expansion.AUTHORED_FLOOR_SLOTS[entry[2]]
		var expected: Vector2 = expansion._at(slot[0], slot[1], 0, 85 if entry[2] == "PitShade" else 33, 145)
		_check(enemy.position.is_equal_approx(expected) and enemy.current_health == enemy.max_health, "New run did not start at supported authored spawn")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("STARFALL SPAWN RESTORE TEST PASSED")
		quit(0)
	else:
		print("STARFALL SPAWN RESTORE TEST FAILED: ", failures)
		quit(1)
