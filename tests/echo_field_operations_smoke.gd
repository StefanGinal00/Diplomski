extends SceneTree

const CASES := [["echo_tide_well", "TideWell/LongTraversal"], ["echo_nest", "EchoNest/LongTraversal"], ["echo_causeway", "CrystalCauseway/LongTraversal"], ["echo_vault", "UndertowVault/LongTraversal"], ["echo_depths", "EchoDepths"]]
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


func _floor(node: Node2D, player: Player) -> void:
	var query := PhysicsRayQueryParameters2D.create(node.global_position + Vector2(0, 5), node.global_position + Vector2(0, 60), 1)
	var excluded: Array[RID] = [player.get_rid()]
	for enemy in get_nodes_in_group("enemy"):
		if enemy is CollisionObject2D:
			excluded.append(enemy.get_rid())
	query.exclude = excluded
	var hit := node.get_world_2d().direct_space_state.intersect_ray(query)
	_check(not hit.is_empty() and hit.get("collider") is StaticBody2D, "Unsupported objective: " + String(node.get_path()))


func _station(ops: Node, index: int, player: Player) -> void:
	if ops.route_id == "nest":
		var trial = ops.get_node("Nursery%d" % index)
		trial._on_body_entered(player)
		await process_frame
		_check(trial.spawned_enemies.size() == 2, "Nursery should spawn two guardians")
		for enemy in trial.spawned_enemies:
			_check(not enemy.counts_for_nest and not enemy.is_in_group("nest_brood"), "Optional brood contaminated main NestVeil")
			_floor(enemy, player)
			enemy.die()
	elif ops.route_id == "depths":
		var post = ops.controls[index]
		for enemy in get_nodes_in_group("enemy"):
			if enemy is Node2D and enemy.has_method("die") and enemy.global_position.distance_to(post.global_position) < 180:
				enemy.die()
		player.global_position = post.global_position
		post._on_body_entered(player)
		_check(post.begin_listening(), "Depths signal could not be recorded")
		post._process(1.3)
		post._on_body_exited(player)
	else:
		var control = ops.controls[index]
		player.global_position = control.global_position
		control._on_body_entered(player)
		var event := InputEventAction.new()
		event.action = "interact"
		event.pressed = true
		control._unhandled_input(event)
		_check(control.is_active and not control.activate(player), "Control failed or activated twice")
		control._on_body_exited(player)


func _effects(ops: Node, first: bool, second: bool) -> void:
	for index in range(2):
		var active := first if index == 0 else second
		match ops.route_id:
			"tide":
				for offset in range(2):
					_check(ops.route.get_node("RisingCurrent%02d" % (index * 2 + offset)).calmed == active, "Tide current state does not match its regulator")
			"causeway":
				for offset in range(2):
					var bridge = ops.route.get_node("TraversalPhaseBridge%02d" % (index * 2 + offset))
					_check(bridge.stabilized == active, "Causeway bridge state not restored")
					if active:
						bridge._process(100)
						_check(bridge.phase == "solid", "Stabilized bridge vanished")
			"vault":
				_check(ops.route.get_node("UndertowCurrent%02d" % index).calmed == active, "Vault current state not restored")
			"depths":
				_check(ops.controls[index].attuned == active, "Depths recorded signal state not restored")
			"nest":
				_check(ops.get_node("Nursery%d" % index).completed == active, "Nursery completion state not restored")


