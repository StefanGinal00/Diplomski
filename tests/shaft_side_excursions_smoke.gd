extends "res://tests/remaining_jump_routes_smoke.gd"

# Terrain-only: ONE placement per excursion, then a continuous climb,
# exploration and return with ordinary movement and no mid-route resets.
const SIDE_ROOMS := ["ShaftHollow", "DrownedCrossing", "FloodedGallery", "BlackwaterCistern", "WardenApproach"]
var excursions := 0


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_shaft_side_excursions_save.json"
	state.start_new_game("normal")
	var template := load("res://Game.tscn").instantiate() as Node
	player = template.get_node("Player")
	template.remove_child(player)
	template.free()
	root.add_child(player)
	player.double_jump_unlocked = false
	player.dash_unlocked = false
	player.set_physics_process(false)
	for scene_name in SIDE_ROOMS:
		var room := load("res://%s.tscn" % scene_name).instantiate() as Node2D
		room.process_mode = Node.PROCESS_MODE_DISABLED
		root.add_child(room)
		await process_frame
		for actor in room.find_children("*", "CollisionObject2D", true, false):
			actor.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if actor is Area2D or actor.is_in_group("enemy") or actor.is_in_group("neutral_creature") or actor.is_in_group("breakable"):
				actor.collision_layer = 0
				actor.collision_mask = 0
		var expansion := room.get_node("ExpandedRoute")
		var route := expansion.get_node("AuthoredDescent") as Node2D
		for kind in ["Branch", "Niche"]:
			for tier in ([1, 3, 5] if kind == "Branch" else [1, 4]):
				var steps: Array[StaticBody2D] = []
				for index in range(1, 4 if kind == "Branch" else 5):
					steps.append(route.get_node("%s%d_%s%d" % [kind, tier, "Step" if kind == "Branch" else "Ascent", index]))
				var crest := route.get_node("%s%d_%s" % [kind, tier, "Chamber" if kind == "Branch" else "Crest"]) as StaticBody2D
				var chamber: Rect2 = expansion._chamber_rect(tier)
				var base := _floor_at(route, chamber.end.y, steps[0].position.x)
				var label := "%s/%s%d" % [scene_name, kind, tier]
				_check(base != null, label + ": missing corridor support")
				if base == null:
					continue
				var path: Array[StaticBody2D] = [base]
				path.append_array(steps)
				path.append(crest)
				await _excursion(path, label)
		room.queue_free()
		await process_frame
	_release()
	player.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("SHAFT SIDE EXCURSIONS TEST PASSED: ", excursions, " continuous out-and-back side routes in ", SIDE_ROOMS.size(), " rooms; terrain-only, no movement upgrades")
		quit(0)
	else:
		print("SHAFT SIDE EXCURSIONS TEST FAILED: ", failures.size())
		quit(1)


func _excursion(path: Array[StaticBody2D], label: String) -> void:
	_release()
	player.set_physics_process(false)
	var base := _bounds(path[0])
	var start_x := clampf(path[1].global_position.x, base.position.x + 16, base.end.x - 16)
	player.global_position = Vector2(start_x, base.position.y - 20)
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	for frame in range(10):
		await physics_frame
	var ok := true
	for index in range(1, path.size()):
		if not await _connected_step(path[index], label):
			ok = false
			break
	if ok:
		# Visit the far half, not just the edge of the destination ledge.
		var crest := _bounds(path.back())
		var far_x := crest.end.x - 35 if start_x < crest.get_center().x else crest.position.x + 35
		ok = await _walk_on_floor(far_x, label + "/explore")
	if ok:
		for index in range(path.size() - 2, -1, -1):
			if not await _connected_step(path[index], label + "/return"):
				ok = false
				break
	if ok:
		ok = await _walk_on_floor(start_x, label + "/corridor")
	var half: Vector2 = player.player_collision.shape.size * 0.5
	_check(ok and player.is_on_floor() and absf(player.global_position.y + half.y - base.position.y) < 4, label + ": did not return to the main corridor at " + str(player.global_position))
	_release()
	player.set_physics_process(false)
	if ok:
		excursions += 1


func _walk_on_floor(goal_x: float, label: String) -> bool:
	var budget := maxi(360, ceili(absf(goal_x - player.global_position.x) / 2.75) + 180)
	for frame in range(budget):
		_release()
		var dx := goal_x - player.global_position.x
		if absf(dx) <= 3 and player.is_on_floor():
			return true
		if absf(dx) > 3:
			Input.action_press("ui_right" if dx > 0 else "ui_left")
		await physics_frame
	_check(false, label + ": walk timed out at " + str(player.global_position))
	return false


