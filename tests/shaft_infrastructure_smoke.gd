extends SceneTree

var failures: Array[String] = []
const HUB := "VerticalChamber/DeepShaftTraversal/Infrastructure"
const DRIFT := "ShaftDriftworks/Infrastructure"


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


func _check_floor(at: Node2D) -> void:
	var query := PhysicsRayQueryParameters2D.create(at.global_position + Vector2(0, 5), at.global_position + Vector2(0, 55), 1)
	query.collide_with_areas = false
	var hit := at.get_world_2d().direct_space_state.intersect_ray(query)
	_check(not hit.is_empty() and hit.get("collider") is StaticBody2D, "%s is not supported by a floor" % at.get_path())


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_shaft_infrastructure_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	_check(not game.has_node(HUB) and not game.has_node(DRIFT), "Unvisited machinery sites loaded eagerly")
	_check(not game.has_node("VerticalChamber/DeepShaftTraversal/DeepPatrol00_00") and not game.has_node("ShaftDriftworks/SupplyCrate0"), "Unvisited hub or expedition population loaded eagerly")
	var player = game.get_node("Player")
	player.max_health = 1000
	player.current_health = 1000
	state.set_current_room("sunken_shaft")
	await physics_frame
	await process_frame
	var hub = game.get_node(HUB)
	for name in ["CableWinch", "Counterweight", "RepairReward", "ReturnReward", "HoistArrival0", "HoistArrival1", "RepairedHoist0", "RepairedHoist1"]:
		_check_floor(hub.get_node(name))
	# A working lift still respects combat safety. Clear its nearby patrols
	# before checking the independent repair gate and two-way transport.
	for enemy in get_nodes_in_group("enemy"):
		if enemy is Node2D and enemy.has_method("die"):
			for terminal_name in ["RepairedHoist0", "RepairedHoist1"]:
				if enemy.global_position.distance_to(hub.get_node(terminal_name).global_position) < 160.0:
					enemy.die()
	await process_frame
	var lift = hub.get_node("RepairedHoist0")
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	player.global_position = lift.global_position
	player.velocity = Vector2.ZERO
	lift.player_in_range = player
	lift._unhandled_input(event)
	_check(not root.get_node("RoomTransition").is_transitioning and not bool(state.unlocked_shortcuts.get(hub.repair_event, false)), "Unrepaired hoist allowed travel or self-activated")
	_check(not hub.get_node("RepairReward").open(player), "Repair reserve opened before restoration")
	hub.get_node("CableWinch").activate(player)
	_check(not bool(state.unlocked_shortcuts.get(hub.repair_event, false)), "One mechanism repaired the entire hoist")
	hub.get_node("Counterweight").activate(player)
	_check(bool(state.unlocked_shortcuts.get(hub.repair_event, false)) and "[E] REPAIRED HOIST" == lift.prompt.text, "Both mechanisms did not restore the hoist")
	_check(hub.get_node("RepairReward").open(player) and not hub.get_node("RepairReward").open(player), "Repair reserve did not pay exactly once")
	for direction in range(2):
		var terminal = hub.get_node("RepairedHoist%d" % direction)
		player.global_position = terminal.global_position
		player.velocity = Vector2.ZERO
		terminal.player_in_range = player
		terminal._unhandled_input(event)
		await create_timer(0.5).timeout
		_check(player.global_position.distance_to(hub.get_node("HoistArrival%d" % (1 - direction)).global_position) < 45.0 and state.current_room_id == "sunken_shaft", "Repaired hoist did not travel in direction %d" % direction)
	var trial = hub.get_node("ReturnTrial")
	trial._on_body_entered(player)
	await process_frame
	_check(not trial.triggered, "Hub return encounter triggered before awakening")
	state.set_current_room("shaft_drift")
	await physics_frame
	await process_frame
	var drift = game.get_node(DRIFT)
	for name in ["IntakePump", "CrownPump", "RepairReward", "ReturnReward"]:
		_check_floor(drift.get_node(name))
	_check(not drift.get_node("PressureLeak0").disabled and not drift.get_node("PressureLeak1").disabled, "Unrepaired pressure leaks started disabled")
	state.set_zone_tier("sunken_shaft", 1)
	drift.get_node("ReturnTrial")._on_body_entered(player)
	await process_frame
	_check(not drift.get_node("ReturnTrial").triggered, "Awakening bypassed required machinery repairs")
	drift.get_node("IntakePump").activate(player)
	_check(drift.get_node("PressureLeak0").disabled and not drift.get_node("PressureLeak1").disabled, "Intake pump did not independently stop its leak")
	_check(not drift.get_node("RepairReward").open(player), "One pump released the two-pump reward")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "infrastructure_test", "Infrastructure Test", "shaft_drift"), "Partial pump progress could not save")
	drift.get_node("CrownPump").activate(player)
	_check(drift.get_node("PressureLeak1").disabled and drift.get_node("RepairReward").open(player), "Both pumps did not stop pressure and open reserve")
	for path in [HUB, DRIFT]:
		state.set_current_room("sunken_shaft" if path == HUB else "shaft_drift")
		var site = game.get_node(path)
		var encounter = site.get_node("ReturnTrial")
		encounter._on_body_entered(player)
		await process_frame
		_check(encounter.spawned_enemies.size() == (2 if path == HUB else 3), "Wrong machinery return encounter composition")
		encounter.spawned_enemies[0].die()
		_check(not site.get_node("ReturnReward").open(player), "Return reward opened with guardians still alive")
		for index in range(1, encounter.spawned_enemies.size()):
			encounter.spawned_enemies[index].die()
		_check(site.get_node("ReturnReward").open(player) and not site.get_node("ReturnReward").open(player), "Return reserve did not open exactly once after victory")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Partial pump snapshot failed to load")
	game = _world()
	await process_frame
	player = game.get_node("Player")
	drift = game.get_node(DRIFT)
	_check(drift.get_node("IntakePump").is_active and not drift.get_node("CrownPump").is_active, "Partial repair snapshot did not restore exactly")
	_check(drift.get_node("PressureLeak0").disabled and not drift.get_node("PressureLeak1").disabled, "Pressure hazards did not follow snapshot rollback")
	_check(not drift.get_node("RepairReward").opened and not drift.get_node("ReturnTrial").completed and not drift.get_node("ReturnReward").opened, "Unsaved machinery rewards survived rollback")
	drift.get_node("CrownPump").activate(player)
	var encounter = drift.get_node("ReturnTrial")
	encounter._on_body_entered(player)
	await process_frame
	for enemy in encounter.spawned_enemies:
		enemy.die()
	_check(drift.get_node("ReturnReward").open(player), "Return reserve could not be earned after rollback")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "infrastructure_test", "Infrastructure Test", "shaft_drift"), "Completed machinery challenge could not save")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Completed machinery save failed to load")
	game = _world()
	await process_frame
	drift = game.get_node(DRIFT)
	encounter = drift.get_node("ReturnTrial")
	encounter._on_body_entered(game.get_node("Player"))
	await process_frame
	_check(encounter.completed and encounter.spawned_enemies.is_empty() and drift.get_node("ReturnReward").opened, "Completed return trial or reward reset after loading")
	var population_count := game.get_node("ShaftDriftworks").get_child_count()
	state.set_current_room("training_passage")
	state.set_current_room("shaft_drift")
	_check(game.get_node("ShaftDriftworks").get_child_count() == population_count, "Re-entry duplicated expedition population")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("SHAFT INFRASTRUCTURE TEST PASSED")
		quit(0)
	else:
		print("SHAFT INFRASTRUCTURE TEST FAILED: ", failures)
		quit(1)
