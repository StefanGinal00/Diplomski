extends "res://tests/boss_combat_presentation_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_boss_transition_readability.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player")
	for data in CASES:
		var boss: CharacterBody2D = load("res://%s.tscn" % data[0]).instantiate()
		game.add_child(boss)
		boss.target_player = player
		player.global_position = boss.global_position + Vector2(200, 0)
		var art := boss.get_node("PaintedAppearance")
		var fx := boss.get_node("CombatPresentation")
		if art.property_names.has("active"): boss.active = true
		for key in ["shot_cooldown", "volley_cooldown"]:
			if art.property_names.has(key): boss.set(key, 5.0)
		var hp: int = boss.current_health
		var collider := boss.get_node("CollisionShape2D") as CollisionShape2D
		var original_shape := collider.shape
		for fps in [30, 60, 120]:
			art._reset_transients()
			art._apply_pose(0)
			var last_blend := 1.0
			for tick in range(fps / 2):
				boss.position.x += 14
				art._process(1.0 / fps)
				_check(art.blend_remaining <= last_blend, data[0] + ": gait repeatedly restarts crossfade")
				last_blend = art.blend_remaining
			_check(art.blend_remaining == 0 and art.self_modulate.a == 1, data[0] + ": gait remains translucent at %d FPS" % fps)
		if art.property_names.has("charge_remaining"):
			boss.charge_direction = -1
			boss.charge_remaining = 0.4
			art.blend_remaining = 0.07
			art._process(1.0 / 120)
			_check(art.frame == 9 and art.self_modulate.a == 1 and not art.pose_blend.visible, data[0] + ": charge impact hidden by anticipation crossfade")
			fx._process(0.07)
			_check(not fx.ghosts.is_empty(), data[0] + ": missing active charge trail")
			boss.charge_remaining = 0
			boss.recovery_remaining = 0.5
			player.global_position = boss.global_position + Vector2(200, 0)
			art._process(0.02)
			_check(art.flip_h, data[0] + ": recovery flips toward dodging player")
			boss.recovery_remaining = 0
			fx.release_remaining = 0
			if not art.property_names.has("facing_direction"):
				art._process(0.2)
				_check(not art.flip_h, data[0] + ": facing never unlocks after recovery")
		var windup_key := "windup_remaining"
		if art.property_names.has("charge_windup"): windup_key = "charge_windup"
		elif art.property_names.has("pulse_windup"): windup_key = "pulse_windup"
		boss.set(windup_key, 0.6)
		fx.age = 99.2
		fx._process(0)
		_check(fx.preparation_frame == 0, data[0] + ": windup starts at arbitrary world-age frame")
		boss.set(windup_key, 0.2)
		fx._process(0.4)
		_check(fx.preparation_frame == 1, data[0] + ": windup did not progress")
		boss.set(windup_key, 0.05)
		fx._process(0.15)
		_check(fx.preparation_frame == 1, data[0] + ": windup reverses")
		boss.set(windup_key, 0)
		fx.release("volley")
		art.hurt_remaining = 0.1
		art.recoil = 2
		# A streamed room disables processing when hidden. No manual _process
		# calls here: visibility signals must clear presentation immediately.
		boss.hide()
		_check(fx.release_remaining == 0 and not fx.charging and fx.ghosts.is_empty(), data[0] + ": hidden room retains release/trails")
		_check(art.hurt_remaining == 0 and art.recoil == 0 and art.blend_remaining == 0, data[0] + ": hidden room retains hurt/blend")
		boss.show()
		fx._process(0)
		_check(fx.preparation_frame == 0 and fx.windup_peak == 0, data[0] + ": stale windup after re-entry")
		_check(boss.current_health == hp and collider.shape == original_shape, data[0] + ": presentation changed health/collision")
		boss.free()
	var castellan := game.get_node("CastellanThrone/AshCastellan")
	game.get_node("CastellanThrone").show()
	castellan.active = true
	castellan._start_eruption()
	var marker := castellan.get_node("EruptionMiddle")
	var warning := marker.get_node("AnimatedWarning")
	warning._process(0)
	castellan.eruption_windup *= 0.2
	warning._process(0)
	_check(warning.animation_frame == 1, "Ground warning progression")
	marker.hide()
	_check(warning.peak_remaining == 0 and warning.animation_frame == 0 and not warning.preparing, "Disabled hidden marker retains warning progress")
	castellan.eruption_windup = 0.3
	marker.show()
	warning._process(0)
	_check(warning.animation_frame == 0 and warning.charge_progress == 0, "New shorter warning inherits old progress")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("TEST PASSED: seven boss/miniboss transitions, 30/60/120fps opaque gait, immediate charge, committed recovery, monotonic cues and disabled-room resets")
	quit(0 if failures.is_empty() else 1)
