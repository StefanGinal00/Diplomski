extends SceneTree

const WORLD_LAYOUT = preload("res://WorldLayout.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_world_population_suite_save.json"
	var state := root.get_node("GameState")
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var population = game.get_node("WorldPopulation")
	_check(population.ROOMS.size() >= 17, "Too few existing danger rooms received a population pass")
	_check(not game.get_node("StarfallRootedHall").has_node("WildPatrol0") and not population.is_room_populated("StarfallRootedHall"), "An unvisited room eagerly instantiated its dynamic population")
	var added_enemies := 0
	var added_fauna := 0
	var added_crates := 0
	for room_name in population.ROOMS:
		var room_id := ""
		for candidate_id in WORLD_LAYOUT.ROOM_NODES:
			if WORLD_LAYOUT.ROOM_NODES[candidate_id] == room_name:
				room_id = candidate_id
				break
		_check(not room_id.is_empty(), "%s has no world-layout room id" % room_name)
		state.set_current_room(room_id)
		await process_frame
		var room: Node2D = game.get_node(room_name)
		var data: Dictionary = population.ROOMS[room_name]
		_check(population.is_room_populated(room_name), "%s did not stream its population on first entry" % room_name)
		_check(room.has_node("WildGrowth0_0"), "%s has no new flora" % room_name)
		for index in range(data["foes"].size()):
			var enemy: Node2D = room.get_node("WildPatrol%d" % index)
			_check(enemy.is_in_group("enemy") and enemy.get("zone_id") == data["zone"], "%s has a misplaced hostile creature" % room_name)
			added_enemies += 1
		for index in range(data["fauna"].size()):
			var creature: Node2D = room.get_node("WildFauna%d" % index)
			_check(creature.is_in_group("neutral_creature") and not creature.is_in_group("enemy") and not creature.is_hostile, "%s has hostile fauna" % room_name)
			added_fauna += 1
		for index in range(data["crates"].size()):
			var crate: Node2D = room.get_node("WildCrate%d" % index)
			_check(crate.is_in_group("breakable") and crate.empty_drop_chance > 0.0, "%s has no sometimes-empty breakable" % room_name)
			added_crates += 1
		var child_count := room.get_child_count()
		state.set_current_room("training_passage")
		state.set_current_room(room_id)
		await process_frame
		_check(room.get_child_count() == child_count, "%s duplicated its population on revisit" % room_name)
	_check(added_enemies >= 20 and added_fauna >= 6 and added_crates >= 17, "Population pass is too sparse")
	for safe_name in ["EchoHaven", "CinderHearth", "StarfallCitadel"]:
		var town: Node2D = game.get_node(safe_name)
		for child in town.get_children():
			_check(not child.is_in_group("enemy"), "%s contains a hostile spawn" % safe_name)
	_check(not game.get_node("CastellanThrone/ThroneLamp")._has_nearby_threat(), "A hostile in another room blocked the pre-boss lamp")
	# The tour can outlast the unload grace period. Explicitly revisit Echo
	# before accessing its actors; off-room population is not guaranteed alive.
	state.set_current_room("echo_grotto")
	await process_frame
	var crate = game.get_node("EchoGrotto/WildCrate0")
	crate.empty_drop_chance = 1.0
	var pickup_count := get_nodes_in_group("gold_pickup").size() + get_nodes_in_group("item_pickup").size()
	crate.take_damage(99)
	await process_frame
	_check(not is_instance_valid(crate) or crate.is_queued_for_deletion(), "A damaged crate did not break")
	_check(get_nodes_in_group("gold_pickup").size() + get_nodes_in_group("item_pickup").size() == pickup_count, "An empty crate still spawned loot")
	var echo_patrol = game.get_node("EchoGrotto/WildPatrol0")
	echo_patrol.take_damage(1)
	var remaining_health := int(echo_patrol.current_health)
	var authored_wisp = game.get_node("EchoGrotto/EchoWisp")
	authored_wisp.take_damage(1)
	var authored_health := int(authored_wisp.current_health)
	game.get_node("EchoGrotto/FarWisp").die()
	var authored_crate = game.get_node("EchoGrotto/ForgottenCrate")
	authored_crate.empty_drop_chance = 1.0
	authored_crate.take_damage(99)
	var generated_crate = game.get_node("EchoGrotto/LongTraversal/TraversalCrate00")
	generated_crate.empty_drop_chance = 1.0
	generated_crate.take_damage(99)
	await process_frame
	state.set_current_room("training_passage")
	population.unload_room_population("EchoGrotto")
	await process_frame
	_check(not population.is_room_populated("EchoGrotto") and not game.get_node("EchoGrotto").has_node("WildPatrol0") and not game.get_node("EchoGrotto").has_node("EchoWisp"), "Leaving a streamed room did not unload its curated and authored population")
	state.set_current_room("echo_grotto")
	await process_frame
	_check(population.is_room_populated("EchoGrotto") and game.get_node("EchoGrotto/WildPatrol0").current_health == remaining_health, "A surviving enemy lost its state after a streamed-room reload")
	_check(not game.get_node("EchoGrotto").has_node("WildCrate0"), "A destroyed crate respawned after a streamed-room reload")
	_check(game.get_node("EchoGrotto/EchoWisp").current_health == authored_health, "An authored enemy lost its health after a streamed-room reload")
	_check(not game.get_node("EchoGrotto").has_node("FarWisp") and not game.get_node("EchoGrotto").has_node("ForgottenCrate"), "A defeated authored enemy or destroyed authored crate respawned")
	_check(not game.get_node("EchoGrotto/LongTraversal").has_node("TraversalCrate00"), "A destroyed generated traversal crate respawned")
	state.set_current_room("ash_hearth_outskirts")
	await process_frame
	var grazer = game.get_node("CinderHearthOutskirts/AshGrazer")
	grazer.take_damage(1)
	var grazer_health := int(grazer.current_health)
	_check(grazer.is_hostile, "Authored neutral creature did not become hostile when attacked")
	state.set_current_room("training_passage")
	population.unload_room_population("CinderHearthOutskirts")
	await process_frame
	_check(not game.get_node("CinderHearthOutskirts").has_node("AshGrazer"), "Authored neutral creature did not unload")
	state.set_current_room("ash_hearth_outskirts")
	await process_frame
	grazer = game.get_node("CinderHearthOutskirts/AshGrazer")
	_check(grazer.is_hostile and grazer.current_health == grazer_health, "Authored neutral creature did not restore hostility and health")
	for generated_case in [
		["shaft_hollow", "ShaftHollow", "ShaftHollow/ExpandedRoute/AuthoredDescent", "DepthFoe0"],
		["echo_grotto", "EchoGrotto", "EchoGrotto/LongTraversal", "ChoirWisp_00_00"],
		["ash_causeway", "BrokenCauseway", "BrokenCauseway/AshSwitchback", "AshRouteFoe0_0"],
		["starfall_outskirts", "StarfallOutskirts", "StarfallOutskirts/ExpandedRoute/StarfallDescent", "DepthFoe0_0"],
	]:
		var generated_room_id: String = generated_case[0]
		var generated_room_name: String = generated_case[1]
		var generated_parent: Node = game.get_node(generated_case[2])
		var generated_name: String = generated_case[3]
		state.set_current_room(generated_room_id)
		await process_frame
		var generated_enemy = generated_parent.get_node(generated_name)
		generated_enemy.take_damage(1)
		var generated_health := int(generated_enemy.current_health)
		state.set_current_room("training_passage")
		population.unload_room_population(generated_room_name)
		await process_frame
		_check(not generated_parent.has_node(generated_name), "%s generated enemy did not unload" % generated_room_name)
		state.set_current_room(generated_room_id)
		await process_frame
		_check(generated_parent.has_node(generated_name) and int(generated_parent.get_node(generated_name).current_health) == generated_health, "%s generated enemy did not restore its health" % generated_room_name)
	state.set_zone_tier("sunken_shaft", 1)
	_check(not game.get_node("DrownedCrossing").has_node("crossing_echo_wisp"), "An unvisited awakened room eagerly spawned its replay patrol")
	state.set_current_room("shaft_crossing")
	var replay_room := game.get_node("DrownedCrossing") as Node2D
	var replay_actor := replay_room.get_node("crossing_echo_wisp") as Node2D
	# Check the spawn itself, before its hovering AI moves during a frame.
	replay_actor.set_physics_process(false)
	await process_frame
	var replay_expansion = replay_room.get_node("ExpandedRoute")
	var replay_points: Array[Vector2] = replay_expansion.get_replay_spawn_points()
	_check(replay_points.any(func(point: Vector2) -> bool: return replay_actor.position.distance_to(point) < 1.0), "Awakened patrol still uses the obsolete small-room coordinates")
	_check(replay_room.get_node("Cache_crossing_dregs").position.distance_to(replay_expansion.get_replay_cache_position()) < 1.0, "Awakened cache still uses the obsolete small-room coordinates")
	_check(replay_room.get_node("Cache_crossing_dregs").global_position.distance_to(replay_expansion.get_node("AuthoredDescent/HiddenDepthCache").global_position) > 300.0, "First-clear and awakened Shaft rewards overlap instead of motivating a different branch")
	replay_actor.take_damage(1)
	var replay_health := int(replay_actor.current_health)
	state.set_current_room("training_passage")
	population.unload_room_population("DrownedCrossing")
	await process_frame
	_check(not replay_room.has_node("crossing_echo_wisp"), "Awakened patrol did not unload with its room")
	state.set_current_room("shaft_crossing")
	await process_frame
	_check(replay_room.has_node("crossing_echo_wisp") and int(replay_room.get_node("crossing_echo_wisp").current_health) == replay_health, "Awakened patrol did not restore its streamed state")
	for replay_case in [
		["echo_grotto", "echo_gallery", "EchoGallery", "gallery_echo_shade", "Cache_gallery_step", "LongTraversal"],
		["ashen_bastion", "ash_forge", "CinderForge", "forge_ash_sentry", "Cache_forge_cinders", "AshSwitchback"],
	]:
		state.set_zone_tier(String(replay_case[0]), 1)
		state.set_current_room(String(replay_case[1]))
		await process_frame
		var aligned_room := game.get_node(String(replay_case[2])) as Node2D
		var aligned_expansion = aligned_room.get_node(String(replay_case[5]))
		var aligned_actor := aligned_room.get_node(String(replay_case[3])) as Node2D
		var aligned_points: Array[Vector2] = aligned_expansion.get_replay_spawn_points()
		_check(aligned_points.any(func(point: Vector2) -> bool: return aligned_actor.position.distance_to(point) < 160.0), "%s replay patrol is not anchored to its expanded route" % replay_case[2])
		_check(aligned_room.get_node(String(replay_case[4])).position.distance_to(aligned_expansion.get_replay_cache_position()) < 1.0, "%s replay cache is not anchored to an exploration branch" % replay_case[2])
	for old_route in [
		["shaft_drift_lamp", "shaft_drift", "ShaftDriftworks", Vector2(40245, 1299)],
		["echo_depths_lamp", "echo_depths", "EchoDepths", Vector2(43245, 1299)],
		["ash_emberspine_lamp", "ash_emberspine", "AshEmberspine", Vector2(46245, 1299)],
		["starfall_ramparts_lamp", "starfall_ramparts", "StarfallRamparts", Vector2(49245, 1299)],
	]:
		var old_lamp_position: Vector2 = old_route[3]
		var old_data: Dictionary = state._build_save_data()
		old_data["version"] = 9
		old_data["has_checkpoint"] = true
		old_data["checkpoint_lamp_id"] = old_route[0]
		old_data["checkpoint_position"] = [old_lamp_position.x, old_lamp_position.y]
		old_data["discovered_lamps"] = {old_route[0]: {"room_id": old_route[1], "position": [old_lamp_position.x, old_lamp_position.y]}}
		state._apply_save_data(old_data)
		var moved_position: Vector2 = game.get_node(str(old_route[2]) + "/TrailLamp/RespawnPoint").global_position
		_check(state.checkpoint_position.distance_to(moved_position) < 1.0 and state.get_lamp_position(old_route[0]).distance_to(moved_position) < 1.0, "Old expedition lamp coordinates did not migrate: %s" % old_route[0])
		state._apply_save_data(state._build_save_data())
		_check(state.checkpoint_position.distance_to(moved_position) < 1.0, "Expedition lamp migration shifted a new save twice: %s" % old_route[0])
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("WORLD POPULATION TEST PASSED")
		quit(0)
	else:
		print("WORLD POPULATION TEST FAILED: ", failures)
		quit(1)
