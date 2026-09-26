extends "res://tests/basic_jump_routes_smoke.gd"

const ROUTE_SCENES := ["ShaftHollow", "DrownedCrossing", "FloodedGallery", "BlackwaterCistern", "WardenApproach", "BrokenCauseway", "CinderForge", "EmberBarracks", "SlagReservoir", "AshChapel", "CinderHearthOutskirts", "StarfallOutskirts", "StarfallSilentGate", "StarfallMemoryVault", "StarfallRootedHall", "StarfallSoulCrucible", "StarfallSunlessPassage"]


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_remaining_jump_routes_save.json"
	state.start_new_game("normal")
	var template := load("res://Game.tscn").instantiate() as Node
	player = template.get_node("Player")
	template.remove_child(player)
	template.free()
	root.add_child(player)
	player.double_jump_unlocked = false
	player.dash_unlocked = false
	player.set_physics_process(false)
	for scene_name in ROUTE_SCENES:
		var room := load("res://%s.tscn" % scene_name).instantiate() as Node2D
		room.process_mode = Node.PROCESS_MODE_DISABLED
		root.add_child(room)
		await process_frame
		for actor in room.find_children("*", "CollisionObject2D", true, false):
			actor.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if actor is Area2D or actor.is_in_group("enemy") or actor.is_in_group("neutral_creature") or actor.is_in_group("breakable"):
				actor.collision_layer = 0
				actor.collision_mask = 0
		var ash := room.get_node_or_null("AshSwitchback") as Node2D
		var route: Node2D = ash if ash != null else room.get_node("ExpandedRoute")
		var holder: Node2D = route if ash != null else route.generated
		var count: int = route.CHAMBER_LAYOUTS[String(route.course_id)].size() if ash != null else route.plan["levels"].size()
		var cursor := 1
		for tier in range(count - 1):
			var a: Rect2 = route._chamber_rect(tier)
			var b: Rect2 = route._chamber_rect(tier + 1)
			var steps: Array[StaticBody2D] = []
			if ash != null:
				var intervals := maxi(2, ceili(absf(a.end.y - b.end.y) / route.STEP_RISE))
				for index in range(intervals - 1):
					steps.append(holder.get_node("AshStep_%02d" % cursor))
					cursor += 1
			else:
				for child in holder.get_children():
					if child is StaticBody2D and String(child.name).begins_with("Turn%d_Drop" % tier):
						steps.append(child)
			await _chain(steps, holder, maxf(a.end.y, b.end.y), minf(a.end.y, b.end.y), scene_name + "/main%d" % tier)
		# Optional reward approaches, not the intentionally one-way return chutes.
		for tier in [1, 4]:
			var steps: Array[StaticBody2D] = []
			var crest: StaticBody2D
			if ash != null:
				for index in range(4):
					steps.append(holder.get_node("AshStep_%02d" % cursor))
					cursor += 1
				var rect: Rect2 = route._niche_crests[0 if tier == 1 else 1]
				crest = _floor_at(holder, rect.get_center().y, rect.get_center().x)
			else:
				for index in range(1, 5):
					steps.append(holder.get_node("Niche%d_Ascent%d" % [tier, index]))
				crest = holder.get_node("Niche%d_Crest" % tier)
			var lower: Rect2 = route._chamber_rect(tier + 1 if ash != null else tier)
			await _chain(steps, holder, lower.end.y, crest.position.y, scene_name + "/niche%d" % tier, crest)
		if ash == null:
			for tier in [1, 3, 5]:
				var steps: Array[StaticBody2D] = []
				for index in range(1, 4):
					steps.append(holder.get_node("Branch%d_Step%d" % [tier, index]))
				var crest := holder.get_node("Branch%d_Chamber" % tier) as StaticBody2D
				var lower: Rect2 = route._chamber_rect(tier)
				await _chain(steps, holder, lower.end.y, crest.position.y, scene_name + "/branch%d" % tier, crest)
		room.queue_free()
		await process_frame
	_release()
	player.queue_free()
	await process_frame
	state.delete_save()
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("REMAINING JUMP ROUTES TEST PASSED: ", jumps, " hops in ", ROUTE_SCENES.size(), " rooms")
		quit(0)
	else:
		print("REMAINING JUMP ROUTES TEST FAILED: ", failures.size(), " / ", jumps)
		quit(1)


func _floor_at(holder: Node2D, y: float, x: float) -> StaticBody2D:
	var best: StaticBody2D
	var distance := INF
	for body in holder.get_children():
		if not body is StaticBody2D or body.collision_layer == 0 or not body.has_node("CollisionShape2D"):
			continue
		var collision := body.get_node("CollisionShape2D") as CollisionShape2D
		if not collision.shape is RectangleShape2D or collision.shape.size.y > 22 or collision.shape.size.x < 40 or absf(body.position.y - y) > 1:
			continue
		var half: float = collision.shape.size.x * 0.5
		var gap := absf(x - clampf(x, body.position.x - half + 12, body.position.x + half - 12))
		if gap < distance:
			distance = gap
			best = body
	return best


func _chain(steps: Array[StaticBody2D], holder: Node2D, lower_y: float, upper_y: float, label: String, crest: StaticBody2D = null) -> void:
	_check(not steps.is_empty(), "Missing staircase: " + label)
	if steps.is_empty():
		return
	steps.sort_custom(func(a: StaticBody2D, b: StaticBody2D) -> bool: return a.position.y > b.position.y)
	var entry := _floor_at(holder, lower_y, steps[0].position.x)
	var exit_floor := crest if crest != null else _floor_at(holder, upper_y, steps.back().position.x)
	_check(entry != null and exit_floor != null, "Missing floor at ends of " + label)
	if entry == null or exit_floor == null:
		return
	var path: Array[StaticBody2D] = [entry]
	path.append_array(steps)
	path.append(exit_floor)
	for index in range(path.size() - 1):
		await _hop(path[index], path[index + 1], label)
