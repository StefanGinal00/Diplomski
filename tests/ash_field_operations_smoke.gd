extends SceneTree

const ROOMS := [["ash_forge", "CinderForge"], ["ash_barracks", "EmberBarracks"], ["ash_reservoir", "SlagReservoir"]]
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _world() -> Node:
	var game := load("res://Game.tscn").instantiate() as Node
	root.add_child(game)
	current_scene = game
	return game


func _floor(node: Node2D) -> void:
	var query := PhysicsRayQueryParameters2D.create(node.global_position + Vector2(0, 5), node.global_position + Vector2(0, 60), 1)
	var excluded: Array[RID] = []
	for body in get_nodes_in_group("enemy") + get_nodes_in_group("player"):
		if body is CollisionObject2D:
			excluded.append(body.get_rid())
	if node is CollisionObject2D:
		excluded.append(node.get_rid())
	query.exclude = excluded
	var hit := node.get_world_2d().direct_space_state.intersect_ray(query)
	_check(not hit.is_empty() and hit.get("collider") is StaticBody2D, "Unsupported Ash interaction: " + String(node.get_path()))


func _press(control: Area2D, player: Player) -> void:
	player.set_physics_process(false)
	player.global_position = control.global_position
	control._on_body_entered(player)
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	control._unhandled_input(event)
	control._on_body_exited(player)


func _win(trial: Area2D, player: Player) -> void:
	trial._on_body_entered(player)
	await process_frame
	_check(trial.spawned_enemies.size() == 2, "Expected two field guardians")
	for enemy in trial.spawned_enemies:
		enemy.die()
	_check(trial.completed, "Guardian victory not recorded")


