extends "res://tests/crossing_live_route_pilot.gd"

# Earn the build/supplies in Crossing, then use ONE explicit Echo entry fixture.
# This is not a Warden defeat or a continuous inter-zone campaign transition.
var echo_active := false


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_echo_grotto_live_save.json"
	await _run_crossing()


func _route_geometry() -> Node2D:
	return room.get_node("LongTraversal") if echo_active else super._route_geometry()


func _settle_upper_step(target: StaticBody2D, label: String) -> bool:
	# A combat jump can land on the neighbouring shaft's higher plank. The
	# next rim crossing needs the requested bridge, not that incidental perch.
	if echo_active and String(target.name).contains("Rise01"):
		if label.count("/echo-upper-rejoin") >= 3:
			_check(false, "Echo bridge rejoin exceeded bounded retries")
			return false
		return await _connected_step(target, label + "/echo-upper-rejoin")
	return await super._settle_upper_step(target, label)


func _connected_step(target: StaticBody2D, label: String) -> bool:
	# Entry-court platforms are siblings of LongTraversal, not generated
	# children. Recover combat knockbacks through those actual supports too.
	if echo_active and target.get_parent() == room:
		for attempt in range(4):
			var feet := player.global_position.y + 10
			if feet - _bounds(target).position.y <= 85:
				break
			var intermediate: StaticBody2D
			var best_y := INF
			for child in room.get_children():
				if not child is StaticBody2D or not child.has_node("CollisionShape2D") or not child.get_node("CollisionShape2D").shape is RectangleShape2D:
					continue
				var bounds := _bounds(child)
				var rise := feet - bounds.position.y
				if bounds.size.y <= 22 and rise > 5 and rise <= 80 and bounds.position.y < best_y:
					intermediate = child
					best_y = bounds.position.y
			if intermediate == null or not await _connected_step(intermediate, label + "/entry-rejoin"):
				return false
	return await super._connected_step(target, label)


func _after_completed_route(game: Node) -> Node:
	var state := root.get_node("GameState")
	ui = game.get_node("UI")
	var gold: int = state.gold
	var points: int = player.skill_points
	var hp: int = player.current_health
	var carried: int = state.inventory.get("healing_herb", 0)
	_check(gold >= 54 and points >= 2, "Crossing did not earn Echo preparation")
	ui._on_sword_mastery_pressed()
	ui._on_sword_reach_pressed()
	ui._open_shop(game.get_node("WayfarerMerchant"))
	for index in range(3):
		ui.selected_shop_item_id = "healing_herb"
		ui._on_shop_buy_pressed()
	ui._close_shop()
	_check(state.gold == gold - 54 and player.skill_points == points - 2, "Echo preparation did not spend actual earnings")
	_check(player.current_health == hp and player.max_health == 5 and not player.double_jump_unlocked and not player.dash_unlocked, "Echo preparation changed health/movement")
	state.set_current_room("echo_grotto")
	await process_frame
	room = game.get_node("EchoGrotto")
	echo_active = true
	advanced_steering = true
	wildlife_chase_range = 110.0
	overhead_wildlife_clearance = 55.0
	purchased_herb_allowance = 3
	defeats = 0
	herbs_used = 0
	herbs_found = 0
	cache_herbs = 0
	legs = 0
	excursions = 0
	health_trace.clear()
	state.item_acquired.connect(_track_supplies)
	node_added.connect(_watch_foe)
	for foe in get_nodes_in_group("enemy"):
		_watch_foe(foe)
	player.health_changed.connect(_trace_health)
	player.global_position = room.get_node("GrottoEntry").global_position
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	for frame in range(12):
		await physics_frame
	var started := Engine.get_physics_frames()
	var ok := await _entry_puzzle()
	if ok:
		ok = await _echo_route()
	_check(ok and not player.is_dead and player.max_health == 5, "Echo connected normal-health route failed")
	_check(legs == 8 and excursions == 4 and defeats >= 15, "Echo connected route coverage incomplete")
	_check(state.has_item("echo_charm") and bool(state.unlocked_shortcuts.get("echo_grotto_field_complete", false)), "Echo room objectives incomplete")
	_check(_route_geometry().get_node("RouteDiscoveryCache").opened, "Echo hidden offering not collected")
	_check(herbs_used <= 3 + cache_herbs and state.inventory.get("healing_herb", 0) == carried + 3 + herbs_found - herbs_used, "Echo finite supplies mismatch")
	print("ECHO GROTTO LIVE: ", defeats, " foes; entered ", hp, "/5 HP, ended ", player.current_health, "/5; ", herbs_used, " herbs of 3 purchased + ", cache_herbs, " guaranteed; ", legs, " links, ", excursions, " branches; ", (Engine.get_physics_frames() - started) / 60.0, " physics seconds")
	_release()
	player.set_physics_process(false)
	if failures.is_empty():
		game = await _save_echo_exit(game)
	if failures.is_empty():
		game = await _after_echo_completed(game)
	return game


