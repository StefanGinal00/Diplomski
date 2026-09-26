extends "res://tests/shaft_side_excursions_smoke.gd"

# One continuous entrance-to-bottom route, including all five side excursions.
# Terrain-only acceptance, NOT a live-combat or first-visit pacing claim.
var legs := 0
var survey: Node2D


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_hollow_full_navigation_save.json"
	state.start_new_game("normal")
	var template := load("res://Game.tscn").instantiate() as Node
	player = template.get_node("Player")
	template.remove_child(player)
	template.free()
	root.add_child(player)
	player.set_physics_process(false)
	var room := load("res://ShaftHollow.tscn").instantiate() as Node2D
	room.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(room)
	await process_frame
	for actor in room.find_children("*", "CollisionObject2D", true, false):
		actor.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
		if actor is Area2D or actor.is_in_group("enemy") or actor.is_in_group("neutral_creature") or actor.is_in_group("breakable"):
			actor.collision_layer = 0
			actor.collision_mask = 0
		if actor.is_in_group("enemy"):
			actor.queue_free() # Navigation isolation, not credited as combat.
	var expansion := room.get_node("ExpandedRoute")
	var route := expansion.get_node("AuthoredDescent") as Node2D
	survey = route.get_node("ExplorationSites/OreSurvey")
	for actor in [survey.get_node("Sample0"), survey.get_node("Sample1"), survey.get_node("Sample2"), survey.get_node("SurveyReward"), route.get_node("ReturnLiftBottom")]:
		actor.collision_mask = 1
	await _traverse(room)
	_release()
	state.delete_save()
	room.queue_free()
	player.queue_free()
	await process_frame
	if failures.is_empty():
		print("HOLLOW FULL NAVIGATION TEST PASSED: 7 galleries, 5 side detours, 3 samples, real return lift and camp reward; one initial placement, terrain-only")
		quit(0)
	else:
		print("HOLLOW FULL NAVIGATION TEST FAILED: ", failures.size())
		quit(1)


func _traverse(room: Node2D) -> bool:
	var state := root.get_node("GameState")
	var expansion := room.get_node("ExpandedRoute")
	var route := expansion.get_node("AuthoredDescent") as Node2D
	survey = route.get_node("ExplorationSites/OreSurvey")
	player.global_position = room.get_node("UpperEntry").global_position
	player.velocity = Vector2.ZERO
	var start_frame := Engine.get_physics_frames()
	player.set_physics_process(true)
	for frame in range(12):
		await physics_frame
	var ok := true
	for tier: int in range(7):
		var objective_ok: bool = await _gallery_objective(room, tier)
		if not objective_ok:
			ok = false
			break
		if tier in [1, 3, 5]:
			ok = await _detour(route, expansion, tier, "Branch")
		if ok and tier in [1, 4]:
			ok = await _detour(route, expansion, tier, "Niche")
		if not ok or tier == 6:
			break
		var stairs: Array[StaticBody2D] = []
		for node in route.get_children():
			if node is StaticBody2D and String(node.name).begins_with("Turn%d_Drop" % tier):
				stairs.append(node)
		var source: Rect2 = expansion._chamber_rect(tier)
		var next: Rect2 = expansion._chamber_rect(tier + 1)
		stairs.sort_custom(func(a, b): return a.position.y < b.position.y if source.end.y < next.end.y else a.position.y > b.position.y)
		ok = await _approach(route, source.end.y, stairs[0].position.x)
		if not ok:
			break
		for step in stairs:
			if not await _connected_step(step, "Hollow/main%d" % tier):
				ok = false
				break
		if ok:
			var landing := _floor_at(route, next.end.y, stairs.back().position.x)
			ok = await _connected_step(landing, "Hollow/main%d/landing" % tier)
		if not ok:
			break
		legs += 1
	if ok:
		ok = await _record(survey.get_node("Sample2"))
	if ok:
		ok = await _walk_on_floor(route.get_node("ReturnLiftBottom").global_position.x, "Hollow/bottom-lift")
	if ok:
		var lift := route.get_node("ReturnLiftBottom")
		await _interact(lift)
		var transition := root.get_node("RoomTransition")
		for frame in range(180):
			if not transition.is_transitioning:
				break
			await physics_frame
		_check(state.unlocked_shortcuts.get("shaft_hollow_return_lift", false), "Lower lift was not activated physically")
		_check(player.global_position.distance_to(route.get_node("ReturnTop").global_position) < 5, "Lift did not return to the entrance")
		# Continue walking from the legitimate lift arrival back to Deren.
		for frame in range(12):
			await physics_frame
		ok = await _approach(route, 330, route.get_node("Turn0_Drop1").position.x)
		for index in range(1, 7):
			if ok:
				ok = await _connected_step(route.get_node("Turn0_Drop%d" % index), "Hollow/revisit-descent")
		if ok:
			ok = await _connected_step(_floor_at(route, 690, 1585), "Hollow/revisit-floor")
		if ok:
			ok = await _detour(route, expansion, 1, "Branch")
	_check(survey.recorded_count() == 3 and survey.get_node("SurveyReward").opened, "Survey loop did not physically collect all samples and return for supplies")
	_check(ok and legs == 6 and excursions == 6, "Continuous Hollow navigation incomplete")
	print("HOLLOW ROUTE PHYSICS TIME: ", snappedf((Engine.get_physics_frames() - start_frame) / 60.0, 0.1), " seconds; interpret using this test's setup allowances")
	_release()
	return ok


