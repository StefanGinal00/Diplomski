extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_vertical_hub_expansion_suite_save.json"
	var shaft := (load("res://VerticalChamber.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(shaft)
	await physics_frame
	var deep := shaft.get_node("DeepShaftTraversal") as Node2D
	_check(deep.MAIN_CHAMBERS.size() == 5 and deep.SIDE_CHAMBERS.size() == 3, "Deep Cuttings lacks its chamber graph")
	_check((deep.get_node("MineChamber0Backdrop") as Polygon2D).polygon.size() >= 8, "Deep Cuttings returned to rectangular rooms")
	var highest := 10000.0
	var lowest := -10000.0
	for index in range(5):
		var room: Rect2 = deep._main_room(index)
		highest = minf(highest, room.position.y)
		lowest = maxf(lowest, room.end.y)
		_check(room.size.x >= 800.0 and room.size.y >= 300.0, "Deep Cuttings main room %d is undersized" % index)
		_check(deep.has_node("MineRoom%dFloor0" % index), "Deep Cuttings main room %d has no floor" % index)
		if index < 4:
			_check(deep.has_node("MineLink%dStep0" % index), "Deep Cuttings main link %d is disconnected" % index)
	_check(lowest - highest >= 1800.0, "Deep Cuttings has no meaningful vertical range")
	for index in range(3):
		var branch: Rect2 = deep._side_room(index)
		_check(branch.size.x >= 1000.0 and deep.has_node("SideRoom%dFloor0" % index), "Deep Cuttings side cave %d is missing" % index)
		_check(deep.has_node("SideLink%dStep0" % index) or deep.has_node("SideLink%dTunnelFloor" % index), "Deep Cuttings side cave %d is disconnected" % index)
	_check(deep.has_node("HoistLoopStep0"), "Broken Hoist does not form an alternate vertical route")
	_check(not deep.has_node("Depth01Ledge00"), "Deep Cuttings regressed to the giant platform snake")
	_check(deep.has_node("DeepPatrol04_02") and deep.has_node("DeepCrate04"), "Warden route is unpopulated")
	_check(deep.has_node("DeepGrazer3") and deep.has_node("DeepCuttingCache") and deep.has_node("DeepBloom"), "Deep Cuttings lacks fauna or exploration rewards")
	_check(shaft.get_node("EntryMarker").position == Vector2(62, 376), "Prologue entry shifted")
	_check(shaft.get_node("UpperCheckpoint").position == Vector2(235, 55), "Existing save lamp shifted")
	_check(shaft.get_node("ShaftArenaDoor").position == Vector2(-122, -938), "Warden arena door must stand above the threshold floor")
	shaft.queue_free()
	await process_frame
	if failures.is_empty():
		print("VERTICAL HUB CHAMBER GRAPH TEST PASSED")
		quit(0)
	else:
		print("VERTICAL HUB CHAMBER GRAPH TEST FAILED: ", failures)
		quit(1)
