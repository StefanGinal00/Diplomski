extends "res://tests/shaft_guard_combat_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_broodling_appearance_save.json"
	state.start_new_game("normal")
	player = _player()
	player.is_invulnerable = true
	player.collision_layer = 0
	player.get_node("Camera2D").enabled = false
	var floor_node := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1500, 20)
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
		print("BROODLING APPEARANCE TEST PASSED: four live AI cycles; six poses, full windup, facing, hit, hidden/teleport, alpha/mipmaps and unchanged physics/rewards")
		quit(0)
	else:
		quit(1)


func _live_case(tier: int, side: float) -> void:
	player.position = Vector2(side * 110, 10)
	var brood := load("res://EchoBroodling.tscn").instantiate() as CharacterBody2D
	brood.position = Vector2(0, 10)
	brood.direction = side
	brood.attack_cooldown = 0.9
	root.add_child(brood)
	var art := brood.get_node("Appearance")
	art.set_process(false)
	var body := brood.get_node("CollisionShape2D")
	var contact := brood.get_node("ContactArea/CollisionShape2D")
	var body_before: Transform2D = body.transform
	var contact_before: Transform2D = contact.transform
	var body_shape: RID = body.shape.get_rid()
	var contact_shape: RID = contact.shape.get_rid()
	for named in ["BodyVisual", "BackSpines", "Eye"]:
		_check(not brood.get_node(named).visible, "Old broodling visual overlaps art")
	var warning_ticks := 0
	var saw_walk := false
	var saw_leap := false
	var saw_recovery := false
	var last_state: int = brood.State.PATROL
	for tick in range(240):
		await physics_frame
		art._process(1.0 / 60.0)
		_check(art.flip_h == (brood.direction < 0), "Brood sprite faces away from committed attack")
		_check(art.scale.is_equal_approx(Vector2.ONE * art.PIXEL_SCALE), "Brood sprite distorted")
		if brood.state == brood.State.PATROL:
			saw_walk = saw_walk or art.frame in [1, 2]
			if art.frame in [1, 2]:
				art._process(0.001)
				_check(art.frame in [1, 2], "Brood walk flickers between physics ticks")
		elif brood.state == brood.State.WINDUP:
			warning_ticks += 1
			_check(art.frame == 3 and brood.warning_icon.visible, "Windup art hides original warning")
			_check(brood.warning_icon.position.y + 4 * brood.warning_icon.scale.y < brood.health_bar.position.y - 2, "Warning overlaps health bar")
		elif brood.state == brood.State.LEAP:
			if last_state == brood.State.WINDUP:
				_check(warning_ticks >= 28, "Art shortened native 0.48s windup")
			saw_leap = true
			_check(art.frame == 4 and not brood.warning_icon.visible, "Leap pose disagrees with AI")
		elif brood.state == brood.State.RECOVER:
			saw_recovery = true
			_check(art.frame == 5, "Recovery pose missing")
			break
		last_state = brood.state
	_check(saw_walk and saw_leap and saw_recovery, "Live broodling did not traverse patrol/windup/leap/recovery")
	_check(brood.max_health == 3 + tier and brood.xp_reward == 2 and brood.gold_reward == 13 + 4 * tier, "Appearance changed balance")
	brood.set_physics_process(false)
	brood.take_damage(1)
	art._process(0.01)
	_check(art.frame == 5 and art.modulate.r > art.modulate.g, "Hit recoil/flash lost")
	brood.hide()
	var stride_before: float = art.stride_distance
	brood.position.x += 1000
	art._process(1.0)
	_check(art.stride_distance == stride_before, "Hidden broodling kept walking animation")
	brood.show()
	brood.state = brood.State.PATROL
	art._process(1.0)
	_check(art.frame == 0, "Hidden relocation produces stride")
	brood.position.x += 1000
	art._process(0.01)
	_check(art.frame == 0, "Visible teleport produces stride")
	_check(body.transform == body_before and body.shape.get_rid() == body_shape and body.shape.size == Vector2(27, 18), "Body collision changed")
	_check(contact.transform == contact_before and contact.shape.get_rid() == contact_shape and contact.shape.size == Vector2(27, 18), "Contact collision changed")
	_check(art.find_children("*", "CollisionObject2D", true, false).is_empty(), "Appearance added collision")
	var pixels: Image = art.texture.get_image()
	_check(pixels.get_size() == Vector2i(1536, 1024) and pixels.get_pixel(0, 0).a == 0 and pixels.has_mipmaps(), "Brood sheet resolution/alpha/mipmaps wrong")
	for pose in range(6):
		art._apply_pose(pose, false, Color.WHITE)
		_check(art.frame == pose and art.position == Vector2(0, 9), "Pose registration wrong")
	brood.queue_free()
	await process_frame