func _gallery_objective(_room: Node2D, _tier: int) -> bool:
	return true


func _detour(route: Node2D, expansion: Node2D, tier: int, kind: String) -> bool:
	var steps: Array[StaticBody2D] = []
	for index in range(1, 4 if kind == "Branch" else 5):
		steps.append(route.get_node("%s%d_%s%d" % [kind, tier, "Step" if kind == "Branch" else "Ascent", index]))
	steps.append(route.get_node("%s%d_%s" % [kind, tier, "Chamber" if kind == "Branch" else "Crest"]))
	var chamber: Rect2 = expansion._chamber_rect(tier)
	if not await _approach(route, chamber.end.y, steps[0].position.x):
		return false
	for step in steps:
		if not await _connected_step(step, "Hollow/%s%d" % [kind, tier]):
			return false
	var crest := _bounds(steps.back())
	if not await _walk_on_floor(crest.get_center().x, "Hollow/side-destination"):
		return false
	if not await _side_objective(route, tier, kind):
		return false
	if is_instance_valid(survey) and kind == "Niche" and tier == 1:
		if not await _record(survey.get_node("Sample0")):
			return false
	if is_instance_valid(survey) and kind == "Branch" and tier == 3:
		if not await _record(survey.get_node("Sample1")):
			return false
	if is_instance_valid(survey) and kind == "Branch" and tier == 1 and survey.recorded_count() == 3:
		if not await _record(survey.get_node("SurveyReward")):
			return false
	steps.pop_back()
	steps.reverse()
	for step in steps:
		if not await _connected_step(step, "Hollow/%s%d/return" % [kind, tier]):
			return false
	var base := _floor_at(route, chamber.end.y, steps.back().position.x)
	if not await _connected_step(base, "Hollow/side-return"):
		return false
	excursions += 1
	return true


func _side_objective(_route: Node2D, _tier: int, _kind: String) -> bool:
	return true


func _approach(route: Node2D, floor_y: float, desired_x: float) -> bool:
	var floor_node := _floor_at(route, floor_y, desired_x)
	var bounds := _bounds(floor_node)
	var goal := clampf(route.to_global(Vector2(desired_x, 0)).x, bounds.position.x + 16, bounds.end.x - 16)
	var direction := signf(goal - player.global_position.x)
	var crossings: Array[StaticBody2D] = []
	for node in route.get_children():
		if node is StaticBody2D and String(node.name).begins_with("ShaftCrossing") and absf(node.position.y - (floor_y - 38)) < 1:
			if (node.global_position.x - player.global_position.x) * direction > 0 and (goal - node.global_position.x) * direction > 0:
				crossings.append(node)
	crossings.sort_custom(func(a, b): return a.global_position.x < b.global_position.x if direction > 0 else a.global_position.x > b.global_position.x)
	for crossing in crossings:
		var current_floor := _floor_at(route, floor_y, route.to_local(player.global_position).x)
		var current_bounds := _bounds(current_floor)
		if absf(player.global_position.y + 10 - current_bounds.position.y) < 5:
			if not await _walk_on_floor(clampf(crossing.global_position.x, current_bounds.position.x + 16, current_bounds.end.x - 16), "Hollow/crossing-approach"):
				return false
		if not await _connected_step(crossing, "Hollow/crossing"):
			return false
	if not crossings.is_empty():
		if not await _connected_step(floor_node, "Hollow/crossing-exit"):
			return false
	return await _walk_on_floor(goal, "Hollow/corridor-approach")


func _record(object: Area2D) -> bool:
	if not await _walk_on_floor(object.global_position.x, "Hollow/sample-or-reward"):
		return false
	await _interact(object)
	return true


func _interact(object: Area2D) -> void:
	_release()
	for frame in range(3):
		await physics_frame
	_press_interaction(object)


func _press_interaction(object: Area2D) -> void:
	_check(object.get_overlapping_bodies().has(player), str(object.name) + ": not physically in interaction range")
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	object._unhandled_input(event)
