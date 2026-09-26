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
	root.get_node("GameState").save_path = "res://_tmp_expedition_wing_expanded_suite_save.json"
	var topology_signatures: Dictionary = {}
	for region in ["shaft", "echo", "ash", "starfall"]:
		var wing := Node2D.new()
		wing.name = "WingProbe"
		wing.set_script(load("res://ExpeditionWing.gd"))
		wing.region = region
		root.add_child(wing)
		await physics_frame
		_check((wing.get_node("MainChamber0Backdrop") as Polygon2D).polygon.size() >= 8, "%s expedition backdrop is still rectangular" % region)
		_check(wing.get_node("TrailLamp").position == Vector2(245, 647), "%s save lamp moved" % region)
		_check(wing.get_node("Entry").position == Vector2(110, 647), "%s entry marker moved" % region)
		_check(wing._main_data().size() == 8 and wing._branch_data().size() == 4, "%s lacks a full chamber graph" % region)
		var signature := str(wing._main_data()) + str(wing._branch_data()) + str(wing.CHAMBER_LAYOUTS[region]["loop"])
		_check(not topology_signatures.has(signature), "%s copied another expedition topology" % region)
		topology_signatures[signature] = region
		var rises := 0
		var drops := 0
		for index in range(8):
			var room: Rect2 = wing._main_rect(index)
			_check(room.size.x >= 1450.0 and room.size.y >= 300.0, "%s main chamber %d is too small" % [region, index])
			_check(wing.has_node("MainRoom%dFloor0" % index), "%s main chamber %d has no continuous floor" % [region, index])
			if index < 7:
				var next_room: Rect2 = wing._main_rect(index + 1)
				if next_room.end.y < room.end.y:
					rises += 1
				else:
					drops += 1
				_check(wing.has_node("MainLink%dShaftStep0" % index), "%s chambers %d/%d are not connected" % [region, index, index + 1])
		_check(rises >= 1 and drops >= 2, "%s is still a one-direction staircase" % region)
		for index in range(4):
			var branch: Rect2 = wing._branch_rect(index)
			_check(branch.size.x >= 850.0 and wing.has_node("BranchRoom%dFloor0" % index), "%s branch chamber %d is missing" % [region, index])
			_check(wing.has_node("BranchLink%dShaftStep0" % index) or wing.has_node("BranchLink%dTunnelFloor" % index) or wing.has_node("BranchLink%dPortalThreshold" % index), "%s branch chamber %d is disconnected" % [region, index])
		_check(wing.has_node("LoopLinkShaftStep0") or wing.has_node("LoopLinkTunnelFloor"), "%s has no alternate route" % region)
		_check(not wing.has_node("Tier0_Span0"), "%s regressed to a platform shelf grid" % region)
		_check(wing.get_node("ReturnLiftBottom").activates_shortcut and not wing.get_node("ReturnLiftTop").activates_shortcut, "%s return lift skips exploration" % region)
		_check(wing.get_node("ReturnLiftLanding/CollisionShape2D").one_way_collision, "%s return lift landing blocks ascent from underneath" % region)
		var patrols := 0
		var guards := 0
		for child in wing.get_children():
			if child.name.begins_with("Patrol"):
				patrols += 1
			elif child.name.begins_with("BranchGuard"):
				guards += 1
		_check(patrols == 20 and guards == 4, "%s chamber graph is under-populated" % region)
		wing.queue_free()
		await process_frame
	_check(topology_signatures.size() == 4, "Expedition regions do not have four unique layouts")
	if failures.is_empty():
		print("EXPEDITION CHAMBER GRAPH TEST PASSED")
		quit(0)
	else:
		print("EXPEDITION CHAMBER GRAPH TEST FAILED: ", failures)
		quit(1)
