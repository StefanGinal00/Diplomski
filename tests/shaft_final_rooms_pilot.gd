extends "res://tests/gallery_live_route_pilot.gd"

# Actual Crossing/Gallery earnings prepare either remaining Shaft room.
# Approach uses the actual Gallery exit; optional Cistern has one explicit
# entrance placement. No claim of a whole-campaign or boss playthrough.
var final_kind := "approach"
var final_active := false
var final_return := false
var final_old_claims := 0


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_shaft_final_rooms_save.json"
	earned_arrival = true
	await _run_crossing()


func _room_name() -> String:
	return "WardenApproach" if final_kind == "approach" else "BlackwaterCistern"


func _after_gallery_completed(game: Node) -> Node:
	var state := root.get_node("GameState")
	if final_kind == "approach":
		await _interact(room.get_node("WardenShortcutDoor"))
		for frame in range(180):
			await physics_frame
			if not root.get_node("RoomTransition").is_transitioning:
				break
		_check(state.current_room_id == "shaft_approach", "Actual Gallery exit missed Approach")
	else:
		state.set_current_room("shaft_cistern")
		await process_frame
	room = game.get_node(_room_name())
	if final_kind == "cistern":
		player.global_position = room.get_node("CrossingEntry").global_position
		player.velocity = Vector2.ZERO
	final_active = true
	advanced_steering = true
	for stage in range(2):
		if not failures.is_empty():
			break
		final_return = stage == 1
		wildlife_chase_range = (110.0 if final_kind == "approach" else 70.0) if final_return else 0.0
		overhead_wildlife_clearance = 55.0 if final_kind == "approach" and final_return else 28.0
		if final_return:
			var saved_hp: int = player.current_health
			var saved_points: int = player.skill_points
			var saved_inventory: Dictionary = state.inventory.duplicate(true)
			var saved_gold: int = state.gold
			state.set_zone_tier("sunken_shaft", 1)
			_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "", "Final room return fixture", "shaft_" + final_kind), "Final room tier snapshot failed")
			game.queue_free()
			await process_frame
			_check(state.load_game(), "Final room tier snapshot failed to load")
			game = load("res://Game.tscn").instantiate()
			root.add_child(game)
			current_scene = game
			await process_frame
			player = game.get_node("Player")
			player.set_physics_process(false)
			_check(player.current_health == saved_hp and player.skill_points == saved_points and state.inventory == saved_inventory and state.gold == saved_gold, "Final room return snapshot changed health or earned quantities")
			room = game.get_node(_room_name())
			ui = game.get_node("UI")
			player.global_position = room.get_node("GalleryEntry" if final_kind == "approach" else "CrossingEntry").global_position
			player.velocity = Vector2.ZERO
		var hp: int = player.current_health
		var gold: int = state.gold
		var carried: int = state.inventory.get("healing_herb", 0)
		purchased_herb_allowance = 3 if final_return else 2
		_check(player.max_health == 5 and hp > 0 and player.sword_mastery_unlocked and player.sword_reach_unlocked and not player.double_jump_unlocked and not player.dash_unlocked, "Final room lost ordinary earned build")
		ui._open_shop(game.get_node("WayfarerMerchant"))
		for purchase in range(purchased_herb_allowance):
			ui.selected_shop_item_id = "healing_herb"
			ui._on_shop_buy_pressed()
		ui._close_shop()
		_check(state.gold == gold - 18 * purchased_herb_allowance and state.inventory.get("healing_herb", 0) == carried + purchased_herb_allowance, "Final room supplies were not purchased with earned money")
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
		awakened_fixture = final_return
		state.item_acquired.connect(_track_supplies)
		node_added.connect(_watch_foe)
		for enemy in get_nodes_in_group("enemy"):
			_watch_foe(enemy)
		player.health_changed.connect(_trace_health)
		player.set_physics_process(true)
		for frame in range(12):
			await physics_frame
		var started := Engine.get_physics_frames()
		var ok := await _crossing_route()
		if ok and final_kind == "cistern":
			ok = await _cistern_post_pump_rewards()
		_check(ok and not player.is_dead and player.current_health > 0 and player.max_health == 5, "Final room continuous live route failed")
		_check(legs == 6 and excursions == (6 if final_kind == "cistern" and not final_return else 5) and defeats >= 12, "Final room route/combat coverage incomplete")
		_check(herbs_used <= purchased_herb_allowance + cache_herbs and state.inventory.get("healing_herb", 0) == carried + purchased_herb_allowance + herbs_found - herbs_used, "Final room finite supplies mismatch")
		_check(_mechanism_complete(), "Final room mechanism incomplete")
		for path in _cache_paths():
			_check(room.get_node(path).opened, "Final room reward skipped: " + path)
		if final_return:
			var sites := _route_geometry().get_node("ExplorationSites")
			_check(sites.get_node("AwakenedTrial").completed and sites.get_node("AwakenedTrialReward").opened, "Final room awakened trial incomplete")
			_check(final_old_claims == _cache_paths().size(), "Final room old-cache revisit checks incomplete")
		print("FINAL ROOM LIVE: ", final_kind, " tier ", stage, ", ", defeats, " foes, entered ", hp, "/5 HP, ended ", player.current_health, "/5 HP; ", herbs_used, " herbs of ", purchased_herb_allowance, " purchased + ", cache_herbs, " guaranteed; ", (Engine.get_physics_frames() - started) / 60.0, " physics seconds")
		_release()
		if failures.is_empty():
			game = await _save_final_room(game)
	if failures.is_empty():
		print("FINAL ROOM EARNED ROUTE TEST PASSED: ", final_kind, " base and tier-one return, ordinary health, finite supplies, live actors, physical rewards/lifts/exits and save restoration")
	return game


