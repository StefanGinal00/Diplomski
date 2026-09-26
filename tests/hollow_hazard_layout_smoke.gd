extends "res://tests/ash_field_operations_smoke.gd"

# Placement/readability audit, not a whole-room survivability test.
func _rect(node: Node2D) -> Rect2:
	var collision := node.get_node("CollisionShape2D") as CollisionShape2D
	var size := (collision.shape as RectangleShape2D).size
	return collision.global_transform * Rect2(-size * 0.5, size)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_hollow_hazard_layout_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	game.get_node("Player").set_physics_process(false)
	state.set_current_room("shaft_hollow")
	await process_frame
	var room := game.get_node("ShaftHollow") as Node2D
	var route := room.get_node("ExpandedRoute/AuthoredDescent")
	var hazards := route.find_children("HollowRockfall*", "Area2D", false, false)
	_check(hazards.size() == 5, "Hollow must retain five rockfall sites")
	for index in range(hazards.size()):
		var hazard := hazards[index] as Area2D
		var bounds := _rect(hazard)
		var supported := false
		print("ROCKFALL ", hazard.name, " at ", room.to_local(hazard.global_position), " size ", bounds.size)
		_check(bounds.size.is_equal_approx(Vector2(302.4, 117.12)), "Rockfall hit area was reduced")
		_check(hazard.damage == 1 and is_equal_approx(hazard.idle_duration, 2.0) and is_equal_approx(hazard.warning_duration, 1.1) and is_equal_approx(hazard.active_duration, 0.55), "Rockfall combat timing/damage changed")
		for previous in range(index):
			_check(not bounds.grow(24).intersects(_rect(hazards[previous]).grow(24)), "%s overlaps another rockfall without a safe gap" % hazard.name)
		for child in route.get_children():
			var named := String(child.name)
			if child is StaticBody2D and (named.begins_with("Turn") or (named.begins_with("Branch") and named.contains("Step")) or (named.begins_with("Niche") and named.contains("Ascent"))):
				_check(not bounds.intersects(_rect(child).grow(18)), "%s covers the waiting/takeoff space at %s" % [hazard.name, child.name])
			if child is StaticBody2D and named.begins_with("Chamber") and named.contains("Floor"):
				var floor_bounds := _rect(child)
				if absf(floor_bounds.position.y - bounds.end.y) < 10 and floor_bounds.position.x <= bounds.position.x - 48 and floor_bounds.end.x >= bounds.end.x + 48:
					supported = true
		_check(supported, "%s lacks solid ground and 48-pixel safe waiting pockets on both sides" % hazard.name)
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("HOLLOW HAZARD LAYOUT TEST PASSED: five separated rockfalls, clear stair takeoffs, unchanged damage and warning windows")
		quit(0)
	else:
		print("HOLLOW HAZARD LAYOUT TEST FAILED: ", failures.size())
		quit(1)
