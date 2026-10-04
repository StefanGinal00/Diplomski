extends "res://tests/story_lifecycle_smoke.gd"

func _break_empty(game: Node, state: Node, path: String) -> void:
	var crate: Node = game.get_node(path)
	crate.empty_drop_chance = 1.0
	crate.take_damage(999)
	crate.take_damage(999)
	_check(state.destroyed_props.get(path, false), "Destruction not tracked: " + path)

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_prop_checkpoint.json"
	state.start_new_game("normal")
	var game: Node = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	_break_empty(game, state, "CratePassage")
	var specs := [["echo_grotto", "EchoGrotto"], ["shaft_hollow", "ShaftHollow"], ["ash_causeway", "BrokenCauseway"], ["starfall_outskirts", "StarfallOutskirts"]]
	var destroyed: Array[String] = ["CratePassage"]
	for spec in specs:
		state.set_current_room(spec[0])
		await process_frame
		var room: Node = game.get_node(spec[1])
		var candidates := room.find_children("*", "StaticBody2D", true, false).filter(func(node: Node): return node.is_in_group("breakable"))
		_check(candidates.size() >= 2, "Missing room crate coverage: " + spec[1])
		# Break all loaded crates in each biome, including curated/authored/generated.
		for crate in candidates:
			var path: String = str(game.get_path_to(crate))
			destroyed.append(path)
			_break_empty(game, state, path)
		state.set_current_room("training_passage")
		game.get_node("WorldPopulation").unload_room_population(spec[1])
		await process_frame
	# A real nonempty drop is collected once before saving alongside its receipt.
	var loot_crate: Node = game.get_node("CrateGate")
	loot_crate.empty_drop_chance = 0.0
	loot_crate.item_drop_chance = 0.0
	loot_crate.min_gold = 7
	loot_crate.max_gold = 7
	loot_crate.take_damage(999)
	destroyed.append("CrateGate")
	await process_frame
	var drops := get_nodes_in_group("gold_pickup")
	_check(drops.size() == 1, "Crate drop duplicated or missing")
	for drop in drops: drop._on_body_entered(game.get_node("Player"))
	await process_frame
	_check(state.gold == 7, "Crate reward was not collected once")
	var player: Node = game.get_node("Player")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position), "Prop checkpoint failed")
	var saved: Dictionary = state.destroyed_props.duplicate(true)
	_break_empty(game, state, "CrateArena") # Deliberately after checkpoint.
	player.die()
	var old_id := game.get_instance_id()
	game.get_node("UI").restart_button.pressed.emit()
	game = await _after_reload(old_id)
	if game == null: quit(1); return
	_check(state.destroyed_props == saved and state.gold == 7, "Prop/reward rollback mixed save states")
	_check(game.has_node("CrateArena"), "Unsaved destruction survived death")
	_check(not game.has_node("CratePassage") and not game.has_node("CrateGate"), "Static crate respawned")
	for spec in specs:
		state.set_current_room(spec[0])
		await process_frame
		await process_frame
		for path in destroyed:
			if path.begins_with(spec[1] + "/"):
				_check(not game.has_node(path), "Saved crate respawned: " + path)
		state.set_current_room("training_passage")
		game.get_node("WorldPopulation").unload_room_population(spec[1])
		await process_frame
		state.set_current_room(spec[0])
		await process_frame
		await process_frame
		for path in destroyed:
			if path.begins_with(spec[1] + "/"):
				_check(not game.has_node(path), "Repeated streaming respawned crate: " + path)
	_check(get_nodes_in_group("gold_pickup").is_empty(), "Restore rerolled a crate's loot")
	_check(state.gold == 7, "Restore replayed a crate's reward")
	_break_empty(game, state, "CrateArena")
	_check(state.save_at_checkpoint(game.get_node("Player"), game.get_node("QuestManager"), Vector2.ZERO), "Second prop checkpoint failed")
	var corrupt := FileAccess.open(state.save_path, FileAccess.WRITE)
	corrupt.store_string("invalid isolated test save")
	corrupt.close()
	_check(state.load_game() and state.last_load_used_backup and state.destroyed_props == saved, "Backup did not replace prop ledger")
	var legacy: Dictionary = state._build_save_data().duplicate(true)
	legacy.erase("destroyed_props")
	state._apply_save_data(legacy)
	_check(state.destroyed_props.is_empty(), "Legacy save reused another session's props")
	state.destroyed_props["fixture"] = true
	state.start_new_game("normal")
	_check(state.destroyed_props.is_empty(), "New game retained prop destruction")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("PROP CHECKPOINT TEST PASSED: ", destroyed.size(), " crates across four biomes and the passage")
		quit(0)
	else:
		print("PROP CHECKPOINT TEST FAILED: ", failures)
		quit(1)