func _route_exit() -> Area2D:
	if not final_active:
		return super._route_exit()
	return room.get_node("ArenaDoor" if final_kind == "approach" else "GalleryShortcutDoor")


func _route_hazards() -> Array[Node]:
	if not final_active:
		return super._route_hazards()
	var result: Array[Node] = []
	if final_kind == "cistern":
		result = room.find_children("CisternPressureWave*", "Area2D", true, false)
		result.append(room.get_node("CisternSurge"))
	return result


func _gallery_objective(source: Node2D, tier: int) -> bool:
	if not final_active:
		return await super._gallery_objective(source, tier)
	var expansion := room.get_node("ExpandedRoute")
	var name := ""
	if final_kind == "approach":
		name = "UpperCache" if tier == 0 else ("CounterweightCrank" if tier == 6 else "")
	else:
		name = "NearDial" if tier == 0 else ("HighDial" if tier == 1 else ("FarDial" if tier == 6 else ""))
	if name.is_empty():
		return true
	var target: Area2D = room.get_node(name)
	if not await _approach(_route_geometry(), expansion._chamber_rect(tier).end.y, target.position.x):
		return false
	await _interact(target)
	if final_kind == "cistern":
		_check(room.puzzle_progress == (3 if final_return else (1 if tier == 0 else (2 if tier == 1 else 3))), "Physically reached dial did not advance the sequence")
	return failures.is_empty()


func _side_objective(route: Node2D, tier: int, kind: String) -> bool:
	if final_active and final_kind == "cistern" and kind == "Niche" and tier == 1 and room.is_complete:
		if not await _record(room.get_node("MemoryReliquary")):
			return false
	if final_active and final_return and kind == "Branch" and tier == 5:
		var trial := route.get_node("ExplorationSites/AwakenedTrial")
		for attempt in range(4):
			if trial.completed:
				break
			for enemy in trial.spawned_enemies:
				if is_instance_valid(enemy) and not enemy.is_dead:
					if not await _walk_on_floor(enemy.global_position.x, "Hollow/side-destination-clear"):
						return false
		_check(trial.triggered and trial.completed and trial.spawned_enemies.size() == 2, "Final room trial guardians not physically cleared")
	return await super._side_objective(route, tier, kind)


func _mechanism_complete() -> bool:
	if final_kind == "approach":
		return room.get_node("CounterweightCrank").is_active and room.get_node("Bridge").is_active
	for hazard in _route_hazards():
		if not hazard.disabled:
			return false
	return room.is_complete and _route_exit()._requirements_met()


func _cache_paths() -> Array[String]:
	var result: Array[String] = ["UpperCache" if final_kind == "approach" else "CisternCache", "ExpandedRoute/AuthoredDescent/HiddenDepthCache"]
	if final_kind == "cistern":
		result.append("MemoryReliquary")
	return result


func _cistern_post_pump_rewards() -> bool:
	var expansion := room.get_node("ExpandedRoute")
	# Use the unlocked shortcut for the distant memory revisit. This tests
	# the real lift's purpose instead of inserting a mid-route placement.
	if not final_return:
		if not await _ride_final_lift(true) or not await _travel_tiers(0, 1) or not await _detour(_route_geometry(), expansion, 1, "Niche") or not await _travel_tiers(1, 0) or not await _ride_final_lift(false):
			return false
	if not await _travel_tiers(6, 5):
		return false
	if not await _approach(_route_geometry(), expansion._chamber_rect(5).end.y, room.get_node("CisternCache").position.x):
		return false
	await _interact(room.get_node("CisternCache"))
	if not await _travel_tiers(5, 6):
		return false
	return await _approach(_route_geometry(), expansion._chamber_rect(6).end.y, _route_exit().position.x)


