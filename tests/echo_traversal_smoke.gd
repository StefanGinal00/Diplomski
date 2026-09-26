extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_echo_traversal_suite_save.json"
	var scenes := ["EchoGrotto", "EchoGallery", "PrismArchive", "TideWell", "EchoNest", "CrystalCauseway", "UndertowVault"]
	var signatures: Dictionary = {}
	for scene_name in scenes:
		var room := (load("res://%s.tscn" % scene_name) as PackedScene).instantiate() as Node2D
		root.add_child(room)
		await physics_frame
		var route := room.get_node("LongTraversal") as Node2D
		var tiers: int = route.profile["tiers"]
		var layout: Array = route.CHAMBER_LAYOUTS[route.route_id]
		_check((route.get_node("ChamberPocket00") as Polygon2D).polygon.size() >= 8, "%s returned to a rectangular cave shell" % scene_name)
		_check(layout.size() == tiers, "%s chamber graph has wrong room count" % scene_name)
		var signature := str(layout)
		_check(not signatures.has(signature), "%s copied another Echo topology" % scene_name)
		signatures[signature] = scene_name
		var rises := 0
		var drops := 0
		var travel := 0.0
		var highest := 10000.0
		var lowest := -10000.0
		for tier in range(tiers):
			var chamber: Rect2 = route._chamber_rect(tier)
			highest = minf(highest, chamber.position.y)
			lowest = maxf(lowest, chamber.end.y)
			_check(chamber.size.x >= 600.0 and chamber.size.y == 300.0, "%s chamber %d is not a playable room" % [scene_name, tier])
			_check(route.has_node("Chamber%02dFloor0" % tier), "%s chamber %d lacks continuous ground" % [scene_name, tier])
			if tier < tiers - 1:
				var next: Rect2 = route._chamber_rect(tier + 1)
				travel += chamber.get_center().distance_to(next.get_center())
				rises += 1 if next.end.y < chamber.end.y else 0
				drops += 1 if next.end.y > chamber.end.y else 0
				_check(route.has_node("Tier%02dRise01" % (tier + 1)), "%s chamber link %d is disconnected" % [scene_name, tier])
			if tier % 2 == 1:
				_check(route.has_node("Tier%02dBranchChamber" % tier) and route.has_node("Tier%02dHiddenShelfB" % tier), "%s lacks side chamber %d" % [scene_name, tier])
				_check((route.get_node("Tier%02dBranchChamber" % tier) as Polygon2D).polygon.size() >= 8, "%s side chamber %d is still rectangular" % [scene_name, tier])
		_check(travel >= 5000.0, "%s chamber route is too short" % scene_name)
		_check(lowest - highest >= 1700.0 and rises >= 1 and drops >= 1, "%s is still a flat one-way staircase" % scene_name)
		_check(not route.has_node("Tier00Shelf00"), "%s regressed to platform shelves" % scene_name)
		_check(route.has_node("RimReturnDoor"), "%s lacks its return shortcut" % scene_name)
		_check(route.has_node("OptionalAmbush") and route.get_node("OptionalAmbush").enemy_scenes.size() == 2, "%s lacks its lazy optional ambush" % scene_name)
		_check(route.has_node("RouteDiscoveryCache") and route.get_node("RouteDiscoveryCache").position.distance_to(route.get_node("Tier07HiddenShelfB").position) < 50.0, "%s lacks a reward in its deepest side chamber" % scene_name)
		room.queue_free()
		await process_frame
	_check(signatures.size() == scenes.size(), "Echo rooms do not have unique chamber graphs")
	if failures.is_empty():
		print("ECHO CHAMBER TOPOLOGY TEST PASSED")
		quit(0)
	else:
		print("ECHO CHAMBER TOPOLOGY TEST FAILED: ", failures)
		quit(1)
