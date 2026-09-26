extends "res://tests/crossing_live_route_pilot.gd"

# Connected base Gallery diagnostic, outside the smoke glob until accepted.
# One entrance placement, ordinary health, starter sword, two purchased herbs.
var earned_arrival := false
var returning_gallery := false


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_gallery_live_route_save.json"
	await _run_gallery()


func _run_gallery() -> void:
	var state := root.get_node("GameState")
	state.start_new_game("normal")
	var game: Node = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	ui = game.get_node("UI")
	_check(player.max_health == 5 and player.current_health == 5 and not player.double_jump_unlocked and not player.dash_unlocked, "Gallery starter setup changed")
	state.add_gold(36)
	ui._open_shop(game.get_node("WayfarerMerchant"))
	for purchase in range(2):
		ui.selected_shop_item_id = "healing_herb"
		ui._on_shop_buy_pressed()
	ui._close_shop()
	_check(state.gold == 0 and state.inventory.get("healing_herb", 0) == 2, "Gallery finite supplies setup failed")
	state.set_current_room("shaft_gallery")
	await process_frame
	room = game.get_node("FloodedGallery")
	state.item_acquired.connect(_track_supplies)
	for enemy in get_nodes_in_group("enemy"):
		_watch_foe(enemy)
	node_added.connect(_watch_foe)
	player.health_changed.connect(_trace_health)
	_check(_route_hazards().size() == 7 and not _route_exit()._requirements_met(), "Gallery initial hazards/gate setup changed")
	for hazard in _route_hazards():
		_check(not hazard.disabled, "Gallery pressure disabled before reaching a control")
	player.global_position = room.get_node("CrossingEntry").global_position
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	for frame in range(12):
		await physics_frame
	await _verify_gallery_route(0)
	if failures.is_empty():
		game = await _save_gallery_exit(game)
	state.delete_save()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("GALLERY LIVE ROUTE TEST PASSED: ordinary health, live combat/pressure, both controls, galleries, detours, rewards, lift, exit and saved progress")
		quit(0)
	else:
		print("HEALTH TRACE: ", health_trace)
		print("GALLERY LIVE ROUTE TEST FAILED: ", failures.size())
		quit(1)


func _verify_gallery_route(carried_herbs: int) -> void:
	var state := root.get_node("GameState")
	var started := Engine.get_physics_frames()
	var ok := await _crossing_route()
	_check(ok and not player.is_dead and player.current_health > 0 and player.max_health == 5, "Gallery connected run failed at normal health")
	_check(legs == 6 and excursions == 5 and defeats >= 12, "Gallery route/combat coverage incomplete")
	_check(room.get_node("LowerControl").is_active and room.get_node("UpperControl").is_active and _route_exit()._requirements_met(), "Gallery controls did not unlock onward gate")
	for hazard in _route_hazards():
		_check(hazard.disabled, "Repaired pressure jet stayed active")
	_check(room.get_node("GalleryCache").opened and _route_geometry().get_node("HiddenDepthCache").opened, "Gallery rewards skipped")
	_check(herbs_used <= purchased_herb_allowance + cache_herbs and state.inventory.get("healing_herb", 0) == carried_herbs + purchased_herb_allowance + herbs_found - herbs_used, "Gallery finite supply ledger failed")
	print("GALLERY LIVE: ", defeats, " enemy defeats, ", player.current_health, "/5 HP, ", herbs_used, " herbs used, ", cache_herbs, " guaranteed herbs; ", legs, " links / ", excursions, " detours; ", (Engine.get_physics_frames() - started) / 60.0, " physics seconds")
	_release()


func _route_exit() -> Area2D:
	if room.name == "DrownedCrossing":
		return super._route_exit()
	return room.get_node("WardenShortcutDoor")


func _route_hazards() -> Array[Node]:
	return room.find_children("GalleryPressureJet*", "Area2D", true, false)


func _gallery_objective(_room: Node2D, tier: int) -> bool:
	if room.name == "DrownedCrossing":
		return await super._gallery_objective(_room, tier)
	var expansion := room.get_node("ExpandedRoute")
	if tier not in [1, 3]:
		return true
	var control: Area2D = room.get_node("UpperControl" if tier == 1 else "LowerControl")
	if not await _approach(_route_geometry(), expansion._chamber_rect(tier).end.y, control.position.x):
		return false
	await _interact(control)
	_check(control.is_active, "Gallery control not physically activated")
	if tier == 1:
		if not returning_gallery:
			_check(not _route_exit()._requirements_met(), "One control incorrectly opened onward gate")
			for hazard in _route_hazards():
				_check(hazard.disabled == (hazard.disabled_by_shortcut_id == "shaft_gallery_upper"), "Upper control affected the wrong pressure circuit")
		var cache: Area2D = room.get_node("GalleryCache")
		if not await _approach(_route_geometry(), expansion._chamber_rect(tier).end.y, cache.position.x):
			return false
		await _interact(cache)
	return control.is_active


