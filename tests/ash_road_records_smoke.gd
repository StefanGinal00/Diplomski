extends "res://tests/ash_field_operations_smoke.gd"

const ROAD_ROOMS := [["ash_causeway", "BrokenCauseway"], ["ash_chapel", "AshChapel"]]


func _clear_station(control: Area2D) -> void:
	for enemy in get_nodes_in_group("enemy"):
		if enemy is Node2D and enemy.has_method("die") and enemy.global_position.distance_to(control.global_position) < 180:
			enemy.die()


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_ash_road_records_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player: Player = game.get_node("Player")
	player.set_physics_process(false)
	player.max_health = 10000
	player.current_health = 10000
	_check(not game.has_node("CinderHearth/EasternDistricts/FieldOffice"), "Unvisited Hearth field office loaded eagerly")
	for room in ROAD_ROOMS:
		_check(not game.has_node(room[1] + "/AshSwitchback/FieldOperations"), "Unvisited road task loaded eagerly")
		state.set_current_room(room[0])
		await process_frame
		await physics_frame
		var ops := game.get_node(room[1] + "/AshSwitchback/FieldOperations")
		for control in ops.controls:
			_floor(control)
		_floor(ops.get_node("ReturnReward"))
		_check(not ops.route.get_node("IdentityRewardCache").open(player), "Road cache opened before task and guardians")
		ops.get_node("ReturnEncounter")._on_body_entered(player)
		_check(not ops.get_node("ReturnEncounter").triggered, "Road return encounter woke before Castellan")
	state.set_current_room("ash_causeway")
	var causeway := game.get_node("BrokenCauseway/AshSwitchback/FieldOperations")
	_clear_station(causeway.controls[1])
	_press(causeway.controls[1], player)
	_check(not causeway.controls[1].is_active, "Signal chain allowed Span before Foot")
	var threat := load("res://AshFiend.tscn").instantiate() as Node2D
	threat.position = causeway.controls[0].position
	causeway.add_child(threat)
	_press(causeway.controls[0], player)
	_check(not causeway.controls[0].is_active, "Threatened signal could be lit")
	_clear_station(causeway.controls[0])
	player.global_position = causeway.controls[0].global_position + Vector2(100, 0)
	_check(not causeway.controls[0].activate(player), "Signal could be lit remotely")
	_press(causeway.controls[0], player)
	_check(causeway.controls[0].is_active and not causeway.completed, "Foot signal failed or completed the entire chain")
	var causeway_detail: Node = causeway.route.get_node("FieldDressing")
	_check("1/3" in causeway_detail.get_node("Site1/RouteClue").text and "1/3" in causeway_detail.get_node("FieldGuide").dialogue_lines[0], "Signal register/guide ignored partial chain")
	_check(causeway_detail.get_node("Site1/ProgressLight0").modulate != Color.WHITE and causeway_detail.get_node("Site1/ProgressLight1").modulate == Color.WHITE, "Partial signal lights are incorrect")
	state.set_current_room("ash_chapel")
	var chapel := game.get_node("AshChapel/AshSwitchback/FieldOperations")
	await _win(chapel.route.get_node("GuardedNicheAmbush"), player)
	_clear_station(chapel.controls[1])
	_press(chapel.controls[1], player)
	_check(chapel.controls[1].is_active and not chapel.controls[0].is_active and not chapel.completed, "Chapel records were not independent")
	var chapel_detail: Node = chapel.route.get_node("FieldDressing")
	_check("1/2" in chapel_detail.get_node("Site1/RouteClue").text and chapel_detail.get_node("Site1/ProgressLight0").modulate == Color.WHITE and chapel_detail.get_node("Site1/ProgressLight1").modulate != Color.WHITE, "Record desk failed to distinguish individual records")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "road_records", "Road Records", "ash_chapel"), "Partial road records could not save")
	_clear_station(chapel.controls[0])
	_press(chapel.controls[0], player)
	_check(not chapel.completed, "Copied records bypassed original Chapel bells")
	_check(chapel_detail.get_node("Site4/BellLight0").modulate == Color.WHITE and "FIELD TASK: PENDING" in chapel_detail.get_node("Site6/RouteClue").text, "Records incorrectly lit bells or unsealed reserve")
	_check(not game.get_node("AshChapel").attempt_dial(1, player), "Wrong first bell accepted")
	_check(chapel_detail.get_node("Site4/BellLight0").modulate == Color.WHITE, "Wrong bell lit completed choir cue")
	for index in range(3):
		game.get_node("AshChapel").attempt_dial(index, player)
	_check(chapel.completed and chapel.route.get_node("IdentityRewardCache").open(player) and not chapel.route.get_node("IdentityRewardCache").open(player), "Chapel field reward not earned once")
	_check(chapel_detail.get_node("Site4/BellLight0").modulate != Color.WHITE and "FIELD TASK: DONE | GUARDIANS: DONE" in chapel_detail.get_node("Site6/RouteClue").text, "Completed Chapel cues did not update")
	state.set_current_room("ash_causeway")
	for index in [1, 2]:
		_clear_station(causeway.controls[index])
		_press(causeway.controls[index], player)
	_check(causeway.completed and not causeway.route.get_node("IdentityRewardCache").open(player), "Signal completion bypassed supply guardians")
	_check("FIELD TASK: DONE | GUARDIANS: PENDING" in causeway_detail.get_node("Site6/RouteClue").text and "Defeat both" in causeway_detail.get_node("FieldGuide").dialogue_lines[0], "Guide/sign ignored pending upper guardians")
	await _win(causeway.route.get_node("GuardedNicheAmbush"), player)
	_check(causeway.route.get_node("IdentityRewardCache").open(player), "Causeway guarded reward not released")
	for index in range(3):
		var beacon: Polygon2D = causeway.route.get_node("AshIdentity/RefugeBeacons/Beacon%d" % index)
		_check(beacon.color.a > 0.9 and beacon.position.distance_to(causeway.controls[index].position) < 70, "Restored beacon is not lit/at its station")
	state.set_zone_tier("ashen_bastion", 1)
	for room in ROAD_ROOMS:
		state.set_current_room(room[0])
		await process_frame
		var ops := game.get_node(room[1] + "/AshSwitchback/FieldOperations")
		_check("now awake" in ops.route.get_node("FieldDressing/FieldGuide").dialogue_lines[0], "Guide ignored awakened return prerequisites")
		await _win(ops.get_node("ReturnEncounter"), player)
		_check(ops.get_node("ReturnReward").open(player) and not ops.get_node("ReturnReward").open(player), "Road return reserve not earned once")
		_check("returning guardians are quiet" in ops.route.get_node("FieldDressing/FieldGuide").dialogue_lines[0], "Guide ignored return victory")
	state.set_current_room("ash_hearth")
	await process_frame
	await physics_frame
	var office := game.get_node("CinderHearth/EasternDistricts/FieldOffice")
	_check("TASKS 2/7" in office.board.text and "RETURN VICTORIES 2/7" in office.board.text, "Hearth board missed new road records")
	_check(office.board.get_minimum_size().x <= 430 and office.board.get_minimum_size().y <= 160, "Hearth board text overflows its backing")
	for npc in [office.keeper, office.courier]:
		_floor(npc)
		_check(npc.route_markers.size() == 2 and npc.interaction_requested.is_connected(Callable(game.get_node("UI"), "_on_npc_interaction_requested")), "New Hearth resident lacks walking/dialogue integration")
	for enemy in get_nodes_in_group("enemy"):
		_check(not game.get_node("CinderHearth").is_ancestor_of(enemy), "Field office spawned danger in Hearth")
	_check("burning again" in office.courier.dialogue_lines[1] and "both Chapel records" in office.courier.dialogue_lines[2], "Courier did not react to completed tasks")
	# Test the same proximity/path prerequisites used by ambient town exchanges.
	office.keeper.position = office.get_node("BoardStop1").position
	office.keeper.current_stop_marker = office.get_node("BoardStop1")
	office.courier.position = office.get_node("BoardStop2").position
	office.courier.current_stop_marker = office.get_node("BoardStop2")
	office.keeper.player_in_range = null
	office.courier.player_in_range = null
	office.keeper.social_cooldown = 0
	office.courier.social_cooldown = 0
	office.keeper._try_social_exchange()
	_check(office.keeper.social_remaining > 0 and office.courier.social_remaining > 0, "Field office residents cannot converse")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Partial road records could not reload")
	game = _world()
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	player.max_health = 10000
	player.current_health = 10000
	state.set_zone_tier("ashen_bastion", 1)
	for room in ROAD_ROOMS:
		state.set_current_room(room[0])
		await process_frame
		var ops := game.get_node(room[1] + "/AshSwitchback/FieldOperations")
		_check(not ops.completed and not ops.get_node("ReturnReward").opened and not ops.route.get_node("IdentityRewardCache").opened, "Unsaved road victory/reward survived rollback")
		ops.get_node("ReturnEncounter")._on_body_entered(player)
		_check(not ops.get_node("ReturnEncounter").triggered, "Awakening bypassed road requirements")
		if ops.course == "causeway":
			_check("1/3" in ops.route.get_node("FieldDressing/Site1/RouteClue").text and "GUARDIANS: PENDING" in ops.route.get_node("FieldDressing/Site6/RouteClue").text, "Signal cue did not restore partial snapshot")
			_check(ops.controls[0].is_active and not ops.controls[1].is_active, "Partial signal chain did not restore")
			for index in [1, 2]:
				_clear_station(ops.controls[index])
				_press(ops.controls[index], player)
			await _win(ops.route.get_node("GuardedNicheAmbush"), player)
		else:
			_check("1/2" in ops.route.get_node("FieldDressing/Site1/RouteClue").text and ops.route.get_node("FieldDressing/Site4/BellLight0").modulate == Color.WHITE, "Record/bell cue survived unsaved completion rollback")
			_check(ops.controls[1].is_active and not ops.controls[0].is_active and ops.route.get_node("GuardedNicheAmbush").completed, "Partial Chapel records or saved guardians did not restore")
			_clear_station(ops.controls[0])
			_press(ops.controls[0], player)
			for index in range(3):
				game.get_node("AshChapel").attempt_dial(index, player)
		ops.route.get_node("IdentityRewardCache").open(player)
		await _win(ops.get_node("ReturnEncounter"), player)
		ops.get_node("ReturnReward").open(player)
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "road_records", "Road Records", "ash_chapel"), "Complete road records could not save")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Complete road records could not reload")
	game = _world()
	await process_frame
	for room in ROAD_ROOMS:
		state.set_current_room(room[0])
		await process_frame
		var ops := game.get_node(room[1] + "/AshSwitchback/FieldOperations")
		_check(ops.completed and ops.route.get_node("IdentityRewardCache").opened and ops.get_node("ReturnReward").opened, "Saved road task/reward reset")
		_check("returning guardians are quiet" in ops.route.get_node("FieldDressing/FieldGuide").dialogue_lines[0] and "FIELD TASK: DONE | GUARDIANS: DONE" in ops.route.get_node("FieldDressing/Site6/RouteClue").text, "Completed guide/reserve cue reset on load")
		ops.get_node("ReturnEncounter")._on_body_entered(game.get_node("Player"))
		await process_frame
		_check(ops.get_node("ReturnEncounter").completed and ops.get_node("ReturnEncounter").spawned_enemies.is_empty(), "Saved road return patrol respawned")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("ASH ROAD RECORDS TEST PASSED")
		quit(0)
	else:
		print("ASH ROAD RECORDS TEST FAILED: ", failures)
		quit(1)
