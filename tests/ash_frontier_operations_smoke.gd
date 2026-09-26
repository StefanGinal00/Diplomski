extends "res://tests/ash_road_records_smoke.gd"

const OUTSKIRTS := "CinderHearthOutskirts/AshSwitchback"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_ash_frontier_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player: Player = game.get_node("Player")
	player.set_physics_process(false)
	player.max_health = 10000
	player.current_health = 10000
	_check(not game.has_node(OUTSKIRTS + "/FieldOperations") and not game.has_node("AshEmberspine/FieldOperations"), "Unvisited frontier content loaded eagerly")
	state.set_current_room("ash_hearth_outskirts")
	await process_frame
	await physics_frame
	var route := game.get_node(OUTSKIRTS)
	var watch := route.get_node("FieldOperations")
	for index in range(2):
		_floor(watch.controls[index])
		var scout := watch.get_node("WatchScout%d" % index)
		_floor(scout)
		_check(scout.route_markers.size() == 2 and scout.interaction_requested.is_connected(Callable(game.get_node("UI"), "_on_npc_interaction_requested")), "Scout walking/dialogue disconnected")
		_clear_station(watch.controls[index])
		_press(watch.controls[index], player)
		_check(not watch.controls[index].is_active, "Report bypassed its patrol")
	_floor(watch.get_node("ReturnReward"))
	await _win(watch.get_node("LowerWatch"), player)
	_clear_station(watch.controls[0])
	_press(watch.controls[0], player)
	_check(watch.controls[0].is_active and not watch.completed, "First report completed both watches")
	var detail := route.get_node("FieldDressing")
	_check("REPORTS COLLECTED 1/2" in detail.get_node("Site0/RouteClue").text and "1/2" in watch.get_node("WatchScout0").dialogue_lines[0], "Watch map/scout ignored partial reports")
	_check(detail.get_node("Site0/Light0").color == Color(0.54, 0.96, 0.70) and detail.get_node("Site0/Light1").color != Color(0.54, 0.96, 0.70), "Watch report lamps not independent")
	_check(game.get_node("QuestManager").get_hearth_gate_progress() == 0, "Optional watch patrol counted as gate quest targets")
	_check(not route.get_node("IdentityRewardCache").open(player), "Outskirts cache bypassed second report")
	state.set_current_room("ash_emberspine")
	await process_frame
	await physics_frame
	var spine := game.get_node("AshEmberspine")
	var cooling := spine.get_node("FieldOperations")
	for control in cooling.controls:
		_floor(control)
	_floor(spine.get_node("RimCache"))
	_floor(spine.get_node("BranchGuard3"))
	_floor(cooling.get_node("ReturnReward"))
	_check(not spine.get_node("LowerHazard0").disabled and not spine.get_node("LowerHazard1").disabled, "Unrepaired fire lanes started disabled")
	_clear_station(cooling.controls[0])
	_press(cooling.controls[0], player)
	_check(spine.get_node("LowerHazard0").disabled and not spine.get_node("LowerHazard1").disabled, "First feed did not control only its own lane")
	_check(not spine.get_node("RimCache").open(player), "Deep reserve bypassed cooling/guard")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "frontier", "Frontier", "ash_emberspine"), "Partial frontier progress could not save")
	_clear_station(cooling.controls[1])
	_press(cooling.controls[1], player)
	_check(spine.get_node("LowerHazard1").disabled and not spine.get_node("RimCache").open(player), "Cooling bypassed deep reserve guard")
	spine.get_node("BranchGuard3").die()
	_check(spine.get_node("RimCache").open(player) and not spine.get_node("RimCache").open(player), "Deep reserve was not earned exactly once")
	cooling.get_node("ReturnEncounter")._on_body_entered(player)
	_check(not cooling.get_node("ReturnEncounter").triggered, "Emberspine return patrol appeared before awakening")
	state.set_current_room("ash_hearth_outskirts")
	await _win(route.get_node("GuardedNicheAmbush"), player)
	_clear_station(watch.controls[1])
	_press(watch.controls[1], player)
	_check(watch.completed and route.get_node("IdentityRewardCache").open(player), "Outskirts report reward did not unlock")
	_check("REPORTS COLLECTED 2/2" in detail.get_node("Site0/RouteClue").text and "TASK: DONE | UPPER GUARDIANS: DONE" in detail.get_node("Site6/RouteClue").text, "Completed watch cues stale")
	state.set_current_room("training_passage")
	game.get_node("WorldPopulation").unload_room_population("CinderHearthOutskirts")
	await process_frame
	state.set_current_room("ash_hearth_outskirts")
	await process_frame
	_check(route.get_node("FieldOperations") == watch and watch.get_node("LowerWatch").completed and watch.controls.size() == 2, "Streaming duplicated/reset persistent watch posts")
	state.set_zone_tier("ashen_bastion", 1)
	for pair in [["ash_hearth_outskirts", watch], ["ash_emberspine", cooling]]:
		state.set_current_room(pair[0])
		await process_frame
		var trial = pair[1].get_node("ReturnEncounter")
		trial._on_body_entered(player)
		await process_frame
		_check(trial.spawned_enemies.size() == 2, "Frontier return patrol missing")
		trial.spawned_enemies[0].die()
		_check(not pair[1].get_node("ReturnReward").open(player), "One return foe released entire reserve")
		trial.spawned_enemies[1].die()
		_check(pair[1].get_node("ReturnReward").open(player) and not pair[1].get_node("ReturnReward").open(player), "Frontier return reserve duplicated")
	state.set_current_room("ash_hearth")
	await process_frame
	var office := game.get_node("CinderHearth/EasternDistricts/FieldOffice")
	_check("TASKS 2/7" in office.board.text and "RETURN VICTORIES 2/7" in office.board.text, "Field office missed frontier tasks")
	_check(office.board.get_minimum_size().x <= 430 and office.board.get_minimum_size().y <= 160, "Seven-task board overflows")
	for enemy in get_nodes_in_group("enemy"):
		_check(not game.get_node("CinderHearth").is_ancestor_of(enemy), "Frontier tasks introduced town enemies")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Partial frontier save did not load")
	game = _world()
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	player.max_health = 10000
	player.current_health = 10000
	spine = game.get_node("AshEmberspine")
	cooling = spine.get_node("FieldOperations")
	_check(cooling.controls[0].is_active and not cooling.controls[1].is_active and spine.get_node("LowerHazard0").disabled and not spine.get_node("LowerHazard1").disabled, "Partial cooling snapshot did not restore")
	_check(spine.has_node("BranchGuard3") and not spine.get_node("RimCache").opened and not cooling.get_node("ReturnReward").opened, "Unsaved deep guard/rewards survived rollback")
	state.set_zone_tier("ashen_bastion", 1)
	cooling.get_node("ReturnEncounter")._on_body_entered(player)
	_check(not cooling.get_node("ReturnEncounter").triggered, "Awakening bypassed unfinished cooling")
	_clear_station(cooling.controls[1])
	_press(cooling.controls[1], player)
	spine.get_node("BranchGuard3").die()
	spine.get_node("RimCache").open(player)
	await _win(cooling.get_node("ReturnEncounter"), player)
	cooling.get_node("ReturnReward").open(player)
	state.set_current_room("ash_hearth_outskirts")
	await process_frame
	route = game.get_node(OUTSKIRTS)
	watch = route.get_node("FieldOperations")
	_check(watch.controls[0].is_active and not watch.controls[1].is_active and watch.get_node("LowerWatch").completed, "Saved lower watch/report lost")
	_check(not watch.completed and not route.get_node("IdentityRewardCache").opened and not watch.get_node("ReturnReward").opened, "Unsaved upper watch/rewards survived rollback")
	_check("REPORTS COLLECTED 1/2" in route.get_node("FieldDressing/Site0/RouteClue").text and "1/2" in watch.get_node("WatchScout1").dialogue_lines[0], "Watch map/scout did not restore partial save")
	await _win(route.get_node("GuardedNicheAmbush"), player)
	_clear_station(watch.controls[1])
	_press(watch.controls[1], player)
	route.get_node("IdentityRewardCache").open(player)
	await _win(watch.get_node("ReturnEncounter"), player)
	watch.get_node("ReturnReward").open(player)
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "frontier", "Frontier", "ash_hearth_outskirts"), "Complete frontier progress could not save")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Complete frontier save did not load")
	game = _world()
	await process_frame
	watch = game.get_node(OUTSKIRTS + "/FieldOperations")
	_check(watch.completed and watch.get_node("LowerWatch").completed and watch.get_node("ReturnReward").opened, "Complete watch progress reset")
	_check("REPORTS COLLECTED 2/2" in game.get_node(OUTSKIRTS + "/FieldDressing/Site0/RouteClue").text and "returning guardians are quiet" in watch.get_node("WatchScout0").dialogue_lines[0], "Saved completed watch cues/advice reset")
	state.set_current_room("ash_emberspine")
	await process_frame
	spine = game.get_node("AshEmberspine")
	cooling = spine.get_node("FieldOperations")
	_check(not spine.has_node("BranchGuard3") and spine.get_node("RimCache").opened and cooling.get_node("ReturnReward").opened, "Saved deep reserve guard/rewards reset")
	for ops in [watch, cooling]:
		ops.get_node("ReturnEncounter")._on_body_entered(game.get_node("Player"))
		await process_frame
		_check(ops.get_node("ReturnEncounter").completed and ops.get_node("ReturnEncounter").spawned_enemies.is_empty(), "Saved return patrol respawned")
	game.queue_free()
	await process_frame
	# Old saves may already have stopped all hazards/opened the old RimCache.
	# Keep those benefits without inventing a deep-guard victory.
	state.start_new_game("normal")
	state.unlock_shortcut("ash_emberspine_hazard_disabled")
	state.open_cache("ash_emberspine_rim")
	game = _world()
	await process_frame
	state.set_current_room("ash_emberspine")
	await process_frame
	spine = game.get_node("AshEmberspine")
	cooling = spine.get_node("FieldOperations")
	_check(cooling.controls[0].is_active and cooling.controls[1].is_active and spine.get_node("LowerHazard0").disabled and spine.get_node("LowerHazard1").disabled, "Legacy shared cooling shutdown did not migrate")
	_check(spine.get_node("RimCache").opened and spine.has_node("BranchGuard3") and not bool(state.unlocked_shortcuts.get("ash_emberspine_guarded_niche_cleared", false)), "Legacy cache migration relocked loot or invented a guard victory")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("ASH FRONTIER OPERATIONS TEST PASSED")
		quit(0)
	else:
		print("ASH FRONTIER OPERATIONS TEST FAILED: ", failures)
		quit(1)
