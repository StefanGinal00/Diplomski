extends "res://tests/shaft_guard_combat_smoke.gd"

var art: Sprite2D


func _step(count: int = 1) -> void:
	for tick in range(count):
		await physics_frame
		art._process(1.0 / 60.0)


func _box(at: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	body.position = at
	root.add_child(body)
	return body


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_player_movement_art_save.json"
	state.start_new_game("normal")
	player = _player()
	player.get_node("Camera2D").enabled = false
	art = player.get_node("Appearance")
	art.set_process(false)
	var shape_id: RID = player.player_collision.shape.get_rid()
	var body_size: Vector2 = player.player_collision.shape.size
	var cast_id: RID = player.attack_cast.shape.get_rid()
	var floor_node := _box(Vector2(0, 30), Vector2(2400, 20))
	var wall := _box(Vector2(120, -100), Vector2(20, 260))
	player.position = Vector2.ZERO
	player.set_physics_process(true)
	await _step(25)
	_check(player.is_on_floor() and art.current_pose == art.Pose.IDLE, "Idle did not settle on real floor")
	Input.action_press("ui_right")
	await _step(16)
	_check(art.current_pose in [art.Pose.WALK_A, art.Pose.WALK_B] and art.stride_distance > 10, "Real travel did not drive stride")
	var stride: float = art.stride_distance
	var held_pose: int = art.current_pose
	art._process(0.001)
	_check(art.current_pose == held_pose and art.stride_distance == stride, "Extra render tick flickers or invents travel")
	await _step(100)
	stride = art.stride_distance
	await _step(20)
	_check(player.is_on_wall() and art.current_pose == art.Pose.IDLE and is_equal_approx(art.stride_distance, stride), "Blocked player walks in place")
	Input.action_release("ui_right")
	Input.action_press("ui_left")
	await _step(15)
	_check(art.flip_h and art.current_pose in [art.Pose.WALK_A, art.Pose.WALK_B], "Left-facing travel lacks stride")
	Input.action_release("ui_left")
	await _step(20)
	Input.action_press("ui_down")
	await _step(4)
	_check(player.is_crouching and art.current_pose == art.Pose.CROUCH, "Real crouch did not select authored pose")
	_check(art.scale == Vector2.ONE * art.MOVEMENT_SCALE, "Crouch was squashed twice")
	Input.action_release("ui_down")
	await _step(4)
	player.jump_buffer_remaining = 0.12
	var saw_jump := false
	var saw_fall := false
	var saw_land := false
	for tick in range(110):
		await _step()
		saw_jump = saw_jump or art.current_pose == art.Pose.JUMP
		saw_fall = saw_fall or art.current_pose == art.Pose.FALL
		saw_land = saw_land or art.current_pose == art.Pose.LAND
	_check(saw_jump and saw_fall and saw_land and art.current_pose == art.Pose.IDLE, "Real jump/fall/landing sequence incomplete")
	# Compression never introduces a gameplay lock or consumes attack time.
	art.landing_remaining = 0.09
	_check(player.try_attack(), "Visual landing blocks real attack")
	var cooldown: float = player.attack_cooldown_timer.time_left
	art._process(0.001)
	_check(art.current_pose == art.Pose.ATTACK and player.attack_cooldown_timer.time_left == cooldown, "Landing overrides attack or changes cooldown")
	await _step(35)
	player.dash_unlocked = true
	_check(player.try_dash(), "Real dash rejected")
	await _step(2)
	_check(player.is_dashing and art.current_pose == art.Pose.DASH and art.flip_h, "Real dash lacks dedicated facing pose")
	await _step(25)
	player.set_physics_process(false)
	player.position.x -= 300
	art._process(0.001)
	_check(art.stride_distance == 0 and art.walk_grace == 0 and art.landing_remaining == 0, "Teleport produced stride/landing")
	art.hurt_remaining = 0.1
	art.landing_remaining = 0.09
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.hide()
	player.position.x -= 200
	player.show()
	art._process(0.001)
	_check(art.hurt_remaining == 0 and art.stride_distance == 0 and art.landing_remaining == 0, "Disabled hidden actor retains transients")
	for pose in range(10):
		for left in [false, true]:
			art._apply_pose(pose, left, false)
			_check(art.current_pose == pose and art.flip_h == left and art.position == Vector2(0, 10), "Pose/facing/foot registration mismatch")
			_check(art.frame == (pose - 6 if pose >= 6 else pose), "Sheet switch frame mismatch")
	var pixels: Image = art.MOVEMENT_SHEET.get_image()
	_check(pixels.get_size() == Vector2i(1254, 1254), "Movement atlas size changed")
	for point in [Vector2i(0, 0), Vector2i(100, 100), Vector2i(620, 620), Vector2i(1000, 700)]:
		_check(pixels.get_pixelv(point).a == 0, "Movement sheet has painted background")
	_check(player.player_collision.shape.get_rid() == shape_id and player.player_collision.shape.size == body_size, "Movement art changed body collision")
	_check(player.attack_cast.shape.get_rid() == cast_id, "Movement art replaced melee shape")
	player.queue_free()
	floor_node.queue_free()
	wall.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("PLAYER MOVEMENT ART TEST PASSED: real walk/wall/jump/fall/land/dash, facing, attack priority, teleport/hidden reset, atlas alpha and collision invariants")
		quit(0)
	else:
		quit(1)