func _after_echo_completed(game: Node) -> Node:
	return game


func _echo_exit() -> Area2D:
	return room.get_node("GalleryDoor")


func _echo_tier_objective(_tier: int) -> bool:
	return true


func _entry_puzzle() -> bool:
	if not await _walk_on_floor(room.get_node("LowerResonator").global_position.x, "Echo/lower-resonator"):
		return false
	await _interact(room.get_node("LowerResonator"))
	for named in ["FirstPlatform", "SecondPlatform", "ThirdPlatform"]:
		if not await _connected_step(room.get_node(named), "Echo/entry-climb"):
			return false
	if not await _walk_on_floor(room.get_node("UpperResonator").global_position.x, "Echo/upper-resonator"):
		return false
	await _interact(room.get_node("UpperResonator"))
	_check(root.get_node("GameState").has_item("echo_charm"), "Physical resonator visits did not award charm")
	if not await _connected_step(room.get_node("GrottoFloor"), "Echo/entry-descent"):
		return false
	return await _walk_on_floor(_route_geometry().get_node("Chamber00Floor0").global_position.x, "Echo/enter-extension")


func _echo_route() -> bool:
	for tier in range(9):
		if OS.get_cmdline_user_args().has("--trace-route"):
			print("ECHO TIER ", tier, " at ", room.to_local(player.global_position))
		if not await _echo_tier_objective(tier):
			return false
		if tier % 2 == 1 and not await _echo_branch(tier):
			return false
		if tier == 8:
			break
		if not await _echo_link(tier, tier + 1):
			return false
		legs += 1
	return await _echo_approach(8, _echo_exit().position.x)


func _echo_link(source_tier: int, destination_tier: int) -> bool:
	var route := _route_geometry()
	var source: Rect2 = route._chamber_rect(source_tier)
	var destination: Rect2 = route._chamber_rect(destination_tier)
	var stairs: Array[StaticBody2D] = []
	for child in route.get_children():
		if child is StaticBody2D and String(child.name).begins_with("Tier%02dRise" % maxi(source_tier, destination_tier)):
			stairs.append(child)
	stairs.sort_custom(func(a, b): return a.position.y < b.position.y if source.end.y < destination.end.y else a.position.y > b.position.y)
	if not await _echo_approach(source_tier, stairs[0].position.x):
		return false
	for stair in stairs:
		if not await _connected_step(stair, "Echo/main%d" % source_tier):
			return false
	return await _connected_step(_echo_floor(destination_tier, stairs.back().position.x), "Echo/landing")


func _echo_floor(tier: int, x: float) -> StaticBody2D:
	var nearest: StaticBody2D
	var gap := INF
	for body in _route_geometry().get_children():
		if not body is StaticBody2D or not String(body.name).begins_with("Chamber%02dFloor" % tier):
			continue
		var half: float = body.get_node("CollisionShape2D").shape.size.x * 0.5
		var distance := absf(x - clampf(x, body.position.x - half + 12, body.position.x + half - 12))
		if distance < gap:
			nearest = body
			gap = distance
	return nearest


