extends "res://tests/hollow_live_route_pilot.gd"

# Base Crossing route driver; the smoke wrapper fixes ordinary health/setup.
# Explicit lower-Shaft entrance fixture; not a continuous Driftworks campaign.
# Currents remain active until the player actually reaches/turns the valve.
func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_crossing_live_route_save.json"
	await _run_crossing()


func _run_crossing() -> void:
	var state := root.get_node("GameState")
	state.start_new_game("normal")
	var game: Node = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	ui = game.get_node("UI")
	_check(player.max_health == 5 and player.current_health == 5 and not player.double_jump_unlocked and not player.dash_unlocked, "Crossing starter setup changed")
	state.add_gold(36)
	ui._open_shop(game.get_node("WayfarerMerchant"))
	for purchase in range(2):
		ui.selected_shop_item_id = "healing_herb"
		ui._on_shop_buy_pressed()
	ui._close_shop()
	_check(state.gold == 0 and state.inventory.get("healing_herb", 0) == 2, "Crossing supply preparation failed")
	state.set_current_room("shaft_crossing")
	await process_frame
	room = game.get_node("DrownedCrossing")
	state.item_acquired.connect(_track_supplies)
	for enemy in get_nodes_in_group("enemy"):
		_watch_foe(enemy)
	node_added.connect(_watch_foe)
	player.health_changed.connect(_trace_health)
	var currents := room.find_children("CrossingCurrent*", "Area2D", true, false)
	_check(currents.size() == 7, "Crossing current coverage changed")
	for current in currents:
		_check(not current.disabled, "Current was silenced before reaching the valve")
	player.global_position = room.get_node("ShaftEntry").global_position
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	for frame in range(12):
		await physics_frame
	var started := Engine.get_physics_frames()
	var ok := await _crossing_route()
	_check(ok and not player.is_dead and player.current_health > 0 and player.max_health == 5, "Connected Crossing run failed at normal health")
	_check(legs == 6 and excursions == 5 and defeats >= 12, "Crossing route/combat coverage incomplete")
	_check(room.get_node("Valve").is_active, "Crossing valve was not activated")
	for current in currents:
		_check(current.disabled, "Valve failed to silence a current")
	_check(room.get_node("CrossingCache").opened and _route_geometry().get_node("HiddenDepthCache").opened, "Crossing optional rewards skipped")
	_check(herbs_used <= 2 + cache_herbs and state.inventory.get("healing_herb", 0) == 2 + herbs_found - herbs_used, "Crossing finite supply ledger failed")
	print("CROSSING LIVE: ", defeats, " enemy defeats, ", player.current_health, "/5 HP, ", herbs_used, " herbs used, ", cache_herbs, " guaranteed herbs; ", legs, " links / ", excursions, " side detours; ", (Engine.get_physics_frames() - started) / 60.0, " physics seconds")
	_release()
	if failures.is_empty():
		game = await _save_crossing_exit(game)
	if failures.is_empty():
		game = await _after_completed_route(game)
	state.delete_save()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("CROSSING LIVE ROUTE TEST PASSED: starter health/sword, live combat/currents, valve, all galleries/detours, two caches, lift round trip, explicit exit and persistence")
		quit(0)
	else:
		print("HEALTH TRACE: ", health_trace)
		print("CROSSING LIVE ROUTE TEST FAILED: ", failures.size())
		quit(1)


func _route_hazards() -> Array[Node]:
	# Continuous currents have no periodic safe phase to wait for. Their real
	# collision-aware force remains active; they are disabled only by the valve.
	return []


func _route_exit() -> Area2D:
	return room.get_node("GalleryDoor")


func _gallery_objective(_room: Node2D, tier: int) -> bool:
	var expansion := room.get_node("ExpandedRoute")
	if tier == 1:
		var valve: Area2D = room.get_node("Valve")
		if not await _approach(_route_geometry(), expansion._chamber_rect(tier).end.y, valve.position.x):
			return false
		await _interact(valve)
		_check(valve.is_active, "Physical valve interaction failed")
		return valve.is_active
	if tier == 6:
		var cache: Area2D = room.get_node("CrossingCache")
		if not await _approach(_route_geometry(), expansion._chamber_rect(tier).end.y, cache.position.x):
			return false
		await _interact(cache)
		return cache.opened
	return true


