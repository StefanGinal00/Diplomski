extends "res://tests/boss_combat_presentation_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_boss_locomotion.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.process_mode = Node.PROCESS_MODE_DISABLED
	await process_frame
	var player: Player = game.get_node("Player")
	for data in CASES.slice(1):
		state.current_room_id = data[1]
		var room := Node2D.new()
		root.add_child(room)
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var boss: CharacterBody2D = load("res://%s.tscn" % data[0]).instantiate()
		boss.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
		room.add_child(boss)
		boss.target_player = player
		var safety := boss.get_node("EncounterSafety")
		var start := Vector2(700, -5000)
		if data[0] == "AbyssWarden": boss.arena_anchor_x = start.x
		if data[0] == "EchoMatriarch": boss.anchor_position = start
		for fps in [30, 60, 120]:
			boss.position = start
			boss.velocity = Vector2.ZERO
			if safety.properties.has("active"): boss.active = true
			for key in safety.COOLDOWNS:
				if safety.properties.has(key): boss.set(key, 5.0)
			player.global_position = start + Vector2(180, 0)
			boss._physics_process(1.0 / fps)
			var expected: float = (240.0 if data[0] == "EchoMatriarch" else 220.0) / fps
			var actual := boss.velocity.length() if data[0] == "EchoMatriarch" else absf(boss.velocity.x)
			_check(is_equal_approx(actual, expected), data[0] + ": native acceleration at " + str(fps))
			var art := boss.get_node("PaintedAppearance")
			art._apply_pose(0)
			var facing: bool = art.flip_h
			for offset in [-5, 5, -2, 2]:
				player.global_position.x = boss.global_position.x + offset
				art._apply_pose(0)
				_check(art.flip_h == facing, data[0] + ": pivot jitter")
		if safety.properties.has("charge_remaining"):
			for direction in [-1.0, 1.0]:
				var edge: float
				if data[0] == "AbyssWarden":
					edge = boss.arena_anchor_x + (boss.arena_left_offset if direction < 0 else boss.arena_right_offset)
				else: edge = boss.arena_left_x if direction < 0 else boss.arena_right_x
				boss.position = Vector2(edge, -5000)
				boss.charge_direction = direction
				boss.charge_remaining = 0.4
				boss.recovery_remaining = 0
				boss._physics_process(1.0 / 60)
				_check(boss.velocity.x == 0 and boss.charge_remaining == 0 and boss.recovery_remaining > 0, data[0] + ": edge charge did not recover")
		if data[0] == "AbyssWarden":
			player.global_position.x = boss.global_position.x
			boss._start_charge_windup()
			_check(absf(boss.charge_direction) == 1, "Warden zero-direction charge")
		room.queue_free()
		await process_frame
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty(): print("BOSS LOCOMOTION TEST PASSED: native 30/60/120 Hz acceleration, facing deadzone, both arena edges, Warden vertical target")
	quit(0 if failures.is_empty() else 1)
