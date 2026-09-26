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
	root.get_node("GameState").save_path = "res://_tmp_shaft_expanded_route_suite_save.json"
	var rooms := ["ShaftHollow", "DrownedCrossing", "FloodedGallery", "BlackwaterCistern", "WardenApproach"]
	var signatures: Dictionary = {}
	for room_name in rooms:
		var room := (load("res://%s.tscn" % room_name) as PackedScene).instantiate() as Node2D
		root.add_child(room)
		await physics_frame
		var expansion := room.get_node("ExpandedRoute") as Node2D
		var descent := expansion.get_node("AuthoredDescent") as Node2D
		_check((descent.get_node("ChamberShadow0") as Polygon2D).polygon.size() >= 8, "%s returned to a rectangular cave shell" % room_name)
		var layout: Array = expansion.CHAMBER_LAYOUTS[room_name]
		var signature := str(layout)
		_check(not signatures.has(signature), "%s copied another Shaft topology" % room_name)
		signatures[signature] = room_name
		var rises := 0
		var drops := 0
		for tier in range(7):
			var chamber: Rect2 = expansion._chamber_rect(tier)
			var floor_coverage := 0.0
			var largest_floor := 0.0
			for child in descent.get_children():
				if child is StaticBody2D and String(child.name).begins_with("Chamber%d_Floor" % tier):
					var width := _width(child as StaticBody2D)
					floor_coverage += width
					largest_floor = maxf(largest_floor, width)
			_check(chamber.size.x >= 1300.0 and largest_floor >= 200.0, "%s chamber %d is undersized" % [room_name, tier])
			_check(absf(floor_coverage - FLOOR_EXPECTATIONS.solid_width(expansion, tier)) < 0.1, "%s chamber %d floor coverage disagrees with its shaft openings" % [room_name, tier])
			_check(descent.has_node("T%d_Bridge8" % tier) and not descent.get_node("T%d_Bridge8" % tier).has_node("CollisionShape2D"), "%s semantic anchors became visible platforms" % room_name)
			if tier < 6:
				var next: Rect2 = expansion._chamber_rect(tier + 1)
				rises += 1 if next.end.y < chamber.end.y else 0
				drops += 1 if next.end.y > chamber.end.y else 0
				_check(descent.has_node("Turn%d_Drop1" % tier), "%s shaft %d is disconnected" % [room_name, tier])
		_check(rises >= 1 and drops >= 3, "%s is still a one-way shelf descent" % room_name)
		for branch_tier in [1, 3, 5]:
			_check(descent.has_node("Branch%d_Step3" % branch_tier), "%s branch %d has no climb" % [room_name, branch_tier])
			var branch := descent.get_node("Branch%d_Chamber" % branch_tier) as StaticBody2D
			_check(_width(branch) >= 400.0, "%s branch %d is not a real dead-end chamber" % [room_name, branch_tier])
		for niche_tier in [1, 4]:
			_check(descent.has_node("Niche%d_Ascent4" % niche_tier) and descent.has_node("Niche%d_Crest" % niche_tier), "%s lacks optional high chamber %d" % [room_name, niche_tier])
		_check(not descent.has_node("CorridorBed0"), "%s regressed to corridor shelves" % room_name)
		_check(descent.has_node("ReturnLiftTop") and descent.has_node("ReturnLiftBottom"), "%s lacks its return lift" % room_name)
		# A detached landing can pass a floor-support ray while remaining
		# unreachable from the room. Require the actual final gallery floor.
		for terminal_name in ["ReturnLiftBottom", "ReturnBottom"]:
			var terminal := descent.get_node(terminal_name) as Node2D
			var connected := false
			for child in descent.get_children():
				if not child is StaticBody2D or not String(child.name).begins_with("Chamber6_Floor"):
					continue
				var half_width := _width(child) * 0.5
				if absf(terminal.position.x - child.position.x) <= half_width - 25 and absf(terminal.position.y - (child.position.y - 32)) < 1:
					connected = true
			_check(connected, "%s/%s is detached from the final gallery" % [room_name, terminal_name])
		_check(descent.has_node("HiddenDepthAmbush") and descent.get_node("HiddenDepthAmbush").enemy_scenes.size() == 2, "%s lacks its lazy hidden-depth encounter" % room_name)
		room.queue_free()
		await process_frame
	_check(signatures.size() == rooms.size(), "Shaft rooms do not have unique chamber graphs")
	if failures.is_empty():
		print("SHAFT CHAMBER ROUTE TEST PASSED")
		quit(0)
	else:
		print("SHAFT CHAMBER ROUTE TEST FAILED: ", failures)
		quit(1)
