extends "res://tests/starfall_field_operations_smoke.gd"

const PREFIX := "starfall_ramparts"


func _enter(game: Node) -> Node:
	root.get_node("GameState").set_current_room(PREFIX)
	return game.get_node("StarfallRamparts")


func _finish_plate(route: Node, index: int, player: Player) -> void:
	var guard := route.get_node_or_null("BranchGuard%d" % (index * 2))
	if guard != null and not guard.is_dead:
		guard.die()
	var control = route.get_node("FieldOperations").controls[index]
	_clear_station(control)
	_press(control, player)
	_check(control.is_active, "Watch plate not recovered")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_rampart_fields_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player := _prepare(game)
	_check(not game.has_node("StarfallRamparts/FieldOperations"), "Rampart task loaded before entry")
	var route := _enter(game)
	await process_frame
	await physics_frame
	var ops := route.get_node("FieldOperations")
	for control in ops.controls:
		_floor(control)
	for node in [route.get_node("RimCache"), route.get_node("MidCache"), ops.get_node("ReturnReward"), route.get_node("LowerHazard0"), route.get_node("LowerHazard1")]:
		_floor(node)
	for sign in ops.signs:
		_check(sign.get_minimum_size().y <= 150, "Rampart instructions overflow")
	_check(not route.get_node("RimCache").open(player), "Unfinished Rim Cache paid out")
	for index in range(2):
		_press(ops.controls[index], player)
		_check(not ops.controls[index].is_active, "Plate bypassed its watch guard")
	_clear_station(ops.controls[2])
	_press(ops.controls[2], player)
	_check(not ops.completed and not route.get_node("LowerHazard0").disabled, "Signal ignored missing plates")
	_finish_plate(route, 0, player)
	_check(not ops.completed and not ops.controls[1].is_active, "West watch completed both plates")
	var identity := ops.get_instance_id()
	state.set_current_room("training_passage")
	_check(not ops.can_process(), "Rampart task active outside room")
	_enter(game)
	await process_frame
	_check(route.get_node("FieldOperations").get_instance_id() == identity and ops.controls[0].is_active, "Re-entry duplicated/reset task")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "rampart_fields", "Rampart Fields", PREFIX), "Partial Rampart save failed")
	state.mark_boss_defeated("hollow_sovereign")
	ops.get_node("ReturnEncounter")._on_body_entered(player)
	_check(not ops.get_node("ReturnEncounter").triggered, "Boss victory bypassed local Rampart work")
	_finish_plate(route, 1, player)
	_clear_station(ops.controls[2])
	_press(ops.controls[2], player)
	_check(ops.completed and route.get_node("LowerHazard0").disabled and route.get_node("LowerHazard1").disabled, "Restored desk did not stop both root lanes")
	_check(not route.get_node("RimCache").open(player), "Signal restoration bypassed deep guard")
	route.get_node("BranchGuard3").die()
	_check(route.get_node("RimCache").open(player), "Deep guard did not release Rim Cache")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Partial Rampart reload failed")
	game = _world()
	await process_frame
	player = _prepare(game)
	route = _enter(game)
	await process_frame
	ops = route.get_node("FieldOperations")
	_check(ops.controls[0].is_active and not ops.controls[1].is_active and not ops.completed, "Partial plate progress failed rollback")
	_check(not route.has_node("BranchGuard0") and route.has_node("BranchGuard2") and route.has_node("BranchGuard3"), "Saved/unsaved watch guards restored incorrectly")
	_check(not route.get_node("LowerHazard0").disabled and not route.get_node("RimCache").opened, "Unsaved shutdown or reward survived rollback")
	_finish_plate(route, 1, player)
	_clear_station(ops.controls[2])
	_press(ops.controls[2], player)
	route.get_node("BranchGuard3").die()
	_check(route.get_node("RimCache").open(player) and not route.get_node("RimCache").open(player), "Rim Cache did not pay exactly once")
	ops.get_node("ReturnEncounter")._on_body_entered(player)
	_check(not ops.get_node("ReturnEncounter").triggered, "Return bypassed Sovereign after rollback")
	state.mark_boss_defeated("hollow_sovereign")
	_check(state.get_zone_tier("starfall_reach") == 0, "Rampart return changed global difficulty")
	var trial := ops.get_node("ReturnEncounter")
	trial._on_body_entered(player)
	await process_frame
	_check(trial.spawned_enemies.size() == 2, "Rampart return patrol missing")
	for index in range(2):
		var base: Node = trial.enemy_scenes[index].instantiate()
		_check(trial.spawned_enemies[index].max_health == base.max_health + 2, "Return patrol lacks strength bonus")
		base.free()
	trial.spawned_enemies[0].die()
	_check(not ops.get_node("ReturnReward").open(player), "One return foe released reward")
	trial.spawned_enemies[1].die()
	state.set_current_room("starfall_citadel")
	await process_frame
	var office := game.get_node("StarfallCitadel/FieldOffice")
	_check(office.rows[PREFIX][3].text == "TAKEN" and office.rows[PREFIX][4].text == "REWARD", "Office did not map existing RimCache and return victory")
	_enter(game)
	var gold_before := int(state.gold)
	_check(ops.get_node("ReturnReward").open(player) and not ops.get_node("ReturnReward").open(player), "Return reserve did not pay exactly once")
	_check(state.gold == gold_before + 30 and office.rows[PREFIX][4].text == "TAKEN", "Return reserve payout/office claim incorrect")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "rampart_fields", "Rampart Fields", PREFIX), "Complete Rampart save failed")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Complete Rampart load failed")
	game = _world()
	await process_frame
	route = _enter(game)
	await process_frame
	ops = route.get_node("FieldOperations")
	_check(ops.completed and route.get_node("RimCache").opened and ops.get_node("ReturnReward").opened, "Saved Rampart completions reset")
	for index in [0, 2, 3]:
		_check(not route.has_node("BranchGuard%d" % index), "Saved objective guard respawned")
	ops.get_node("ReturnEncounter")._on_body_entered(game.get_node("Player"))
	_check(ops.get_node("ReturnEncounter").completed and ops.get_node("ReturnEncounter").spawned_enemies.is_empty(), "Saved return patrol respawned")
	game.queue_free()
	await process_frame
	state.start_new_game("normal")
	state.unlock_shortcut(PREFIX + "_hazard_disabled")
	state.open_cache(PREFIX + "_rim")
	game = _world()
	await process_frame
	route = _enter(game)
	await process_frame
	ops = route.get_node("FieldOperations")
	_check(route.get_node("LowerHazard0").disabled and route.get_node("LowerHazard1").disabled and route.get_node("RimCache").opened, "Legacy shutdown/claim reset")
	_check(not ops.completed and not ops.controls[0].is_active and route.has_node("BranchGuard3"), "Legacy state fabricated new objective progress")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("RAMPART FIELD OPERATIONS TEST PASSED")
		quit(0)
	else:
		print("RAMPART FIELD OPERATIONS TEST FAILED: ", failures)
		quit(1)
