extends "res://tests/preview_characters.gd"
## Real authored arenas and native warning/release, staged without player input.
func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_encounter_review.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.get_node("UI").hide()
	var player := game.get_node("Player")
	player.get_node("Camera2D").enabled = false
	for body in game.find_children("*", "CollisionObject2D", true, false):
		body.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var cases := [
		[".", "training_passage", "SentinelBoss", Vector2(1030, 265), 1.5],
		["VerticalChamber", "sunken_shaft", "AbyssWarden", Vector2(570, 515), 1.6],
		["ResonanceSanctum", "echo_sanctum", "EchoMatriarch", Vector2(500, 0), 1.5],
		["CastellanThrone", "ash_throne", "AshCastellan", Vector2(700, 270), 1.4],
		["StarfallEmptyCourt", "starfall_empty_court", "Guardian", Vector2(960, 235), 1.0],
		["StarfallHollowThrone", "starfall_hollow_throne", "HollowSovereign", Vector2(1090, 265), 1.0],
		["AshArena", "ash_arena", "MarshalReview", Vector2(780, 265), 1.0],
	]
	for data in cases:
		state.set_current_room(data[1])
		game.get_node("Background/BiomeBackdrop")._set_room(data[1], true)
		var room := game.get_node(data[0]) as Node2D
		room.show()
		if data[1] == "ash_arena":
			var marshal: Node2D = load("res://EmberMarshal.tscn").instantiate()
			marshal.name = "MarshalReview"
			marshal.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			marshal.position = Vector2(920, 400)
			room.add_child(marshal)
		var boss := room.get_node(data[2])
		if "active" in boss: boss.active = true
		player.global_position = boss.global_position + Vector2(-190, 10)
		boss.target_player = player
		var zoom: float = data[4]
		root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), Vector2(640, 360) - room.to_global(data[3]) * zoom)
		var effects := boss.get_node("CombatPresentation")
		var art := boss.get_node("PaintedAppearance")
		match data[1]:
			"training_passage": boss._start_volley_windup()
			"sunken_shaft": boss._start_charge_windup()
			"echo_sanctum": boss._start_pulse()
			"ash_throne": boss._start_eruption()
			"starfall_empty_court": boss._start_pulse()
			"starfall_hollow_throne": boss._start_pattern("starfall")
			"ash_arena": boss._start_charge()
		effects._process(0.2)
		art._process(0.2)
		await _capture("review_%s_warning" % data[1])
		match data[1]:
			"sunken_shaft", "ash_arena":
				# Run the actual charge windup through native physics, not an
				# unrelated volley while the charge lane is still on screen.
				while boss.windup_remaining > 0:
					boss._physics_process(1.0 / 60)
					effects._process(1.0 / 60)
					art._process(1.0 / 60)
					await physics_frame
				boss._physics_process(1.0 / 60)
			"ash_throne": boss._release_eruption()
			"starfall_empty_court": boss._release_pulse()
			"starfall_hollow_throne": boss._release_pattern()
			"echo_sanctum":
				boss.pulse_windup = 0
				boss.pulse_ring.hide()
				boss._fire_ring()
			_:
				boss.windup_remaining = 0
				boss._fire_volley()
		for effect in get_nodes_in_group("boss_cosmetic_effect"):
			if not effect.is_queued_for_deletion(): effect._process(0.08)
		effects._process(0.02)
		art._process(0.02)
		await _capture("review_%s_release" % data[1])
		boss.get_node("EncounterSafety")._abort()
		if room != game: room.hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
