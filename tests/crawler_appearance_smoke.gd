extends "res://tests/shaft_guard_combat_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_crawler_appearance_save.json"
	state.start_new_game("normal")
	player = _player()
	player.is_invulnerable = true
	# AI presentation fixture: don't end a charge by colliding with the
	# stationary target. Real contact/melee damage is covered separately.
	player.collision_layer = 0
	player.get_node("Camera2D").enabled = false
	var floor_node := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1500, 20)
	collision.shape = shape
	floor_node.add_child(collision)
	floor_node.position.y = 30
	root.add_child(floor_node)
	for tier in [0, 1]:
		state.set_zone_tier("sunken_shaft", tier)
		for side in [-1.0, 1.0]:
			await _live_case(tier, side)
	floor_node.queue_free()
	player.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("CRAWLER APPEARANCE TEST PASSED: four live AI cycles, full warnings/awakened echo charge, grounded stride, facing, damage, hidden/teleport, alpha and collision invariants")
		quit(0)
	else:
		quit(1)


func _live_case(tier: int, side: float) -> void:
	player.position = Vector2(side * 110, 10)
	var crawler := load("res://ShaftCrawler.tscn").instantiate() as CharacterBody2D
	crawler.position = Vector2(0, 10)
	crawler.direction = side
	crawler.attack_cooldown = 0.9
	root.add_child(crawler)
	var art := crawler.get_node("Appearance")
	art.set_process(false)
	var body := crawler.get_node("CollisionShape2D")
	var contact := crawler.get_node("ContactArea/CollisionShape2D")
	var body_before: Transform2D = body.transform
	var contact_before: Transform2D = contact.transform
	var body_shape: RID = body.shape.get_rid()
	var contact_shape: RID = contact.shape.get_rid()
	_check(art.previous_health == crawler.current_health, "First crawler hit would lack visual feedback")
	_check(not crawler.body_visual.visible and not crawler.get_node("Eye").visible, "Old crawler art overlaps sprite")
	var warning_count := 0
	var warning_ticks := 0
	var last_state: int = crawler.State.PATROL
	var saw_charge := false
	var saw_walk := false
	var saw_recovery := false
	for tick in range(220):
		await physics_frame
		art._process(1.0 / 60.0)
		_check(art.flip_h == (crawler.direction < 0), "Sprite disagrees with committed facing")
		if crawler.state == crawler.State.PATROL:
			saw_walk = saw_walk or art.frame in [1, 2]
			if art.frame in [1, 2]:
				art._process(0.001)
				_check(art.frame in [1, 2], "Stride flickers to idle between physics ticks")
		elif crawler.state == crawler.State.WARNING:
			if last_state != crawler.State.WARNING:
				warning_count += 1
				warning_ticks = 0
			warning_ticks += 1
			_check(art.frame == 3 and crawler.warning_icon.visible, "Warning pose/icon not shown for full AI windup")
			_check(crawler.warning_icon.position.y + 4 * crawler.warning_icon.scale.y < crawler.health_bar.position.y - 2, "Pulsing warning overlaps health bar")
		elif crawler.state == crawler.State.CHARGE:
			if last_state == crawler.State.WARNING:
				_check(warning_ticks >= 30, "Art integration shortened the 0.52 second warning")
			saw_charge = true
			_check(art.frame == 4 and not crawler.warning_icon.visible, "Charge pose out of sync with AI")
		elif crawler.state == crawler.State.RECOVER:
			saw_recovery = true
			_check(art.frame == 5, "Recovery pose missing")
			break
		last_state = crawler.state
	_check(saw_walk and saw_charge and saw_recovery, "Live crawler failed to exercise patrol/charge/recovery")
	_check(warning_count == (2 if tier == 1 else 1), "Awakened extra charge/warning changed")
	crawler.set_physics_process(false)
	crawler.take_damage(1)
	art._process(0.01)
	_check(art.hurt_remaining > 0 and art.frame == 5 and art.modulate.r > art.modulate.g, "Real hit lacks red recoil feedback")
	crawler.hide()
	var stride_before: float = art.stride_distance
	var hurt_before: float = art.hurt_remaining
	crawler.position.x += 1000
	art._process(1.0)
	_check(art.stride_distance == stride_before and art.hurt_remaining == hurt_before, "Hidden crawler kept animating")
	crawler.show()
	crawler.state = crawler.State.PATROL
	art._process(1.0)
	_check(art.frame == 0, "Hidden relocation became a walking stride")
	crawler.position.x += 1000
	art._process(0.01)
	_check(art.frame == 0, "Visible teleport became a walking stride")
	_check(body.transform == body_before and body.shape.get_rid() == body_shape and body.shape.size == Vector2(25, 18), "Body shape changed")
	_check(contact.transform == contact_before and contact.shape.get_rid() == contact_shape and contact.shape.size == Vector2(29, 19), "Contact shape changed")
	_check(art.find_children("*", "CollisionObject2D", true, false).is_empty(), "Art introduced collision")
	var pixels: Image = art.texture.get_image()
	_check(pixels.get_size() == Vector2i(1536, 1024) and pixels.get_pixel(0, 0).a == 0, "Atlas dimensions/alpha incorrect")
	crawler.queue_free()
	await process_frame
