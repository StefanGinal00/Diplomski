extends "res://tests/remaining_jump_routes_smoke.gd"

# Run with --headless --fixed-fps 60. Uses the real basic controller, with
# combat disabled. Ascents are isolated hops; each descent/tunnel is continuous.
var descents := 0
var tunnels := 0


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_expedition_jump_routes_save.json"
	state.start_new_game("normal")
	var template := load("res://Game.tscn").instantiate() as Node
	player = template.get_node("Player")
	template.remove_child(player)
	template.free()
	root.add_child(player)
	player.double_jump_unlocked = false
	player.dash_unlocked = false
	player.set_physics_process(false)
	for region in ["shaft", "echo", "ash", "starfall"]:
		var wing := load("res://ExpeditionWing.tscn").instantiate() as Node2D
		wing.region = region
		wing.process_mode = Node.PROCESS_MODE_DISABLED
		root.add_child(wing)
		await process_frame
		for actor in wing.find_children("*", "CollisionObject2D", true, false):
			actor.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if actor is Area2D or actor.is_in_group("enemy") or actor.is_in_group("neutral_creature") or actor.is_in_group("breakable"):
				actor.collision_layer = 0
				actor.collision_mask = 0
		for index in range(7):
			await _link(wing, "MainLink%d" % index, wing._main_rect(index), wing._main_rect(index + 1))
		for index in range(4):
			var parent_index: int = wing._branch_data()[index][4]
			await _link(wing, "BranchLink%d" % index, wing._main_rect(parent_index), wing._branch_rect(index))
		var loop: Array = wing.CHAMBER_LAYOUTS[region]["loop"]
		await _link(wing, "LoopLink", wing._main_rect(loop[0]), wing._main_rect(loop[1]))
		wing.queue_free()
		await process_frame
	_check(jumps == 322 and descents == 42 and tunnels == 12, "Expedition traversal coverage changed; review every route before updating expected counts")
	_release()
	player.queue_free()
	await process_frame
	state.delete_save()
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("EXPEDITION JUMP ROUTES TEST PASSED: ", jumps, " hops, ", descents, " continuous descents, ", tunnels, " tunnel walks")
		quit(0)
	else:
		print("EXPEDITION JUMP ROUTES TEST FAILED: ", failures.size(), " / ", jumps)
		quit(1)


func _link(wing: Node2D, prefix: String, a: Rect2, b: Rect2) -> void:
	if absf(a.end.y - b.end.y) < 100:
		await _walk_tunnel(wing, prefix, a, b)
		await _walk_tunnel(wing, prefix, b, a)
		return
	var steps: Array[StaticBody2D] = []
	for child in wing.get_children():
		if child is StaticBody2D and String(child.name).begins_with(prefix + "ShaftStep"):
			steps.append(child)
	await _chain(steps, wing, maxf(a.end.y, b.end.y), minf(a.end.y, b.end.y), String(wing.region) + "/" + prefix)
	await _descend(wing, prefix, a if a.end.y < b.end.y else b, b if a.end.y < b.end.y else a)


func _stand_on(body: StaticBody2D, x: float) -> void:
	_release()
	player.set_physics_process(false)
	var rect := _bounds(body)
	var half: Vector2 = player.player_collision.shape.size * 0.5
	player.global_position = Vector2(clampf(x, rect.position.x + half.x + 3, rect.end.x - half.x - 3), rect.position.y - half.y - 1)
	player.velocity = Vector2.ZERO
	player.jump_buffer_remaining = 0
	player.set_physics_process(true)
	for frame in range(8):
		await physics_frame
	_check(player.is_on_floor(), "Cannot stand at route entry: " + String(body.name))


func _steer(x: float) -> void:
	_release()
	var dx := x - player.global_position.x
	if absf(dx) > 2:
		Input.action_press("ui_right" if dx > 0 else "ui_left")


