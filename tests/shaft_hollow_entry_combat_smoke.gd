extends "res://tests/shaft_hollow_smoke.gd"

# Continuous first-corridor combat, NOT a whole-room acceptance test. Setup
# places the starter player at the normal entrance once; all room actors and
# hazards remain live, with normal health, damage, cooldowns and movement.
var player: Player
var room: Node2D
var frames := 0
var flank_direction := 0.0
var defeats := 0


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_shaft_hollow_entry_combat_save.json"
	state.start_new_game("normal")
	var game := load("res://Game.tscn").instantiate() as Node
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	state.set_current_room("shaft_hollow")
	await process_frame
	room = game.get_node("ShaftHollow")
	player.global_position = room.get_node("UpperEntry").global_position
	player.velocity = Vector2.ZERO
	for node in get_nodes_in_group("enemy"):
		if room.is_ancestor_of(node):
			node.defeated.connect(func(): defeats += 1)
	_check(player.max_health == 5 and player.current_health == 5, "Entry test does not start with ordinary health")
	player.set_physics_process(true)
	var reached := await _walk_to(Vector2(1500, 310), 1800)
	_check(reached and not player.is_dead and defeats >= 4, "First corridor combat not completed")
	_check(not room.has_node("HollowWispNear") or room.get_node("HollowWispNear").is_dead, "First main guardian survived corridor traversal")
	_check(room.has_node("HollowWispFar") and not room.get_node("Relay").is_active, "Entry clear unexpectedly completed the whole room")
	var health_left := player.current_health
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	state.delete_save()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("SHAFT HOLLOW ENTRY COMBAT TEST PASSED: continuous first corridor, ", defeats, " live defeats, ", health_left, "/5 HP remaining, no healing or teleports after entry")
		quit(0)
	else:
		print("SHAFT HOLLOW ENTRY COMBAT TEST FAILED: ", failures.size())
		quit(1)


func _walk_to(destination: Vector2, budget: int) -> bool:
	for frame in range(budget):
		frames += 1
		_before_step()
		if player.is_dead:
			for enemy in get_nodes_in_group("enemy"):
				if room.is_ancestor_of(enemy) and enemy.global_position.distance_to(player.global_position) < 160:
					print("NEAR DEATH: ", enemy.name, " ", room.to_local(enemy.global_position), " HP ", enemy.current_health)
			_check(false, "Connected pilot died")
			return false
		var here := room.to_local(player.global_position)
		Input.action_release("ui_left")
		Input.action_release("ui_right")
		var target := destination
		var foe: Node2D
		var nearest := 150.0
		for candidate in get_nodes_in_group("enemy"):
			if not is_instance_valid(candidate) or candidate.is_dead or not room.is_ancestor_of(candidate):
				continue
			var distance: float = player.global_position.distance_to(candidate.global_position)
			if distance < nearest:
				nearest = distance
				foe = candidate
		# Reaching the waypoint is not a cleared approach while a guardian
		# is still beside it. In particular, do not leave a live original wisp
		# behind and then report the relay interaction as a navigation failure.
		if foe == null and absf(here.x - destination.x) < 12 and absf(here.y - destination.y) < 35:
			return true
		if foe != null:
			target = room.to_local(foe.global_position)
			player.attack_cast.force_shapecast_update()
			for hit in player.attack_cast.get_collision_count():
				if player.attack_cast.get_collider(hit) == foe:
					player.try_attack()
			if target.y < here.y - 35 and absf(target.x - here.x) < 90 and player.is_on_floor():
				player._try_jump()
			if foe.get_script() == load("res://ShaftCrawler.gd") and foe.state == foe.State.WARNING and foe.state_remaining < 0.2 and player.is_on_floor():
				player._try_jump()
			if target.y > here.y + 25 and player.is_on_floor():
				if flank_direction == 0:
					flank_direction = 1.0 if target.x >= here.x else -1.0
				target.x = here.x + flank_direction * 70
			elif absf(target.y - here.y) < 25:
				flank_direction = 0
		else:
			flank_direction = 0
		var combat_target := target
		target = _adjust_target(here, target, foe)
		var navigation_override := not target.is_equal_approx(combat_target)
		var dx := target.x - here.x
		if absf(dx) > (42 if foe != null and not navigation_override else 10) or (foe != null and not navigation_override and signf(dx) != player.facing_direction):
			Input.action_press("ui_right" if dx > 0 else "ui_left")
		if player.is_on_wall() and player.is_on_floor():
			player._try_jump()
		await physics_frame
	_check(false, "Connected walk timed out at %s, target %s" % [room.to_local(player.global_position), destination])
	for candidate in get_nodes_in_group("enemy"):
		if room.is_ancestor_of(candidate) and player.global_position.distance_to(candidate.global_position) < 170:
			print("STALLED FOE ", candidate.name, " ", room.to_local(candidate.global_position), " HP ", candidate.current_health)
	return false


func _before_step() -> void:
	pass


func _adjust_target(_here: Vector2, target: Vector2, _foe: Node2D) -> Vector2:
	return target
