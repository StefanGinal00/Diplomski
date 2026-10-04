extends "res://tests/preview_characters.gd"
## Real miniboss physics in its authored arena; scripted target crossover.
## Player is stationary/test-repositioned, so this is not a manual fight.
func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_marshal_transitions_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("UI").hide()
	var player: Player = game.get_node("Player")
	player.get_node("Camera2D").enabled = false
	player.max_health = 100
	player.current_health = 100
	for body in game.find_children("*", "CollisionObject2D", true, false):
		body.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	game.process_mode = Node.PROCESS_MODE_DISABLED
	state.set_current_room("ash_arena")
	game.get_node("Background/BiomeBackdrop")._set_room("ash_arena", true)
	var room := game.get_node("AshArena") as Node2D
	room.show()
	var boss: CharacterBody2D = load("res://EmberMarshal.tscn").instantiate()
	room.get_node("Combatants").add_child(boss)
	boss.position = Vector2(1100, 401)
	boss.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	player.global_position = room.to_global(Vector2(950, 409))
	boss.target_player = player
	boss.volley_cooldown = 10
	boss.charge_cooldown = 10
	var art := boss.get_node("PaintedAppearance")
	var fx := boss.get_node("CombatPresentation")
	root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2(480, 270) - room.to_global(Vector2(1030, 350)) * 2.5)
	await physics_frame
	for tick in range(8):
		boss._physics_process(1.0 / 60)
		art._process(1.0 / 60)
		fx._process(1.0 / 60)
		await physics_frame
	boss._start_charge()
	var captured := {}
	var crossed := false
	for tick in range(145):
		boss._physics_process(1.0 / 60)
		art._process(1.0 / 60)
		fx._process(1.0 / 60)
		for warning in boss.find_children("AnimatedWarning", "Node2D", true, false):
			warning._process(1.0 / 60)
		for effect in get_nodes_in_group("boss_cosmetic_effect"):
			if not effect.is_queued_for_deletion():
				effect._process(1.0 / 60)
		var stage: String = art.motion_state
		var capture := stage in ["prepare", "charge", "recover"]
		if stage == "prepare": capture = boss.windup_remaining < 0.3
		if stage == "recover": capture = boss.recovery_remaining < 0.35
		if crossed and stage == "stride": capture = true
		if capture and not captured.has(stage):
			captured[stage] = true
			print("MARSHAL ", stage, " frame=", art.frame, " alpha=", art.self_modulate.a, " flip=", art.flip_h, " x=", boss.position.x)
			await _capture("marshal_transition_" + stage)
		if stage == "charge" and not crossed:
			player.global_position = boss.global_position + Vector2(85, 8)
			crossed = true
		await physics_frame
	if not (captured.has("prepare") and captured.has("charge") and captured.has("recover") and captured.has("stride")):
		push_error("Marshal preview missed a required stage: " + str(captured))
		game.queue_free()
		await process_frame
		state.delete_save()
		quit(1)
		return
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
