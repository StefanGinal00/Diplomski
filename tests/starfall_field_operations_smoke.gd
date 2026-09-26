extends "res://tests/ash_field_operations_smoke.gd"

const STAR_ROOMS := [["starfall_outskirts", "StarfallOutskirts"], ["starfall_silent_gate", "StarfallSilentGate"], ["starfall_memory_vault", "StarfallMemoryVault"]]


func _route(game: Node, room: Array) -> Node2D:
	return game.get_node(room[1] + "/ExpandedRoute/StarfallDescent")


func _clear_station(control: Area2D) -> void:
	for enemy in get_nodes_in_group("enemy"):
		if enemy is Node2D and not bool(enemy.get("is_dead")) and enemy.global_position.distance_to(control.global_position) < 180:
			enemy.die()


func _prepare(game: Node) -> Player:
	var player := game.get_node("Player") as Player
	player.set_physics_process(false)
	player.max_health = 10000
	player.current_health = 10000
	return player


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_starfall_fields_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player := _prepare(game)
	for room in STAR_ROOMS:
		_check(not _route(game, room).has_node("FieldOperations"), "Starfall fields loaded before entry")
		state.set_current_room(room[0])
		await process_frame
		await physics_frame
		var route := _route(game, room)
		var ops := route.get_node("FieldOperations")
		for control in ops.controls:
			_floor(control)
		_floor(ops.get_node("ReturnReward"))
		_check(not route.get_node("HiddenStarCache").open(player), "Discovery ignored first-clear task")
		ops.get_node("ReturnEncounter")._on_body_entered(player)
		_check(not ops.get_node("ReturnEncounter").triggered, "Post-Sovereign patrol spawned early")
	var outer := _route(game, STAR_ROOMS[0]).get_node("FieldOperations")
	state.set_current_room("starfall_outskirts")
	_clear_station(outer.controls[0])
	player.global_position = outer.controls[0].global_position + Vector2(80, 0)
	_check(not outer.controls[0].activate(player), "Winch allowed distant interaction")
	_press(outer.controls[0], player)
	_check(outer.covers[0].collision_layer == 1 and outer.covers[1].collision_layer == 0 and not outer.completed, "Winches did not independently enable cover")
	for cover in outer.covers:
		_floor(cover)
		_check(cover.get_node("CollisionShape2D").shape.size.y == 55, "Cover blocks basic-jump traversal")
	var silent := _route(game, STAR_ROOMS[1]).get_node("FieldOperations")
	state.set_current_room("starfall_silent_gate")
	_clear_station(silent.controls[0])
	_press(silent.controls[0], player)
	_check(not silent.controls[0].is_active, "Inspection bypassed original high relay")
	game.get_node("StarfallSilentGate/HighRelay").activate(player)
	_press(silent.controls[0], player)
	_check(silent.controls[0].is_active and not silent.completed, "High relay did not enable side terminal")
	state.set_current_room("starfall_memory_vault")
	var vault := _route(game, STAR_ROOMS[2])
	await physics_frame
	for index in range(3):
		_floor(vault.get_node("SealedRecord%d" % index))
	vault.get_node("SealedRecord0").take_damage(10)
	_check(not vault.get_node("FieldOperations").completed, "One record completed archive")
	vault.get_node("SealedRecord1").take_damage(1)
	var controller_id := vault.get_node("FieldOperations").get_instance_id()
	state.set_current_room("training_passage")
	game.get_node("WorldPopulation").unload_room_population("StarfallMemoryVault")
	await process_frame
	_check(not vault.has_node("SealedRecord1"), "Unvisited record crate failed to unload")
	state.set_current_room("starfall_memory_vault")
	await process_frame
	_check(not vault.has_node("SealedRecord0") and vault.get_node("SealedRecord1").current_health == 1, "Record streaming lost destruction/damage state")
	_check(vault.get_node("FieldOperations").get_instance_id() == controller_id, "Returning duplicated field controller")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "star_fields", "Star Fields", "starfall_memory_vault"), "Partial field save failed")
	# Unsaved actions must disappear when the partial lamp snapshot is restored.
	vault.get_node("SealedRecord1").take_damage(10)
	state.mark_boss_defeated("hollow_sovereign")
	vault.get_node("FieldOperations/ReturnEncounter")._on_body_entered(player)
	_check(not vault.get_node("FieldOperations/ReturnEncounter").triggered, "Boss victory bypassed local unfinished task")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Partial field load failed")
	game = _world()
	await process_frame
	player = _prepare(game)
	for room in STAR_ROOMS:
		state.set_current_room(room[0])
		await process_frame
		var route := _route(game, room)
		var ops := route.get_node("FieldOperations")
		_check(not ops.completed and not ops.get_node("ReturnReward").opened, "Unsaved field completion survived reload")
		match room[1]:
			"StarfallOutskirts":
				_check(ops.controls[0].is_active and not ops.controls[1].is_active and ops.covers[0].collision_layer == 1, "Saved repair not restored")
				_clear_station(ops.controls[1])
				_press(ops.controls[1], player)
			"StarfallSilentGate":
				_check(ops.controls[0].is_active and not ops.controls[1].is_active, "Saved inspection not restored")
				_clear_station(ops.controls[1])
				_press(ops.controls[1], player)
				_check(not ops.controls[1].is_active, "Low inspection bypassed low relay")
				game.get_node("StarfallSilentGate/LowRelay").activate(player)
				_press(ops.controls[1], player)
			"StarfallMemoryVault":
				_check(not route.has_node("SealedRecord0") and route.has_node("SealedRecord1") and route.has_node("SealedRecord2"), "Records did not follow lamp snapshot")
				for index in [1, 2]:
					route.get_node("SealedRecord%d" % index).take_damage(10)
		_check(ops.completed, "Field task failed: " + String(room[1]))
		_check(not route.get_node("HiddenStarCache").open(player), "Field task bypassed cache guardians")
		await _win(route.get_node("HiddenStarAmbush"), player)
		_check(route.get_node("HiddenStarCache").open(player) and not route.get_node("HiddenStarCache").open(player), "Discovery paid incorrectly")
		ops.get_node("ReturnEncounter")._on_body_entered(player)
		_check(not ops.get_node("ReturnEncounter").triggered, "Field completion bypassed Sovereign")
	_check(not bool(state.defeated_bosses.get("hollow_sovereign", false)), "Unsaved Sovereign victory survived lamp rollback")
	state.mark_boss_defeated("hollow_sovereign")
	_check(state.get_zone_tier("starfall_reach") == 0, "Optional returns raised global Starfall difficulty")
	for room in STAR_ROOMS:
		state.set_current_room(room[0])
		await process_frame
		var ops := _route(game, room).get_node("FieldOperations")
		var trial := ops.get_node("ReturnEncounter")
		_check(not trial.status_label.text.contains("DORMANT"), "Sovereign victory did not refresh patrol prompt")
		trial._on_body_entered(player)
		await process_frame
		_check(trial.spawned_enemies.size() == 2, "Return patrol missing")
		for index in range(trial.spawned_enemies.size()):
			var base: Node = trial.enemy_scenes[index].instantiate()
			_check(trial.spawned_enemies[index].max_health == base.max_health + 2, "Return guard missing health bonus")
			base.free()
		trial.spawned_enemies[0].die()
		_check(not ops.get_node("ReturnReward").open(player), "One guard unsealed return reward")
		trial.spawned_enemies[1].die()
		_check(ops.get_node("ReturnReward").open(player) and not ops.get_node("ReturnReward").open(player), "Return reward not exactly once")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "star_fields", "Star Fields", "starfall_memory_vault"), "Complete field save failed")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Complete field load failed")
	game = _world()
	await process_frame
	player = _prepare(game)
	for room in STAR_ROOMS:
		state.set_current_room(room[0])
		await process_frame
		var route := _route(game, room)
		var ops := route.get_node("FieldOperations")
		_check(ops.completed and route.get_node("HiddenStarCache").opened and ops.get_node("ReturnReward").opened, "Saved Starfall rewards reset")
		for trial in [route.get_node("HiddenStarAmbush"), ops.get_node("ReturnEncounter")]:
			trial._on_body_entered(player)
			await process_frame
			_check(trial.completed and trial.spawned_enemies.is_empty(), "Saved guardians respawned")
	game.queue_free()
	await process_frame
	# An old, already claimed reserve stays claimed without fabricating tasks.
	state.start_new_game("normal")
	for room in STAR_ROOMS:
		state.open_cache(room[0] + "_hidden_depth")
	game = _world()
	await process_frame
	for room in STAR_ROOMS:
		state.set_current_room(room[0])
		await process_frame
		var route := _route(game, room)
		_check(route.get_node("HiddenStarCache").opened and not route.get_node("FieldOperations").completed and not route.get_node("HiddenStarAmbush").completed, "Old cache migration changed earned loot or invented victory")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("STARFALL FIELD OPERATIONS TEST PASSED")
		quit(0)
	else:
		print("STARFALL FIELD OPERATIONS TEST FAILED: ", failures)
		quit(1)
