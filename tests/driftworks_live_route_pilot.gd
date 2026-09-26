extends "res://tests/hollow_live_route_pilot.gd"

# Connected expedition driver; the smoke wrapper fixes its ordinary-health setup.
# One entrance placement, starter sword/5 HP, two purchased herbs. No injected
# damage, movement upgrades, automatic healing or mid-route resets.
var links_walked := 0
var branches_visited := 0
var neutral_defeats := 0


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_driftworks_live_route_save.json"
	await _run_driftworks()


func _run_driftworks() -> void:
	var state := root.get_node("GameState")
	state.start_new_game("normal")
	var game: Node = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	_check(player.current_health == 5 and player.max_health == 5 and not player.double_jump_unlocked and not player.dash_unlocked, "Driftworks starter setup changed")
	ui = game.get_node("UI")
	state.add_gold(36)
	ui._open_shop(game.get_node("WayfarerMerchant"))
	for purchase in range(2):
		ui.selected_shop_item_id = "healing_herb"
		ui._on_shop_buy_pressed()
	ui._close_shop()
	_check(state.gold == 0 and state.inventory.get("healing_herb", 0) == 2, "Driftworks finite preparation failed")
	state.set_current_room("shaft_drift")
	await process_frame
	room = game.get_node("ShaftDriftworks")
	for index in range(7):
		var animal := room.get_node("QuietGrazer%d" % index)
		_check(not animal.is_hostile and not animal.is_dead, "Grazer did not begin passive")
		animal.defeated.connect(func(): neutral_defeats += 1)
	state.item_acquired.connect(_track_supplies)
	for enemy in get_nodes_in_group("enemy"):
		_watch_foe(enemy)
	node_added.connect(_watch_foe)
	player.health_changed.connect(_trace_health)
	player.global_position = room.get_node("Entry").global_position
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	for frame in range(12):
		await physics_frame
	var started := Engine.get_physics_frames()
	var ok := await _expedition()
	_check(ok and not player.is_dead and player.current_health > 0 and player.max_health == 5, "Driftworks connected base run failed")
	_check(links_walked == 7 and branches_visited == 4, "Driftworks route coverage incomplete")
	_check(defeats >= 12, "Driftworks live combat not exercised")
	_check(room.get_node("Infrastructure/IntakePump").is_active and room.get_node("Infrastructure/CrownPump").is_active, "Both pumps were not restored")
	for path in ["MidCache", "RimCache", "Infrastructure/RepairReward"]:
		_check(room.get_node(path).opened, "Reward not physically collected: " + path)
	for hazard in _route_hazards():
		_check(hazard.disabled, "Repaired pump did not disable its matching pressure leak")
	_check(not room.get_node("Infrastructure/ReturnTrial").triggered, "First visit incorrectly started the awakened trial")
	_check(herbs_used <= 2 + cache_herbs and state.inventory.get("healing_herb", 0) == 2 + herbs_found - herbs_used, "Finite supply ledger failed")
	print("DRIFTWORKS LIVE: ", defeats, " enemy defeats, ", neutral_defeats, " provoked fauna defeats (not a pacifist route), ", player.current_health, "/5 HP, ", herbs_used, " herbs used, ", cache_herbs, " guaranteed herbs; ", links_walked, " main links, ", branches_visited, " branches; ", (Engine.get_physics_frames() - started) / 60.0, " physics seconds")
	_release()
	if failures.is_empty():
		game = await _save_and_exit(game)
	if failures.is_empty():
		game = await _after_completed_route(game)
	state.delete_save()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("DRIFTWORKS LIVE ROUTE TEST PASSED: ordinary health, live combat, pumps, four branches, rewards, lift round trip, explicit exit and saved progress")
		quit(0)
	else:
		print("HEALTH TRACE: ", health_trace)
		print("DRIFTWORKS LIVE ROUTE TEST FAILED: ", failures.size())
		quit(1)


func _route_geometry() -> Node2D:
	return room


func _route_hazards() -> Array[Node]:
	return room.find_children("PressureLeak*", "Area2D", true, false)


func _branch_destinations(branch: int) -> Array:
	return [["Infrastructure/IntakePump"], ["MidCache"], ["Infrastructure/CrownPump", "Infrastructure/RepairReward"], ["RimCache"]][branch]


func _expedition() -> bool:
	for tier in range(8):
		var chamber: Rect2 = room._main_rect(tier)
		for branch in range(4):
			if int(room._branch_data()[branch][4]) != tier:
				continue
			var side: Rect2 = room._branch_rect(branch)
			if not await _link("BranchLink%d" % branch, chamber, side):
				return false
			var destinations: Array = _branch_destinations(branch)
			for path in destinations:
				var object: Area2D = room.get_node(path)
				if not await _corridor(side.end.y, object.position.x):
					return false
				await _interact(object)
				if path == "Infrastructure/IntakePump" and not room.get_node("Infrastructure/CrownPump").is_active:
					_check(object.is_active and room.get_node("Infrastructure/PressureLeak0").disabled and not room.get_node("Infrastructure/PressureLeak1").disabled, "Intake did not independently repair its own pressure leak")
					_check(not room.get_node("Infrastructure/RepairReward").open(player), "Intake alone released the two-pump reserve")
			if not await _link("BranchLink%d" % branch, side, chamber):
				return false
			branches_visited += 1
		if tier < 7:
			if not await _link("MainLink%d" % tier, chamber, room._main_rect(tier + 1)):
				return false
			links_walked += 1
	if not await _corridor(room._main_rect(7).end.y, room.get_node("ReturnLiftBottom").position.x):
		return false
	for below in [true, false]:
		var lift: Area2D = room.get_node("ReturnLiftBottom" if below else "ReturnLiftTop")
		await _interact(lift)
		var transition := root.get_node("RoomTransition")
		for frame in range(180):
			await physics_frame
			if not transition.is_transitioning:
				break
		var marker: Marker2D = room.get_node("ReturnLiftTopMarker" if below else "ReturnLiftBottomMarker")
		_check(not transition.is_transitioning and player.global_position.distance_to(marker.global_position) < 50, "Lift did not complete its physical round trip")
		if not failures.is_empty():
			return false
	return await _corridor(room._main_rect(7).end.y, room.get_node("UpperShortcutDoor").position.x)


