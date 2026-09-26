extends "res://tests/route_field_dressing_smoke.gd"

const NEW_ROOMS := [["echo_gallery", "EchoGallery", "gallery", 5, 2], ["echo_archive", "PrismArchive", "archive", 5, 1]]


func _enter(game: Node, entry: Array) -> Node2D:
	root.get_node("GameState").set_current_room(entry[0])
	_freeze(game.get_node(entry[1]))
	var detail := game.get_node(entry[1] + "/LongTraversal/FieldDressing")
	detail.get_node("FieldGuide").set_process(false)
	return detail


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_room_dressing_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player: Player = game.get_node("Player")
	player.set_physics_process(false)
	for entry in NEW_ROOMS:
		var detail := game.get_node(entry[1] + "/LongTraversal/FieldDressing")
		_check(not detail.population_loaded and not detail.has_node("FieldGuide"), "Unvisited room dressing spawned actors")
		detail = _enter(game, entry)
		await physics_frame
		_check(detail.PREVIEW_ANCHORS[entry[2]].size() == 9, "Missing editor landmark anchors")
		for index in range(9):
			var site := detail.get_node("Site%d" % index)
			_check(site.get_child_count() >= 3, "Empty field landmark")
			_check(site.find_children("*", "CollisionObject2D", true, false).is_empty(), "Decor obstructs traversal")
			_check(site.position.distance_to(detail.PREVIEW_ANCHORS[entry[2]][index]) < 0.02, "Editor/live dressing drift")
		var crates: Array[Node] = []
		var fauna: Array[Node] = []
		for actor in detail.get_children():
			if actor.is_in_group("breakable"):
				crates.append(actor)
				_floor(actor)
				_check(actor.max_gold == 4 and actor.empty_drop_chance == 0.55, "Supply economy changed")
			if actor.is_in_group("neutral_creature"):
				fauna.append(actor)
				_floor(actor)
				_check(not actor.is_hostile, "Peaceful fauna started hostile")
		_check(crates.size() == entry[3] and fauna.size() == entry[4], "Wrong room dressing population")
		var guide := detail.get_node("FieldGuide")
		_floor(guide)
		for marker in guide.route_markers:
			_floor(marker)
		_check(guide.interaction_requested.is_connected(Callable(game.get_node("UI"), "_on_npc_interaction_requested")), "Guide has no dialogue UI")
		var nearest := INF
		for enemy in get_nodes_in_group("enemy"):
			if game.get_node(entry[1]).is_ancestor_of(enemy):
				nearest = minf(nearest, guide.global_position.distance_to(enemy.global_position))
		_check(nearest > 170, "Guide overlaps a hostile patrol")
		var guide_id := guide.get_instance_id()
		var damaged_path := detail.get_path_to(crates[0])
		var broken_path := detail.get_path_to(crates[1])
		var fauna_path := detail.get_path_to(fauna[0])
		crates[0].current_health = 1
		crates[1].empty_drop_chance = 1
		crates[1].take_damage(10)
		fauna[0].take_damage(1)
		var moved: Vector2 = fauna[0].position + Vector2(8, 0)
		fauna[0].position = moved
		await process_frame
		state.set_current_room("training_passage")
		_check(not guide.can_process(), "Off-room guide remains active")
		game.get_node("WorldPopulation").unload_room_population(entry[1])
		await process_frame
		_check(not detail.has_node(damaged_path) and not detail.has_node(fauna_path), "Room props did not unload")
		detail = _enter(game, entry)
		await process_frame
		_check(detail.get_node(damaged_path).current_health == 1 and not detail.has_node(broken_path), "Supply streaming reset state")
		_check(detail.get_node(fauna_path).is_hostile and detail.get_node(fauna_path).position.is_equal_approx(moved), "Fauna streaming reset state")
		_check(detail.get_node("FieldGuide").get_instance_id() == guide_id, "Revisit duplicated guide")
		_check(not detail.has_node("SalvageCache"), "Dressing duplicated the original discovery reward")
		_check(not detail.get_parent().get_node("RouteDiscoveryCache").open(player), "Dressing bypassed records")
	# Partial Gallery progress is independently saved; unfinished Archive order
	# does not persist. The dressing reads those same flags, never grants them.
	var gallery := _enter(game, NEW_ROOMS[0])
	gallery.get_parent().get_node("FieldDiscoveries")._on_heard(1)
	_check(gallery.get_node("Site1/RecordLight").modulate.a < 0.5 and gallery.get_node("Site5/RecordLight").modulate.a == 1, "Gallery lenses did not track separate witnesses")
	_check("1/2" in gallery.get_node("FieldGuide").dialogue_lines[0], "Guide lost partial witness advice")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), Vector2(120, 0), "dressing_test", "Dressing Test", "training_passage"), "Partial records save failed")
	for entry in NEW_ROOMS:
		var detail := _enter(game, entry)
		var records := detail.get_parent().get_node("FieldDiscoveries")
		if entry[2] == "archive":
			records._on_heard(0)
			_check(records.sequence.is_empty() and detail.get_node("Site1/RecordLight").modulate.a < 0.5, "Dawn incorrectly starts archive sequence")
		for index in ([0] if entry[2] == "gallery" else [1, 0, 2]):
			records._on_heard(index)
		_check(records.completed and "unsealed" in detail.get_node("FieldGuide").dialogue_lines[0], "Completed objective did not update guide")
		_check(detail.get_parent().get_node("RouteDiscoveryCache").open(player), "Existing discovery reward lost")
	_check(state.load_game(), "Partial records reload failed")
	game.queue_free()
	await process_frame
	game = _world()
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	gallery = _enter(game, NEW_ROOMS[0])
	_check(gallery.get_node("Site1/RecordLight").modulate.a < 0.5 and gallery.get_node("Site5/RecordLight").modulate.a == 1, "Saved partial Gallery lights did not restore")
	var archive := _enter(game, NEW_ROOMS[1])
	_check(archive.get_node("Site3/RecordLight").modulate.a < 0.5 and "Zenith" in archive.get_node("FieldGuide").dialogue_lines[0], "Unsaved archive completion survived rollback")
	state.set_zone_tier("echo_grotto", 1)
	for entry in NEW_ROOMS:
		var detail := _enter(game, entry)
		var records := detail.get_parent().get_node("FieldDiscoveries")
		var trial := records.get_node("ReturnEncounter")
		trial._on_body_entered(player)
		_check(not trial.triggered, "Awakening skipped incomplete records")
		for index in ([0] if entry[2] == "gallery" else [1, 0, 2]):
			records._on_heard(index)
		_check("return trial" in detail.get_node("FieldGuide").dialogue_lines[0], "Guide missed awakened objective")
		trial._on_body_entered(player)
		await process_frame
		_check(trial.spawned_enemies.size() == 2, "Existing return trial changed")
		for enemy in trial.spawned_enemies:
			enemy.die()
		_check("quiet" in detail.get_node("FieldGuide").dialogue_lines[0], "Guide missed return victory")
		var cache := records.get_node("ReturnReward")
		_check(cache.open(player) and not cache.open(player), "Return reserve must pay once")
		var first_cache := detail.get_parent().get_node("RouteDiscoveryCache")
		_check(first_cache.open(player) and not first_cache.open(player), "Discovery reserve must pay once after rollback")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), Vector2(120, 0), "dressing_test", "Dressing Test", "training_passage"), "Completed records save failed")
	_check(state.load_game(), "Completed records reload failed")
	game.queue_free()
	await process_frame
	game = _world()
	await process_frame
	for entry in NEW_ROOMS:
		var detail := _enter(game, entry)
		_check(detail.get_node("Site1/RecordLight").modulate.a == 1 and "quiet" in detail.get_node("FieldGuide").dialogue_lines[0], "Saved completed field cues reset")
		_check(detail.get_parent().get_node("RouteDiscoveryCache").opened and detail.get_parent().get_node("FieldDiscoveries/ReturnReward").opened, "Saved reward refilled")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("ECHO ROOM DRESSING TEST PASSED: 18 sites, 10 supplies, 3 fauna, 2 guides; record cues, streaming and save rollback")
		quit(0)
	else:
		print("ECHO ROOM DRESSING TEST FAILED: ", failures)
		quit(1)
