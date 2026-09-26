extends "res://tests/hollow_hazard_layout_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_cistern_hazard_layout_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	game.get_node("Player").set_physics_process(false)
	state.set_current_room("shaft_cistern")
	await process_frame
	var room := game.get_node("BlackwaterCistern") as Node2D
	var route := room.get_node("ExpandedRoute/AuthoredDescent")
	var hazards := route.find_children("CisternPressureWave*", "Area2D", false, false)
	_check(hazards.size() == 3, "Cistern pressure field count changed")
	for hazard in hazards:
		var bounds := _rect(hazard)
		print("PRESSURE ", hazard.name, " local ", room.to_local(hazard.global_position), " size ", bounds.size)
		_check(bounds.size.is_equal_approx(Vector2(382.2, 86.4)), "Pressure hit area changed")
		_check(hazard.damage == 1 and is_equal_approx(hazard.idle_duration, 2.0) and is_equal_approx(hazard.warning_duration, 1.1) and is_equal_approx(hazard.active_duration, 0.55), "Pressure combat values changed")
		_check(is_equal_approx(absf(hazard.force.x), 170.0) and is_equal_approx(hazard.force.y, -155.0), "Pressure force changed")
		for other in hazards:
			if other != hazard:
				_check(not bounds.grow(24).intersects(_rect(other).grow(24)), "Pressure fields lack a safe gap")
		var supported := false
		for child in route.get_children():
			if not child is StaticBody2D or not child.has_node("CollisionShape2D") or not child.get_node("CollisionShape2D").shape is RectangleShape2D:
				continue
			var named := String(child.name)
			if named.begins_with("Turn") or (named.begins_with("Branch") and named.contains("Step")) or (named.begins_with("Niche") and named.contains("Ascent")):
				_check(not bounds.intersects(_rect(child).grow(18)), "%s covers stair takeoff %s" % [hazard.name, child.name])
			if named.begins_with("Chamber") and named.contains("Floor"):
				var floor_bounds := _rect(child)
				if absf(floor_bounds.position.y - bounds.end.y) < 10 and floor_bounds.position.x <= bounds.position.x - 48 and floor_bounds.end.x >= bounds.end.x + 48:
					supported = true
		_check(supported, "%s has no fully supported danger stretch with waiting pockets" % hazard.name)
	state.unlock_shortcut("shaft_cistern_pump")
	for hazard in hazards:
		_check(hazard.disabled, "Pump did not silence relocated pressure field")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("CISTERN HAZARD LAYOUT TEST PASSED: three full-size pressure fields, protected stair approaches and waiting pockets")
		quit(0)
	else:
		print("CISTERN HAZARD LAYOUT TEST FAILED: ", failures.size())
		quit(1)
