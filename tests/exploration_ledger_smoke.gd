extends SceneTree

const LEDGER := preload("res://ExplorationLedger.gd")
var failures: Array[String] = []
var reentrant_awards := 0


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


func _cache(game: Node, id: String) -> Area2D:
	for node in game.find_children("*", "Area2D", true, false):
		if node.get_script() == preload("res://ResonanceCache.gd") and node.cache_id == id:
			return node
	return null


func _reenter(_id: String, cache: Area2D, player: Player) -> void:
	if cache.open(player):
		reentrant_awards += 1


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_exploration_ledger_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player: Player = game.get_node("Player")
	player.set_physics_process(false)
	player.max_health = 10000
	player.current_health = 10000
	_check(LEDGER.journal(state).is_empty(), "Journal reveals unvisited routes")
	_check(LEDGER.bonus("unrelated_cache").is_empty(), "Unrelated cache gained field supplies")
	var seen := {}
	for route in LEDGER.ROUTES:
		var id := LEDGER.cache_id(route)
		_check(not seen.has(id), "Duplicate route receipt: " + id)
		seen[id] = true
		_check(state.ITEM_DEFINITIONS.has(route[6]) and int(route[7]) > 0, "Invalid authored supply: " + id)
		state.set_current_room(str(route[0]))
		await process_frame
		var cache := _cache(game, id)
		_check(cache != null, "No real streamed reserve for " + id)
		if cache == null:
			continue
		_check(cache.required_event_ids.has(LEDGER.completion_id(route)), "Ledger has wrong completion receipt: " + id)
		var journal := LEDGER.journal(state)
		_check(str(route[4]) in journal and str(route[5]) in journal, "Current route lacks authored clues: " + id)
		_check(str(route[8]) not in journal, "Dispatch revealed before collection")
		_check(LEDGER.return_status(state, route).begins_with("AFTER "), "First-visit boss lock missing: " + id)
		_check(not cache.open(player), "Locked reserve opened: " + id)
		# Isolate lifecycle states, without defeating enemies or advancing quests.
		if route[2] == "starfall":
			state.defeated_bosses["hollow_sovereign"] = true
		else:
			state.zone_tiers[route[2]] = 1
		if route[2] != "sunken_shaft":
			_check(LEDGER.return_status(state, route) == "FINISH LOCAL TASK", "Missing task not shown: " + id)
			state.unlock_shortcut(str(route[1]) + "_field_complete")
		if route[2] in ["ashen_bastion", "starfall"]:
			_check(LEDGER.return_status(state, route) == "CLEAR RESERVE GUARDS", "Missing guards not shown: " + id)
			state.unlock_shortcut(str(route[1]) + ("_guarded_niche_cleared" if route[2] == "ashen_bastion" else "_niche_cleared"))
		_check(LEDGER.return_status(state, route) == "RETURN ENCOUNTER READY", "Return readiness wrong: " + id)
		_check(not cache.open(player), "Ready encounter bypassed reserve gate: " + id)
		state.unlock_shortcut(LEDGER.completion_id(route))
		_check(LEDGER.return_status(state, route) == "COLLECT RESERVE", "Unclaimed reserve confused with collected: " + id)
		player.is_dead = true
		_check(not cache.open(player) and not bool(state.opened_caches.get(id, false)), "Dead player claimed reserve: " + id)
		player.is_dead = false
		var before: Dictionary = state.inventory.duplicate(true)
		var gold_before := int(state.gold)
		var expected: Dictionary = LEDGER.bonus(id)
		if not cache.reward_item_id.is_empty():
			expected[cache.reward_item_id] = int(expected.get(cache.reward_item_id, 0)) + 1
		expected["healing_herb"] = int(expected.get("healing_herb", 0)) + 1
		var callback := _reenter.bind(cache, player)
		state.cache_opened.connect(callback)
		_check(cache.open(player) and not cache.open(player), "Reserve not awarded exactly once: " + id)
		state.cache_opened.disconnect(callback)
		_check(reentrant_awards == 0, "Reentry duplicated reward: " + id)
		_check(state.gold == gold_before + cache.gold_reward, "Base gold changed: " + id)
		for item in expected:
			_check(int(state.inventory.get(item, 0)) == int(before.get(item, 0)) + int(expected[item]), "Supply count wrong: " + id + "/" + str(item))
		_check(LEDGER.return_status(state, route) == "CLAIMED", "Claimed receipt not shown: " + id)
		_check(str(route[8]) in game.get_node("UI").quest_tracker_label.text, "Live journal did not show dispatch: " + id)
		# Reset only boss/tier fixture for the next route's first-visit assertion.
		state.defeated_bosses.erase("hollow_sovereign")
		state.zone_tiers[route[2]] = 0
	_check(seen.size() == 26, "Expected 26 optional routes across four regions")
	var final_inventory: Dictionary = state.inventory.duplicate(true)
	var final_gold := int(state.gold)
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "ledger_test", "Ledger Test", state.current_room_id), "Ledger checkpoint save failed")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Ledger save did not reload")
	game = _world()
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	for route in LEDGER.ROUTES:
		state.set_current_room(str(route[0]))
		await process_frame
		var cache := _cache(game, LEDGER.cache_id(route))
		_check(cache != null and cache.opened and not cache.open(player), "Saved reserve paid again: " + str(route[0]))
		_check(LEDGER.return_status(state, route) == "CLAIMED", "Saved receipt lost: " + str(route[0]))
	state.set_current_room("training_passage")
	var archived := LEDGER.journal(state)
	for route in LEDGER.ROUTES:
		_check(str(route[8]) in archived, "Recovered dispatch unavailable outside its room: " + str(route[0]))
	_check(state.inventory.size() == final_inventory.size() and state.gold == final_gold, "Reload changed item kinds or gold")
	for item in final_inventory:
		_check(int(state.inventory.get(item, 0)) == int(final_inventory[item]), "Reload changed saved supply count: " + str(item))
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("TEST PASSED: 26 regional exploration routes, supplies, journal and saved receipts")
	quit(0 if failures.is_empty() else 1)
