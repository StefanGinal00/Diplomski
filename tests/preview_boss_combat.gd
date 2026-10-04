extends "res://tests/preview_characters.gd"

func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_boss_combat_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.get_node("UI").hide()
	var player := game.get_node("Player")
	player.get_node("Camera2D").enabled = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	for data in [["CastellanThrone", "ash_throne", "AshCastellan", Vector2(700, 300)], ["StarfallHollowThrone", "starfall_hollow_throne", "HollowSovereign", Vector2(1090, 300)], ["ResonanceSanctum", "echo_sanctum", "EchoMatriarch", Vector2(500, 0)]]:
		state.set_current_room(data[1])
		game.get_node("Background/BiomeBackdrop")._set_room(data[1], true)
		var room := game.get_node(data[0]) as Node2D
		room.show()
		var boss := room.get_node(data[2])
		boss.active = true
		player.global_position = boss.global_position + Vector2(-190, 10)
		var zoom := 1.5
		root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), Vector2(640, 360) - room.to_global(data[3]) * zoom)
		var effects := boss.get_node("CombatPresentation")
		var art := boss.get_node("PaintedAppearance")
		if data[2] == "AshCastellan":
			boss._start_eruption()
		elif data[2] == "HollowSovereign":
			boss._start_pattern("starfall")
		else:
			boss._start_pulse()
		effects._process(0.2)
		art._process(0.2)
		await _capture("boss_%s_warning" % data[1])
		if data[2] == "AshCastellan":
			boss._release_eruption()
		elif data[2] == "HollowSovereign":
			boss._release_pattern()
		else:
			boss.pulse_windup = 0.0
			boss.pulse_ring.hide()
			boss._fire_ring()
		for effect in get_nodes_in_group("boss_cosmetic_effect"):
			effect._process(0.08)
		effects._process(0.02)
		art._process(0.02)
		await _capture("boss_%s_release" % data[1])
		effects.awakened = true
		effects._process(0.3)
		await _capture("boss_%s_aura" % data[1])
		room.hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