func _cache(route: Node) -> Node:
	return route.get_node("RimCache" if route.name == "EchoDepths" else "RouteDiscoveryCache")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_operations_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player: Player = game.get_node("Player")
	player.set_physics_process(false)
	player.max_health = 10000
	player.current_health = 10000
	for entry in CASES:
		_check(not game.has_node(entry[1] + "/FieldOperations"), "Unvisited operations loaded eagerly")
		state.set_current_room(entry[0])
		await process_frame
		await physics_frame
		var route := game.get_node(entry[1])
		var ops := route.get_node("FieldOperations")
		for control in ops.controls:
			_floor(control, player)
		_floor(ops.get_node("ReturnReward"), player)
		_check(not _cache(route).open(player), "Discovery cache opened before its field task")
		ops.get_node("ReturnEncounter")._on_body_entered(player)
		_check(not ops.get_node("ReturnEncounter").triggered, "Return trial started before awakening")
		await _station(ops, 0, player)
		_check(not ops.completed, "One station completed both-station task")
		_effects(ops, true, false)
	_check(not game.get_node("EchoNest/NestVeil").is_open, "Optional nursery opened the original NestVeil")
	_check(not bool(state.unlocked_shortcuts.get("echo_causeway_anchor", false)), "Optional anchors bypassed main Causeway puzzle")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "operations_test", "Operations Test", "echo_depths"), "Partial operations could not save")
	for entry in CASES:
		state.set_current_room(entry[0])
		await process_frame
		var route := game.get_node(entry[1])
		var ops := route.get_node("FieldOperations")
		await _station(ops, 1, player)
		if ops.route_id == "vault":
			_check(not ops.completed and not _cache(route).open(player), "Vault drains bypassed original seals")
			game.get_node("UndertowVault/UpperSeal").activate(player)
			_check(not ops.completed, "Only one vault seal completed task")
			game.get_node("UndertowVault/FarSeal").activate(player)
		_check(ops.completed and _cache(route).open(player) and not _cache(route).open(player), "First-clear reward not earned exactly once: " + entry[0])
		_effects(ops, true, true)
	state.set_zone_tier("echo_grotto", 1)
	for entry in CASES:
		state.set_current_room(entry[0])
		await process_frame
		var ops := game.get_node(entry[1] + "/FieldOperations")
		var trial = ops.get_node("ReturnEncounter")
		trial._on_body_entered(player)
		await process_frame
		_check(trial.spawned_enemies.size() == 2, "Return trial did not spawn both foes")
		trial.spawned_enemies[0].die()
		_check(not ops.get_node("ReturnReward").open(player), "Return reserve opened after only one defeat")
		trial.spawned_enemies[1].die()
		_check(trial.completed and ops.get_node("ReturnReward").open(player) and not ops.get_node("ReturnReward").open(player), "Return reward not earned exactly once")
	state.set_current_room("echo_haven")
	await process_frame
	var board: Label = game.get_node("EchoHaven/NewDistricts/DiscoveryBoard").board
	_check("RECORDS 5/8" in board.text, "Haven board missed new field tasks")
	_check(board.get_minimum_size().x <= 380 and board.get_minimum_size().y <= 140, "Expanded board text overflows its panel")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Partial operations snapshot could not load")
	game = _world()
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	player.max_health = 10000
	player.current_health = 10000
	state.set_zone_tier("echo_grotto", 1)
	for entry in CASES:
		state.set_current_room(entry[0])
		await process_frame
		var route := game.get_node(entry[1])
		var ops := route.get_node("FieldOperations")
		_effects(ops, true, false)
		_check(not ops.completed and not _cache(route).opened and not ops.get_node("ReturnReward").opened, "Unsaved task/reward survived rollback")
		var trial = ops.get_node("ReturnEncounter")
		trial._on_body_entered(player)
		_check(not trial.triggered, "Awakening bypassed incomplete field task")
		await _station(ops, 1, player)
		if ops.route_id == "vault":
			game.get_node("UndertowVault/UpperSeal").activate(player)
			game.get_node("UndertowVault/FarSeal").activate(player)
		_cache(route).open(player)
		trial._on_body_entered(player)
		await process_frame
		for enemy in trial.spawned_enemies:
			enemy.die()
		ops.get_node("ReturnReward").open(player)
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "operations_test", "Operations Test", "echo_depths"), "Completed operations could not save")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Completed operations could not load")
	game = _world()
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	for entry in CASES:
		state.set_current_room(entry[0])
		await process_frame
		var route := game.get_node(entry[1])
		var ops := route.get_node("FieldOperations")
		_effects(ops, true, true)
		var trial = ops.get_node("ReturnEncounter")
		trial._on_body_entered(player)
		await process_frame
		_check(ops.completed and trial.completed and trial.spawned_enemies.is_empty() and _cache(route).opened and ops.get_node("ReturnReward").opened, "Saved task, encounter or rewards reset")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("ECHO FIELD OPERATIONS TEST PASSED")
		quit(0)
	else:
		print("ECHO FIELD OPERATIONS TEST FAILED: ", failures)
		quit(1)
