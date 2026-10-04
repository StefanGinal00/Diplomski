extends "res://tests/player_movement_art_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_player_gait_transition_save.json"
	state.start_new_game("normal")
	player = _player()
	player.get_node("Camera2D").enabled = false
	art = player.get_node("Appearance")
	art.set_process(false)
	var body_shape: RID = player.player_collision.shape.get_rid()
	var body_transform := player.player_collision.transform
	var cast_shape: RID = player.attack_cast.shape.get_rid()
	var floor_node := _box(Vector2(0, 30), Vector2(2400, 20))
	player.position = Vector2.ZERO
	player.set_physics_process(true)
	await _step(25)
	Input.action_press("ui_right")
	await _step(18)
	_check(art.walk_direction == 1 and art.stride_distance > 18, "Rightward stride setup failed")
	Input.action_release("ui_right")
	Input.action_press("ui_left")
	var turned := false
	for tick in range(25):
		await _step()
		if art.walk_direction == -1:
			_check(art.stride_distance < 6, "Turning inherits old opposite-direction stride")
			turned = true
			break
	_check(turned, "Actual motion never reverses gait")
	await _step(15)
	_check(art.stride_distance > 18, "Reversed gait does not accumulate normally")
	Input.action_release("ui_left")
	await _step(20)
	_check(art.current_pose == art.Pose.IDLE and art.walk_direction == 0, "Stopped gait does not reset direction")
	Input.action_press("ui_right")
	await _step(3)
	_check(art.stride_distance < 10, "Restart resumes old stride phase")
	await _step(18)
	player.attack_cooldown_timer.stop()
	_check(player.try_attack(), "Gait attack setup failed")
	_check(art.stride_distance == 0 and art.walk_grace == 0, "Attack does not cancel gait immediately")
	await _step(3)
	_check(art.current_pose == art.Pose.ATTACK and art.stride_distance == 0, "Moving attack banks walk distance")
	player.is_invulnerable = false
	player.take_damage(1, Vector2(-120, 0))
	await _step(3)
	_check(art.current_pose == art.Pose.HURT and art.stride_distance == 0 and art.walk_direction == 0, "Knockback recoil banks a stride")
	await _step(25)
	Input.action_press("ui_down")
	await _step(4)
	_check(player.is_crouching and art.current_pose == art.Pose.CROUCH and art.stride_distance == 0, "Crouch movement banks standing gait")
	Input.action_release("ui_down")
	await _step(4)
	player.jump_buffer_remaining = 0.12
	await _step(5)
	_check(not player.is_on_floor() and art.stride_distance == 0 and art.walk_grace == 0, "Airborne travel advances grounded stride")
	Input.action_release("ui_right")
	await _step(110)
	player.set_physics_process(false)
	for boundary in ["room", "rest", "transition", "hidden"]:
		art.stride_distance = 25.0
		art.walk_grace = 0.04
		art.walk_direction = -1
		art.landing_remaining = 0.08
		# A short relocation below the teleport threshold must also reset.
		player.position.x += 10
		if boundary == "room":
			state.room_changed.emit("test_room")
		elif boundary == "rest":
			state.checkpoint_resting.emit("test_lamp")
		elif boundary == "transition":
			root.get_node("RoomTransition").transition_started.emit("test_room")
		else:
			player.process_mode = Node.PROCESS_MODE_DISABLED
			player.hide()
			player.show()
			player.process_mode = Node.PROCESS_MODE_INHERIT
		_check(art.stride_distance == 0 and art.walk_direction == 0 and art.walk_grace == 0 and art.landing_remaining == 0 and art.previous_position == player.global_position, "Motion boundary retains stale gait: " + boundary)
	_check(player.player_collision.shape.get_rid() == body_shape and player.player_collision.transform == body_transform and player.attack_cast.shape.get_rid() == cast_shape, "Gait changes collision")
	player.queue_free()
	floor_node.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("PLAYER GAIT TRANSITION TEST PASSED: reversal/restart, moving attack, knockback, crouch/airborne exclusion, short room/rest/transition relocation, hidden reset and collision")
		quit(0)
	else:
		quit(1)
