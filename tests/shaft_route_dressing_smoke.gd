extends "res://tests/route_field_dressing_smoke.gd"

const SHAFT_ROOMS := [["shaft_hollow", "ShaftHollow", "hollow", 5], ["shaft_crossing", "DrownedCrossing", "crossing", 3]]


func _assert_cues(game: Node, active: bool) -> void:
	for entry in SHAFT_ROOMS:
		var detail := game.get_node(entry[1] + "/ExpandedRoute/FieldDressing")
		_check(detail.get_node("Site4/GuardianSeal0").visible == not active, "Cache sign disagrees with guardian progress")
		if entry[2] == "hollow":
			_check(("RELAY ACTIVE" in detail.get_node("Site0/RouteClue").text) == active, "Relay sign disagrees with saved progress")
		else:
			_check(is_equal_approx(detail.get_node("Site2/Water").scale.y, 0.22 if active else 1.0), "Water gauge disagrees with saved valve")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_shaft_route_dressing_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player: Player = game.get_node("Player")
	player.set_physics_process(false)
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "shaft_dressing", "Shaft Dressing", "training_passage"), "Initial snapshot failed")
	_assert_cues(game, false)
	for entry in SHAFT_ROOMS:
		var room := game.get_node(entry[1])
		var detail := room.get_node("ExpandedRoute/FieldDressing")
		_check(not detail.population_loaded, "Unvisited field population loaded early")
		_check(not room.has_node("ExpandedRoute/AuthoredDescent/ExplorationSites"), "Unvisited guide loaded early")
		for index in range(7):
			var site := detail.get_node("Site%d" % index)
			_check(site.position.distance_to(detail.ROUTE_ANCHORS[entry[2]][index]) < 0.02, "Editor anchor differs from supported runtime floor")
			_check(site.get_child_count() >= 3, "Missing field scenery")
			_check(site.find_children("*", "CollisionObject2D", true, false).is_empty(), "Scenery added collision")
		state.set_current_room(entry[0])
		_freeze(room)
		await physics_frame
		var route := room.get_node("ExpandedRoute/AuthoredDescent")
		var guide := route.get_node("ExplorationSites/FieldResident")
		guide.set_process(false)
		var guide_id := guide.get_instance_id()
		_check(guide.dialogue_lines.size() == (4 if entry[2] == "hollow" else 3), "Existing guide lost its first-clear clues")
		if entry[2] == "hollow":
			_check(guide.dialogue_lines[3].contains("Ore survey 0/3"), "Hollow guide lost its additional survey clue")
		_check(guide.interaction_requested.is_connected(Callable(game.get_node("UI"), "_on_npc_interaction_requested")), "Guide UI disconnected")
		_check(not detail.has_node("FieldGuide") and not detail.has_node("SalvageCache"), "Dressing duplicated existing guide/reward")
		var crates: Array[Node] = []
		var fauna: Array[Node] = []
		for actor in detail.get_children():
			if actor.is_in_group("breakable"):
				crates.append(actor)
				_floor(actor)
				_check(actor.max_gold <= 4 and actor.empty_drop_chance >= 0.5, "Supply rewards too generous")
			elif actor.is_in_group("neutral_creature"):
				fauna.append(actor)
				_floor(actor)
				_check(not actor.is_hostile and actor.zone_id == "sunken_shaft", "Grazer has wrong disposition or zone")
		_check(crates.size() == entry[3] and fauna.size() == 2, "Wrong local population count")
		var damaged := detail.get_path_to(crates[0])
		var broken := detail.get_path_to(crates[1])
		var grazer := detail.get_path_to(fauna[0])
		crates[0].current_health = 1
		crates[1].empty_drop_chance = 1.0
		crates[1].take_damage(10)
		fauna[0].take_damage(1)
		var moved: Vector2 = fauna[0].position + Vector2(8, 0)
		fauna[0].position = moved
		await process_frame
		state.set_current_room("training_passage")
		game.get_node("WorldPopulation").unload_room_population(entry[1])
		await process_frame
		_check(not detail.has_node(damaged) and not detail.has_node(grazer), "Supplies/fauna did not unload")
		state.set_current_room(entry[0])
		_freeze(room)
		await process_frame
		_check(detail.get_node(damaged).current_health == 1 and not detail.has_node(broken), "Reload reset supply state")
		_check(detail.get_node(grazer).is_hostile and detail.get_node(grazer).position.is_equal_approx(moved), "Reload reset grazer state")
		_check(route.get_node("ExplorationSites/FieldResident").get_instance_id() == guide_id, "Guide duplicated on return")
		var trial := route.get_node("HiddenDepthAmbush")
		var cache := route.get_node("HiddenDepthCache")
		_check(not cache.open(player), "Cache ignored its guardians")
		trial._on_body_entered(player)
		await process_frame
		_check(trial.spawned_enemies.size() == 2, "Hidden niche lacks guardians")
		trial.spawned_enemies[0].die()
		_check(detail.get_node("Site4/GuardianSeal0").visible and not cache.open(player), "One guardian incorrectly cleared the niche")
		trial.spawned_enemies[1].die()
		_check(not detail.get_node("Site4/GuardianSeal0").visible, "Sign ignored completed niche")
		_check(cache.open(player) and not cache.open(player), "Niche reward not one-time")
		_check("separate cache" in guide.dialogue_lines[1], "Guide ignored separate niche reward")
		var main_flag := "shaft_hollow_relay" if entry[2] == "hollow" else "shaft_sluice_valve"
		_check(not state.unlocked_shortcuts.get(main_flag, false), "Optional guardians bypassed main objective")
		if entry[2] == "hollow":
			_check(not room.get_node("Relay").activate(player), "Relay ignored original wisps")
			for guardian in ["HollowWispNear", "HollowWispFar"]:
				room.get_node(guardian).die()
			_check(room.get_node("Relay").activate(player) and room.get_node("LowerReturnDoor")._requirements_met(), "Relay did not open its original route")
			_check("relay is active" in guide.dialogue_lines[0], "Guide ignored relay")
		else:
			_check(room.get_node("Valve").activate(player), "Sluice failed")
			for index in range(7):
				_check(route.get_node("CrossingCurrent%02d" % index).disabled, "Sluice left an expanded current enabled")
			_check("currents are calmed" in guide.dialogue_lines[0], "Guide ignored sluice")
	_assert_cues(game, true)
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Initial snapshot did not reload")
	game = _world()
	await process_frame
	_assert_cues(game, false)
	# Save a mixed state: relay completed, sluice and both caches still pending.
	player = game.get_node("Player")
	player.set_physics_process(false)
	state.set_current_room("shaft_hollow")
	_freeze(game.get_node("ShaftHollow"))
	for guardian in ["HollowWispNear", "HollowWispFar"]:
		game.get_node("ShaftHollow/" + guardian).die()
	_check(game.get_node("ShaftHollow/Relay").activate(player), "Relay could not be re-earned after rollback")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "shaft_dressing", "Shaft Dressing", "shaft_hollow"), "Mixed snapshot failed")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Mixed snapshot did not reload")
	game = _world()
	await process_frame
	_check("RELAY ACTIVE" in game.get_node("ShaftHollow/ExpandedRoute/FieldDressing/Site0/RouteClue").text, "Saved relay cue reset")
	_check(game.get_node("ShaftHollow/ExpandedRoute/FieldDressing/Site4/GuardianSeal0").visible, "Relay save falsely cleared separate cache")
	_check(is_equal_approx(game.get_node("DrownedCrossing/ExpandedRoute/FieldDressing/Site2/Water").scale.y, 1.0), "Relay save falsely drained other room")
	state.delete_save()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("SHAFT ROUTE DRESSING TEST PASSED")
		quit(0)
	else:
		print("SHAFT ROUTE DRESSING TEST FAILED: ", failures)
		quit(1)
