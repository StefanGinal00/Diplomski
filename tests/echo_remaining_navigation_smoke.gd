extends "res://tests/echo_grotto_live_pilot.gd"

# One placement per room, then continuous exploration and backtracking.
# Terrain isolation: AI, hazards and interactions are disabled. This is not
# a combat, quest-completion or human-pacing acceptance test.
const NAV_ROOMS := ["TideWell", "EchoNest", "CrystalCauseway", "UndertowVault"]
var forward_links := 0
var reverse_links := 0
var branches := 0


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_remaining_navigation_save.json"
	state.start_new_game("normal")
	var template: Node = load("res://Game.tscn").instantiate()
	player = template.get_node("Player")
	template.remove_child(player)
	template.free()
	root.add_child(player)
	player.set_physics_process(false)
	echo_active = true
	advanced_steering = true
	for scene_name in NAV_ROOMS:
		room = load("res://%s.tscn" % scene_name).instantiate()
		room.process_mode = Node.PROCESS_MODE_DISABLED
		root.add_child(room)
		await process_frame
		for actor in room.find_children("*", "CollisionObject2D", true, false):
			actor.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if actor is Area2D or actor.is_in_group("enemy") or actor.is_in_group("neutral_creature") or actor.is_in_group("breakable"):
				actor.collision_layer = 0
				actor.collision_mask = 0
		var first := _echo_floor(0, _route_geometry()._chamber_rect(0).get_center().x)
		player.global_position = Vector2(_bounds(first).get_center().x, _bounds(first).position.y - 11)
		player.velocity = Vector2.ZERO
		player.set_physics_process(true)
		for frame in range(12):
			await physics_frame
		var count: int = _route_geometry().profile["tiers"]
		var ok := true
		for tier in range(count):
			if tier % 2 == 1:
				ok = await _navigation_branch(tier)
			if not ok or tier == count - 1:
				break
			ok = await _echo_link(tier, tier + 1)
			if not ok:
				break
			forward_links += 1
		if ok:
			ok = await _echo_approach(count - 1, _route_geometry().get_node("RimReturnDoor").position.x)
		if ok:
			for tier in range(count - 1, 0, -1):
				ok = await _echo_link(tier, tier - 1)
				if not ok:
					break
				reverse_links += 1
		_check(ok, scene_name + " connected exploration/backtracking failed")
		print("ECHO NAVIGATION: ", scene_name, " round trip ", ok, "; ", count, " chambers")
		_release()
		player.set_physics_process(false)
		room.queue_free()
		await process_frame
		if not failures.is_empty():
			break
	_check(forward_links == 36 and reverse_links == 36 and branches == 18, "Remaining Echo navigation coverage incomplete")
	_check(player.max_health == 5 and not player.double_jump_unlocked and not player.dash_unlocked, "Navigation no longer uses basic movement")
	player.queue_free()
	state.delete_save()
	await process_frame
	if failures.is_empty():
		print("ECHO REMAINING NAVIGATION TEST PASSED: 40 chambers, 18 branches, 36 forward + 36 reverse links; terrain-only, four initial placements")
		quit(0)
	else:
		quit(1)


func _supplies() -> void:
	pass


func _foes() -> Array[Node]:
	return []


func _walk_on_floor(goal_x: float, label: String) -> bool:
	for frame in range(1800):
		_release()
		var dx := goal_x - player.global_position.x
		if absf(dx) <= 3 and player.is_on_floor():
			return true
		if absf(dx) > 3:
			Input.action_press("ui_right" if dx > 0 else "ui_left")
		await physics_frame
	var collisions: Array[String] = []
	for index in range(player.get_slide_collision_count()):
		collisions.append(str(player.get_slide_collision(index).get_collider().name))
	_check(false, "%s: terrain walk stalled in %s at %s toward %s; collisions %s, links %d/%d" % [label, room.name, player.global_position, goal_x, collisions, forward_links, reverse_links])
	return false


func _navigation_branch(tier: int) -> bool:
	var route := _route_geometry()
	var steps: Array[StaticBody2D] = []
	for suffix in ["BranchStep1", "BranchStep2", "HiddenShelfA", "HiddenShelfB"]:
		steps.append(route.get_node("Tier%02d%s" % [tier, suffix]))
	# A/B names are left-to-right, not entrance-to-interior. Left-facing
	# branches must visit B before A, then reverse that physical path.
	if absf(steps[3].position.x - steps[1].position.x) < absf(steps[2].position.x - steps[1].position.x):
		var near_shelf := steps[3]
		steps[3] = steps[2]
		steps[2] = near_shelf
	if not await _echo_approach(tier, steps[0].position.x):
		return false
	for step in steps:
		if not await _connected_step(step, "Echo/navigation-branch"):
			return false
	# Reach both halves, not merely the shaft-side lip of the hidden room.
	if not await _walk_on_floor(steps.back().global_position.x, "Echo/branch-interior"):
		return false
	steps.reverse()
	for step in steps:
		if not await _connected_step(step, "Echo/navigation-return"):
			return false
	if not await _connected_step(_echo_floor(tier, steps.back().position.x), "Echo/navigation-floor"):
		return false
	branches += 1
	return true