func _crossing_route() -> bool:
	var expansion := room.get_node("ExpandedRoute")
	var route := _route_geometry()
	for tier in range(7):
		if not await _gallery_objective(room, tier):
			return false
		if tier in [1, 3, 5] and not await _detour(route, expansion, tier, "Branch"):
			return false
		if tier in [1, 4] and not await _detour(route, expansion, tier, "Niche"):
			return false
		if tier == 6:
			break
		var stairs: Array[StaticBody2D] = []
		for node in route.get_children():
			if node is StaticBody2D and String(node.name).begins_with("Turn%d_Drop" % tier):
				stairs.append(node)
		var source: Rect2 = expansion._chamber_rect(tier)
		var next: Rect2 = expansion._chamber_rect(tier + 1)
		stairs.sort_custom(func(a, b): return a.position.y < b.position.y if source.end.y < next.end.y else a.position.y > b.position.y)
		if not await _approach(route, source.end.y, stairs[0].position.x):
			return false
		for step in stairs:
			if not await _connected_step(step, "Crossing/main%d" % tier):
				return false
		if not await _connected_step(_floor_at(route, next.end.y, stairs.back().position.x), "Crossing/landing"):
			return false
		legs += 1
	if not await _approach(route, expansion._chamber_rect(6).end.y, route.get_node("ReturnLiftBottom").position.x):
		return false
	for below in [true, false]:
		var lift: Area2D = route.get_node("ReturnLiftBottom" if below else "ReturnLiftTop")
		if not below and not await _approach(route, expansion._chamber_rect(0).end.y, lift.position.x):
			return false
		await _interact(lift)
		for frame in range(180):
			await physics_frame
			if not root.get_node("RoomTransition").is_transitioning:
				break
		var marker: Marker2D = route.get_node("ReturnTop" if below else "ReturnBottom")
		_check(not root.get_node("RoomTransition").is_transitioning and player.global_position.distance_to(marker.global_position) < 50, "Crossing lift round trip failed")
		if not failures.is_empty():
			return false
		for frame in range(12):
			await physics_frame
	return await _approach(route, expansion._chamber_rect(6).end.y, _route_exit().position.x)


func _save_crossing_exit(game: Node) -> Node:
	var state := root.get_node("GameState")
	player.set_physics_process(false)
	var hp: int = player.current_health
	var gold: int = state.gold
	var inventory: Dictionary = state.inventory.duplicate(true)
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "", "Crossing route snapshot", "shaft_crossing"), "Completed Crossing snapshot failed")
	_check(state.current_room_id == "shaft_crossing", "Crossing door transitioned without interaction")
	await _interact(room.get_node("GalleryDoor"))
	for frame in range(180):
		await physics_frame
		if not root.get_node("RoomTransition").is_transitioning:
			break
	_check(state.current_room_id == "shaft_gallery", "Explicit exit did not reach Flooded Gallery")
	state.item_acquired.disconnect(_track_supplies)
	node_added.disconnect(_watch_foe)
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Crossing snapshot could not load")
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	room = game.get_node("DrownedCrossing")
	_check(state.current_room_id == "shaft_crossing" and player.current_health == hp and player.max_health == 5, "Saved Crossing room/health changed")
	_check(room.get_node("Valve").is_active and bool(state.unlocked_shortcuts.get("shaft_crossing_return_lift", false)), "Saved valve/lift progress changed")
	for current in room.find_children("CrossingCurrent*", "Area2D", true, false):
		_check(current.disabled, "Current restarted after restoring saved valve")
	for path in ["CrossingCache", "ExpandedRoute/AuthoredDescent/HiddenDepthCache"]:
		var cache := room.get_node(path)
		_check(cache.opened and not cache.open(player), "Saved Crossing reward paid again: " + path)
	_check(state.gold == gold and state.inventory.size() == inventory.size(), "Saved Crossing supplies changed")
	for item_id in inventory:
		_check(state.inventory.has(item_id) and float(state.inventory.get(item_id, -1)) == float(inventory[item_id]), "Saved Crossing item quantity changed: " + str(item_id))
	return game
