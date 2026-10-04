extends "res://tests/preview_characters.gd"
const ACTORS := ["Boss", "AbyssWarden", "EchoMatriarch", "AshCastellan", "HollowSovereign", "StarfallGuardian", "EmberMarshal"]

func _render() -> void:
	root.size = Vector2i(1600, 500)
	root.content_scale_size = Vector2i(1600, 500)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_boss_extended_preview.json"
	state.start_new_game("normal")
	var gallery := Node2D.new()
	root.add_child(gallery)
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1600, 0), Vector2(1600, 500), Vector2(0, 500)])
	bg.color = Color("172c3b")
	bg.z_index = -5
	gallery.add_child(bg)
	_label(gallery, "12 PAINTED FRAMES PER ACTOR / animation registration review (1.3x)", Vector2(28, 20), 23)
	var actors: Array[Node] = []
	for i in range(ACTORS.size()):
		var boss: CharacterBody2D = load("res://%s.tscn" % ACTORS[i]).instantiate()
		gallery.add_child(boss)
		boss.set_physics_process(false)
		boss.scale = Vector2.ONE * 1.3
		var art := boss.get_node("PaintedAppearance")
		var effects := boss.get_node("CombatPresentation")
		art.set_process(false)
		effects.set_process(false)
		effects.hide()
		if art.property_names.has("active"):
			boss.active = true
		for key in ["shot_cooldown", "volley_cooldown"]:
			if art.property_names.has(key):
				boss.set(key, 5)
		for label in boss.find_children("*", "Label", true, false):
			label.hide()
		for bar in boss.find_children("*", "ProgressBar", true, false):
			bar.hide()
		for key in ["charge_direction", "facing_direction"]:
			if art.property_names.has(key):
				boss.set(key, 1)
		boss.position = Vector2(112 + i * 228, 342 - art.position.y * 1.3 - (45 if ACTORS[i] == "EchoMatriarch" else 0))
		_label(gallery, ACTORS[i], Vector2(45 + i * 228, 410), 16)
		actors.append(boss)
	var floor_line := Line2D.new()
	floor_line.points = PackedVector2Array([Vector2(24, 342), Vector2(1576, 342)])
	floor_line.default_color = Color("526977")
	floor_line.width = 2
	floor_line.z_index = -1
	gallery.add_child(floor_line)
	for step in range(12):
		for boss in actors:
			var art := boss.get_node("PaintedAppearance")
			var effects := boss.get_node("CombatPresentation")
			var timer := ""
			for key in ["windup_remaining", "charge_windup", "pulse_windup"]:
				if art.property_names.has(key):
					timer = key
					break
			if step == 0:
				art._apply_pose(0)
			elif step <= 6:
				art.stride_distance = (step - 1) * 7
				art.frame_sequence.hover_clock = (step - 1) / 8.0
				art._apply_pose(1)
			elif step <= 8:
				boss.set(timer, 0.6 if step == 7 else 0.2)
				art._process(1.0 / 60)
			elif step == 9:
				boss.set(timer, 0)
				effects.release("volley")
			else:
				art.frame_sequence.release_age = 0.14 if step == 10 else 0.23
				art._apply_pose(3)
			# Review exact painted registration without transitional double exposure.
			art.self_modulate.a = 1
			art.pose_blend.hide()
		await _capture("boss_extended_%02d" % step)
	gallery.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
