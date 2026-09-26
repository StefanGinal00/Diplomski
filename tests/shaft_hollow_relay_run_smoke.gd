extends "res://tests/shaft_hollow_entry_combat_smoke.gd"

# Connected upper-route acceptance: entrance -> guardians -> relay -> Drift
# door, not the whole expanded Hollow. 5 HP / starter sword, all actors live.
# Preparation explicitly supplies 36 Gold to BUY two ordinary herbs; no
# healing/stat cheats or teleporting after initial entrance placement.
var ui: Node
var herbs_used := 0
var hazard_retreats := 0
var damage_log: Array[String] = []


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_shaft_hollow_relay_run_save.json"
	state.start_new_game("normal")
	var game := load("res://Game.tscn").instantiate() as Node
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	ui = game.get_node("UI")
	state.add_gold(36)
	ui._open_shop(game.get_node("WayfarerMerchant"))
	ui.selected_shop_item_id = "healing_herb"
	ui._on_shop_buy_pressed()
	ui.selected_shop_item_id = "healing_herb"
	ui._on_shop_buy_pressed()
	ui._close_shop()
	_check(state.inventory.get("healing_herb", 0) == 2 and state.gold == 0, "Two-herb purchase setup failed")
	state.set_current_room("shaft_hollow")
	await process_frame
	room = game.get_node("ShaftHollow")
	player.global_position = room.get_node("UpperEntry").global_position
	player.velocity = Vector2.ZERO
	for node in get_nodes_in_group("enemy"):
		if room.is_ancestor_of(node):
			node.defeated.connect(func(): defeats += 1)
	player.set_physics_process(true)
	player.health_changed.connect(func(hp: int, _maximum: int): damage_log.append("HP %d at %s, frame %d" % [hp, room.to_local(player.global_position), frames]))
	var reached := true
	for point in [Vector2(1500, 310), Vector2(1530, 362), Vector2(1670, 670), Vector2(2390, 670)]:
		if not await _walk_to(point, 2400):
			reached = false
			break
	# A dodged dive can leave the far guardian back at its anchor, outside
	# the driver's 150-pixel local scan. Actually backtrack to finish it;
	# reaching the relay must not bypass its unchanged guardian requirement.
	for attempt in range(3):
		var guardian := room.get_node_or_null("HollowWispFar")
		if not reached or guardian == null or guardian.is_dead:
			break
		reached = await _walk_to(Vector2(guardian.position.x, 670), 1800)
	if reached:
		reached = await _walk_to(Vector2(2390, 670), 1800)
	if reached:
		var relay := room.get_node("Relay")
		for guardian in ["HollowWispNear", "HollowWispFar"]:
			var survivor := room.get_node_or_null(guardian)
			if survivor != null and not survivor.is_dead:
				print("UNFINISHED RELAY GUARDIAN ", guardian, " at ", survivor.position, " HP ", survivor.current_health)
		_check(relay.player_in_range == player, "Relay range not reached physically")
		var event := InputEventAction.new()
		event.action = "interact"
		event.pressed = true
		relay._unhandled_input(event)
		_check(relay.is_active, "Connected combat did not clear both original guardians")
		reached = await _walk_to(room.get_node("DriftDoor").position, 1800)
		if reached:
			var door := room.get_node("DriftDoor")
			_check(door.nearby_player == player, "Door range not reached physically")
			_check(state.current_room_id == "shaft_hollow", "Door crossed without interaction")
			door._unhandled_input(event)
			await _wait_for_transition(player)
			_check(state.current_room_id == "shaft_drift", "Driftworks exit failed")
	_check(reached and not player.is_dead and player.max_health == 5, "Upper route did not finish with normal health")
	_check(defeats >= 6 and hazard_retreats > 0, "Upper route skipped live combat or hazard steering")
	_check(herbs_used <= 2, "Pilot exceeded its finite herb allowance")
	print("RELAY RUN END: ", defeats, " defeats, ", herbs_used, " of 2 purchased herbs, ", player.current_health, "/5 HP, ", hazard_retreats, " hazard steering frames, ", frames, " frames")
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	state.delete_save()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("SHAFT HOLLOW RELAY RUN TEST PASSED")
		quit(0)
	else:
		print("HEALTH TRACE: ", damage_log)
		print("SHAFT HOLLOW RELAY RUN TEST FAILED: ", failures.size())
		quit(1)


func _before_step() -> void:
	var state := root.get_node("GameState")
	# Clear destructible clutter with the real sword before jumping onto it.
	# Otherwise this pilot keeps fighting floor enemies from a low crate roof.
	player.attack_cast.force_shapecast_update()
	for hit in player.attack_cast.get_collision_count():
		var collider := player.attack_cast.get_collider(hit) as Node
		if collider != null and collider.is_in_group("breakable"):
			player.try_attack()
	if not player.is_dead and player.current_health <= 2 and state.has_item("healing_herb"):
		ui.selected_item_id = "healing_herb"
		var before: int = state.inventory.get("healing_herb", 0)
		ui._on_inventory_action_pressed()
		if int(state.inventory.get("healing_herb", 0)) == before - 1:
			herbs_used += 1


func _adjust_target(here: Vector2, target: Vector2, foe: Node2D) -> Vector2:
	if foe == null and target.y > here.y + 45 and player.is_on_floor():
		player._try_drop_through()
	for hazard in room.find_children("HollowRockfall*", "Area2D", true, false):
		if hazard.disabled or hazard.phase == "idle":
			continue
		var half: Vector2 = hazard.get_node("CollisionShape2D").shape.size * hazard.global_scale * 0.5
		var center := room.to_local(hazard.global_position)
		if absf(here.y - center.y) > half.y + 20:
			continue
		var left := center.x - half.x - 24
		var right := center.x + half.x + 24
		if here.x > left and here.x < right:
			hazard_retreats += 1
			return Vector2(left if here.x < center.x else right, here.y)
		if (here.x <= left and target.x > left) or (here.x >= right and target.x < right):
			return Vector2(minf(here.x, left) if here.x < center.x else maxf(here.x, right), here.y)
	return target