func _echo_post(tier: int) -> Area2D:
	var fields := _route_geometry().get_node("FieldDiscoveries")
	var index: int = fields.data["tiers"].find(tier)
	return fields.get_node("ListeningPost%d" % index) if index >= 0 else null


func _visit_echo_post(post: Area2D, tier: int) -> bool:
	if not await _record(post):
		return false
	for frame in range(100):
		_supplies()
		await physics_frame
	if not post.attuned:
		print("LISTEN STALL: ", room.name, " tier ", tier, " player ", room.to_local(player.global_position), " post ", post.position, " threat ", post._has_threat(), " sequence ", _route_geometry().get_node("FieldDiscoveries").sequence)
		for foe in _foes():
			if is_instance_valid(foe) and room.is_ancestor_of(foe) and foe.global_position.distance_to(post.global_position) < 200:
				print("LISTEN FOE: ", foe.name, " at ", room.to_local(foe.global_position))
	_check(post.attuned, "Physical listening did not complete: " + str(post.name))
	return post.attuned


func _echo_branch(tier: int) -> bool:
	var route := _route_geometry()
	var steps: Array[StaticBody2D] = []
	for named in ["BranchStep1", "BranchStep2", "HiddenShelfA", "HiddenShelfB"]:
		steps.append(route.get_node("Tier%02d%s" % [tier, named]))
	var post := _echo_post(tier)
	if post != null:
		# A guard on the corridor below the balcony also interrupts listening.
		# Physically clear that lane before ascending; do not silence the guard.
		if post._has_threat() and not await _echo_approach(tier, post.position.x):
			return false
	if not await _echo_approach(tier, steps[0].position.x):
		return false
	for step in steps:
		if not await _connected_step(step, "Echo/branch%d" % tier):
			return false
	if post != null:
		if not await _visit_echo_post(post, tier):
			return false
	elif tier == 7:
		if not await _record(route.get_node("RouteDiscoveryCache")):
			return false
	steps.reverse()
	for step in steps:
		if not await _connected_step(step, "Echo/branch-return%d" % tier):
			return false
	if not await _connected_step(_echo_floor(tier, steps.back().position.x), "Echo/branch-floor"):
		return false
	excursions += 1
	return true


func _echo_approach(tier: int, x: float) -> bool:
	var route := _route_geometry()
	var target := _echo_floor(tier, x)
	var target_bounds := _bounds(target)
	var goal := clampf(route.to_global(Vector2(x, 0)).x, target_bounds.position.x + 16, target_bounds.end.x - 16)
	for attempt in range(12):
		var here := route.to_local(player.global_position)
		var floor_body := _echo_floor(tier, here.x)
		var bounds := _bounds(floor_body)
		if absf(player.global_position.y + 10 - bounds.position.y) > 4:
			if not await _connected_step(floor_body, "Echo/corridor-rejoin"):
				return false
		if floor_body == target:
			if String(route.route_id) == "grotto":
				return await _walk_on_floor(goal, "Echo/corridor")
			# A landing can end only a few pixels inside the lip while still
			# carrying outward speed. Reverse with a real jump; merely holding
			# the other direction brakes too late and falls back into the shaft.
			if (player.global_position.x < target_bounds.position.x + 24 and player.velocity.x < 0) or (player.global_position.x > target_bounds.end.x - 24 and player.velocity.x > 0):
				player._try_jump()
			# Use the shared bounded combat walk: nearby foes beyond a shaft
			# are not a reason to chase off this confirmed floor segment.
			var previous_top := approach_floor_top
			approach_floor_top = target_bounds.position.y
			var reached := await _walk_on_floor(goal, "Hollow/corridor-approach")
			approach_floor_top = previous_top
			return reached
		var direction := signf(goal - player.global_position.x)
		var next_floor: StaticBody2D
		var distance := INF
		for child in route.get_children():
			if not child is StaticBody2D or not String(child.name).begins_with("Chamber%02dFloor" % tier):
				continue
			var candidate := _bounds(child)
			var delta := (candidate.get_center().x - bounds.get_center().x) * direction
			if delta > 0 and delta < distance:
				next_floor = child
				distance = delta
		_check(next_floor != null, "Echo corridor has no next floor")
		if next_floor == null:
			return false
		var next_bounds := _bounds(next_floor)
		var gap_left := bounds.end.x if direction > 0 else next_bounds.end.x
		var gap_right := next_bounds.position.x if direction > 0 else bounds.position.x
		var bridge: StaticBody2D
		for child in route.get_children():
			if child is StaticBody2D and String(child.name).contains("Rise01") and child.global_position.x > gap_left and child.global_position.x < gap_right and child.global_position.y > bounds.position.y and child.global_position.y < bounds.position.y + 75:
				bridge = child
		_check(bridge != null, "Echo shaft crossing has no top step")
		if bridge == null:
			return false
		if not await _walk_on_floor(bounds.end.x - 16 if direction > 0 else bounds.position.x + 16, "Echo/crossing-takeoff"):
			return false
		if not await _connected_step(bridge, "Echo/crossing") or not await _connected_step(next_floor, "Echo/crossing-exit"):
			return false
	_check(false, "Echo corridor retry limit")
	return false


