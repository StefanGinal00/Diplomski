extends "res://tests/echo_room_dressing_smoke.gd"

const CROSSING_ROOMS := [["echo_causeway", "CrystalCauseway", "causeway", 6], ["echo_vault", "UndertowVault", "vault", 4]]


func _cues(detail: Node2D, first: bool, second: bool, upper: bool = false, far: bool = false) -> void:
	var expected := [first, second, upper, far]
	for i in range(2):
		var site := detail.get_node("Site%d" % (1 if i == 0 else 5))
		if detail.region == "causeway":
			_check(site.get_node("StableTether").visible == expected[i] and site.get_node("BrokenTether").visible != expected[i], "Tether disagrees with anchor")
			for offset in range(2):
				_check(detail.get_parent().get_node("TraversalPhaseBridge%02d" % (i * 2 + offset)).stabilized == expected[i], "Tether disagrees with actual bridge")
		else:
			_check(is_equal_approx(site.get_node("ChannelWater").scale.y, 0.25 if expected[i] else 1), "Channel display disagrees with drain")
			_check(detail.get_parent().get_node("UndertowCurrent%02d" % i).calmed == expected[i], "Display disagrees with actual current")
	if detail.region == "vault":
		for i in range(4):
			_check((detail.get_node("Site3/StatusLamp%d" % i).color.g > 0.9) == expected[i], "Vault table lost a drain/seal state")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_crossing_dressing_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player: Player = game.get_node("Player")
	player.set_physics_process(false)
	player.max_health = 10000
	player.current_health = 10000
	for entry in CROSSING_ROOMS:
		var detail := game.get_node(entry[1] + "/LongTraversal/FieldDressing")
		_check(not detail.population_loaded and not detail.has_node("FieldGuide"), "Crossing actors loaded before entry")
		detail = _enter(game, entry)
		await physics_frame
		_check(detail.CROSSING_ANCHORS[entry[2]].size() == 9, "Missing crossing preview anchors")
		for i in range(9):
			var site := detail.get_node("Site%d" % i)
			_check(site.get_child_count() >= 3 and site.find_children("*", "CollisionObject2D", true, false).is_empty(), "Empty or collidable scenery")
			_check(site.position.distance_to(detail.CROSSING_ANCHORS[entry[2]][i]) < 0.02, "Crossing editor/live drift")
		var crates: Array[Node] = []
		var fauna: Array[Node] = []
		for actor in detail.get_children():
			if actor.is_in_group("breakable"):
				crates.append(actor)
				_floor(actor)
				_check(actor.max_gold == 4 and actor.empty_drop_chance == 0.55, "Supply economy changed")
			elif actor.is_in_group("neutral_creature"):
				fauna.append(actor)
				_floor(actor)
				_check(not actor.is_hostile, "Fauna starts hostile")
		_check(crates.size() == entry[3] and fauna.size() == 2, "Wrong crossing population")
		var guide := detail.get_node("FieldGuide")
		_floor(guide)
		for marker in guide.route_markers:
			_floor(marker)
		_check(guide.interaction_requested.is_connected(Callable(game.get_node("UI"), "_on_npc_interaction_requested")), "Guide not connected to dialogue UI")
		var nearest := INF
		for enemy in get_nodes_in_group("enemy"):
			if game.get_node(entry[1]).is_ancestor_of(enemy):
				nearest = minf(nearest, guide.global_position.distance_to(enemy.global_position))
		_check(nearest > 170, "Guide crowds hostile spawn")
		var guide_id := guide.get_instance_id()
		var damaged := detail.get_path_to(crates[0])
		var broken := detail.get_path_to(crates[1])
		var fauna_path := detail.get_path_to(fauna[0])
		crates[0].current_health = 1
		crates[1].empty_drop_chance = 1
		crates[1].take_damage(10)
		fauna[0].take_damage(1)
		var moved: Vector2 = fauna[0].position + Vector2(8, 0)
		fauna[0].position = moved
		await process_frame
		state.set_current_room("training_passage")
		_check(not guide.can_process(), "Off-room guide remains active")
		game.get_node("WorldPopulation").unload_room_population(entry[1])
		await process_frame
		_check(not detail.has_node(damaged) and not detail.has_node(fauna_path), "Crossing population did not unload")
		detail = _enter(game, entry)
		await process_frame
		_check(detail.get_node(damaged).current_health == 1 and not detail.has_node(broken), "Streaming reset supply state")
		_check(detail.get_node(fauna_path).is_hostile and detail.get_node(fauna_path).position.is_equal_approx(moved), "Streaming reset fauna state")
		_check(detail.get_node("FieldGuide").get_instance_id() == guide_id, "Re-entry duplicated guide")
		_cues(detail, false, false)
		_check(not detail.has_node("SalvageCache") and not detail.get_parent().get_node("RouteDiscoveryCache").open(player), "Dressing bypassed the original task")
		_check(detail.get_parent().get_node("FieldOperations").controls[0].activate(player), "First side control failed")
		if entry[2] == "vault":
			_check(game.get_node("UndertowVault/UpperSeal").activate(player), "Upper seal failed")
		_cues(detail, true, false, entry[2] == "vault", false)
		_check("1/2" in guide.dialogue_lines[0], "Guide missed partial progress")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), Vector2(120, 0), "crossing_test", "Crossing Test", "training_passage"), "Partial crossing save failed")
	for entry in CROSSING_ROOMS:
		var detail := _enter(game, entry)
		detail.get_parent().get_node("FieldOperations").controls[1].activate(player)
		if entry[2] == "vault":
			_cues(detail, true, true, true, false)
			_check(not detail.get_parent().get_node("RouteDiscoveryCache").open(player), "Both drains bypassed a missing seal")
			game.get_node("UndertowVault/FarSeal").activate(player)
		else:
			_check(not game.get_node("CrystalCauseway/TideLoopDoor")._requirements_met(), "Side anchors bypassed main anchor")
		_cues(detail, true, true, true, true)
		_check("unsealed" in detail.get_node("FieldGuide").dialogue_lines[0], "Guide missed discovery reward")
		_check(detail.get_parent().get_node("RouteDiscoveryCache").open(player), "Discovery reward did not unlock")
	_check(state.load_game(), "Partial crossing snapshot did not load")
	game.queue_free()
	await process_frame
	game = _world()
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	state.set_zone_tier("echo_grotto", 1)
	for entry in CROSSING_ROOMS:
		var detail := _enter(game, entry)
		_cues(detail, true, false, entry[2] == "vault", false)
		_check("1/2" in detail.get_node("FieldGuide").dialogue_lines[0], "Unsaved crossing completion survived rollback")
		var ops := detail.get_parent().get_node("FieldOperations")
		var trial := ops.get_node("ReturnEncounter")
		trial._on_body_entered(player)
		_check(not trial.triggered, "Awakening bypassed incomplete tasks")
		if entry[2] == "vault":
			game.get_node("UndertowVault/FarSeal").activate(player)
			_cues(detail, true, false, true, true)
			_check(not detail.get_parent().get_node("RouteDiscoveryCache").open(player), "Both seals bypassed a missing drain")
			_check(game.get_node("UndertowVault/VaultCache").open(player), "Original two-seal reliquary acquired extra drain requirement")
		else:
			_check(not game.get_node("CrystalCauseway/TideLoopDoor")._requirements_met(), "Main anchor state changed")
			game.get_node("CrystalCauseway/Anchor").activate(player)
			_check(game.get_node("CrystalCauseway/TideLoopDoor")._requirements_met(), "Main anchor no longer opens Tide loop")
			_check("opened the Tide loop" in " ".join(detail.get_node("FieldGuide").dialogue_lines), "Guide missed separate main anchor")
		ops.controls[1].activate(player)
		_check("return trial" in detail.get_node("FieldGuide").dialogue_lines[0], "Guide missed awakened task")
		trial._on_body_entered(player)
		await process_frame
		_check(trial.spawned_enemies.size() == 2, "Return trial lost guardians")
		for enemy in trial.spawned_enemies:
			enemy.die()
		_check("quiet" in detail.get_node("FieldGuide").dialogue_lines[0], "Guide missed return victory")
		for cache in [ops.get_node("ReturnReward"), detail.get_parent().get_node("RouteDiscoveryCache")]:
			_check(cache.open(player) and not cache.open(player), "Reward did not pay exactly once")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), Vector2(120, 0), "crossing_test", "Crossing Test", "training_passage"), "Completed crossing save failed")
	_check(state.load_game(), "Completed crossing snapshot did not load")
	game.queue_free()
	await process_frame
	game = _world()
	await process_frame
	for entry in CROSSING_ROOMS:
		var detail := _enter(game, entry)
		_cues(detail, true, true, true, true)
		_check("quiet" in detail.get_node("FieldGuide").dialogue_lines[0], "Saved crossing guide progress reset")
		_check(detail.get_parent().get_node("RouteDiscoveryCache").opened and detail.get_parent().get_node("FieldOperations/ReturnReward").opened, "Saved rewards refilled")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("ECHO CROSSING DRESSING TEST PASSED: 18 sites, 10 supplies, 4 fauna, 2 guides; independent gates, streaming and lamp snapshots")
		quit(0)
	else:
		print("ECHO CROSSING DRESSING TEST FAILED: ", failures)
		quit(1)