func _after_completed_route(game: Node) -> Node:
	if not earned_arrival:
		return game
	var state := root.get_node("GameState")
	ui = game.get_node("UI")
	var points: int = player.skill_points
	var gold: int = state.gold
	var hp: int = player.current_health
	var carried: int = state.inventory.get("healing_herb", 0)
	_check(points >= 2 and gold >= 36, "Crossing did not earn Gallery preparation")
	if not failures.is_empty():
		return game
	ui._on_sword_mastery_pressed()
	ui._on_sword_reach_pressed()
	ui._open_shop(game.get_node("WayfarerMerchant"))
	for purchase in range(2):
		ui.selected_shop_item_id = "healing_herb"
		ui._on_shop_buy_pressed()
	ui._close_shop()
	_check(player.skill_points == points - 2 and player.sword_mastery_unlocked and player.sword_reach_unlocked, "Gallery sword build was not purchased with earned points")
	_check(state.gold == gold - 36 and state.inventory.get("healing_herb", 0) == carried + 2, "Gallery herbs were not bought with earned Gold")
	# The base snapshot was taken at this door. Continue via its real input and
	# transition, not another initial placement or artificial Gallery spawn.
	await _interact(room.get_node("GalleryDoor"))
	for frame in range(180):
		await physics_frame
		if not root.get_node("RoomTransition").is_transitioning:
			break
	_check(state.current_room_id == "shaft_gallery" and player.current_health == hp and player.max_health == 5, "Gallery arrival changed room or health")
	room = game.get_node("FloodedGallery")
	_check(player.global_position.distance_to(room.get_node("CrossingEntry").global_position) < 50, "Gallery actual entrance was missed")
	_check(not player.double_jump_unlocked and not player.dash_unlocked and state.get_zone_tier("sunken_shaft") == 0, "Gallery earned arrival changed movement or tier")
	if not failures.is_empty():
		return game
	defeats = 0
	herbs_used = 0
	herbs_found = 0
	cache_herbs = 0
	legs = 0
	excursions = 0
	hazard_waits = 0
	flank_direction = 0.0
	approach_floor_top = NAN
	health_trace.clear()
	supplies_trace.clear()
	state.item_acquired.connect(_track_supplies)
	node_added.connect(_watch_foe)
	for enemy in get_nodes_in_group("enemy"):
		_watch_foe(enemy)
	player.health_changed.connect(_trace_health)
	_check(_route_hazards().size() == 7 and not _route_exit()._requirements_met(), "Gallery initial pressure/gate changed")
	for hazard in _route_hazards():
		_check(not hazard.disabled, "Gallery pressure disabled before reaching controls")
	player.set_physics_process(true)
	for frame in range(12):
		await physics_frame
	print("GALLERY EARNED ARRIVAL: ", points, " earned points / ", gold, " earned Gold; spent 2 points / 36 Gold, entered ", hp, "/5 HP with two newly purchased herbs; carried herbs cannot raise healing budget")
	await _verify_gallery_route(carried)
	if failures.is_empty():
		game = await _save_gallery_exit(game)
	if failures.is_empty():
		print("GALLERY EARNED ARRIVAL TEST PASSED: real Crossing clear, earned sword build, real door arrival, connected Gallery and onward exit/save")
		game = await _after_gallery_completed(game)
	return game


func _after_gallery_completed(game: Node) -> Node:
	return game


func _save_gallery_exit(game: Node) -> Node:
	var state := root.get_node("GameState")
	player.set_physics_process(false)
	var hp: int = player.current_health
	var gold: int = state.gold
	var points: int = player.skill_points
	var inventory: Dictionary = state.inventory.duplicate(true)
	_check(state.current_room_id == "shaft_gallery", "Gallery exit triggered without input")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "", "Gallery route snapshot", "shaft_gallery"), "Gallery snapshot failed")
	await _interact(_route_exit())
	for frame in range(180):
		await physics_frame
		if not root.get_node("RoomTransition").is_transitioning:
			break
	_check(state.current_room_id == "shaft_approach", "Gallery explicit exit did not reach Warden Approach")
	state.item_acquired.disconnect(_track_supplies)
	node_added.disconnect(_watch_foe)
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Gallery snapshot could not load")
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	room = game.get_node("FloodedGallery")
	ui = game.get_node("UI")
	_check(state.current_room_id == "shaft_gallery" and player.current_health == hp and player.max_health == 5, "Saved Gallery room/health changed")
	_check(player.skill_points == points and (not earned_arrival or (player.sword_mastery_unlocked and player.sword_reach_unlocked)), "Saved Gallery skill progress changed")
	_check(room.get_node("LowerControl").is_active and room.get_node("UpperControl").is_active and _route_exit()._requirements_met(), "Saved controls/gate reset")
	_check(bool(state.unlocked_shortcuts.get("shaft_gallery_return_lift", false)), "Saved Gallery lift reset")
	for hazard in _route_hazards():
		_check(hazard.disabled, "Saved pressure jet restarted")
	for path in ["GalleryCache", "ExpandedRoute/AuthoredDescent/HiddenDepthCache"]:
		var cache := room.get_node(path)
		_check(cache.opened and not cache.open(player), "Saved Gallery cache paid again: " + path)
	_check(state.gold == gold and state.inventory.size() == inventory.size(), "Gallery saved supplies changed")
	for item_id in inventory:
		_check(state.inventory.has(item_id) and float(state.inventory.get(item_id, -1)) == float(inventory[item_id]), "Gallery saved item quantity changed: " + str(item_id))
	return game
