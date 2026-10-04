extends "res://tests/boss_combat_presentation_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_boss_frame_sequence.json"
	state.start_new_game("normal")
	var scene: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = scene.get_node("Player")
	for data in CASES:
		var boss: CharacterBody2D = load("res://%s.tscn" % data[0]).instantiate()
		scene.add_child(boss)
		boss.set_physics_process(false)
		boss.target_player = player
		player.global_position = boss.global_position + Vector2(200, 0)
		var art := boss.get_node("PaintedAppearance")
		var effects := boss.get_node("CombatPresentation")
		if art.property_names.has("active"):
			boss.active = true
		var sequence: RefCounted = art.frame_sequence
		_check(sequence != null, data[0] + ": missing twelve-frame library")
		if sequence == null:
			continue
		var shape: Shape2D = boss.get_node("CollisionShape2D").shape
		var health: int = boss.current_health
		var visited := {}
		for index in range(6):
			sequence.hover_clock = index / 8.0
			visited[sequence.select(1, index * 7.0, false, 0, 0)] = true
		_check(visited.size() == 6 and visited.has(1) and visited.has(6), data[0] + ": locomotion doesn't use six distinct frames")
		sequence.tick(0.01, 0.6, 0)
		_check(sequence.select(2, 0, false, 0.6, 0) == 7, data[0] + ": anticipation start incorrect")
		sequence.tick(0.3, 0.2, 0)
		_check(sequence.select(2, 0, false, 0.2, 0) == 8, data[0] + ": anticipation finish incorrect")
		effects.release("volley")
		_check(art.frame == 9 and art.blend_remaining == 0, data[0] + ": strike not visible on actual release tick")
		sequence.tick(0.11, 0, 0.48)
		_check(sequence.select(3, 0, false, 0, 0.48) == 10, data[0] + ": no follow-through")
		sequence.tick(0.3, 0, 0.12)
		_check(sequence.select(3, 0, false, 0, 0.12) == 11, data[0] + ": no recovery finish")
		_check(sequence.select(2, 0, true, 0, 0) == 9, data[0] + ": charge not held on strike frame")
		sequence.reset()
		_check(sequence.release_age > 1 and sequence.windup_peak == 0, data[0] + ": hidden room retains stale attack playback")
		# Every extracted frame contains actual body pixels and transparent gutters.
		var image: Image = art.texture.get_image()
		var cell: Vector2i = Vector2i(image.get_size()) / Vector2i(4, 3)
		var signatures := {}
		for index in range(12):
			var region := Rect2i(Vector2i(index % 4, index / 4) * cell, cell)
			var frame_image := image.get_region(region)
			_check(not frame_image.is_empty() and frame_image.get_used_rect().get_area() > 1000, data[0] + ": blank frame " + str(index))
			signatures[hash(frame_image.get_data())] = true
			for corner in [Vector2i.ZERO, Vector2i(cell.x - 1, 0), cell - Vector2i.ONE, Vector2i(0, cell.y - 1)]:
				_check(frame_image.get_pixelv(corner).a == 0, data[0] + ": opaque frame corner")
		_check(signatures.size() == 12, data[0] + ": duplicated painted frames")
		_check(boss.current_health == health and boss.get_node("CollisionShape2D").shape == shape, data[0] + ": animation altered gameplay")
		boss.queue_free()
		await process_frame
	scene.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("BOSS FRAME SEQUENCE TEST PASSED: seven actors, 84 unique transparent frames, six-phase locomotion, timed anticipation/release/recovery, gameplay unchanged")
	quit(0 if failures.is_empty() else 1)