func _save_and_exit(game: Node) -> Node:
	var state := root.get_node("GameState")
	player.set_physics_process(false)
	var saved_hp: int = player.current_health
	var saved_gold: int = state.gold
	var saved_inventory: Dictionary = state.inventory.duplicate(true)
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "", "Driftworks route snapshot", "shaft_drift"), "Driftworks checkpoint snapshot failed")
	_check(state.current_room_id == "shaft_drift", "Approaching the exit transitioned without a click")
	await _interact(room.get_node("UpperShortcutDoor"))
	for frame in range(180):
		await physics_frame
		if not root.get_node("RoomTransition").is_transitioning:
			break
	_check(state.current_room_id == "shaft_crossing", "Explicit Driftworks exit did not arrive in Drowned Crossing")
	state.item_acquired.disconnect(_track_supplies)
	node_added.disconnect(_watch_foe)
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Completed Driftworks snapshot failed to load")
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	room = game.get_node("ShaftDriftworks")
	_check(state.current_room_id == "shaft_drift" and player.current_health == saved_hp and player.max_health == 5, "Driftworks reload changed room/health")
	_check(bool(state.unlocked_shortcuts.get("shaft_drift_return_lift", false)), "Activated lift did not persist")
	_check(room.get_node("Infrastructure/IntakePump").is_active and room.get_node("Infrastructure/CrownPump").is_active, "Saved pumps reset")
	for hazard in _route_hazards():
		_check(hazard.disabled, "Saved pump repair did not keep its leak disabled")
	for path in ["MidCache", "RimCache", "Infrastructure/RepairReward"]:
		var cache := room.get_node(path)
		_check(cache.opened and not cache.open(player), "Saved Driftworks cache paid twice: " + path)
	_check(state.gold == saved_gold and state.inventory.size() == saved_inventory.size(), "Saved supplies changed")
	for item_id in saved_inventory:
		_check(state.inventory.has(item_id) and float(state.inventory.get(item_id, -1)) == float(saved_inventory[item_id]), "Saved item quantity changed: " + str(item_id))
	return game


func _link(prefix: String, source: Rect2, destination: Rect2) -> bool:
	print("DRIFT LINK ", prefix, " ", source.end.y, " -> ", destination.end.y, " from ", room.to_local(player.global_position))
	var steps: Array[StaticBody2D] = []
	for body in room.get_children():
		if body is StaticBody2D and String(body.name).begins_with(prefix + "ShaftStep"):
			steps.append(body)
	if steps.is_empty():
		return await _corridor(destination.end.y, destination.get_center().x)
	steps.sort_custom(func(a, b): return a.position.y < b.position.y if source.end.y < destination.end.y else a.position.y > b.position.y)
	if not await _corridor(source.end.y, steps[0].position.x):
		return false
	for step in steps:
		if not await _connected_step(step, "Drift/" + prefix):
			return false
	return await _connected_step(_floor_at(room, destination.end.y, steps.back().position.x), "Drift/landing")


func _corridor(floor_y: float, desired_x: float) -> bool:
	# Walk solid segments and use the top shaft ledge to bridge each floor cut.
	var destination := _floor_at(room, floor_y, desired_x)
	var direction := signf(desired_x - room.to_local(player.global_position).x)
	var floors: Array[StaticBody2D] = []
	for body in room.get_children():
		if not body is StaticBody2D or not "Floor" in String(body.name) or absf(body.position.y - floor_y) > 1:
			continue
		var bounds := _bounds(body)
		if (bounds.get_center().x - player.global_position.x) * direction > 0 and (bounds.get_center().x - _bounds(destination).get_center().x) * direction <= 0:
			floors.append(body)
	floors.sort_custom(func(a, b): return a.position.x < b.position.x if direction > 0 else a.position.x > b.position.x)
	for floor_body in floors:
		var target := _bounds(floor_body)
		var feet := player.global_position + Vector2(0, 9)
		var hit := player.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(feet, feet + Vector2(0, 9), 1, [player.get_rid()]))
		if not hit.is_empty() and hit.collider is StaticBody2D:
			var current := _bounds(hit.collider)
			var gap := maxf(target.position.x, current.position.x) - minf(target.end.x, current.end.x)
			if gap > 150:
				var bridge: StaticBody2D
				for body in room.get_children():
					if body is StaticBody2D and "ShaftStep" in String(body.name) and body.position.y > floor_y and body.position.y < floor_y + 70:
						if (body.global_position.x - current.get_center().x) * direction > 0 and (target.get_center().x - body.global_position.x) * direction > 0:
							bridge = body
							break
				if bridge != null and not await _connected_step(bridge, "Drift/crossing"):
					return false
		if not await _connected_step(floor_body, "Drift/corridor"):
			return false
	var bounds := _bounds(destination)
	approach_floor_top = bounds.position.y
	return await _walk_on_floor(clampf(room.to_global(Vector2(desired_x, 0)).x, bounds.position.x + 16, bounds.end.x - 16), "Hollow/corridor-approach")
