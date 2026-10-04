extends "res://tests/shaft_guard_combat_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_shade_appearance_save.json"
	state.start_new_game("normal")
	player = _player()
	player.collision_layer = 0
	player.get_node("Camera2D").enabled = false
	var floor_node := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1800, 20)
	collider.shape = shape
	floor_node.add_child(collider)
	floor_node.position.y = 30
	root.add_child(floor_node)
	for tier in [0, 1]:
		state.set_zone_tier("echo_grotto", tier)
		for side in [-1.0, 1.0]:
			await _live_case(tier, side)
	floor_node.queue_free()
	player.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("SHADE APPEARANCE TEST PASSED: four live attack cycles, tier followup, six poses, facing, hit flash, hidden/teleport, alpha/mipmaps and unchanged combat geometry")
		quit(0)
	else:
		quit(1)


func _live_case(tier: int, side: float) -> void:
	player.position = Vector2(side * 140, 2.5)
	var shade: CharacterBody2D = load("res://EchoShade.tscn").instantiate()
	shade.position = Vector2(0, 2.5)
	shade.attack_cooldown = 0.7
	root.add_child(shade)
	var art := shade.get_node("Appearance")
	art.set_process(false)
	var body := shade.get_node("CollisionShape2D")
	var contact := shade.get_node("ContactArea/CollisionShape2D")
	var geometry := [body.transform, contact.transform, body.shape.get_rid(), contact.shape.get_rid()]
	for named in ["Mantle", "BodyVisual", "Eyes"]:
		_check(not shade.get_node(named).visible, "Old shade polygon overlaps artwork")
	var saw_glide := false
	var recovered := false
	var dash_starts := 0
	var warning_ticks := 0
	var was_warning := false
	var was_dash := false
	for tick in range(350):
		await physics_frame
		art._process(1.0 / 60.0)
		var warning: bool = shade.telegraph_remaining > 0
		var dashing: bool = shade.dash_remaining > 0
		if warning:
			if not was_warning:
				warning_ticks = 0
			warning_ticks += 1
			_check(art.frame == 2 and shade.telegraph.visible and art.flip_h == (shade.dash_direction < 0), "Windup/facing disagrees with native telegraph")
			_check(shade.telegraph.z_index > art.z_index and shade.telegraph.points[1] == Vector2(shade.dash_direction * 130, 0), "Art obscures or changes native warning lane")
		elif dashing:
			if not was_dash:
				dash_starts += 1
				_check(warning_ticks >= (27 if dash_starts > 1 else 33), "Appearance shortened native warning")
			_check(art.frame == 3 and not shade.telegraph.visible and art.flip_h == (shade.dash_direction < 0), "Dash pose/facing missing")
		elif shade.recovery_remaining > 0:
			recovered = true
			_check(art.frame == 4, "Recovery pose missing")
			break
		else:
			saw_glide = saw_glide or art.frame == 1
			if art.frame == 1:
				art._process(0.001)
				_check(art.frame == 1, "Gliding flickers between physics ticks")
		was_warning = warning
		was_dash = dashing
	_check(saw_glide and recovered and dash_starts == (2 if tier == 1 else 1), "Live movement/dash/followup/recovery coverage incomplete")
	_check(shade.max_health == 4 + tier and shade.gold_reward == 14 + tier * 4 and shade.xp_reward == 2, "Art changed native balance")
	shade.set_physics_process(false)
	shade.take_damage(1)
	art._process(0)
	_check(art.frame == 5 and art.modulate.r > art.modulate.g and shade.current_health == shade.max_health - 1, "Hit pose/native flash lost")
	_check(shade.dash_remaining == 0 and shade.telegraph_remaining == 0 and not shade.telegraph.visible, "Native damage interrupt changed")
	await create_timer(0.2).timeout
	art._process(0.2)
	_check(art.frame == 4, "Hit pose outlives native flash")
	shade.recovery_remaining = 0
	shade.hide()
	shade.position.x += 1000
	art._process(1)
	shade.show()
	art._process(1)
	_check(art.frame == 0, "Hidden relocation becomes a glide")
	shade.position.x += 1000
	art._process(0.001)
	_check(art.frame == 0, "Visible teleport becomes a glide")
	_check(geometry == [body.transform, contact.transform, body.shape.get_rid(), contact.shape.get_rid()] and body.shape.size == Vector2(28, 35), "Collision changed")
	_check(art.find_children("*", "CollisionObject2D", true, false).is_empty(), "Art adds collision")
	var pixels: Image = art.texture.get_image()
	_check(pixels.get_size() == Vector2i(1536, 1024) and pixels.has_mipmaps() and pixels.get_pixel(0, 0).a == 0, "Source alpha/resolution/mipmaps wrong")
	for pose in range(6):
		for left in [false, true]:
			art._apply_pose(pose, left, Color.WHITE)
			_check(art.frame == pose and art.flip_h == left and art.position == Vector2(0, 17.5) and art.scale == Vector2.ONE * art.PIXEL_SCALE, "Pose registration wrong")
	shade.process_mode = Node.PROCESS_MODE_DISABLED
	_check(not art.can_process(), "Disabled population still animates")
	shade.queue_free()
	await process_frame
