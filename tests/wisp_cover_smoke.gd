extends "res://tests/shaft_guard_combat_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_wisp_cover_save.json"
	for tier in [0, 1]:
		for horizontal in [false, true]:
			state.start_new_game("normal")
			state.set_zone_tier("sunken_shaft", tier)
			await _case(tier, horizontal)
		await _scaffold_case()
	state.delete_save()
	if failures.is_empty():
		print("WISP COVER TEST PASSED: solid wall/floor occlusion, interrupted and fresh telegraphs, unobstructed real dives at both tiers")
		quit(0)
	else:
		print("WISP COVER TEST FAILED: ", failures.size())
		quit(1)


func _case(tier: int, horizontal: bool) -> void:
	var context := "Wisp tier %d horizontal %s" % [tier, horizontal]
	player = _player()
	player.global_position = Vector2(0, 140) if horizontal else Vector2(140, 0)
	player.max_health = 100
	player.current_health = 100
	var holder := Node2D.new()
	root.add_child(holder)
	var cover := StaticBody2D.new()
	cover.position = Vector2(0, 70) if horizontal else Vector2(70, 0)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1000, 24) if horizontal else Vector2(24, 1000)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	cover.add_child(collision)
	holder.add_child(cover)
	var wisp := load("res://ShaftWisp.tscn").instantiate() as CharacterBody2D
	holder.add_child(wisp)
	var attacks_through_cover := false
	for frame in range(180):
		await physics_frame
		attacks_through_cover = attacks_through_cover or wisp.state in [wisp.State.TELEGRAPH, wisp.State.DIVE]
	_check(not attacks_through_cover and player.current_health == 100, context + ": acquired/attacked player through solid cover")
	cover.position += Vector2(2000, 2000)
	await _warning(wisp)
	_check(wisp.state == wisp.State.TELEGRAPH, context + ": no visible-target warning")
	for frame in range(8):
		await physics_frame
	# Put real geometry between their current positions during windup.
	cover.position = (wisp.global_position + player.global_position) * 0.5
	for frame in range(6):
		await physics_frame
	_check(wisp.state == wisp.State.HOVER, context + ": interrupted windup survived solid cover")
	_check(wisp.body_visual.scale.is_equal_approx(Vector2.ONE), context + ": interrupted warning left pulsing scale")
	cover.position += Vector2(2000, 2000)
	await _warning(wisp)
	_check(wisp.state == wisp.State.TELEGRAPH and wisp.state_time >= wisp.telegraph_duration - 0.035, context + ": resumed an old partial warning")
	var warning_frames := 0
	while wisp.state == wisp.State.TELEGRAPH and warning_frames < 120:
		warning_frames += 1
		await physics_frame
	_check(wisp.state == wisp.State.DIVE and warning_frames >= floori(wisp.telegraph_duration * 60) - 3, context + ": fresh telegraph was shortened")
	for frame in range(120):
		await physics_frame
	_check(player.current_health < 100, context + ": visible dive never hit the player")
	holder.queue_free()
	player.queue_free()
	await process_frame


func _warning(wisp: Node) -> void:
	for frame in range(360):
		await physics_frame
		if wisp.state == wisp.State.TELEGRAPH:
			return


func _scaffold_case() -> void:
	player = _player()
	player.global_position = Vector2(140, 0)
	var holder := Node2D.new()
	root.add_child(holder)
	var plank := StaticBody2D.new()
	plank.position = Vector2(70, 0)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 1000)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.one_way_collision = true
	plank.add_child(collision)
	holder.add_child(plank)
	var trigger := Area2D.new()
	trigger.position = Vector2(100, 0)
	var trigger_collision := CollisionShape2D.new()
	trigger_collision.shape = shape
	trigger.add_child(trigger_collision)
	holder.add_child(trigger)
	var wisp := load("res://ShaftWisp.tscn").instantiate() as CharacterBody2D
	holder.add_child(wisp)
	await _warning(wisp)
	_check(wisp.state == wisp.State.TELEGRAPH, "Scaffold/trigger incorrectly occluded wisp vision")
	holder.queue_free()
	player.queue_free()
	await process_frame
