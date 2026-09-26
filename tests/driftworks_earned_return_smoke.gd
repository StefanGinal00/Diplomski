extends "res://tests/driftworks_live_route_pilot.gd"

# Two live stages with saved, earned progress. Awakening itself is an explicit
# fixture, NOT a Warden defeat. One entrance placement per stage, real shop
# handlers without merchant travel, no health refill or synthetic skill points.
var returning := false
var old_cache_checks := 0


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_driftworks_earned_return_save.json"
	await _run_driftworks()


func _branch_destinations(branch: int) -> Array:
	var paths := super._branch_destinations(branch)
	if returning and branch == 3:
		paths.append("Infrastructure/ReturnTrial")
		paths.append("Infrastructure/ReturnReward")
	return paths


func _after_completed_route(game: Node) -> Node:
	var state := root.get_node("GameState")
	ui = game.get_node("UI")
	var earned_points: int = player.skill_points
	var earned_gold: int = state.gold
	var entry_health: int = player.current_health
	_check(earned_points >= 2 and earned_gold >= 36, "First visit did not earn return preparation")
	if not failures.is_empty():
		return game
	ui._on_sword_mastery_pressed()
	ui._on_sword_reach_pressed()
	_check(player.sword_mastery_unlocked and player.sword_reach_unlocked and player.skill_points == earned_points - 2, "Sword skills did not spend exactly two earned points")
	state.set_zone_tier("sunken_shaft", 1)
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "", "Driftworks earned return fixture", "shaft_drift"), "Return preparation snapshot failed")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Return preparation snapshot could not load")
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	room = game.get_node("ShaftDriftworks")
	ui = game.get_node("UI")
	_check(state.get_zone_tier("sunken_shaft") == 1 and state.gold == earned_gold, "Saved return tier/money changed")
	_check(player.max_health == 5 and player.current_health == entry_health and not player.double_jump_unlocked and not player.dash_unlocked, "Return setup changed health or movement")
	_check(player.sword_mastery_unlocked and player.sword_reach_unlocked and player.skill_points == earned_points - 2, "Earned sword skills did not persist")
	_check(not room.get_node("Infrastructure/ReturnTrial").completed and not room.get_node("Infrastructure/ReturnReward").opened, "New return objective started completed")
	var carried_herbs: int = state.inventory.get("healing_herb", 0)
	ui._open_shop(game.get_node("WayfarerMerchant"))
	for purchase in range(2):
		ui.selected_shop_item_id = "healing_herb"
		ui._on_shop_buy_pressed()
	ui._close_shop()
	_check(state.gold == earned_gold - 36 and state.inventory.get("healing_herb", 0) == carried_herbs + 2, "Return herbs were not bought with earned Gold")
	if not failures.is_empty():
		return game
	defeats = 0
	neutral_defeats = 0
	herbs_used = 0
	herbs_found = 0
	cache_herbs = 0
	hazard_waits = 0
	links_walked = 0
	branches_visited = 0
	flank_direction = 0.0
	approach_floor_top = NAN
	health_trace.clear()
	supplies_trace.clear()
	returning = true
	state.item_acquired.connect(_track_supplies)
	for enemy in get_nodes_in_group("enemy"):
		_watch_foe(enemy)
	for index in range(7):
		room.get_node("QuietGrazer%d" % index).defeated.connect(func(): neutral_defeats += 1)
	node_added.connect(_watch_foe)
	player.health_changed.connect(_trace_health)
	player.global_position = room.get_node("Entry").global_position
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	for frame in range(12):
		await physics_frame
	var started := Engine.get_physics_frames()
	var ok := await _expedition()
	_check(ok and not player.is_dead and player.current_health > 0 and player.max_health == 5, "Earned Driftworks return failed at ordinary health")
	_check(links_walked == 7 and branches_visited == 4 and defeats >= 12, "Return route/combat coverage incomplete")
	_check(room.get_node("Infrastructure/ReturnTrial").completed and room.get_node("Infrastructure/ReturnReward").opened, "New return trial/reward was skipped")
	_check(old_cache_checks == 3 and cache_herbs == 1, "Old caches paid again or new guaranteed herb was missed")
	_check(herbs_used <= 2 + cache_herbs and state.inventory.get("healing_herb", 0) == carried_herbs + 2 + herbs_found - herbs_used, "Return relied on carried/random healing or lost inventory")
	print("DRIFTWORKS EARNED RETURN: base earned ", earned_points, " points / ", earned_gold, " Gold; spent 2 points and 36 earned Gold; entered ", entry_health, "/5 HP, finished ", player.current_health, "/5 HP, ", defeats, " enemy / ", neutral_defeats, " fauna defeats, ", herbs_used, " herbs used, ", cache_herbs, " new guaranteed herb; ", (Engine.get_physics_frames() - started) / 60.0, " physics seconds")
	_release()
	if failures.is_empty():
		var final_points: int = player.skill_points
		game = await _save_and_exit(game)
		_check(player.sword_mastery_unlocked and player.sword_reach_unlocked and player.skill_points == final_points, "Completed return lost earned skill progress")
		_check(room.get_node("Infrastructure/ReturnTrial").completed, "Completed return trial reset after reload")
		var reserve := room.get_node("Infrastructure/ReturnReward")
		var gold: int = state.gold
		var inventory: Dictionary = state.inventory.duplicate(true)
		_check(reserve.opened and not reserve.open(player), "Return reserve paid again after reload")
		_check(state.gold == gold and state.inventory == inventory, "Return reserve duplicated saved supplies")
	return game


func _interact(object: Area2D) -> void:
	if returning and object == room.get_node("Infrastructure/ReturnTrial"):
		# Its encounter starts through the real proximity trigger, not E. Finish
		# every guardian even if knockback carried one beyond the local scan.
		for attempt in range(4):
			if object.completed:
				break
			for enemy in object.spawned_enemies:
				if is_instance_valid(enemy) and not enemy.is_dead:
					if not await _corridor(room._branch_rect(3).end.y, room.to_local(enemy.global_position).x):
						return
		_check(object.triggered and object.completed and object.spawned_enemies.size() == 3, "Three awakened engine guardians were not physically cleared")
		return
	if returning and object.get_script() == preload("res://ResonanceCache.gd") and object.opened:
		var state := root.get_node("GameState")
		var gold: int = state.gold
		var inventory: Dictionary = state.inventory.duplicate(true)
		await super._interact(object)
		_check(state.gold == gold and state.inventory == inventory, "Claimed base cache paid out on awakened revisit")
		old_cache_checks += 1
	else:
		await super._interact(object)
