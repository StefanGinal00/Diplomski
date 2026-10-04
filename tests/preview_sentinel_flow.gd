extends "res://tests/preview_characters.gd"
## Authored arena, actual boss physics; fixed timeline with a player crossover.
func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_sentinel_flow_preview.json"
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
	var boss := game.get_node("SentinelBoss")
	boss.global_position = Vector2(1140, 370)
	player.global_position = Vector2(950, 370)
	boss.target_player = player
	boss.shot_cooldown = 0.4
	boss.facing_direction = -1
	boss._update_facing_markers()
	var art := boss.get_node("PaintedAppearance")
	var effects := boss.get_node("CombatPresentation")
	await physics_frame
	root.canvas_transform = Transform2D(Vector2(2, 0), Vector2(0, 2), Vector2(480, 360) - Vector2(1090, 370) * 2)
	var previous := ""
	var captured: Dictionary = {}
	for tick in range(240):
		# Player crosses only after the charge has committed, illustrating dodge.
		if tick == 52:
			player.global_position = Vector2(1225, 370)
		boss._physics_process(1.0 / 60)
		art._process(1.0 / 60)
		effects._process(1.0 / 60)
		for projectile in get_nodes_in_group("enemy_projectile"):
			if projectile.source == boss and not projectile.is_queued_for_deletion():
				projectile._physics_process(1.0 / 60)
		for effect in get_nodes_in_group("boss_cosmetic_effect"):
			if not effect.is_queued_for_deletion():
				effect._process(1.0 / 60)
		if previous != boss.combat_state:
			print("SENTINEL tick=", tick, " state=", boss.combat_state, " x=", boss.position.x, " vx=", boss.velocity.x, " facing=", boss.facing_direction)
			previous = boss.combat_state
		var stage: String = boss.combat_state
		var ready_to_capture: bool = stage != "windup" or boss.windup_remaining < 0.3
		if stage == "recover":
			ready_to_capture = boss.recovery_remaining < 0.32
		elif stage == "turn":
			ready_to_capture = boss.turn_remaining < 0.13
		if ready_to_capture and not captured.has(stage):
			captured[stage] = true
			await _capture("sentinel_flow_" + stage)
		await physics_frame
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
