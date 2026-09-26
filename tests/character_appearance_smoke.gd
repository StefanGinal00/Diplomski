extends "res://tests/shaft_guard_combat_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_character_appearance_save.json"
	state.start_new_game("normal")
	player = _player()
	player.position = Vector2.ZERO
	player.get_node("Camera2D").enabled = false
	var art := player.get_node("Appearance")
	art.set_process(false)
	var collision := player.get_node("CollisionShape2D")
	var body_transform: Transform2D = collision.transform
	var body_shape: RID = collision.shape.get_rid()
	var cast_transform: Transform2D = player.attack_cast.transform
	var cast_shape: RID = player.attack_cast.shape.get_rid()
	_check(not player.sprite.visible, "Godot placeholder overlaps painted player")
	_check(art.previous_health == player.current_health, "Initial player health not observed")
	for pose in range(6):
		for left in [false, true]:
			art._apply_pose(pose, left, false)
			_check(art.frame == pose and art.flip_h == left, "Player atlas/facing mismatch")
			_check(art.position == Vector2(0, 10), "Player foot registration drifted")
	_check(collision.transform == body_transform and collision.shape.get_rid() == body_shape, "Art changed body collision")
	_check(player.attack_cast.transform == cast_transform and player.attack_cast.shape.get_rid() == cast_shape, "Art changed melee reach")
	player.begin_safe_rest()
	art._process(0.01)
	_check(art.hurt_remaining == 0, "Safe rest incorrectly triggers hurt pose")
	player.end_safe_rest()
	player.set_physics_process(false)
	player.is_dashing = true
	player.facing_direction = -1
	art._process(0.01)
	_check(art.current_pose == art.Pose.DASH and art.flip_h, "Dash/facing pose missing")
	player.is_dashing = false
	_check(player.try_attack(), "Real player attack rejected")
	var cooldown: float = player.attack_cooldown_timer.time_left
	art._process(0.01)
	_check(art.current_pose == art.Pose.ATTACK and art.texture == art.COMBAT_SHEET and player.attack_visual.visible, "Real attack did not drive pose")
	_check(player.attack_cooldown_timer.time_left == cooldown, "Art changed attack cooldown")
	player.attack_visual_timer.stop()
	player._on_attack_visual_timer_timeout()
	player.take_damage(1)
	art._process(0.01)
	_check(art.frame == 5 and art.hurt_remaining > 0, "Real damage did not drive hurt pose")
	player.die()
	await process_frame
	player.respawn()
	player.set_physics_process(false)
	_check(art.hurt_remaining == 0, "Hurt pose survived respawn")
	# Real grounded walk / idle / crouch, then a real buffered jump.
	var floor_node := StaticBody2D.new()
	var support := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(600, 20)
	support.shape = rectangle
	floor_node.add_child(support)
	floor_node.position = Vector2(0, 30)
	root.add_child(floor_node)
	player.position = Vector2.ZERO
	player.set_physics_process(true)
	for tick in range(20):
		await physics_frame
	art._process(0.02)
	_check(player.is_on_floor() and art.frame == 0, "Grounded idle missing")
	Input.action_press("ui_right")
	for tick in range(12):
		await physics_frame
	art._process(0.02)
	_check(art.frame in [1, 2], "Real walking does not select stride")
	Input.action_release("ui_right")
	Input.action_press("ui_down")
	for tick in range(12):
		await physics_frame
	art._process(0.02)
	_check(art.current_pose == art.Pose.CROUCH and art.scale == Vector2.ONE * art.MOVEMENT_SCALE, "Authored crouch missing or squashed twice")
	Input.action_release("ui_down")
	player.jump_buffer_remaining = 0.12
	for tick in range(4):
		await physics_frame
	art._process(0.02)
	_check(not player.is_on_floor() and art.frame == 3, "Real jump did not select airborne pose")
	player.set_physics_process(false)
	var wisp := load("res://ShaftWisp.tscn").instantiate() as CharacterBody2D
	wisp.position = Vector2(1000, 0)
	root.add_child(wisp)
	wisp.set_physics_process(false)
	var wisp_art := wisp.get_node("Appearance")
	wisp_art.set_process(false)
	_check(wisp_art.previous_health == wisp.current_health, "First wisp hit would lack recoil")
	var contact := wisp.get_node("ContactArea/CollisionShape2D")
	var contact_before: Transform2D = contact.transform
	var contact_shape: RID = contact.shape.get_rid()
	for ai_state in [wisp.State.HOVER, wisp.State.TELEGRAPH, wisp.State.DIVE, wisp.State.RECOVER]:
		wisp.state = ai_state
		wisp.dive_direction = Vector2.DOWN
		wisp_art._process(0.02)
		var expected: int = [0, 2, 3, 4][ai_state]
		_check(wisp_art.frame in [0, 1] if ai_state == 0 else wisp_art.frame == expected, "Wisp AI/pose mismatch")
		_check(wisp.state == ai_state, "Presentation changed enemy AI")
		if ai_state == wisp.State.DIVE:
			_check(is_equal_approx(wisp_art.rotation, PI / 2), "Dive sprite not aligned with real direction")
	wisp.take_damage(1)
	wisp_art._process(0.01)
	_check(wisp_art.frame == 5, "First real wisp hit did not recoil")
	_check(contact.transform == contact_before and contact.shape.get_rid() == contact_shape, "Wisp art changed contact reach")
	# Let the real red hit-flash tween finish before comparing tier colors.
	for tick in range(20):
		await physics_frame
	state.set_zone_tier("sunken_shaft", 1)
	wisp.state = wisp.State.HOVER
	wisp_art._process(0.3)
	_check(wisp_art.modulate.b > wisp_art.modulate.r, "Awakened tier lost its cooler appearance")
	wisp.state = wisp.State.TELEGRAPH
	wisp.body_visual.modulate = Color.WHITE
	wisp_art._process(0.02)
	_check(wisp_art.frame == 2 and wisp_art.modulate == Color.WHITE, "Awakened tint washed out warning")
	for visual in [art, wisp_art]:
		var actor: Node2D = visual.get_parent()
		actor.hide()
		var time: float = visual.elapsed
		visual._process(1.0)
		_check(visual.elapsed == time, "Hidden actor kept animating")
		_check(visual.find_children("*", "CollisionObject2D", true, false).is_empty(), "Art introduced collision")
		var pixels: Image = visual.texture.get_image()
		_check(pixels.get_size() == Vector2i(1536, 1024), "Atlas dimensions changed")
		_check(pixels.get_pixel(0, 0).a == 0 and pixels.get_pixel(512, 512).a == 0, "Atlas lost transparent padding")
	player.queue_free()
	wisp.queue_free()
	floor_node.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("CHARACTER APPEARANCE TEST PASSED: real movement/attack/hurt/respawn, all poses, alpha, hidden sleep, unchanged body/melee/contact shapes")
		quit(0)
	else:
		quit(1)
