extends "res://tests/boss_combat_presentation_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_boss_motion.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.process_mode = Node.PROCESS_MODE_DISABLED
	await process_frame
	await process_frame
	var player: Player = game.get_node("Player")
	for data in CASES:
		var boss: CharacterBody2D = load("res://%s.tscn" % data[0]).instantiate()
		game.add_child(boss)
		boss.set_physics_process(false)
		boss.target_player = player
		player.global_position = boss.global_position + Vector2(150, 0)
		var art := boss.get_node("PaintedAppearance")
		var effects := boss.get_node("CombatPresentation")
		if art.property_names.has("active"):
			boss.active = true
		for cooldown in ["shot_cooldown", "volley_cooldown"]:
			if art.property_names.has(cooldown):
				boss.set(cooldown, 5.0)
		boss.velocity.x = 200
		var starting_stride: float = art.stride_distance
		art._process(0.2)
		_check((art.pose_index == 0 or data[0] == "EchoMatriarch") and art.stride_distance == starting_stride, data[0] + ": blocked velocity produced walking")
		for tick in range(2):
			boss.position.x += 7
			art._process(1.0 / 60)
		_check(art.pose_index == 1 and art.frame in range(1, 7), data[0] + ": no registered locomotion frame")
		if data[0] != "EchoMatriarch":
			_check(art.pose_blend.visible and art.blend_remaining > 0, data[0] + ": no walking transition")
		_check(is_equal_approx(art.self_modulate.a + art.pose_blend.self_modulate.a, 1.0), data[0] + ": transition doubles brightness")
		art._process(1.0 / 120)
		_check(art.pose_index == 1 and art.motion_state == "stride", data[0] + ": render frame between physics ticks flashes idle")
		art._process(0.2)
		_check(not art.pose_blend.visible and art.self_modulate.a == 1.0, data[0] + ": transition did not settle")
		var distance_before: float = art.stride_distance
		boss.position.x += 1000
		art._process(0.016)
		_check(art.stride_distance == distance_before, data[0] + ": teleport counted as steps")
		for fps in [30, 120]:
			art.stride_distance = 0
			for tick in range(fps):
				boss.position.x += 60.0 / fps
				art._process(1.0 / fps)
			_check(is_equal_approx(art.stride_distance, 60), data[0] + ": stride depends on frame rate")
		if art.property_names.has("charge_remaining"):
			boss.charge_remaining = 0.4
			boss.charge_direction = -1
			for cooldown in ["shot_cooldown", "volley_cooldown"]:
				if art.property_names.has(cooldown):
					boss.set(cooldown, 0.1)
			_check(effects.sample_windup() == 0, data[0] + ": charge accidentally anticipates another volley")
			art._process(0.016)
			_check(art.motion_state == "charge" and art.flip_h, data[0] + ": charge motion priority/facing wrong")
			boss.charge_remaining = 0
			boss.recovery_remaining = 0.5
			art._process(0.016)
			_check(art.motion_state == "recover" and effects.sample_windup() == 0, data[0] + ": recovery interrupted by pre-cue")
		var anchor: Vector2 = boss.position
		boss.health_changed.emit(boss.current_health - 1, boss.max_health)
		art._process(0.016)
		_check(absf(art.position.x) > 0.1 and boss.position == anchor, data[0] + ": cosmetic hit reaction moved collision body")
		art._process(0.5)
		_check(absf(art.position.x) < 0.01, data[0] + ": recoil did not settle")
		boss.hide()
		art._process(0.1)
		_check(not art.pose_blend.visible and art.self_modulate.a == 1.0, data[0] + ": stale crossfade after hide")
		boss.queue_free()
		await process_frame
	var surface_count := 0
	for path in ["TrainingPassageDecor/SentinelRelics", "VerticalChamber/ArenaRelics", "ResonanceSanctum/ArenaRelics", "CastellanThrone/ArenaRelics", "AshArena/ArenaRelics", "StarfallEmptyCourt/ArenaRelics", "StarfallHollowThrone/ArenaRelics"]:
		var relic := game.get_node(path)
		_check(not relic.finished_surfaces.is_empty(), path + ": missing arena surface finish")
		var count: int = relic.finished_surfaces.size()
		relic._finish_surfaces()
		_check(relic.finished_surfaces.size() == count, path + ": duplicated surface pass")
		for detail in relic.finished_surfaces:
			var original := detail.get_parent() as Polygon2D
			var rect := Rect2(original.polygon[0], Vector2.ZERO)
			for point in original.polygon:
				rect = rect.expand(point)
			_check(rect.encloses(detail.bounds) and (detail.stone == original.texture or detail.fill_base), path + ": material detail leaves authored surface")
			_check(not detail.is_processing(), path + ": static finish doing per-frame work")
			surface_count += 1
	var castellan := game.get_node("CastellanThrone/AshCastellan")
	game.get_node("CastellanThrone").show()
	castellan.active = true
	castellan._start_eruption()
	var warning := castellan.get_node("EruptionMiddle/AnimatedWarning")
	warning._process(0.01)
	castellan.eruption_windup *= 0.5
	warning._process(0.01)
	_check(is_equal_approx(warning.charge_progress, 0.5), "Warning progress isn't tied to authoritative windup")
	castellan._hide_eruption_marks()
	warning._process(0.01)
	_check(warning.peak_remaining == 0 and warning.charge_progress == 0, "Hidden marker retains old attack progress")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("BOSS MOTION TEST PASSED: 7 actors, distance-based stride, transitions, recoil, charge priority, timed warnings; ", surface_count, " bounded material surfaces")
	quit(0 if failures.is_empty() else 1)