func _ride_final_lift(from_bottom: bool) -> bool:
	var route := _route_geometry()
	var lift: Area2D = route.get_node("ReturnLiftBottom" if from_bottom else "ReturnLiftTop")
	if not await _approach(route, room.get_node("ExpandedRoute")._chamber_rect(6 if from_bottom else 0).end.y, lift.position.x):
		return false
	await _interact(lift)
	for frame in range(180):
		await physics_frame
		if not root.get_node("RoomTransition").is_transitioning:
			break
	var target := route.get_node("ReturnTop" if from_bottom else "ReturnBottom")
	_check(player.global_position.distance_to(target.global_position) < 50, "Memory revisit lift missed its real marker")
	for frame in range(12):
		await physics_frame
	return failures.is_empty()


func _travel_tiers(start: int, finish: int) -> bool:
	var expansion := room.get_node("ExpandedRoute")
	var direction := 1 if finish > start else -1
	for tier in range(start, finish, direction):
		var next_tier := tier + direction
		var source: Rect2 = expansion._chamber_rect(tier)
		var destination: Rect2 = expansion._chamber_rect(next_tier)
		var stairs: Array[StaticBody2D] = []
		for node in _route_geometry().get_children():
			if node is StaticBody2D and String(node.name).begins_with("Turn%d_Drop" % mini(tier, next_tier)):
				stairs.append(node)
		stairs.sort_custom(func(a, b): return a.position.y < b.position.y if source.end.y < destination.end.y else a.position.y > b.position.y)
		if not await _approach(_route_geometry(), source.end.y, stairs[0].position.x):
			return false
		for step in stairs:
			if not await _connected_step(step, "Final/backtrack"):
				return false
		if not await _connected_step(_floor_at(_route_geometry(), destination.end.y, stairs.back().position.x), "Final/backtrack-landing"):
			return false
	return true


func _interact(object: Area2D) -> void:
	if final_active and final_return and object.get_script() == preload("res://ResonanceCache.gd") and object.opened:
		_release()
		for frame in range(3):
			await physics_frame
		var state := root.get_node("GameState")
		var gold: int = state.gold
		var inventory: Dictionary = state.inventory.duplicate(true)
		_press_interaction(object)
		_check(state.gold == gold and state.inventory == inventory, "Old final-room cache paid again")
		final_old_claims += 1
	else:
		await super._interact(object)


func _save_final_room(game: Node) -> Node:
	var state := root.get_node("GameState")
	player.set_physics_process(false)
	var hp: int = player.current_health
	var points: int = player.skill_points
	var gold: int = state.gold
	var inventory: Dictionary = state.inventory.duplicate(true)
	_check(state.current_room_id == "shaft_" + final_kind, "Final room exited without input")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "", "Final room snapshot", "shaft_" + final_kind), "Final room snapshot failed")
	await _interact(_route_exit())
	for frame in range(180):
		await physics_frame
		if not root.get_node("RoomTransition").is_transitioning:
			break
	_check(state.current_room_id == ("sunken_shaft" if final_kind == "approach" else "shaft_gallery"), "Final room onward transition failed")
	state.item_acquired.disconnect(_track_supplies)
	node_added.disconnect(_watch_foe)
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Final room snapshot did not load")
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	room = game.get_node(_room_name())
	ui = game.get_node("UI")
	_check(state.current_room_id == "shaft_" + final_kind and player.current_health == hp and player.max_health == 5 and player.skill_points == points, "Final room saved player state changed")
	_check(player.sword_mastery_unlocked and player.sword_reach_unlocked and _mechanism_complete(), "Final room saved build/mechanisms reset")
	_check(bool(state.unlocked_shortcuts.get("shaft_%s_return_lift" % final_kind, false)), "Final room saved lift reset")
	var caches := _cache_paths()
	if final_return:
		_check(_route_geometry().get_node("ExplorationSites/AwakenedTrial").completed, "Final room saved trial reset")
		caches.append("ExpandedRoute/AuthoredDescent/ExplorationSites/AwakenedTrialReward")
	for path in caches:
		var cache := room.get_node(path)
		_check(cache.opened and not cache.open(player), "Saved final-room reward duplicated: " + path)
	_check(state.gold == gold and state.inventory.size() == inventory.size(), "Final room saved money/items changed")
	for item_id in inventory:
		_check(state.inventory.has(item_id) and float(state.inventory.get(item_id, -1)) == float(inventory[item_id]), "Final room saved quantity changed: " + str(item_id))
	return game
