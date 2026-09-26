extends "res://tests/shaft_hollow_smoke.gd"

# Real walking along each final lift approach and real transition/save logic.
# Test setup moves the player between rooms/terminals and defeats nearby foes;
# it is NOT a whole-room traversal or an end-to-end combat playthrough.
const ROUTES := {"ShaftHollow": "hollow", "DrownedCrossing": "crossing", "FloodedGallery": "gallery", "BlackwaterCistern": "cistern", "WardenApproach": "approach"}
var walks := 0
var trips := 0


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_shaft_return_lift_save.json"
	state.start_new_game("normal")
	var game := load("res://Game.tscn").instantiate() as Node2D
	root.add_child(game)
	current_scene = game
	await process_frame
	var player := game.get_node("Player") as Player
	player.set_physics_process(false)
	player.double_jump_unlocked = false
	player.dash_unlocked = false
	for scene_name in ROUTES:
		var room_id := "shaft_" + String(ROUTES[scene_name])
		state.set_current_room(room_id)
		await process_frame
		var room := game.get_node(String(scene_name)) as Node2D
		var route := room.get_node("ExpandedRoute/AuthoredDescent")
		room.process_mode = Node.PROCESS_MODE_DISABLED
		for actor in room.find_children("*", "CollisionObject2D", true, false):
			actor.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if actor is Area2D or actor.is_in_group("enemy") or actor.is_in_group("neutral_creature") or actor.is_in_group("breakable"):
				actor.collision_layer = 0
				actor.collision_mask = 0
		var top := route.get_node("ReturnLiftTop")
		var bottom := route.get_node("ReturnLiftBottom")
		var event := InputEventAction.new()
		event.action = "interact"
		event.pressed = true
		var denials: Array[String] = []
		for terminal in [top, bottom]:
			terminal.lift_blocked.connect(func(message: String) -> void: denials.append(message))
			for enemy in get_nodes_in_group("shaft_enemy"):
				if not enemy.is_dead and enemy.global_position.distance_to(terminal.global_position) < 180:
					enemy.take_damage(enemy.max_health)
		await process_frame
		player.global_position = top.global_position
		top.player_in_range = player
		top._unhandled_input(event)
		_check(not state.unlocked_shortcuts.get(bottom.shortcut_id, false) and not root.get_node("RoomTransition").is_transitioning and denials.size() == 1, scene_name + ": upper lift bypassed first-clear activation")
		# One initial placement, then walk to the lower terminal and back.
		var approach: Vector2 = bottom.global_position + Vector2(-180, 0)
		player.global_position = approach
		player.velocity = Vector2.ZERO
		player.set_physics_process(true)
		await _walk(player, bottom.global_position.x, scene_name + "/approach")
		await _walk(player, approach.x, scene_name + "/return")
		player.set_physics_process(false)
		player.global_position = bottom.global_position
		bottom.player_in_range = player
		player.is_dead = true
		bottom._unhandled_input(event)
		_check(not state.unlocked_shortcuts.get(bottom.shortcut_id, false) and not root.get_node("RoomTransition").is_transitioning, scene_name + ": dead player activated lift")
		player.is_dead = false
		var real_target: StringName = bottom.target_marker_group
		bottom.target_marker_group = &"missing_return_lift_test_target"
		bottom._unhandled_input(event)
		_check(not state.unlocked_shortcuts.get(bottom.shortcut_id, false) and denials.back().contains("jammed"), scene_name + ": broken destination permanently unlocked lift")
		bottom.target_marker_group = real_target
		root.get_node("RoomTransition").is_transitioning = true
		bottom._unhandled_input(event)
		_check(not state.unlocked_shortcuts.get(bottom.shortcut_id, false), scene_name + ": overlapping transition unlocked lift")
		root.get_node("RoomTransition").is_transitioning = false
		var guard := load("res://ShaftCrawler.tscn").instantiate() as CharacterBody2D
		room.add_child(guard)
		guard.global_position = bottom.global_position + Vector2(35, 0)
		player.global_position = bottom.global_position
		bottom.player_in_range = player
		bottom._unhandled_input(event)
		_check(not state.unlocked_shortcuts.get(bottom.shortcut_id, false) and denials.back().contains("nearby enemies"), scene_name + ": lift ignored a living guard")
		guard.take_damage(guard.max_health)
		await process_frame
		game.get_node("SentinelBoss").active = true
		bottom._unhandled_input(event)
		_check(not state.unlocked_shortcuts.get(bottom.shortcut_id, false) and denials.back().contains("boss fight"), scene_name + ": lift bypassed encounter lock")
		game.get_node("SentinelBoss").active = false
		bottom._unhandled_input(event)
		await _wait_for_transition(player)
		trips += 1
		_check(state.unlocked_shortcuts.get(bottom.shortcut_id, false), scene_name + ": lower terminal did not unlock shortcut")
		_check(player.global_position.distance_to(route.get_node("ReturnTop").global_position) < 2 and state.current_room_id == room_id, scene_name + ": wrong upper arrival")
		player.global_position = top.global_position
		top.player_in_range = player
		top._unhandled_input(event)
		await _wait_for_transition(player)
		trips += 1
		_check(player.global_position.distance_to(route.get_node("ReturnBottom").global_position) < 2 and state.current_room_id == room_id, scene_name + ": wrong lower arrival")
		player.set_physics_process(true)
		await _walk(player, bottom.global_position.x, scene_name + "/arrival-to-terminal")
		player.set_physics_process(false)
	# Saving/reloading must retain the discovered return routes after awakening.
	state.set_zone_tier("sunken_shaft", 1)
	var checkpoint := game.get_node("WardenApproach/ApproachLamp/RespawnPoint") as Node2D
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), checkpoint.global_position, "warden_approach_lamp", "Warden Approach Lamp", "shaft_approach"), "Return shortcuts could not save")
	state.unlocked_shortcuts.clear()
	_check(state.load_game(), "Return shortcuts could not load")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	_check(state.get_zone_tier("sunken_shaft") == 1, "Awakened tier did not restore")
	player = game.get_node("Player")
	player.set_physics_process(false)
	for scene_name in ROUTES:
		var room_id := "shaft_" + String(ROUTES[scene_name])
		state.set_current_room(room_id)
		await process_frame
		game.get_node(String(scene_name)).process_mode = Node.PROCESS_MODE_DISABLED
		var lift := game.get_node(String(scene_name) + "/ExpandedRoute/AuthoredDescent/ReturnLiftTop")
		_check(state.unlocked_shortcuts.get(lift.shortcut_id, false) and lift.prompt.text == "[E] RETURN LIFT", scene_name + ": saved lift relocked")
		for enemy in get_nodes_in_group("shaft_enemy"):
			if not enemy.is_dead and enemy.global_position.distance_to(lift.global_position) < 180:
				enemy.take_damage(enemy.max_health)
		player.global_position = lift.global_position
		lift.player_in_range = player
		var event := InputEventAction.new()
		event.action = "interact"
		event.pressed = true
		lift._unhandled_input(event)
		await _wait_for_transition(player)
		trips += 1
		var arrival := lift.get_parent().get_node("ReturnBottom") as Node2D
		_check(state.current_room_id == room_id and player.global_position.distance_to(arrival.global_position) < 2, scene_name + ": awakened saved lift did not reach the gallery")
	state.delete_save()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("SHAFT RETURN LIFT TEST PASSED: ", walks, " continuous local walks, ", trips, " trips, 5 saved shortcuts")
		quit(0)
	else:
		print("SHAFT RETURN LIFT TEST FAILED: ", failures.size())
		quit(1)


func _walk(player: Player, goal_x: float, label: String) -> void:
	walks += 1
	var reached := false
	var start_y := player.global_position.y
	for frame in range(600):
		Input.action_release("ui_left")
		Input.action_release("ui_right")
		var dx := goal_x - player.global_position.x
		if absf(dx) > 3:
			Input.action_press("ui_right" if dx > 0 else "ui_left")
		await physics_frame
		if player.is_on_floor() and absf(player.global_position.x - goal_x) < 4:
			reached = true
			break
		if player.global_position.y > start_y + 65:
			break
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	_check(reached, label + ": lift approach is not walkable; stopped at " + str(player.global_position))
