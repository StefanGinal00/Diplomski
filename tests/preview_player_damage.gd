extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_player_damage_preview_save.json"
	state.start_new_game("normal")
	var room: Node2D = load("res://EchoGrotto.tscn").instantiate()
	root.add_child(room)
	await process_frame
	await process_frame
	room.process_mode = Node.PROCESS_MODE_DISABLED
	var template := load("res://Game.tscn").instantiate() as Node
	var actor := template.get_node("Player") as Player
	template.remove_child(actor)
	template.free()
	root.add_child(actor)
	actor.get_node("Camera2D").enabled = false
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	actor.position = Vector2(455, 148)
	actor.max_health = 10
	var art := actor.get_node("Appearance")
	root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2(640, 360) - Vector2(460, 65) * 2.5)
	room.get_node("VisualStyleSlice")._process(0.1)
	for mode in ["hurt_right", "hurt_left", "second_breath"]:
		actor.current_health = 2 if mode == "second_breath" else 10
		actor.health_changed.emit(actor.current_health, 10)
		art._clear_damage_feedback()
		actor.invulnerability_timer.stop()
		actor._on_invulnerability_timer_timeout()
		actor.second_breath_active = mode == "second_breath"
		actor.facing_direction = -1 if mode == "hurt_left" else 1
		art._reset_motion()
		actor.attack_cooldown_timer.stop()
		actor.try_attack()
		actor.take_damage(5 if mode == "second_breath" else 1, Vector2(120 * actor.facing_direction, -80))
		art._process(0.035)
		actor.get_node("WeaponAppearance")._process(0)
		if is_instance_valid(art.damage_burst):
			art.damage_burst.set_process(false)
			art.damage_burst.age = 0.035
			art.damage_burst.queue_redraw()
		var overlay := CanvasLayer.new()
		root.add_child(overlay)
		_label(overlay, "STAGED ACCEPTED DAMAGE / " + mode + " / frozen at 35ms / normal zoom", Vector2(28, 20), 19)
		_label(overlay, "HP %d/10 | existing invulnerability alpha unchanged" % actor.current_health, Vector2(28, 48), 17)
		print("DAMAGE PREVIEW ", mode, " hp=", actor.current_health, " invulnerable=", actor.is_invulnerable)
		await _capture("player_" + mode)
		overlay.queue_free()
		art._clear_damage_feedback()
		await process_frame
	actor.queue_free()
	room.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
