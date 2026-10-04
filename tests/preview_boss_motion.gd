extends "res://tests/preview_characters.gd"
## Deterministic time-stepped real encounter, not poses manually set for pictures.
func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_boss_motion_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.get_node("UI").hide()
	var player: Player = game.get_node("Player")
	player.get_node("Camera2D").enabled = false
	player.max_health = 100
	player.current_health = 100
	for body in game.find_children("*", "CollisionObject2D", true, false):
		body.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	game.process_mode = Node.PROCESS_MODE_DISABLED
	state.set_current_room("sunken_shaft")
	var room := game.get_node("VerticalChamber") as Node2D
	room.show()
	game.get_node("Background/BiomeBackdrop")._set_room("sunken_shaft", true)
	var boss := room.get_node("AbyssWarden")
	boss.active = true
	player.global_position = room.to_global(Vector2(400, 632))
	boss.target_player = player
	boss.shot_cooldown = 10
	boss._start_charge_windup()
	var art := boss.get_node("PaintedAppearance")
	var effects := boss.get_node("CombatPresentation")
	await physics_frame
	root.canvas_transform = Transform2D(Vector2(1.7, 0), Vector2(0, 1.7), Vector2(480, 270) - room.to_global(Vector2(570, 555)) * 1.7)
	for tick in range(121):
		boss._physics_process(1.0 / 60)
		art._process(1.0 / 60)
		effects._process(1.0 / 60)
		for warning in boss.find_children("AnimatedWarning", "Node2D", true, false):
			warning._process(1.0 / 60)
		for effect in get_nodes_in_group("boss_cosmetic_effect"):
			if not effect.is_queued_for_deletion():
				effect._process(1.0 / 60)
		if tick in [0, 20, 40, 48, 60, 76, 100, 120]:
			print("MOTION SAMPLE ", tick, " state=", art.motion_state, " pose=", art.frame, " x=", boss.position.x, " windup=", effects.windup)
			await _capture("boss_motion_%03d" % tick)
		await physics_frame
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
