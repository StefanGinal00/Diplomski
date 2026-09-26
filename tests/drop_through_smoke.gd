extends "res://tests/shaft_guard_combat_smoke.gd"


func _floor(holder: Node, y: float, one_way: bool) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = Vector2(0, y)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(240, 10)
	collision.shape = shape
	collision.one_way_collision = one_way
	body.add_child(collision)
	holder.add_child(body)
	return body


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_drop_through_save.json"
	for layout in ["one_way", "overlap", "solid", "mixed", "compound"]:
		state.start_new_game("normal")
		var holder := Node2D.new()
		root.add_child(holder)
		var top := _floor(holder, 100, layout != "solid")
		if layout == "compound":
			var solid_part := CollisionShape2D.new()
			var solid_shape := RectangleShape2D.new()
			solid_shape.size = Vector2(20, 100)
			solid_part.shape = solid_shape
			solid_part.position = Vector2(180, 0)
			top.add_child(solid_part)
		if layout in ["overlap", "mixed"]:
			_floor(holder, 100, layout == "overlap")
		_floor(holder, 175, true)
		_floor(holder, 245, false)
		player = _player()
		player.global_position = Vector2(0, 70)
		player.set_physics_process(true)
		for frame in range(20):
			await physics_frame
		_check(player.is_on_floor(), layout + ": could not stand at setup")
		Input.action_press("ui_down")
		Input.action_press("ui_accept")
		for frame in range(3):
			await physics_frame
		Input.action_release("ui_accept")
		for frame in range(80):
			await physics_frame
		var expected := 160.0 if layout in ["one_way", "overlap"] else 85.0
		_check(player.is_on_floor() and absf(player.position.y - expected) < 2, layout + ": down+jump landed at incorrect level " + str(player.position))
		_check(player.drop_through_floors.is_empty() and player.get_collision_exceptions().is_empty(), layout + ": stale floor exception")
		Input.action_release("ui_down")
		if layout in ["one_way", "overlap"]:
			await physics_frame
			Input.action_press("ui_accept")
			for frame in range(65):
				await physics_frame
			Input.action_release("ui_accept")
			_check(player.is_on_floor() and absf(player.position.y - 85) < 2, layout + ": could not jump back onto released platform")
			_check(player._try_drop_through(), layout + ": second drop refused")
			_check(not player.drop_through_floors.is_empty(), "Drop registered no temporary exception")
			player.die()
			_check(player.drop_through_floors.is_empty() and player.get_collision_exceptions().is_empty(), "Death retained floor exceptions")
			player.respawn()
			_check(player.drop_through_floors.is_empty(), "Respawn retained floor exceptions")
		player.queue_free()
		holder.queue_free()
		await process_frame
	state.start_new_game("normal")
	await _real_stair()
	state.delete_save()
	if failures.is_empty():
		print("DROP THROUGH TEST PASSED: 5 support layouts, single descent, return jump, death cleanup, authored Hollow stair")
		quit(0)
	else:
		print("DROP THROUGH TEST FAILED: ", failures.size())
		quit(1)


func _real_stair() -> void:
	player = _player()
	var room := load("res://ShaftHollow.tscn").instantiate() as Node2D
	room.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(room)
	await process_frame
	for actor in room.find_children("*", "CollisionObject2D", true, false):
		actor.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	var route := room.get_node("ExpandedRoute/AuthoredDescent")
	var stair := route.get_node("Turn0_Drop6") as StaticBody2D
	var landing := route.get_node("Chamber1_Floor0") as StaticBody2D
	player.global_position = stair.global_position + Vector2(0, -16)
	player.set_physics_process(true)
	for frame in range(20):
		await physics_frame
	_check(player.is_on_floor(), "Could not stand on authored Hollow stair")
	Input.action_press("ui_down")
	Input.action_press("ui_accept")
	for frame in range(3):
		await physics_frame
	Input.action_release("ui_accept")
	for frame in range(80):
		await physics_frame
	Input.action_release("ui_down")
	_check(player.is_on_floor() and absf(player.global_position.y - (landing.global_position.y - 19)) < 2, "Authored stair descent missed solid gallery floor")
	_check(player.drop_through_floors.is_empty(), "Authored stair retained collision exception")
	player.queue_free()
	room.queue_free()
	await process_frame
