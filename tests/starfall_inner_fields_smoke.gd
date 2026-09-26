extends "res://tests/starfall_field_operations_smoke.gd"

const INNER_ROOMS := [["starfall_rooted_hall", "StarfallRootedHall"], ["starfall_soul_crucible", "StarfallSoulCrucible"], ["starfall_sunless_passage", "StarfallSunlessPassage"]]


func _light(ops: Node, index: int, player: Player) -> void:
	_clear_station(ops.controls[index])
	_press(ops.controls[index], player)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_starfall_inner_fields_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player := _prepare(game)
	for room in INNER_ROOMS:
		_check(not _route(game, room).has_node("FieldOperations"), "Inner field loaded before entry")
		state.set_current_room(room[0])
		await process_frame
		await physics_frame
		var route := _route(game, room)
		var ops := route.get_node("FieldOperations")
		for control in ops.controls:
			_floor(control)
		_floor(ops.get_node("ReturnReward"))
		for sign in ops.signs:
			_check(sign.get_minimum_size().y <= sign.size.y, "Inner field sign overflow")
		_check(not route.get_node("HiddenStarCache").open(player), "Inner cache ignored local task")
		ops.get_node("ReturnEncounter")._on_body_entered(player)
		_check(not ops.get_node("ReturnEncounter").triggered, "Inner return started before Sovereign")
	var garden := _route(game, INNER_ROOMS[0]).get_node("FieldOperations")
	state.set_current_room("starfall_rooted_hall")
	_light(garden, 0, player)
	_check(not garden.controls[0].is_active, "Seedbed bypassed root channel")
	game.get_node("StarfallRootedHall/RootControl").activate(player)
	# Peaceful grazers near a bed are not enemies and must not need killing.
	var grazer := load("res://NeutralCreature.tscn").instantiate() as Node2D
	grazer.position = garden.controls[0].position + Vector2(35, 0)
	garden.add_child(grazer)
	_light(garden, 0, player)
	_check(garden.controls[0].is_active and not garden.controls[1].is_active and not grazer.is_hostile and not grazer.is_dead, "Seedbed required harming peaceful fauna")
	_check(garden.landmarks[0].color != garden.landmarks[1].color, "Garden restoration lacks visual state")
	var crucible := _route(game, INNER_ROOMS[1]).get_node("FieldOperations")
	state.set_current_room("starfall_soul_crucible")
	for index in range(2):
		crucible.get_node("Containment%d" % index)._on_body_entered(player)
		_check(not crucible.get_node("Containment%d" % index).triggered, "Containment ignored matching channel")
	game.get_node("StarfallSoulCrucible/HighChannel").activate(player)
	await _win(crucible.get_node("Containment0"), player)
	_check(not crucible.completed, "One chamber completed containment task")
	crucible.get_node("Containment1")._on_body_entered(player)
	_check(not crucible.get_node("Containment1").triggered, "High channel enabled low chamber")
	var passage := _route(game, INNER_ROOMS[2])
	var lights := passage.get_node("FieldOperations")
	state.set_current_room("starfall_sunless_passage")
	await physics_frame
	for index in range(6):
		_floor(passage.get_node("VoidPulse%d" % index))
	_light(lights, 2, player)
	_check(not lights.controls[2].is_active, "Last beacon ignored chain")
	_light(lights, 0, player)
	for index in range(6):
		_check(passage.get_node("VoidPulse%d" % index).disabled == (index < 2), "First beacon disabled wrong void lanes")
	_check(not game.get_node("StarfallSunlessPassage/BridgeOne").stabilized, "Beacon replaced original anchor")
	_check(not game.get_node("StarfallSunlessPassage/HollowThroneDoor")._requirements_met(), "Beacon bypassed final gate")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "inner_fields", "Inner Fields", "starfall_sunless_passage"), "Partial inner field save failed")
	_light(lights, 1, player)
	game.get_node("StarfallSunlessPassage/DawnAnchor").activate(player)
	for index in range(6):
		_check(passage.get_node("VoidPulse%d" % index).disabled, "Original anchor no longer quiets every void lane")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Partial inner field load failed")
	game = _world()
	await process_frame
	player = _prepare(game)
	for room in INNER_ROOMS:
		state.set_current_room(room[0])
		await process_frame
		var route := _route(game, room)
		var ops := route.get_node("FieldOperations")
		_check(not ops.completed and not route.get_node("HiddenStarCache").opened, "Unsaved inner completion survived rollback")
		match room[1]:
			"StarfallRootedHall":
				_check(ops.controls[0].is_active and not ops.controls[1].is_active, "Partial garden failed to restore")
				_light(ops, 1, player)
			"StarfallSoulCrucible":
				_check(ops.get_node("Containment0").completed and ops.get_node("Containment0").spawned_enemies.is_empty(), "Saved containment respawned")
				game.get_node("StarfallSoulCrucible/LowChannel").activate(player)
				_check(not ops.completed, "Both original channels bypassed containment")
				await _win(ops.get_node("Containment1"), player)
			"StarfallSunlessPassage":
				_check(ops.controls[0].is_active and not ops.controls[1].is_active, "Partial lights failed to restore")
				for index in range(6):
					_check(route.get_node("VoidPulse%d" % index).disabled == (index < 2), "Local quieting failed save/rollback")
				_check(not game.get_node("StarfallSunlessPassage/BridgeOne").stabilized, "Unsaved anchor survived rollback")
				for index in [1, 2]:
					_light(ops, index, player)
		_check(ops.completed and not route.get_node("HiddenStarCache").open(player), "Inner task bypassed niche guardians")
		await _win(route.get_node("HiddenStarAmbush"), player)
		_check(route.get_node("HiddenStarCache").open(player) and not route.get_node("HiddenStarCache").open(player), "Inner discovery paid incorrectly")
		ops.get_node("ReturnEncounter")._on_body_entered(player)
		_check(not ops.get_node("ReturnEncounter").triggered, "Inner completion bypassed Sovereign")
	state.mark_boss_defeated("hollow_sovereign")
	_check(state.get_zone_tier("starfall_reach") == 0, "Inner returns raised global tier")
	for room in INNER_ROOMS:
		state.set_current_room(room[0])
		await process_frame
		var ops := _route(game, room).get_node("FieldOperations")
		await _win(ops.get_node("ReturnEncounter"), player)
		_check(ops.get_node("ReturnReward").open(player) and not ops.get_node("ReturnReward").open(player), "Inner return paid incorrectly")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "inner_fields", "Inner Fields", "starfall_sunless_passage"), "Complete inner save failed")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Complete inner load failed")
	game = _world()
	await process_frame
	player = _prepare(game)
	for room in INNER_ROOMS:
		state.set_current_room(room[0])
		await process_frame
		var route := _route(game, room)
		var ops := route.get_node("FieldOperations")
		_check(ops.completed and route.get_node("HiddenStarCache").opened and ops.get_node("ReturnReward").opened, "Inner completed rewards reset")
		for trial in [route.get_node("HiddenStarAmbush"), ops.get_node("ReturnEncounter")]:
			trial._on_body_entered(player)
			await process_frame
			_check(trial.completed and trial.spawned_enemies.is_empty(), "Inner saved guardians respawned")
	game.queue_free()
	await process_frame
	# Legacy global shutdown and already claimed reserves keep their meaning.
	state.start_new_game("normal")
	state.unlock_shortcut("starfall_sunless_anchor")
	for room in INNER_ROOMS:
		state.open_cache(room[0] + "_hidden_depth")
	game = _world()
	await process_frame
	for room in INNER_ROOMS:
		state.set_current_room(room[0])
		await process_frame
		var route := _route(game, room)
		_check(route.get_node("HiddenStarCache").opened and not route.get_node("FieldOperations").completed and not route.get_node("HiddenStarAmbush").completed, "Old reward invented new field/guardian progress")
		if room[1] == "StarfallSunlessPassage":
			for index in range(6):
				_check(route.get_node("VoidPulse%d" % index).disabled, "Saved original anchor lost global shutdown")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("STARFALL INNER FIELDS TEST PASSED")
		quit(0)
	else:
		print("STARFALL INNER FIELDS TEST FAILED: ", failures)
		quit(1)
