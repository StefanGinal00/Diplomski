extends "res://tests/echo_room_dressing_smoke.gd"

const HABITAT_ROOMS := [["echo_tide_well", "TideWell", "tide", 13, 9, 3], ["echo_nest", "EchoNest", "nest", 9, 6, 2]]


func _station(detail: Node2D, index: int, player: Player) -> void:
	var ops := detail.get_parent().get_node("FieldOperations")
	if detail.region == "tide":
		_check(ops.controls[index].activate(player), "Regulator failed to activate")
	else:
		var trial := ops.get_node("Nursery%d" % index)
		trial._on_body_entered(player)
		await process_frame
		_check(trial.spawned_enemies.size() == 2, "Side nursery lost its two guardians")
		for enemy in trial.spawned_enemies:
			_check(not enemy.counts_for_nest, "Optional brood bypasses main Nest Veil")
			enemy.die()


func _cues(detail: Node2D, first: bool, second: bool) -> void:
	for i in range(2):
		var active := first if i == 0 else second
		var index := (3 if i == 0 else 9) if detail.region == "tide" else (1 if i == 0 else 5)
		var site := detail.get_node("Site%d" % index)
		if detail.region == "tide":
			_check((site.get_node("GaugeNeedle").points[1].x < 0) == active, "Gauge disagrees with regulator")
			for offset in range(2):
				_check(detail.get_parent().get_node("RisingCurrent%02d" % (i * 2 + offset)).calmed == active, "Gauge disagrees with actual current")
		else:
			_check(site.get_node("SpentSilk").visible == active and site.get_node("DormantPods").visible != active, "Silk chamber disagrees with nursery")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_habitat_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player: Player = game.get_node("Player")
	player.set_physics_process(false)
	player.max_health = 10000
	player.current_health = 10000
	for entry in HABITAT_ROOMS:
		var detail := game.get_node(entry[1] + "/LongTraversal/FieldDressing")
		_check(not detail.population_loaded and not detail.has_node("FieldGuide"), "Habitat actors loaded before entry")
		detail = _enter(game, entry)
		await physics_frame
		_check(detail.HABITAT_ANCHORS[entry[2]].size() == entry[3], "Habitat preview anchors missing")
		for i in range(entry[3]):
			var site := detail.get_node("Site%d" % i)
			_check(site.get_child_count() >= 3 and site.find_children("*", "CollisionObject2D", true, false).is_empty(), "Empty or collidable habitat scenery")
			_check(site.position.distance_to(detail.HABITAT_ANCHORS[entry[2]][i]) < 0.02, "Habitat editor/live positions drifted")
		var crates: Array[Node] = []
		var fauna: Array[Node] = []
		for actor in detail.get_children():
			if actor.is_in_group("breakable"):
				crates.append(actor)
				_floor(actor)
				_check(actor.max_gold == 4 and actor.empty_drop_chance == 0.55, "Ambient supply economy changed")
			elif actor.is_in_group("neutral_creature"):
				fauna.append(actor)
				_floor(actor)
				_check(not actor.is_hostile, "Habitat fauna starts hostile")
		_check(crates.size() == entry[4] and fauna.size() == entry[5], "Incorrect habitat population")
		var guide := detail.get_node("FieldGuide")
		_floor(guide)
		for marker in guide.route_markers:
			_floor(marker)
		_check(guide.interaction_requested.is_connected(Callable(game.get_node("UI"), "_on_npc_interaction_requested")), "Guide missing dialogue UI")
		var nearest := INF
		for enemy in get_nodes_in_group("enemy"):
			if game.get_node(entry[1]).is_ancestor_of(enemy):
				nearest = minf(nearest, guide.global_position.distance_to(enemy.global_position))
		_check(nearest > 170, "Guide crowds a hostile spawn")
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
		_check(not guide.can_process(), "Off-room guide still processing")
		game.get_node("WorldPopulation").unload_room_population(entry[1])
		await process_frame
		_check(not detail.has_node(damaged) and not detail.has_node(fauna_path), "Habitat props did not unload")
		detail = _enter(game, entry)
		await process_frame
		_check(detail.get_node(damaged).current_health == 1 and not detail.has_node(broken), "Supply streaming lost damage/destruction")
		_check(detail.get_node(fauna_path).is_hostile and detail.get_node(fauna_path).position.is_equal_approx(moved), "Fauna streaming lost hostility/movement")
		_check(detail.get_node("FieldGuide").get_instance_id() == guide_id, "Habitat guide duplicated on entry")
		_cues(detail, false, false)
		if entry[2] == "tide":
			for sign in detail.get_parent().get_node("FieldOperations").signs:
				_check("PEARL MARKS" in sign.text and not "FINAL HIDDEN" in sign.text, "Well clue points past the tier-seven reward")
		_check(not detail.has_node("SalvageCache") and not detail.get_parent().get_node("RouteDiscoveryCache").open(player), "Dressing bypassed original objective")
		await _station(detail, 0, player)
		_cues(detail, true, false)
		_check("1/2" in guide.dialogue_lines[0], "Guide missed partial task progress")
	_check(not game.get_node("EchoNest/NestVeil").is_open, "Side nursery unsealed main veil")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), Vector2(120, 0), "habitat_test", "Habitat Test", "training_passage"), "Partial habitat save failed")
	for entry in HABITAT_ROOMS:
		var detail := _enter(game, entry)
		await _station(detail, 1, player)
		_cues(detail, true, true)
		_check("unsealed" in detail.get_node("FieldGuide").dialogue_lines[0], "Guide missed first-clear reward")
		_check(detail.get_parent().get_node("RouteDiscoveryCache").open(player), "Original discovery cache did not unlock")
	_check(state.load_game(), "Partial habitat save failed to load")
	game.queue_free()
	await process_frame
	game = _world()
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	state.set_zone_tier("echo_grotto", 1)
	for entry in HABITAT_ROOMS:
		var detail := _enter(game, entry)
		_cues(detail, true, false)
		_check("1/2" in detail.get_node("FieldGuide").dialogue_lines[0], "Unsaved completion survived rollback")
		var ops := detail.get_parent().get_node("FieldOperations")
		var trial := ops.get_node("ReturnEncounter")
		trial._on_body_entered(player)
		_check(not trial.triggered, "Awakening bypassed incomplete habitat objective")
		await _station(detail, 1, player)
		_check("return trial" in detail.get_node("FieldGuide").dialogue_lines[0], "Guide missed awakened return task")
		trial._on_body_entered(player)
		await process_frame
		_check(trial.spawned_enemies.size() == 2, "Return trial lost guardians")
		for enemy in trial.spawned_enemies:
			enemy.die()
		_check("quiet" in detail.get_node("FieldGuide").dialogue_lines[0], "Guide missed completed return")
		for cache in [ops.get_node("ReturnReward"), detail.get_parent().get_node("RouteDiscoveryCache")]:
			_check(cache.open(player) and not cache.open(player), "Reward did not pay exactly once")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), Vector2(120, 0), "habitat_test", "Habitat Test", "training_passage"), "Completed habitat save failed")
	_check(state.load_game(), "Completed habitat reload failed")
	game.queue_free()
	await process_frame
	game = _world()
	await process_frame
	for entry in HABITAT_ROOMS:
		var detail := _enter(game, entry)
		_cues(detail, true, true)
		_check("quiet" in detail.get_node("FieldGuide").dialogue_lines[0], "Saved guide progress reset")
		_check(detail.get_parent().get_node("RouteDiscoveryCache").opened and detail.get_parent().get_node("FieldOperations/ReturnReward").opened, "Saved habitat rewards refilled")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("ECHO HABITAT DRESSING TEST PASSED: 22 sites, 15 supplies, 5 fauna, 2 guides; task cues, streaming and lamp snapshots")
		quit(0)
	else:
		print("ECHO HABITAT DRESSING TEST FAILED: ", failures)
		quit(1)