func _check_industry_cues(route: Node) -> void:
	var detail := route.get_node("FieldDressing")
	var ops := route.get_node("FieldOperations")
	var flags: Dictionary = root.get_node("GameState").unlocked_shortcuts
	var on := Color(0.54, 0.96, 0.70)
	var expected: Array = []
	match ops.course:
		"forge":
			for key in ["ash_forge_service_winch", "ash_forge_service_gearbox", "ash_forge_fan"]:
				expected.append(bool(flags.get(key, false)))
			_check((detail.get_node("Site3/Blade0").modulate != Color.WHITE) == expected[2], "Fan cue ignores original cooling flag")
		"barracks":
			for i in range(4):
				expected.append(bool(flags.get("ash_barracks_drill_%d" % i, false)))
			expected.append(bool(flags.get("ash_barracks_cleared", false)))
		"reservoir":
			expected = [bool(flags.get("ash_reservoir_lower", false)), bool(flags.get("ash_reservoir_upper", false))]
			var calibrated := bool(flags.get("ash_reservoir_calibrated", false))
			for i in range(3):
				_check((detail.get_node("Site3/Light%d" % i).color == on) == (calibrated or ops.sequence.has([1, 0, 2][i])), "Calibration diagram differs from live order/reset")
			_check(("CALIBRATED" in detail.get_node("Site3/RouteClue").text) == calibrated, "Calibration caption falsely claims completion")
	for i in range(expected.size()):
		_check((detail.get_node("Site1/Light%d" % i).color == on) == expected[i], "Industry panel disagrees with saved task step")
	var complete := bool(flags.get("ash_%s_field_complete" % ops.course, false))
	var guarded := bool(flags.get("ash_%s_guarded_niche_cleared" % ops.course, false))
	_check(("TASK: DONE" in detail.get_node("Site6/RouteClue").text) == complete, "Reserve board ignores task requirements")
	_check(("GUARDIANS: DONE" in detail.get_node("Site6/RouteClue").text) == guarded, "Reserve board ignores guardians")
	if flags.get("ash_%s_field_return_complete" % ops.course, false):
		_check("returning guardians are quiet" in detail.get_node("FieldGuide").dialogue_lines[0], "Industry guide forgot return victory")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_ash_fields_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player: Player = game.get_node("Player")
	player.set_physics_process(false)
	player.max_health = 10000
	player.current_health = 10000
	for room in ROOMS:
		_check(not game.has_node(room[1] + "/AshSwitchback/FieldOperations"), "Field operations loaded before room entry")
		state.set_current_room(room[0])
		await process_frame
		await physics_frame
		var route := game.get_node(room[1] + "/AshSwitchback")
		var ops := route.get_node("FieldOperations")
		for control in ops.controls:
			_floor(control)
		_floor(ops.get_node("ReturnReward"))
		_check(not route.get_node("IdentityRewardCache").open(player), "Unguarded/unfinished cache paid out")
		ops.get_node("ReturnEncounter")._on_body_entered(player)
		_check(not ops.get_node("ReturnEncounter").triggered, "Awakened trial started on first clear")
		_check_industry_cues(route)
	var forge := game.get_node("CinderForge/AshSwitchback/FieldOperations")
	state.set_current_room("ash_forge")
	for index in range(2):
		_floor(forge.get_node("ServiceArrival%d" % index))
		_floor(forge.get_node("ServiceHoist%d" % index))
	_press(forge.get_node("ServiceHoist0"), player)
	_check(not root.get_node("RoomTransition").is_transitioning, "Unrepaired service hoist allowed travel")
	_press(forge.controls[0], player)
	_check(not forge.completed, "One repair enabled service hoist")
	state.set_current_room("ash_barracks")
	var barracks := game.get_node("EmberBarracks/AshSwitchback")
	for index in range(4):
		_floor(barracks.get_node("DrillTarget%d" % index))
	for index in range(2):
		barracks.get_node("DrillTarget%d" % index).take_damage(10)
	state.set_current_room("ash_reservoir")
	var reservoir := game.get_node("SlagReservoir/AshSwitchback/FieldOperations")
	_press(reservoir.controls[1], player)
	_check(reservoir.sequence.is_empty(), "Calibration bypassed original valves")
	_check_industry_cues(reservoir.route)
	game.get_node("SlagReservoir/LowerValve").activate(player)
	game.get_node("SlagReservoir/UpperValve").activate(player)
	_press(reservoir.controls[1], player)
	_press(reservoir.controls[2], player)
	_check(reservoir.sequence.is_empty() and not reservoir.controls[1].is_active, "Wrong pressure order did not reset partial sequence")
	_check_industry_cues(reservoir.route)
	_press(reservoir.controls[1], player)
	_check(reservoir.sequence == [1], "Correct first pressure station not recorded")
	for room in ROOMS:
		_check_industry_cues(game.get_node(room[1] + "/AshSwitchback"))
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "ash_fields", "Ash Fields", "ash_reservoir"), "Partial Ash progress could not save")
	state.set_current_room("ash_forge")
	_press(forge.controls[1], player)
	_check(not forge.completed, "Repairs bypassed cooling fan")
	game.get_node("CinderForge/CoolingFan").activate(player)
	_check(forge.completed, "Cooling and repairs did not restore hoist")
	for enemy in get_nodes_in_group("enemy"):
		if enemy is Node2D and enemy.has_method("die"):
			for index in range(2):
				if enemy.global_position.distance_to(forge.get_node("ServiceHoist%d" % index).global_position) < 170:
					enemy.die()
	for index in range(2):
		_press(forge.get_node("ServiceHoist%d" % index), player)
		await create_timer(0.5).timeout
		player.set_physics_process(false)
		_check(player.global_position.distance_to(forge.get_node("ServiceArrival%d" % (1 - index)).global_position) < 45 and state.current_room_id == "ash_forge", "Service hoist failed two-way travel")
	state.set_current_room("ash_barracks")
	for index in range(2, 4):
		barracks.get_node("DrillTarget%d" % index).take_damage(10)
	_check(not barracks.get_node("FieldOperations").completed, "Drill targets bypassed beacon trial")
	state.unlock_shortcut("ash_barracks_cleared")
	state.set_current_room("ash_reservoir")
	_press(reservoir.controls[0], player)
	_press(reservoir.controls[2], player)
	_check(reservoir.completed, "Pressure order failed to complete task")
	for room in ROOMS:
		state.set_current_room(room[0])
		await process_frame
		var route := game.get_node(room[1] + "/AshSwitchback")
		var ops := route.get_node("FieldOperations")
		_check(ops.completed and not route.get_node("IdentityRewardCache").open(player), "Field task bypassed upper guardians")
		_check_industry_cues(route)
		await _win(route.get_node("GuardedNicheAmbush"), player)
		_check(route.get_node("IdentityRewardCache").open(player) and not route.get_node("IdentityRewardCache").open(player), "Guarded discovery cache not earned exactly once")
	state.set_zone_tier("ashen_bastion", 1)
	for room in ROOMS:
		state.set_current_room(room[0])
		await process_frame
		var ops := game.get_node(room[1] + "/AshSwitchback/FieldOperations")
		var trial = ops.get_node("ReturnEncounter")
		trial._on_body_entered(player)
		await process_frame
		_check(trial.spawned_enemies.size() == 2, "Awakened Ash patrol missing")
		trial.spawned_enemies[0].die()
		_check(not ops.get_node("ReturnReward").open(player), "Only one defeat released reserve")
		trial.spawned_enemies[1].die()
		_check(ops.get_node("ReturnReward").open(player) and not ops.get_node("ReturnReward").open(player), "Return reserve paid incorrectly")
		_check_industry_cues(ops.route)
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Partial Ash save could not reload")
	game = _world()
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	player.max_health = 10000
	player.current_health = 10000
	state.set_zone_tier("ashen_bastion", 1)
	for room in ROOMS:
		state.set_current_room(room[0])
		await process_frame
		var route := game.get_node(room[1] + "/AshSwitchback")
		var ops := route.get_node("FieldOperations")
		_check(not ops.completed and not route.get_node("IdentityRewardCache").opened and not ops.get_node("ReturnReward").opened, "Unsaved reward/task survived rollback")
		ops.get_node("ReturnEncounter")._on_body_entered(player)
		_check(not ops.get_node("ReturnEncounter").triggered, "Awakening bypassed unfinished task")
		_check_industry_cues(route)
		match ops.course:
			"forge":
				_check(ops.controls[0].is_active and not ops.controls[1].is_active, "Partial hoist repairs not restored")
				_press(ops.controls[1], player)
				game.get_node("CinderForge/CoolingFan").activate(player)
			"barracks":
				_check(not route.has_node("DrillTarget0") and not route.has_node("DrillTarget1") and route.has_node("DrillTarget2"), "Saved drill targets respawned or unfinished targets disappeared")
				for index in range(2, 4):
					route.get_node("DrillTarget%d" % index).take_damage(10)
				state.unlock_shortcut("ash_barracks_cleared")
			"reservoir":
				_check(ops.sequence.is_empty() and not ops.controls[1].is_active, "Unfinished calibration survived reload")
				for index in [1, 0, 2]:
					_press(ops.controls[index], player)
		await _win(route.get_node("GuardedNicheAmbush"), player)
		route.get_node("IdentityRewardCache").open(player)
		await _win(ops.get_node("ReturnEncounter"), player)
		ops.get_node("ReturnReward").open(player)
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "ash_fields", "Ash Fields", "ash_reservoir"), "Complete Ash progress could not save")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Complete Ash progress could not reload")
	game = _world()
	await process_frame
	for room in ROOMS:
		state.set_current_room(room[0])
		await process_frame
		var route := game.get_node(room[1] + "/AshSwitchback")
		var ops := route.get_node("FieldOperations")
		_check(ops.completed and route.get_node("IdentityRewardCache").opened and ops.get_node("ReturnReward").opened, "Saved Ash completion reset")
		_check_industry_cues(route)
		for trial in [route.get_node("GuardedNicheAmbush"), ops.get_node("ReturnEncounter")]:
			trial._on_body_entered(game.get_node("Player"))
			await process_frame
			_check(trial.completed and trial.spawned_enemies.is_empty(), "Saved Ash guardians respawned")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("ASH FIELD OPERATIONS TEST PASSED")
		quit(0)
	else:
		print("ASH FIELD OPERATIONS TEST FAILED: ", failures)
		quit(1)