func _walk_tunnel(wing: Node2D, prefix: String, a: Rect2, b: Rect2) -> void:
	tunnels += 1
	var to_right := b.get_center().x > a.get_center().x
	var start_x := a.end.x - 45 if to_right else a.position.x + 45
	var goal_x := b.position.x + 45 if to_right else b.end.x - 45
	var entry := _floor_at(wing, a.end.y, start_x)
	_check(entry != null, "Missing tunnel entry " + prefix)
	if entry == null:
		return
	await _stand_on(entry, start_x)
	var reached := false
	for frame in range(900):
		_steer(goal_x)
		await physics_frame
		if player.is_on_floor() and absf(player.position.x - goal_x) < 5:
			reached = true
			break
		if player.position.y > maxf(a.end.y, b.end.y) + 80:
			break
	_check(reached, "%s/%s tunnel is not walkable toward %s; stopped at %s" % [wing.region, prefix, goal_x, player.position])
	_release()
	player.set_physics_process(false)


func _descend(wing: Node2D, prefix: String, upper: Rect2, lower: Rect2) -> void:
	descents += 1
	var shaft_x := (maxf(upper.position.x, lower.position.x) + minf(upper.end.x, lower.end.x)) * 0.5
	var entry := _floor_at(wing, upper.end.y, shaft_x)
	_check(entry != null, "Missing descent entry " + prefix)
	if entry == null:
		return
	await _stand_on(entry, shaft_x)
	var half: Vector2 = player.player_collision.shape.size * 0.5
	var destination := _floor_at(wing, lower.end.y, shaft_x)
	_check(destination != null, "Missing descent destination " + prefix)
	if destination == null:
		return
	var landing := _bounds(destination)
	var landing_x := clampf(shaft_x, landing.position.x + half.x + 8, landing.end.x - half.x - 8)
	var exit_x := shaft_x
	var departure_y := upper.end.y
	var reached := false
	for frame in range(1500):
		# The lower gallery can itself contain another shaft mouth. Aim for
		# its actual floor before the final drop, not straight through that hole.
		var near_bottom := player.position.y + half.y >= lower.end.y - 250
		var air_target := landing_x if near_bottom else shaft_x
		if player.is_on_floor():
			var feet := player.position.y + half.y
			if absf(feet - (lower.end.y - 9)) < 3 and player.position.x >= lower.position.x and player.position.x <= lower.end.x:
				reached = true
				break
			for hit in range(player.get_slide_collision_count()):
				var collision := player.get_slide_collision(hit)
				if collision.get_normal().y > -0.5:
					continue
				var floor_body := collision.get_collider() as StaticBody2D
				if floor_body == null:
					continue
				var rect := _bounds(floor_body)
				var right := air_target > rect.get_center().x
				if lower.end.y - rect.position.y < 100:
					# On the last ledge, choose the lip above solid ground.
					# The point nearest the shaft may be behind the wrong lip.
					var left_exit := rect.position.x - half.x - 4
					var right_exit := rect.end.x + half.x + 4
					var safe_left := landing.position.x + half.x + 8
					var safe_right := landing.end.x - half.x - 8
					var left_gap := absf(left_exit - clampf(left_exit, safe_left, safe_right))
					var right_gap := absf(right_exit - clampf(right_exit, safe_left, safe_right))
					if not is_equal_approx(left_gap, right_gap):
						right = right_gap < left_gap
					landing_x = clampf(right_exit if right else left_exit, safe_left, safe_right)
					air_target = landing_x
				exit_x = rect.end.x + half.x + 4 if right else rect.position.x - half.x - 4
				departure_y = rect.position.y
		# Clear the lip before steering back toward the shaft, otherwise the
		# same one-way platform catches the player again on the very next tick.
		_steer(exit_x if player.position.y + half.y <= departure_y + 16 else air_target)
		await physics_frame
		if player.position.y > lower.end.y + 90:
			break
	_check(reached, "%s/%s descent stalled or missed the lower room at %s" % [wing.region, prefix, player.position])
	_release()
	player.set_physics_process(false)
