extends SceneTree

const FLOOR_EXPECTATIONS := preload("res://tests/route_floor_expectations.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _width(body: StaticBody2D) -> float:
	return (body.get_node("CollisionShape2D").shape as RectangleShape2D).size.x


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_starfall_expanded_route_suite_save.json"
	var rooms := ["StarfallOutskirts", "StarfallSilentGate", "StarfallMemoryVault", "StarfallRootedHall", "StarfallSoulCrucible", "StarfallSunlessPassage"]
	var signatures: Dictionary = {}
	for room_name in rooms:
		var room := (load("res://%s.tscn" % room_name) as PackedScene).instantiate() as Node2D
		root.add_child(room)
		await physics_frame
		var expansion := room.get_node("ExpandedRoute") as Node2D
		var route := expansion.get_node("StarfallDescent") as Node2D
		var layout: Array = expansion.STAR_CHAMBER_LAYOUTS[room_name]
		var signature := str(layout)
		_check(not signatures.has(signature), "%s copied another Starfall topology" % room_name)
		signatures[signature] = room_name
		var rises := 0
		var drops := 0
		var shaft_columns: Dictionary = {}
		for tier in range(layout.size()):
			var chamber: Rect2 = expansion._chamber_rect(tier)
			var coverage := 0.0
			var largest_floor := 0.0
			for child in route.get_children():
				if child is StaticBody2D and String(child.name).begins_with("Chamber%d_Floor" % tier):
					var width := _width(child as StaticBody2D)
					coverage += width
					largest_floor = maxf(largest_floor, width)
			_check(chamber.size.x >= 1650.0 and largest_floor >= 250.0, "%s chamber %d is undersized" % [room_name, tier])
			_check(absf(coverage - FLOOR_EXPECTATIONS.solid_width(expansion, tier)) < 0.1, "%s chamber %d floor coverage disagrees with its shaft openings" % [room_name, tier])
			_check(route.has_node("T%d_Bridge8" % tier) and not route.get_node("T%d_Bridge8" % tier).has_node("CollisionShape2D"), "%s semantic anchors became visible platforms" % room_name)
			if tier < layout.size() - 1:
				var next: Rect2 = expansion._chamber_rect(tier + 1)
				var overlap_left := maxf(chamber.position.x, next.position.x)
				var overlap_right := minf(chamber.end.x, next.end.x)
				shaft_columns[roundi(((overlap_left + overlap_right) * 0.5) / 100.0)] = true
				rises += 1 if next.end.y < chamber.end.y else 0
				drops += 1 if next.end.y > chamber.end.y else 0
				_check(route.has_node("Turn%d_Drop1" % tier), "%s lacks reversible shaft %d" % [room_name, tier])
		_check(shaft_columns.size() >= 4, "%s repeats one vertical column" % room_name)
		_check(rises >= 1 and drops >= 3, "%s lacks meaningful climbs and descents" % room_name)
		for tier in [1, 3, 5]:
			_check(route.has_node("Branch%d_Chamber" % tier) and route.has_node("Branch%d_Step3" % tier), "%s lacks dead-end branch %d" % [room_name, tier])
		_check(route.has_node("RoomIdentity"), "%s lacks its authored room identity" % room_name)
		_check(route.has_node("ReturnLiftTop") and route.has_node("ReturnLiftBottom"), "%s lacks backtracking support" % room_name)
		_check(route.has_node("HiddenStarAmbush") and route.get_node("HiddenStarAmbush").enemy_scenes.size() == 2, "%s lacks its lazy hidden-cache encounter" % room_name)
		room.queue_free()
		await process_frame
	if failures.is_empty():
		print("STARFALL CHAMBER ROUTE TEST PASSED")
		quit(0)
	else:
		print("STARFALL CHAMBER ROUTE TEST FAILED: ", failures)
		quit(1)
