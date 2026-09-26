extends "res://tests/starfall_spawn_restore_smoke.gd"

const DETAILS := [
	["sunken_shaft", "VerticalChamber", "DeepShaftTraversal/FieldDressing", 5, 3, 2],
	["echo_grotto", "EchoGrotto", "LongTraversal/FieldDressing", 9, 4, 2],
]


func _details(game: Node, entry: Array) -> Node2D:
	return game.get_node(entry[1] + "/" + entry[2])


func _freeze(room: Node) -> void:
	super._freeze(room)
	for fauna in get_nodes_in_group("neutral_creature"):
		if room.is_ancestor_of(fauna):
			fauna.set_physics_process(false)


func _clear_salvage(detail: Node2D, player: Player) -> void:
	var trial := detail.get_node("SalvageEncounter")
	var cache := detail.get_node("SalvageCache")
	_check(not cache.open(player), "Salvage opened without its guardians")
	trial._on_body_entered(player)
	await process_frame
	_check(trial.spawned_enemies.size() == 2, "Salvage did not create two guardians")
	for enemy in trial.spawned_enemies:
		enemy.set_physics_process(false)
		enemy.set_process(false)
	_floor(trial.spawned_enemies[0])
	trial.spawned_enemies[0].die()
	_check(not cache.open(player), "Salvage ignored its second guardian")
	trial.spawned_enemies[1].die()
	_check(cache.open(player) and not cache.open(player), "Salvage payout is missing or repeatable")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_route_field_dressing_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player: Player = game.get_node("Player")
	player.set_physics_process(false)
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "field_content_test", "Field Content", "training_passage"), "Could not save pre-salvage snapshot")
	for entry in DETAILS:
		var detail := _details(game, entry)
		_check(not detail.population_loaded and not detail.has_node("FieldGuide") and not detail.has_node("SalvageEncounter"), "Unvisited field population loaded early")
		for index in range(entry[3]):
			var site := detail.get_node("Site%d" % index)
			_check(site.position.distance_to(detail.PREVIEW_ANCHORS[detail.region][index]) < 0.02, "Editor field landmark no longer matches the live floor anchor")
			_check(site.get_child_count() >= 3, "Missing local scenery")
			_check(site.find_children("*", "CollisionObject2D", true, false).is_empty(), "Field scenery added invisible collision")
		state.set_current_room(entry[0])
		_freeze(game.get_node(entry[1]))
		await physics_frame
		var crates: Array[Node] = []
		var fauna: Array[Node] = []
		for node in detail.get_children():
			if node.is_in_group("breakable"):
				crates.append(node)
				_floor(node)
				_check(node.empty_drop_chance > 0 and node.max_gold <= 4, "Ambient supply economy is too generous")
			elif node.is_in_group("neutral_creature"):
				fauna.append(node)
				_floor(node)
				_check(not node.is_hostile, "Field fauna is hostile by default")
		_check(crates.size() == entry[4] and fauna.size() == entry[5], "Wrong authored field population count")
		var guide := detail.get_node("FieldGuide")
		_floor(guide)
		for marker in guide.route_markers:
			_floor(marker)
		_check(guide.interaction_requested.is_connected(Callable(game.get_node("UI"), "_on_npc_interaction_requested")), "Field guide dialogue is disconnected")
		_floor(detail.get_node("SalvageCache"))
		for door in game.get_node(entry[1]).find_children("*", "Area2D", true, false):
			if door.get_script() == load("res://RoomDoor.gd"):
				_check(door.global_position.distance_to(detail.get_node("SalvageCache").global_position) > 110, "Salvage cache crowds a room doorway")
		# Every ground guardian uses a supported, margin-protected spawn.
		var nearest := INF
		for enemy in get_nodes_in_group("enemy"):
			if game.get_node(entry[1]).is_ancestor_of(enemy):
				nearest = minf(nearest, guide.global_position.distance_to(enemy.global_position))
		_check(nearest > 170, "Field guide spawned inside a hostile patrol")
		var guide_id := guide.get_instance_id()
		var damaged_path := detail.get_path_to(crates[0])
		var broken_path := detail.get_path_to(crates[1])
		var fauna_path := detail.get_path_to(fauna[0])
		crates[0].current_health = 1
		crates[1].empty_drop_chance = 1.0
		crates[1].take_damage(10)
		fauna[0].take_damage(1)
		var moved: Vector2 = fauna[0].position + Vector2(8, 0)
		fauna[0].position = moved
		await process_frame
		state.set_current_room("training_passage")
		_check(not guide.can_process(), "Field NPC is active outside its room")
		game.get_node("WorldPopulation").unload_room_population(entry[1])
		await process_frame
		_check(not detail.has_node(damaged_path) and not detail.has_node(fauna_path), "Field props/fauna did not unload")
		state.set_current_room(entry[0])
		_freeze(game.get_node(entry[1]))
		await process_frame
		_check(detail.get_node(damaged_path).current_health == 1 and not detail.has_node(broken_path), "Reload healed supplies or respawned broken loot")
		_check(detail.get_node(fauna_path).is_hostile and detail.get_node(fauna_path).position.is_equal_approx(moved), "Reload reset fauna state")
		_check(detail.get_node("FieldGuide").get_instance_id() == guide_id, "Reload duplicated the field guide")
		await _clear_salvage(detail, player)
		_check(not state.unlocked_shortcuts.get("shaft_hoist_repair_complete", false) and not state.unlocked_shortcuts.get("echo_grotto_field_complete", false), "Salvage bypassed the original field objective")
		state.set_zone_tier(entry[0], 1)
		_check(not detail.get_node("SalvageCache").open(player), "Awakening refilled claimed salvage")
	_check(state.load_game(), "Pre-salvage snapshot did not load")
	game.queue_free()
	await process_frame
	game = _world()
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	for entry in DETAILS:
		state.set_current_room(entry[0])
		_freeze(game.get_node(entry[1]))
		await physics_frame
		var detail := _details(game, entry)
		_check(not detail.get_node("SalvageEncounter").completed and not detail.get_node("SalvageCache").opened, "Unsaved salvage survived lamp rollback")
		await _clear_salvage(detail, player)
	state.set_current_room("training_passage")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), Vector2(120, 0), "field_content_test", "Field Content", "training_passage"), "Completed salvage did not save")
	_check(state.load_game(), "Completed salvage did not load")
	game.queue_free()
	await process_frame
	game = _world()
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	for entry in DETAILS:
		state.set_current_room(entry[0])
		var detail := _details(game, entry)
		var trial := detail.get_node("SalvageEncounter")
		trial._on_body_entered(player)
		await process_frame
		_check(trial.completed and trial.spawned_enemies.is_empty() and detail.get_node("SalvageCache").opened, "Saved salvage completion reset")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("ROUTE FIELD DRESSING TEST PASSED: 14 sites, 7 supplies, 4 fauna, 2 guides, 2 guarded caches")
		quit(0)
	else:
		print("ROUTE FIELD DRESSING TEST FAILED: ", failures)
		quit(1)
