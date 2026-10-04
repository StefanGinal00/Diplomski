extends "res://tests/boss_combat_presentation_smoke.gd"
## Exercises actual physics in the authored starting arena, not just poses.

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_sentinel_combat_flow.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	for body in game.find_children("*", "CollisionObject2D", true, false):
		body.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var boss := game.get_node("SentinelBoss")
	var player: Player = game.get_node("Player")
	player.max_health = 100
	player.current_health = 100
	player.global_position = Vector2(945, 370)
	boss.target_player = player
	boss.global_position = Vector2(1130, 370)
	boss.facing_direction = -1
	boss._update_facing_markers()
	boss.shot_cooldown = 0.3
	var art := boss.get_node("PaintedAppearance")
	var effects := boss.get_node("CombatPresentation")
	await physics_frame
	var stages: Array[String] = []
	var locked := Vector2.ZERO
	var planted_x := 0.0
	var windup_ticks := 0
	var recover_ticks := 0
	var crossed := false
	for tick in range(145):
		boss._physics_process(1.0 / 60)
		art._process(1.0 / 60)
		effects._process(1.0 / 60)
		if stages.is_empty() or stages.back() != boss.combat_state:
			stages.append(boss.combat_state)
		if tick == 0:
			_check(absf(boss.velocity.x) < boss.move_speed, "Initial movement snapped to maximum speed")
		if boss.combat_state == "windup":
			windup_ticks += 1
			if windup_ticks == 1:
				locked = boss.locked_shot_direction
				planted_x = boss.global_position.x
				player.global_position.x = boss.global_position.x + 100
				crossed = true
			_check(is_equal_approx(boss.global_position.x, planted_x), "Feet slid during windup")
			_check(boss.facing_direction == -1 and art.flip_h, "Crossing player turned charging body")
			_check(boss.locked_shot_direction.is_equal_approx(locked), "Committed aim tracked player behind boss")
			_check(effects.sample_windup() > 0, "Real windup missing from animation")
		elif boss.combat_state == "recover":
			recover_ticks += 1
			_check(is_equal_approx(boss.global_position.x, planted_x), "Recovery moved the actor")
			_check(art.pose_index == 3 and art.frame in [9, 10, 11] and effects.sample_windup() == 0, "Recovery animation re-entered charge")
			_check(boss.facing_direction == -1, "Recovery flipped toward player")
		if boss.combat_state == "turn" and recover_ticks > 0:
			break
		await physics_frame
	_check(crossed and windup_ticks >= 36 and recover_ticks >= 28, "Windup / punish window shortened unexpectedly")
	_check(stages == ["approach", "brake", "windup", "recover", "approach", "turn"], "Invalid combat flow: " + str(stages))
	var bolts := _bolts(boss)
	_check(bolts.size() == 1, "First attack didn't release exactly one bolt")
	if not bolts.is_empty():
		_check(bolts[0].direction.is_equal_approx(locked), "Released bolt ignored committed aim")
	for tick in range(16):
		boss._physics_process(1.0 / 60)
		await physics_frame
	_check(boss.facing_direction == 1, "Boss never completed deliberate turn")
	# Small crossings of the pivot must not cause twitching left/right.
	boss.shot_cooldown = 5
	for tick in range(12):
		player.global_position.x = boss.global_position.x + (5 if tick % 2 else -5)
		boss._update_combat(1.0 / 60)
	_check(boss.facing_direction == 1 and boss.combat_state == "approach", "Facing deadzone oscillates")
	# The faster phase still uses the same committed windup and full recovery.
	boss.phase = 2
	player.global_position.x = boss.global_position.x + 120
	boss._start_volley_windup()
	_check(is_equal_approx(boss.windup_remaining, 0.48), "Phase two lost its telegraph")
	for tick in range(29):
		boss._update_combat(1.0 / 60)
	bolts = _bolts(boss)
	_check(bolts.size() == 4 and boss.combat_state == "recover", "Phase two fan or recovery missing")
	# Aborted attacks must never release after death, room exit, or re-entry.
	boss._start_volley_windup()
	player.is_dead = true
	boss._physics_process(0.8)
	_check(boss.windup_remaining == 0 and _bolts(boss).is_empty(), "Player defeat didn't cancel pending shot and live bolts")
	player.is_dead = false
	boss.get_node("EncounterSafety").should_suspend()
	boss._start_volley_windup()
	state.current_room_id = "sunken_shaft"
	boss._physics_process(0.8)
	_check(not boss.active and boss.windup_remaining == 0 and _bolts(boss).is_empty(), "Room exit released a stale attack")
	state.current_room_id = "training_passage"
	boss.global_position.x = boss.arena_right - 0.1
	player.global_position.x = boss.arena_right + 170
	boss.velocity.x = boss.phase_two_speed
	boss.shot_cooldown = 5
	boss._physics_process(1.0 / 30)
	_check(boss.global_position.x <= boss.arena_right and boss.velocity.x == 0, "Arena edge overshoot wasn't stopped")
	# Acceleration itself is time-scaled at low and high update rates.
	for fps in [30, 120]:
		boss._cancel_attack()
		boss.velocity.x = 0
		boss.facing_direction = -1
		player.global_position.x = boss.global_position.x - 220
		for tick in range(fps / 5):
			boss._update_combat(1.0 / fps)
		_check(is_equal_approx(boss.velocity.x, -32), "Acceleration depends on frame rate: " + str(fps))
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("SENTINEL COMBAT FLOW TEST PASSED: braking, planting, committed aim, recovery, turning, fan, cancellation, boundaries, 30/120 Hz")
	quit(0 if failures.is_empty() else 1)

func _bolts(boss: Node) -> Array[Node]:
	var result: Array[Node] = []
	for bolt in get_nodes_in_group("enemy_projectile"):
		if bolt.source == boss and not bolt.is_queued_for_deletion():
			result.append(bolt)
	return result
