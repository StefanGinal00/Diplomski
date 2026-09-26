extends "res://tests/gallery_live_route_pilot.gd"

# Crossing -> Gallery with earned skills, then saved awakened Gallery return.
# Awakening is a tier fixture, not an earned Warden victory. No health refill.
var old_cache_checks := 0


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_gallery_earned_return_save.json"
	earned_arrival = true
	await _run_crossing()


func _after_gallery_completed(game: Node) -> Node:
	var state := root.get_node("GameState")
	var hp: int = player.current_health
	var points: int = player.skill_points
	var gold: int = state.gold
	var carried: int = state.inventory.get("healing_herb", 0)
	_check(gold >= 54, "Gallery did not earn three return herbs")
	state.set_zone_tier("sunken_shaft", 1)
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "", "Gallery awakened fixture", "shaft_gallery"), "Gallery tier snapshot failed")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Gallery tier snapshot failed to load")
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	room = game.get_node("FloodedGallery")
	ui = game.get_node("UI")
	_check(player.current_health == hp and player.max_health == 5 and player.skill_points == points and player.sword_mastery_unlocked and player.sword_reach_unlocked, "Gallery return altered earned health/build")
	_check(not player.double_jump_unlocked and not player.dash_unlocked and state.get_zone_tier("sunken_shaft") == 1, "Gallery return fixture changed movement/tier")
	_check(room.get_node("LowerControl").is_active and room.get_node("UpperControl").is_active, "Gallery return reset controls")
	for hazard in _route_hazards():
		_check(hazard.disabled, "Gallery return restarted repaired pressure")
	var sites := _route_geometry().get_node("ExplorationSites")
	_check(not sites.get_node("AwakenedTrial").completed and not sites.get_node("AwakenedTrialReward").opened, "New Gallery return trial started completed")
	ui._open_shop(game.get_node("WayfarerMerchant"))
	for purchase in range(3):
		ui.selected_shop_item_id = "healing_herb"
		ui._on_shop_buy_pressed()
	ui._close_shop()
	_check(state.gold == gold - 54 and state.inventory.get("healing_herb", 0) == carried + 3, "Gallery return supplies were not purchased with earned Gold")
	if not failures.is_empty():
		return game
	returning_gallery = true
	awakened_fixture = true
	purchased_herb_allowance = 3
	defeats = 0
	herbs_used = 0
	herbs_found = 0
	cache_herbs = 0
	legs = 0
	excursions = 0
	flank_direction = 0.0
	approach_floor_top = NAN
	health_trace.clear()
	supplies_trace.clear()
	state.item_acquired.connect(_track_supplies)
	node_added.connect(_watch_foe)
	for enemy in get_nodes_in_group("enemy"):
		_watch_foe(enemy)
	player.health_changed.connect(_trace_health)
	# Explicit single entrance placement for the return stage, not mid-route.
	player.global_position = room.get_node("CrossingEntry").global_position
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	for frame in range(12):
		await physics_frame
	print("GALLERY RETURN PREPARATION: preserved ", hp, "/5 HP and earned sword skills; three herbs for 54 earned Gold")
	await _verify_gallery_route(carried)
	_check(old_cache_checks == 2 and cache_herbs == 2, "Old Gallery cache paid again or new reserve supplies missing")
	_check(sites.get_node("AwakenedTrial").completed and sites.get_node("AwakenedTrialReward").opened, "Gallery return trial/reward incomplete")
	if failures.is_empty():
		game = await _save_gallery_exit(game)
		sites = _route_geometry().get_node("ExplorationSites")
		gold = state.gold
		var inventory: Dictionary = state.inventory.duplicate(true)
		var reward := sites.get_node("AwakenedTrialReward")
		_check(sites.get_node("AwakenedTrial").completed and reward.opened and not reward.open(player), "Saved Gallery trial/reward reset")
		_check(state.gold == gold and state.inventory == inventory, "Gallery return reward duplicated saved supplies")
	if failures.is_empty():
		print("GALLERY EARNED RETURN TEST PASSED: saved controls/build, two real guardians, new reserve, old-cache refusal, connected route and final save")
	return game


func _side_objective(route: Node2D, tier: int, kind: String) -> bool:
	if returning_gallery and kind == "Branch" and tier == 5:
		var trial := route.get_node("ExplorationSites/AwakenedTrial")
		for attempt in range(4):
			if trial.completed:
				break
			for enemy in trial.spawned_enemies:
				if is_instance_valid(enemy) and not enemy.is_dead:
					if not await _walk_on_floor(enemy.global_position.x, "Hollow/side-destination-clear"):
						return false
		_check(trial.triggered and trial.completed and trial.spawned_enemies.size() == 2, "Two inspection guardians were not physically cleared")
	return await super._side_objective(route, tier, kind)


func _interact(object: Area2D) -> void:
	if returning_gallery and object.get_script() == preload("res://ResonanceCache.gd") and object.opened:
		_release()
		for frame in range(3):
			await physics_frame
		var state := root.get_node("GameState")
		var gold: int = state.gold
		var inventory: Dictionary = state.inventory.duplicate(true)
		_press_interaction(object)
		_check(state.gold == gold and state.inventory == inventory, "Claimed Gallery cache paid on revisit")
		old_cache_checks += 1
	else:
		await super._interact(object)
