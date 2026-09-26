extends "res://tests/shaft_guard_combat_smoke.gd"

var launches := 0


func _on_launch(_direction: Vector2) -> void:
	launches += 1


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_ranged_attack_cue_save.json"
	state.start_new_game("normal")
	player = _player()
	player.get_node("Camera2D").enabled = false
	for side in [-1.0, 1.0]:
		for height in [0.0, -50.0]:
			await _case(side, height)
	player.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("RANGED ATTACK CUE TEST PASSED: both facings, real shot cadence/spawn/aim/contact, warning cancellation, missing projectile, hurt, hidden sleep and collision invariants")
		quit(0)
	else:
		quit(1)


func _clear_shots() -> void:
	for projectile in get_nodes_in_group("enemy_projectile"):
		projectile.queue_free()
	await process_frame


func _case(side: float, height: float) -> void:
	player.position = Vector2(side * 100, height)
	player.current_health = 100
	player.max_health = 100
	player.is_invulnerable = false
	var holder := Node2D.new()
	root.add_child(holder)
	var sentry: StaticBody2D = load("res://RangedEnemy.tscn").instantiate()
	holder.add_child(sentry)
	sentry.set_process(false)
	var art := sentry.get_node("AttackCue")
	art.set_process(false)
	var appearance := sentry.get_node("Appearance")
	appearance.set_process(false)
	sentry.shot_fired.connect(_on_launch)
	launches = 0
	var collision := sentry.get_node("CollisionShape2D")
	var before: Transform2D = collision.transform
	var shape: RID = collision.shape.get_rid()
	var warning_seen := false
	var shot_times: Array[float] = []
	for tick in range(72):
		var count_before := launches
		sentry._process(0.05)
		art._process(0.05)
		appearance._process(0.05)
		_check(appearance.frame == art.pose and appearance.flip_h == (side < 0), "Bitmap disagrees with attack cue/facing")
		warning_seen = warning_seen or art.pose == 1
		_check(sentry.sprite.flip_h == (side < 0), "Sprite faces away from muzzle")
		_check(sentry.muzzle.position == Vector2(side * 13, 0), "Appearance moved projectile muzzle")
		if launches > count_before:
			shot_times.append((tick + 1) * 0.05)
			var expected_direction: Vector2 = (player.global_position - sentry.muzzle.global_position).normalized()
			_check(art.pose == 2 and art.shot_direction.is_equal_approx(expected_direction), "Real launch missing/aligned firing cue")
			_check(is_equal_approx(sentry.shot_cooldown_remaining, 1.4), "Presentation changed cooldown reset")
			var projectile: Area2D = get_nodes_in_group("enemy_projectile").back()
			_check(projectile.source == sentry and projectile.global_position == sentry.muzzle.global_position, "Projectile source/spawn changed")
			_check(projectile.direction.is_equal_approx(expected_direction) and projectile.damage == 1 and projectile.speed == 125, "Projectile aim/stats changed")
	_check(warning_seen and shot_times.size() == 3, "Did not observe warning and three real launches")
	if shot_times.size() == 3:
		_check(absf(shot_times[0] - 0.6) <= 0.051, "Initial shot timing changed")
		for index in [1, 2]:
			_check(absf(shot_times[index] - shot_times[index - 1] - 1.4) <= 0.051, "Repeat cadence changed")
	await _clear_shots()
	# Real Area2D projectile flight, not a direct damage callback.
	sentry.shot_cooldown_remaining = 0
	sentry._process(0.01)
	for tick in range(70):
		await physics_frame
	_check(player.current_health == 99, "New art prevented real projectile contact damage")
	await _clear_shots()
	art._process(1.0)
	sentry.shot_cooldown_remaining = 0.2
	art._process(0.01)
	_check(art.pose == 1, "In-range charged shot lacks warning")
	player.position.x = side * 1000
	var count_before := launches
	sentry._process(0.1)
	art._process(0.01)
	_check(art.pose == 0 and launches == count_before, "Out-of-range target kept charging/firing")
	player.position.x = side * 100
	player.is_dead = true
	art._process(0.01)
	_check(art.pose == 0, "Dead target kept warning active")
	player.is_dead = false
	var scene: PackedScene = sentry.projectile_scene
	sentry.projectile_scene = null
	sentry.shot_cooldown_remaining = 0
	sentry._process(0.1)
	art._process(0.01)
	_check(launches == count_before and art.pose == 0, "Failed launch produced a fake shot/warning")
	sentry.projectile_scene = scene
	sentry.take_damage(1)
	art._process(0.01)
	_check(art.pose == 3 and art.hurt_remaining > 0 and sentry.sprite.modulate.g < 0.4, "First real hit lacks original flash")
	appearance._process(0.01)
	_check(appearance.frame == 3, "Bitmap lacks hurt frame")
	# No _process call: a disabled, hidden room must clear old effects.
	holder.process_mode = Node.PROCESS_MODE_DISABLED
	holder.hide()
	_check(art.fire_remaining == 0 and art.hurt_remaining == 0 and art.pose == 0, "Disabled hidden room retained stale effects")
	holder.show()
	appearance._process(0)
	_check(appearance.frame == 0, "Room re-entry replayed old pose")
	sentry.hide()
	art._process(1.0)
	sentry.shot_fired.emit(Vector2.RIGHT)
	_check(art.fire_remaining == 0 and art.hurt_remaining == 0, "Hidden sentry retained/replayed old effects")
	sentry.show()
	_check(collision.transform == before and collision.shape.get_rid() == shape and collision.shape.size == Vector2(18, 18), "Sprite changed body collision")
	_check(not sentry.sprite.visible and art.find_children("*", "CollisionObject2D", true, false).is_empty(), "Prototype overlaps bitmap or new collision added")
	var pixels: Image = appearance.texture.get_image()
	_check(pixels.get_size() == Vector2i(1254, 1254) and pixels.get_pixel(0, 0).a == 0, "Atlas geometry/alpha changed")
	var expired_target := Node2D.new()
	sentry.target_player = expired_target
	expired_target.free()
	art._process(1.0)
	_check(art.pose == 0, "Freed target retained warning")
	holder.queue_free()
	await process_frame