func _connected_step(target: StaticBody2D, label: String) -> bool:
	var dest := _bounds(target)
	var half: Vector2 = player.player_collision.shape.size * 0.5
	var support: StaticBody2D
	for index in range(player.get_slide_collision_count()):
		var hit := player.get_slide_collision(index)
		if hit.get_normal().y < -0.5:
			support = hit.get_collider() as StaticBody2D
	# Floor snapping may keep is_on_floor true without a fresh slide collision.
	# Probe the actual feet instead of assuming the last collision list persists.
	if support == null and player.is_on_floor():
		var feet := player.global_position + Vector2(0, half.y - 1)
		var query := PhysicsRayQueryParameters2D.create(feet, feet + Vector2(0, 7), 1)
		query.exclude = [player.get_rid()]
		var hit := player.get_world_2d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			support = hit.collider as StaticBody2D
	if support == null:
		_check(false, label + ": no takeoff support")
		return false
	if support == target:
		return true
	var source := _bounds(support)
	# A neighbouring one-way plank a few pixels lower is a walking step,
	# not a drop-through: that input would ignore both overlapping planks.
	if dest.position.y > source.position.y and dest.position.y - source.position.y <= 8 and source.end.x >= dest.position.x and dest.end.x >= source.position.x:
		var exposed_x := NAN
		if dest.end.x > source.end.x + half.x * 2 + 10:
			exposed_x = source.end.x + half.x + 6
		elif dest.position.x < source.position.x - half.x * 2 - 10:
			exposed_x = source.position.x - half.x - 6
		if is_finite(exposed_x):
			var walked := await _walk_on_floor(exposed_x, label + "/shallow-step")
			var arrived := walked and absf(player.global_position.y + half.y - dest.position.y) < 4
			# Combat obstacle hops can land on a higher crossing plank while
			# traversing this tiny step. Use the actual support for a bounded
			# physical retry, rather than accepting the wrong elevation.
			if walked and not arrived and player.is_on_floor() and player.global_position.y + half.y < source.position.y - 4 and label.count("/shallow-replan") < 3:
				return await _connected_step(target, label + "/shallow-replan")
			_check(arrived, "%s: shallow %s -> %s ended at %s; target %s" % [label, support.name, target.name, player.global_position, dest])
			return arrived
	if absf(source.position.y - dest.position.y) <= 0.5 and source.end.x >= dest.position.x and dest.end.x >= source.position.x:
		var walked := await _walk_on_floor(dest.get_center().x, label + "/overlapping-floor")
		if walked and absf(player.global_position.y + half.y - dest.position.y) < 4:
			return true
		if walked and player.is_on_floor() and label.count("/overlap-replan") < 3:
			return await _connected_step(target, label + "/overlap-replan")
		_check(false, "%s: overlapping %s -> %s changed height at %s" % [label, support.name, target.name, player.global_position])
		return false
	var takeoff_x := clampf(dest.get_center().x, source.position.x + half.x + 5, source.end.x - half.x - 5)
	var ascending := dest.position.y < source.position.y - 2
	var solid_ascent: bool = ascending and not target.get_node("CollisionShape2D").one_way_collision
	if solid_ascent:
		var left := dest.position.x - half.x - 18
		var right := dest.end.x + half.x + 18
		takeoff_x = clampf(left if absf(left - source.get_center().x) < absf(right - source.get_center().x) else right, source.position.x + half.x + 5, source.end.x - half.x - 5)
	if not await _walk_on_floor(takeoff_x, label + "/takeoff"):
		return false
	# An active hazard or obstacle hop can change the actual support while
	# walking to takeoff. Re-plan before using the old platform's geometry.
	if player.is_on_floor() and absf(player.global_position.y + half.y - source.position.y) > 4:
		return await _connected_step(target, label)
	var landing_x := clampf(takeoff_x, dest.position.x + half.x + 5, dest.end.x - half.x - 5)
	if not ascending and not support.get_node("CollisionShape2D").one_way_collision:
		# Solid floors require walking off the shaft lip, not a drop input
		# while still standing above the overlapping part of the lower step.
		landing_x = clampf(source.end.x + half.x + 4 if dest.get_center().x > source.get_center().x else source.position.x - half.x - 4, dest.position.x + half.x + 5, dest.end.x - half.x - 5)
	var takeoff_position := player.global_position
	var horizontal_gap := maxf(source.position.x, dest.position.x) - minf(source.end.x, dest.end.x)
	var jumping := ascending or horizontal_gap > 8
	if jumping:
		player._try_jump()
	else:
		player._try_drop_through()
	for frame in range(100):
		_release()
		_step_frame()
		if not ascending and frame > 5 and player.is_on_floor() and player.global_position.y + half.y < dest.position.y - 3:
			player._try_drop_through()
		var dx := landing_x - player.global_position.x
		# With a real gap, approach horizontally during ascent. Waiting until
		# above a distant solid lip wastes the available jump arc. Delay only
		# when the destination is already alongside/overlapping the takeoff.
		if absf(dx) > 2 and (not solid_ascent or horizontal_gap > half.x + 4 or player.global_position.y + half.y < dest.position.y - 1):
			Input.action_press("ui_right" if dx > 0 else "ui_left")
		await physics_frame
		if frame > 4 and player.is_on_floor():
			var obstruction_cleared: bool = await _clear_landing_obstruction()
			if obstruction_cleared:
				return await _connected_step(target, label)
			if absf(player.global_position.y + half.y - dest.position.y) < 4 and player.global_position.x > dest.position.x and player.global_position.x < dest.end.x:
				_release()
				return true
			for index in range(player.get_slide_collision_count()):
				if player.get_slide_collision(index).get_collider() == target:
					_release()
					return true
			# Dressing or a crossing stair can catch an ascent OR a horizontal
			# gap jump above the requested step. Keep the real supported landing
			# for the next leg; drop-through descents still require their floor.
			if (ascending or (jumping and _allow_horizontal_cover())) and player.global_position.y + half.y <= dest.position.y + 2 and player.global_position.x > dest.position.x and player.global_position.x < dest.end.x:
				_release()
				return await _settle_upper_step(target, label)
	if await _recover_failed_step(target, label):
		return true
	_check(false, "%s: %s -> %s failed at %s; takeoff %s source %s target %s" % [label, support.name, target.name, player.global_position, takeoff_position, source, dest])
	return false


func _clear_landing_obstruction() -> bool:
	return false


func _step_frame() -> void:
	# Terrain-only callers deliberately have no combat input.
	pass


func _recover_failed_step(_target: StaticBody2D, _label: String) -> bool:
	return false


func _settle_upper_step(_target: StaticBody2D, _label: String) -> bool:
	return true


func _allow_horizontal_cover() -> bool:
	return false
