extends "res://tests/preview_characters.gd"
## Native defeat callbacks; deterministic dissolve samples, not a full fight.
func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_boss_defeat_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.get_node("UI").hide()
	var player: Player = game.get_node("Player")
	player.get_node("Camera2D").enabled = false
	for entry in [["CastellanThrone", "ash_throne", "AshCastellan"], ["ResonanceSanctum", "echo_sanctum", "EchoMatriarch"], ["AshArena", "ash_arena", "EmberMarshal"]]:
		state.set_current_room(entry[1])
		game.get_node("Background/BiomeBackdrop")._set_room(entry[1], true)
		var room := game.get_node(entry[0]) as Node2D
		room.show()
		var boss: CharacterBody2D
		if entry[2] == "EmberMarshal":
			boss = load("res://EmberMarshal.tscn").instantiate()
			room.get_node("Combatants").add_child(boss)
			boss.position = Vector2(1060, 401)
		else:
			boss = room.get_node(entry[2])
			boss.active = true
		player.global_position = boss.global_position + Vector2(-110, 0)
		boss.target_player = player
		var art := boss.get_node("PaintedAppearance")
		art._apply_pose(0)
		root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2(480, 270) - (boss.global_position + Vector2(0, -38)) * 2.5)
		await _capture("defeat_%s_before" % entry[2])
		boss.take_damage(999)
		for stage in range(4):
			if stage > 0:
				for effect in get_nodes_in_group("boss_cosmetic_effect"):
					if not effect.is_queued_for_deletion():
						effect._process(0.19)
			await _capture("defeat_%s_%d" % [entry[2], stage])
		room.hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
