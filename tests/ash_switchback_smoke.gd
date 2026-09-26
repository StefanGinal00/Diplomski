extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_ash_switchback_suite_save.json"
	var rooms := ["BrokenCauseway", "CinderForge", "EmberBarracks", "SlagReservoir", "AshChapel", "CinderHearthOutskirts"]
	var signatures: Dictionary = {}
	for room_name in rooms:
		var room := (load("res://%s.tscn" % room_name) as PackedScene).instantiate() as Node2D
		root.add_child(room)
		await physics_frame
		var route := room.get_node("AshSwitchback") as Node2D
		var layout: Array = route.CHAMBER_LAYOUTS[String(route.course_id)]
		var signature := str(layout)
		_check(not signatures.has(signature), "%s copied another Ash topology" % room_name)
		signatures[signature] = room_name
		_check(layout.size() == 7, "%s lacks a complete seven-room route" % room_name)
		var rises := 0
		var drops := 0
		var columns: Dictionary = {}
		for chamber_index in range(layout.size()):
			var chamber: Rect2 = route._chamber_rect(chamber_index)
			var gallery := chamber_index - 1
			var spans: Array = route._track_rects[gallery]
			_check(chamber.size.x >= 1100.0 and chamber.size.y == 240.0, "%s chamber %d is undersized" % [room_name, chamber_index])
			_check(spans.size() == 9, "%s chamber %d lacks gameplay anchors" % [room_name, chamber_index])
			for span_value in spans:
				var span: Rect2 = span_value
				_check(chamber.grow(2.0).has_point(span.get_center()), "%s has an anchor outside chamber %d" % [room_name, chamber_index])
			if chamber_index < layout.size() - 1:
				var next: Rect2 = route._chamber_rect(chamber_index + 1)
				var overlap_left := maxf(chamber.position.x, next.position.x)
				var overlap_right := minf(chamber.end.x, next.end.x)
				columns[roundi(((overlap_left + overlap_right) * 0.5) / 100.0)] = true
				_check(overlap_right - overlap_left >= 180.0, "%s chamber %d has no navigable shaft" % [room_name, chamber_index])
				rises += 1 if next.end.y < chamber.end.y else 0
				drops += 1 if next.end.y > chamber.end.y else 0
		_check(columns.size() >= 4, "%s repeats one vertical shaft" % room_name)
		_check(rises >= 3 and drops >= 1, "%s lacks climbs and descents" % room_name)
		_check(route._step_rects.size() >= 30, "%s lacks reversible shaft steps" % room_name)
		_check(route._niche_crests.size() == 2, "%s lacks its two dead-end reward chambers" % room_name)
		for crest_value in route._niche_crests:
			var crest: Rect2 = crest_value
			_check(crest.size.x >= 350.0, "%s reward branch is only a small shelf" % room_name)
		_check(route.has_node("AshIdentity"), "%s lacks distinct route architecture" % room_name)
		_check(route.has_node("GuardedNicheAmbush") and route.get_node("GuardedNicheAmbush").enemy_scenes.size() == 2, "%s lacks its guarded optional reward" % room_name)
		var foes := 0
		for child in route.get_children():
			if child.name.begins_with("AshRouteFoe"):
				foes += 1
		_check(foes == 12, "%s population is not distributed across six chambers" % room_name)
		room.queue_free()
		await process_frame
	if failures.is_empty():
		print("ASH CHAMBER TOPOLOGY TEST PASSED")
		quit(0)
	else:
		print("ASH CHAMBER TOPOLOGY TEST FAILED: ", failures)
		quit(1)
