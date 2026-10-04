extends "res://tests/boss_combat_presentation_smoke.gd"
const Echo = preload("res://BossDefeatEcho.gd")
const Burst = preload("res://BossBurst.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_boss_defeat_echo.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player")
	for data in CASES:
		state.current_room_id = data[1]
		var room := Node2D.new()
		game.add_child(room)
		room.position = Vector2(50, 80)
		room.rotation = 0.18
		room.scale = Vector2(1.5, 0.85)
		var boss: CharacterBody2D = load("res://%s.tscn" % data[0]).instantiate()
		room.add_child(boss)
		boss.target_player = player
		var art := boss.get_node("PaintedAppearance")
		if art.property_names.has("active"): boss.active = true
		art._apply_pose(3)
		var expected_transform: Transform2D = art.global_transform
		var expected_frame: int = art.frame
		var expected_texture: Texture2D = art.texture
		var expected_bounds: Vector4 = art.material.get_shader_parameter("frame_bounds")
		var defeat_count := [0]
		boss.defeated.connect(func(): defeat_count[0] += 1)
		boss.take_damage(999)
		_check(boss.is_dead and boss.is_queued_for_deletion() and defeat_count[0] == 1, data[0] + ": cosmetic death delayed native defeat")
		var echoes := get_nodes_in_group(Echo.GROUP)
		_check(echoes.size() == 1, data[0] + ": missing/duplicate defeat snapshot")
		if echoes.size() == 1:
			var echo: Sprite2D = echoes[0]
			_check(echo.global_transform.is_equal_approx(expected_transform), data[0] + ": snapshot drifts/scales under transformed room")
			_check(echo.frame == expected_frame and echo.texture == expected_texture and echo.texture_filter == art.texture_filter, data[0] + ": snapshot loses pose/texture/filter")
			_check(echo.material != art.material and echo.material.get_shader_parameter("frame_bounds") == expected_bounds, data[0] + ": dissolve mutates live material or loses mask")
			_check(echo.get_child_count() == 0, data[0] + ": cosmetic snapshot owns gameplay nodes")
			echo._process(0.275)
			_check(is_equal_approx(echo.material.get_shader_parameter("dissolve_progress"), 0.5), "Dissolve not tied to local lifetime")
			_check(echo.global_position.is_equal_approx(expected_transform.origin + Vector2(0, -7)), "Dissolve drift is not world-space")
			await process_frame
			_check(not is_instance_valid(boss) and is_instance_valid(echo), "Snapshot did not outlive native boss cleanup")
			echo._process(0.3)
			_check(not echo.visible and echo.is_queued_for_deletion(), "Defeat snapshot lingers after lifetime")
		room.queue_free()
		await process_frame
	game.queue_free()
	await process_frame
	await _lifecycle(state)
	state.delete_save()
	if failures.is_empty():
		print("TEST PASSED: seven immediate native defeats, detached masked snapshots, transformed registration, dissolve lifetime, pause/room/rest/transition/hidden cleanup, shared cap")
	quit(0 if failures.is_empty() else 1)

func _lifecycle(state: Node) -> void:
	var host := Node2D.new()
	root.add_child(host)
	var actor := Node2D.new()
	host.add_child(actor)
	var art := Sprite2D.new()
	actor.add_child(art)
	art.texture = preload("res://art/characters/boss_void_sentinel_animation_v2.png")
	art.hframes = 4
	art.vframes = 3
	for event in ["room", "rest", "transition", "hidden", "parent", "pause"]:
		var echo := Echo.spawn(art, Color.CYAN)
		_check(echo != null, "Lifecycle snapshot missing")
		if echo == null: continue
		match event:
			"room": state.room_changed.emit("test_room")
			"rest": state.checkpoint_resting.emit("test_lamp")
			"transition": root.get_node("RoomTransition").transition_started.emit("test_room")
			"hidden":
				host.process_mode = Node.PROCESS_MODE_DISABLED
				host.hide()
			"parent":
				# Removing the snapshot's owner also removes its signal receivers.
				host.remove_child(echo)
				echo.queue_free()
			"pause":
				paused = true
				var previous_age: float = echo.age
				for frame in range(3): await process_frame
				_check(echo.age == previous_age, "Pause consumed defeat lifetime")
				paused = false
				echo._process(Echo.DURATION)
		if event != "parent":
			_check(not echo.visible and echo.is_queued_for_deletion(), "No immediate retirement: " + event)
		await process_frame
		_check(not is_instance_valid(echo), "Defeat snapshot leaked: " + event)
		host.show()
		host.process_mode = Node.PROCESS_MODE_INHERIT
	host.process_mode = Node.PROCESS_MODE_DISABLED
	for index in range(63):
		Burst.spawn(host, Vector2.ZERO, Color.WHITE, "contact", Vector2.ONE, 1)
	_check(Echo.spawn(art, Color.CYAN) != null, "Last shared cosmetic slot unavailable")
	_check(Echo.spawn(art, Color.CYAN) == null and get_nodes_in_group("boss_cosmetic_effect").size() == 64, "Defeat bypasses shared cosmetic cap")
	host.queue_free()
	await process_frame
	_check(get_nodes_in_group("boss_cosmetic_effect").is_empty(), "Deleted parent retained cosmetic nodes")
	# Freed receivers must not be called on subsequent state changes.
	state.room_changed.emit("after_cleanup")
	state.checkpoint_resting.emit("after_cleanup")
