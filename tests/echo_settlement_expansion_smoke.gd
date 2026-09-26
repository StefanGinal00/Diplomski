extends SceneTree

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
	root.get_node("GameState").save_path = "res://_tmp_echo_settlement_expansion_suite_save.json"
	var cases := [["EchoHaven", "NewDistricts", true], ["EchoHavenOutskirts", "GateApproach", false]]
	for info in cases:
		var room := (load("res://%s.tscn" % String(info[0])) as PackedScene).instantiate() as Node2D
		root.add_child(room)
		await physics_frame
		var district := room.get_node(String(info[1])) as Node2D
		var path: Array = district._path()
		_check((district.get_node("DistrictPocket00") as Polygon2D).polygon.size() >= 8, "%s settlement shell is still rectangular" % info[0])
		_check(district.ledges.size() == 6, "%s lacks six connected districts" % info[0])
		var columns: Dictionary = {}
		for x in path:
			columns[roundi(float(x) / 100.0)] = true
		_check(columns.size() >= 6, "%s is still a stacked rectangular city" % info[0])
		for tier in range(6):
			var sites: Array = district.ledges[tier]
			_check(sites.size() >= 5, "%s district %d is too small" % [info[0], tier])
			var first := district.get_node("Tier%02dStreet00" % tier) as StaticBody2D
			var last := district.get_node("Tier%02dStreet%02d" % [tier, sites.size() - 1]) as StaticBody2D
			var leg_width := absf(last.position.x - first.position.x) + (_width(first) + _width(last)) * 0.5
			_check(leg_width < district.end_x - district.start_x, "%s district %d spans the whole rectangular room" % [info[0], tier])
			if tier > 0:
				var prior_x: float = path[tier]
				var prior_y: float = float(district.base_y) - float(tier - 1) * 220.0
				for step in range(1, 4):
					var stair := district.get_node("Tier%02dStair%02d" % [tier, step]) as StaticBody2D
					_check(absf(stair.position.x - prior_x) <= 110.0 and prior_y - stair.position.y <= 60.0, "%s shaft %d stair %d is unreachable" % [info[0], tier, step])
					prior_x = stair.position.x
					prior_y = stair.position.y
		var houses := 0
		for child in district.get_children():
			if child.name.begins_with("LowerHome") or child.name.begins_with("TerraceHome"):
				houses += 1
		_check(houses >= 15, "%s does not read as a populated multi-level settlement" % info[0])
		_check(district.has_node("QuarterLantern00_00") and district.has_node("StreetBench05") and district.has_node("LaundryLine05") and district.has_node("QuarterStall04"), "%s lacks street-scale settlement detail" % info[0])
		if bool(info[2]):
			var residents := 0
			var services := 0
			for child in district.get_children():
				if child.is_in_group("town_resident"):
					residents += 1
				if child.is_in_group("town_service"):
					services += 1
			_check(residents >= 6 and services >= 2, "Haven lacks residents or services")
			for node in room.find_children("*", "Node", true, false):
				_check(not node.is_in_group("enemy"), "An enemy entered the safe Haven")
		else:
			var foes := 0
			var keepers := 0
			for child in district.get_children():
				if child.is_in_group("enemy"):
					foes += 1
					_check(child.position.y > district.base_y - 4.0 * 220.0, "Hostile patrol entered the protected gate quarter")
				if child.is_in_group("town_resident"):
					keepers += 1
			_check(foes >= 4 and keepers >= 4, "Outskirts lacks danger or friendly road life outside its safe gate")
		room.queue_free()
		await process_frame
	if failures.is_empty():
		print("ECHO SETTLEMENT TOPOLOGY TEST PASSED")
		quit(0)
	else:
		print("ECHO SETTLEMENT TOPOLOGY TEST FAILED: ", failures)
		quit(1)
