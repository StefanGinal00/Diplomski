extends "res://tests/shaft_guard_combat_smoke.gd"

var shots := 0


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_sentry_cover_save.json"
	node_added.connect(_count_shots)
	for scene_name in ["ShaftSentry", "AshSentry"]:
		for tier in [0, 1]:
			state.start_new_game("normal")
			state.set_zone_tier("sunken_shaft" if scene_name == "ShaftSentry" else "ashen_bastion", tier)
			await _cover_case(scene_name, tier)
	state.delete_save()
	if failures.is_empty():
		print("SENTRY COVER TEST PASSED: 4 base/awakened Shaft/Ash cases, cover, interrupted windup, fresh warning, real shots")
		quit(0)
	else:
		print("SENTRY COVER TEST FAILED: ", failures.size())
		quit(1)


func _count_shots(node: Node) -> void:
	if node.is_in_group("enemy_projectile"):
		shots += 1


func _cover_case(scene_name: String, tier: int) -> void:
	var label := "%s tier %d" % [scene_name, tier]
	player = _player()
	player.global_position = Vector2(140, -2)
	player.max_health = 100
	player.current_health = 100
	var holder := Node2D.new()
	root.add_child(holder)
	var cover := StaticBody2D.new()
	cover.position = Vector2(70, 0)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24, 100)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	cover.add_child(collision)
	holder.add_child(cover)
	# A small trigger volume is not cover and must not block the later shot.
	var trigger := Area2D.new()
	trigger.position = Vector2(100, 0)
	var trigger_shape := CollisionShape2D.new()
	trigger_shape.shape = shape
	trigger.add_child(trigger_shape)
	holder.add_child(trigger)
	var sentry := load("res://%s.tscn" % scene_name).instantiate() as StaticBody2D
	holder.add_child(sentry)
	var before := shots
	var warned_through_cover := false
	for frame in range(180):
		await physics_frame
		warned_through_cover = warned_through_cover or sentry.warning_ray.visible
	_check(shots == before and not warned_through_cover, label + ": targets player through solid cover")
	cover.position.y = 250
	await _wait_for_warning(sentry)
	_check(sentry.warning_ray.visible, label + ": no warning after leaving cover")
	_check(sentry.warning_ray.points[0].is_equal_approx(sentry.muzzle.position), label + ": warning does not originate at muzzle")
	_check(sentry.warning_ray.points[1].x > sentry.warning_ray.points[0].x, label + ": first warning frame points away from player")
	for ray in sentry.spread_rays:
		_check(ray.points[0].is_equal_approx(sentry.muzzle.position) and ray.points[1].x > ray.points[0].x, label + ": spread warning starts with stale direction/origin")
	# Interrupt a started windup. No shot should survive the cancellation.
	for frame in range(12):
		await physics_frame
	cover.position.y = 0
	for frame in range(90):
		await physics_frame
	_check(not sentry.warning_ray.visible and shots == before, label + ": cover failed to cancel windup")
	for ray in sentry.spread_rays:
		_check(not ray.visible, label + ": spread warning remained behind cover")
	cover.position.y = 250
	await _wait_for_warning(sentry)
	_check(sentry.warning_ray.visible and sentry.windup_remaining >= sentry.windup_time - 0.04, label + ": resumed an old windup instead of a full warning")
	var warning_frames := 0
	while shots == before and warning_frames < 180:
		await physics_frame
		warning_frames += 1
	_check(warning_frames >= int(sentry.windup_time * 60) - 3, label + ": shot arrived before full telegraph")
	_check(shots - before == (3 if tier == 1 else 1), label + ": wrong base/spread projectile count")
	for frame in range(60):
		await physics_frame
	_check(player.current_health < 100, label + ": unobstructed projectile did not reach player")
	holder.queue_free()
	player.queue_free()
	await process_frame


func _wait_for_warning(sentry: Node) -> void:
	for frame in range(240):
		await physics_frame
		if sentry.warning_ray.visible:
			return
