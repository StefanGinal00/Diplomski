extends "res://tests/drop_through_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_close_platform_descent_save.json"
	for pause_frames in [12, 80]:
		state.start_new_game("normal")
		var holder := Node2D.new()
		root.add_child(holder)
		var upper := _floor(holder, 100, true)
		upper.get_child(0).shape.size.y = 17
		_floor(holder, 114.5, true)
		_floor(holder, 180, false)
		player = _player()
		player.global_position = Vector2(0, 65)
		player.set_physics_process(true)
		for frame in range(25):
			await physics_frame
		await _press_drop()
		for frame in range(pause_frames):
			await physics_frame
		_check(player.is_on_floor() and absf(player.position.y - 99.5) < 2, "Close platforms: first drop did not stay on lower plank after %d frames: %s" % [pause_frames, player.position])
		_check(player.get_collision_exceptions().has(upper), "Overlapping upper plank was restored through the player's body")
		await _press_drop()
		for frame in range(65):
			await physics_frame
		_check(player.is_on_floor() and absf(player.position.y - 165) < 2, "Close platforms: second deliberate drop failed after %d frames: %s" % [pause_frames, player.position])
		_check(player.drop_through_floors.is_empty() and player.get_collision_exceptions().is_empty(), "Close platforms retained a collision exception below the stack")
		_check(not player._try_drop_through(), "Solid bottom floor became droppable")
		player.queue_free()
		holder.queue_free()
		await process_frame
	for exit_kind in ["jump", "side", "deleted"]:
		await _leave_overlap(exit_kind)
	state.delete_save()
	if failures.is_empty():
		print("CLOSE PLATFORM DESCENT TEST PASSED: immediate/delayed second drops, stable narrow landing, solid floor; jump/side/deleted-body cleanup")
		quit(0)
	else:
		print("CLOSE PLATFORM DESCENT TEST FAILED: ", failures.size())
		quit(1)


func _press_drop() -> void:
	Input.action_press("ui_down")
	Input.action_press("ui_accept")
	for frame in range(3):
		await physics_frame
	Input.action_release("ui_accept")
	Input.action_release("ui_down")


func _leave_overlap(exit_kind: String) -> void:
	var holder := Node2D.new()
	root.add_child(holder)
	var upper := _floor(holder, 100, true)
	upper.get_child(0).shape.size.y = 17
	_floor(holder, 114.5, true)
	_floor(holder, 180, false)
	player = _player()
	player.global_position = Vector2(0, 65)
	player.set_physics_process(true)
	for frame in range(25):
		await physics_frame
	await _press_drop()
	for frame in range(20):
		await physics_frame
	_check(player.get_collision_exceptions().has(upper), exit_kind + ": setup did not retain overlapping exception")
	match exit_kind:
		"jump":
			Input.action_press("ui_accept")
		"side":
			Input.action_press("ui_right")
		"deleted":
			upper.queue_free()
	for frame in range(65):
		await physics_frame
	Input.action_release("ui_accept")
	Input.action_release("ui_right")
	_check(player.drop_through_floors.is_empty() and player.get_collision_exceptions().is_empty(), exit_kind + ": stale exception after leaving overlap")
	if exit_kind == "jump":
		_check(player.is_on_floor() and absf(player.position.y - 81.5) < 2, "Return jump could not land on restored upper plank")
	player.queue_free()
	holder.queue_free()
	await process_frame
