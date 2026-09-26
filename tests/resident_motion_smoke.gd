extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_resident_motion_save.json"
	var resident: Area2D = load("res://TownResident.tscn").instantiate()
	root.add_child(resident)
	resident.set_process(false)
	var motion := resident.get_node("ResidentMotion")
	motion.set_process(false)
	var reach := resident.get_node("CollisionShape2D")
	var collision_before: Transform2D = reach.transform
	var shape_before: RID = reach.shape.get_rid()
	var label_before: Vector2 = resident.get_node("NameLabel").position
	for frame in range(20):
		resident.position.x += 1.5
		motion._process(0.05)
	_check(motion.stride > 0.9 and motion.facing > 0, "Rightward walk pose missing")
	for frame in range(20):
		resident.position.x -= 1.5
		motion._process(0.05)
	_check(motion.facing < 0, "Resident did not face travel direction")
	for frame in range(20):
		motion._process(0.05)
	_check(is_zero_approx(motion.stride), "Stationary resident kept walking")
	var position_before: Vector2 = resident.position
	resident.set_player_dialogue_active(true)
	motion._process(0.1)
	_check(resident.position == position_before, "Visual moved dialogue actor")
	_check(reach.transform == collision_before and reach.shape.get_rid() == shape_before, "Visual altered interaction collider")
	_check(resident.get_node("NameLabel").position == label_before, "Visual moved name/UI")
	_check(motion.find_children("*", "CollisionObject2D", true, false).is_empty(), "Visual introduced colliders")
	resident.hide()
	var time: float = motion.elapsed
	motion._process(1.0)
	_check(motion.elapsed == time, "Indoor/hidden actor kept animating")
	resident.show()
	resident.position.x += 1000
	motion._process(0.1)
	_check(is_zero_approx(motion.stride), "Teleport was interpreted as walking")
	resident.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("RESIDENT MOTION TEST PASSED: walk, facing, idle, dialogue, hidden state, teleport, collider/UI invariants")
		quit(0)
	else:
		quit(1)
