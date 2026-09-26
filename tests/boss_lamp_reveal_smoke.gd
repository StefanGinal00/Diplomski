extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_boss_lamp_reveal_suite_save.json"
	var state := root.get_node("GameState")
	state.start_new_game("normal")
	var expectations := {
		"ResonanceSanctum": ["SanctumLamp", "echo_matriarch"],
		"CastellanThrone": ["ThroneLamp", "ash_castellan"],
		"StarfallHollowThrone": ["ThroneLamp", "hollow_sovereign"],
	}
	for scene_name: String in expectations:
		var packed := load("res://%s.tscn" % scene_name) as PackedScene
		var room := packed.instantiate() as Node2D
		var expected: Array = expectations[scene_name]
		var authored_lamp = room.get_node(String(expected[0]))
		_check(authored_lamp.reveal_after_boss_id == String(expected[1]), "%s lamp has the wrong boss reveal condition" % scene_name)
		room.free()
	var lamp := (load("res://Checkpoint.tscn") as PackedScene).instantiate()
	lamp.reveal_after_boss_id = "test_guardian"
	root.add_child(lamp)
	await process_frame
	_check(not lamp.visible and not lamp.is_revealed and not lamp.monitoring, "Boss lamp was interactive before its boss was defeated")
	state.mark_boss_defeated("test_guardian")
	await process_frame
	await process_frame
	_check(lamp.visible and lamp.is_revealed and lamp.monitoring, "Boss lamp did not appear after its boss was defeated")
	lamp.queue_free()
	await process_frame
	if failures.is_empty():
		print("BOSS LAMP REVEAL TEST PASSED")
		quit(0)
	else:
		print("BOSS LAMP REVEAL TEST FAILED: ", failures)
		quit(1)
