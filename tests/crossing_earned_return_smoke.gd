extends "res://tests/crossing_live_route_pilot.gd"

# Saved earned-build return after the real base run. Awakening is explicitly
# configured, NOT a Warden victory. Each stage has one entrance placement.
# Shopping uses real UI handlers but no physical merchant journey.
var returning := false
var old_cache_checks := 0


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_crossing_earned_return_save.json"
	await _run_crossing()


func _after_completed_route(game: Node) -> Node:
	var state := root.get_node("GameState")
	ui = game.get_node("UI")
	var earned_points: int = player.skill_points
	var earned_gold: int = state.gold
	var entry_hp: int = player.current_health
	_check(earned_points >= 2 and earned_gold >= 54, "Base Crossing did not earn return preparation")
	if not failures.is_empty():
		return game
	ui._on_sword_mastery_pressed()
	ui._on_sword_reach_pressed()
	_check(player.sword_mastery_unlocked and player.sword_reach_unlocked and player.skill_points == earned_points - 2, "Sword skills did not cost two earned points")
	state.set_zone_tier("sunken_shaft", 1)
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "", "Crossing earned return fixture", "shaft_crossing"), "Return preparation snapshot failed")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Return preparation snapshot could not load")
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	room = game.get_node("DrownedCrossing")
	ui = game.get_node("UI")
	_check(state.get_zone_tier("sunken_shaft") == 1 and state.gold == earned_gold, "Saved tier/money changed")
	_check(player.max_health == 5 and player.current_health == entry_hp and not player.double_jump_unlocked and not player.dash_unlocked, "Return changed health or movement abilities")
	_check(player.sword_mastery_unlocked and player.sword_reach_unlocked and player.skill_points == earned_points - 2, "Earned sword skills did not persist")
	_check(room.get_node("Valve").is_active, "Saved valve reset on return")
	for current in room.find_children("CrossingCurrent*", "Area2D", true, false):
		_check(current.disabled, "Saved currents restarted on awakening")
	var sites := _route_geometry().get_node("ExplorationSites")
	_check(not sites.get_node("AwakenedTrial").completed and not sites.get_node("AwakenedTrialReward").opened, "New return objective started completed")
	var carried_herbs: int = state.inventory.get("healing_herb", 0)
	ui._open_shop(game.get_node("WayfarerMerchant"))
	for purchase in range(3):
		ui.selected_shop_item_id = "healing_herb"
		ui._on_shop_buy_pressed()
	ui._close_shop()
	_check(state.gold == earned_gold - 54 and state.inventory.get("healing_herb", 0) == carried_herbs + 3, "Three return herbs were not purchased with earned Gold")
	if not failures.is_empty():
		return game
	defeats = 0
	herbs_used = 0
	herbs_found = 0
	cache_herbs = 0
	hazard_waits = 0
	legs = 0
	excursions = 0
	flank_direction = 0.0
	approach_floor_top = NAN
	health_trace.clear()
	supplies_trace.clear()
	returning = true
	purchased_herb_allowance = 3
	awakened_fixture = true
	state.item_acquired.connect(_track_supplies)
	for enemy in get_nodes_in_group("enemy"):
		_watch_foe(enemy)
	node_added.connect(_watch_foe)
	player.health_changed.connect(_trace_health)
	player.global_position = room.get_node("ShaftEntry").global_position
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	for frame in range(12):
		await physics_frame
	var started := Engine.get_physics_frames()
	var ok := await _crossing_route()
	_check(ok and not player.is_dead and player.current_health > 0 and player.max_health == 5, "Earned Crossing return failed at normal health")
	_check(legs == 6 and excursions == 5 and defeats >= 12, "Return route/combat coverage incomplete")
	_check(sites.get_node("AwakenedTrial").completed and sites.get_node("AwakenedTrialReward").opened, "New return trial/reward skipped")
	_check(old_cache_checks == 2 and cache_herbs == 1, "Old rewards paid again or new guaranteed herb missing")
	_check(herbs_used <= 3 + cache_herbs and state.inventory.get("healing_herb", 0) == carried_herbs + 3 + herbs_found - herbs_used, "Return healing depended on carried/random items or lost supplies")
	print("CROSSING EARNED RETURN: base earned ", earned_points, " points / ", earned_gold, " Gold; spent 2 points and 54 earned Gold on three herbs; entered ", entry_hp, "/5 HP, finished ", player.current_health, "/5 HP, ", defeats, " enemy defeats, ", herbs_used, " herbs used, ", cache_herbs, " guaranteed herb; ", (Engine.get_physics_frames() - started) / 60.0, " physics seconds")
	_release()
	if failures.is_empty():
		var final_points: int = player.skill_points
		game = await _save_crossing_exit(game)
		_check(player.sword_mastery_unlocked and player.sword_reach_unlocked and player.skill_points == final_points, "Completed return lost skill progress")
		sites = _route_geometry().get_node("ExplorationSites")
		_check(sites.get_node("AwakenedTrial").completed, "Completed trial reset after saving")
		var gold: int = state.gold
		var inventory: Dictionary = state.inventory.duplicate(true)
		var reserve := sites.get_node("AwakenedTrialReward")
		_check(reserve.opened and not reserve.open(player), "Return reserve paid again after reload")
		_check(state.gold == gold and state.inventory == inventory, "Return reserve duplicated supplies")
	return game


func _side_objective(route: Node2D, tier: int, kind: String) -> bool:
	if returning and kind == "Branch" and tier == 5:
		var trial := route.get_node("ExplorationSites/AwakenedTrial")
		for attempt in range(4):
			if trial.completed:
				break
			for enemy in trial.spawned_enemies:
				if is_instance_valid(enemy) and not enemy.is_dead:
					if not await _walk_on_floor(enemy.global_position.x, "Hollow/side-destination-clear"):
						return false
		_check(trial.triggered and trial.completed and trial.spawned_enemies.size() == 2, "Two sediment wisps were not physically cleared")
	return await super._side_objective(route, tier, kind)


func _interact(object: Area2D) -> void:
	if returning and object.get_script() == preload("res://ResonanceCache.gd") and object.opened:
		_release()
		for frame in range(3):
			await physics_frame
		var state := root.get_node("GameState")
		var gold: int = state.gold
		var inventory: Dictionary = state.inventory.duplicate(true)
		# Compare around the synchronous input only. Ordinary loot may arrive
		# during the settling frames; that is not a repeat cache payout.
		_press_interaction(object)
		_check(state.gold == gold and state.inventory == inventory, "Claimed base cache paid on awakened revisit")
		old_cache_checks += 1
	else:
		await super._interact(object)