func _save_echo_exit(game: Node) -> Node:
	var state := root.get_node("GameState")
	var hp: int = player.current_health
	var gold: int = state.gold
	var points: int = player.skill_points
	var inventory: Dictionary = state.inventory.duplicate(true)
	_check(state.current_room_id == "echo_grotto", "Echo exited before explicit interaction")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "", "Echo route snapshot", "echo_grotto"), "Echo snapshot failed")
	await _interact(room.get_node("GalleryDoor"))
	for frame in range(180):
		await physics_frame
		if not root.get_node("RoomTransition").is_transitioning:
			break
	_check(state.current_room_id == "echo_gallery", "Echo onward door failed")
	state.item_acquired.disconnect(_track_supplies)
	node_added.disconnect(_watch_foe)
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Echo snapshot load failed")
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	room = game.get_node("EchoGrotto")
	ui = game.get_node("UI")
	_check(state.current_room_id == "echo_grotto" and player.current_health == hp and player.max_health == 5, "Echo saved room/health changed")
	_check(player.skill_points == points and player.sword_mastery_unlocked and player.sword_reach_unlocked, "Echo saved earned build changed")
	_check(state.gold == gold and state.inventory.size() == inventory.size() and state.has_item("echo_charm"), "Echo saved quantities changed")
	# JSON restores numeric values as floats; compare quantities, not Variant
	# numeric types, while still checking every key and rejecting added items.
	for item_id in inventory:
		_check(state.inventory.has(item_id) and float(state.inventory.get(item_id, -1)) == float(inventory[item_id]), "Echo saved item quantity changed: " + str(item_id))
	_check(_route_geometry().get_node("FieldDiscoveries").completed, "Echo listening sequence did not persist")
	_check(bool(state.unlocked_shortcuts.get("echo_resonator_lower", false)) and bool(state.unlocked_shortcuts.get("echo_resonator_upper", false)), "Echo saved resonators reset")
	var reward := _route_geometry().get_node("RouteDiscoveryCache")
	_check(reward.opened and not reward.open(player), "Echo saved offering duplicated")
	_check(state.gold == gold and state.inventory.size() == inventory.size(), "Echo opened-cache refusal changed rewards")
	for item_id in inventory:
		_check(float(state.inventory.get(item_id, -1)) == float(inventory[item_id]), "Echo opened-cache refusal changed quantity: " + str(item_id))
	if failures.is_empty():
		print("ECHO GROTTO EARNED BUILD TEST PASSED: resonators, nine galleries, four branches, listening sequence, offering, onward exit and persistence")
	return game
