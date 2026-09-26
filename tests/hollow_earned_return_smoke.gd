extends "res://tests/hollow_live_route_pilot.gd"

# Two connected-room stages, NOT a campaign/Warden playthrough. The first
# earns every upgrade and the return's shopping money in live base combat.
# Only awakening itself is an explicit fixture. Each stage has one entrance
# placement; no in-route teleports, stat injection or forced enemy deaths.
var returning := false
var claimed_checks := 0


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_hollow_earned_return_save.json"
	diagnostic_health = 5
	awakened_fixture = false
	await _run_route()


func _after_completed_route(game: Node) -> Node:
	var state := root.get_node("GameState")
	player.set_physics_process(false)
	var earned_points: int = player.skill_points
	var earned_gold: int = state.gold
	var saved_health: int = player.current_health
	_check(earned_points >= 2 and earned_gold >= 36, "Base route did not earn the return preparation")
	if not failures.is_empty():
		return game
	ui._on_sword_mastery_pressed()
	ui._on_sword_reach_pressed()
	_check(player.sword_mastery_unlocked and player.sword_reach_unlocked and player.skill_points == earned_points - 2, "Real skill purchases did not spend exactly two earned points")
	# Snapshot preserves current health; no lamp/rest healing or extra money.
	state.set_zone_tier("sunken_shaft", 1)
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "", "Earned return fixture", "shaft_hollow"), "Earned return save failed")
	state.item_acquired.disconnect(_track_supplies)
	node_added.disconnect(_watch_foe)
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Earned return save could not load")
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	ui = game.get_node("UI")
	room = game.get_node("ShaftHollow")
	_check(player.max_health == 5 and player.current_health == saved_health, "Save/reload changed ordinary health")
	_check(player.sword_mastery_unlocked and player.sword_reach_unlocked and player.skill_points == earned_points - 2, "Earned skills did not survive reload")
	_check(state.gold == earned_gold and state.get_zone_tier("sunken_shaft") == 1, "Saved return preparation changed")
	var carried_herbs: int = state.inventory.get("healing_herb", 0)
	ui._open_shop(game.get_node("WayfarerMerchant"))
	for purchase in range(2):
		ui.selected_shop_item_id = "healing_herb"
		ui._on_shop_buy_pressed()
	ui._close_shop()
	_check(state.gold == earned_gold - 36 and state.inventory.get("healing_herb", 0) == carried_herbs + 2, "Return supplies were not bought with earned gold")
	var entry_herbs: int = state.inventory.get("healing_herb", 0)
	var route := room.get_node("ExpandedRoute/AuthoredDescent")
	_check(route.get_node("HiddenDepthCache").opened and route.get_node("ExplorationSites/OreSurvey/SurveyReward").opened, "First-clear rewards reset on return")
	_check(not route.get_node("ExplorationSites/AwakenedTrialReward").opened, "New return reward already claimed")
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
	awakened_fixture = true
	returning = true
	state.item_acquired.connect(_track_supplies)
	for node in get_nodes_in_group("enemy"):
		if room.is_ancestor_of(node):
			_watch_foe(node)
	node_added.connect(_watch_foe)
	player.health_changed.connect(_trace_health)
	var ok := await _traverse(room)
	_check(ok and not player.is_dead and player.current_health > 0 and player.max_health == 5, "Earned-build awakened route failed at ordinary health")
	_check(route.get_node("ExplorationSites/AwakenedTrialReward").opened, "New return trial was not physically completed")
	_check(claimed_checks >= 2, "Old cache payouts were not rechecked through interaction")
	_check(defeats >= 10 and hazard_waits > 0, "Return did not exercise live combat/hazards")
	_check(herbs_used <= 2 + cache_herbs, "Return depended on carried/random healing supplies")
	_check(state.inventory.get("healing_herb", 0) == entry_herbs + herbs_found - herbs_used, "Return supply ledger does not reconcile")
	print("EARNED RETURN: base earned ", earned_points, " skill points / ", earned_gold, " Gold; spent two points on sword mastery/reach, 36 earned Gold on two herbs; entered ", saved_health, "/5 HP; ended ", player.current_health, "/5 HP, ", defeats, " defeats, ", herbs_used, " herbs used, ", cache_herbs, " new guaranteed cache herbs; ", claimed_checks, " claimed-cache interactions without payout")
	_release()
	if not failures.is_empty():
		return game
	_check(cache_herbs == 1, "Return awarded more than its one new guaranteed cache herb")
	player.set_physics_process(false)
	var return_health: int = player.current_health
	var return_gold: int = state.gold
	var return_inventory: Dictionary = state.inventory.duplicate(true)
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "", "Completed return fixture", "shaft_hollow"), "Completed return save failed")
	state.item_acquired.disconnect(_track_supplies)
	node_added.disconnect(_watch_foe)
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Completed return save could not load")
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	room = game.get_node("ShaftHollow")
	route = room.get_node("ExpandedRoute/AuthoredDescent")
	_check(player.current_health == return_health and player.max_health == 5, "Completed return reload changed health")
	_check(route.get_node("ExplorationSites/OreSurvey").recorded_count() == 3, "Completed survey was lost after return save")
	_check(route.get_node("ExplorationSites/AwakenedTrial").completed, "Completed return encounter reset after saving")
	for cache_path in ["HiddenDepthCache", "ExplorationSites/OreSurvey/SurveyReward", "ExplorationSites/AwakenedTrialReward"]:
		var cache := route.get_node(cache_path)
		_check(cache.opened and not cache.open(player), "Completed cache paid out after reload: " + cache_path)
	_check(state.gold == return_gold and _same_item_counts(state.inventory, return_inventory), "Completed return reload duplicated/lost supplies: Gold %d -> %d; inventory %s -> %s" % [return_gold, state.gold, return_inventory, state.inventory])
	if failures.is_empty():
		print("EARNED RETURN SAVE: health, inventory, survey, completed trial and all three claimed caches preserved without duplicate payouts")
	return game


func _same_item_counts(actual: Dictionary, expected: Dictionary) -> bool:
	# JSON restores numbers as floats; compare every item/quantity, not Variant
	# storage types. Do not truncate fractional values or ignore unexpected keys.
	if actual.size() != expected.size():
		return false
	for item_id in expected:
		if not actual.has(item_id) or float(actual[item_id]) != float(expected[item_id]):
			return false
	return true


func _record(object: Area2D) -> bool:
	if not returning or object.get_script() != preload("res://ResonanceCache.gd") or not object.opened:
		return await super._record(object)
	# Compare exactly around interaction, excluding loot earned while walking.
	if not await _walk_on_floor(object.global_position.x, "Hollow/claimed-cache"):
		return false
	var state := root.get_node("GameState")
	var before_gold: int = state.gold
	var before_inventory: Dictionary = state.inventory.duplicate(true)
	await _interact(object)
	_check(state.gold == before_gold and state.inventory == before_inventory, "Claimed first-clear cache paid out again")
	claimed_checks += 1
	return true
