extends "res://tests/expedition_jump_routes_smoke.gd"

# Fixed-60fps controller test. Each route is walked/jumped continuously in
# both directions; only the initial placement of each route is teleported.
var routes_checked := 0
var legs_checked := 0
var street_walks := 0
var walk_floors: Array[Rect2] = []


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_settlement_traversal_save.json"
	state.start_new_game("normal")
	var template := load("res://Game.tscn").instantiate() as Node
	player = template.get_node("Player")
	template.remove_child(player)
	template.free()
	root.add_child(player)
	player.double_jump_unlocked = false
	player.dash_unlocked = false
	player.set_physics_process(false)
	for scene_name in ["EchoHaven", "CinderHearth", "StarfallCitadel"]:
		var room := load("res://%s.tscn" % scene_name).instantiate() as Node2D
		room.process_mode = Node.PROCESS_MODE_DISABLED
		root.add_child(room)
		await process_frame
		walk_floors.clear()
		for actor in room.find_children("*", "CollisionObject2D", true, false):
			actor.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if not actor is StaticBody2D:
				actor.collision_layer = 0
				actor.collision_mask = 0
			elif actor.has_node("CollisionShape2D"):
				var shape := actor.get_node("CollisionShape2D").shape as RectangleShape2D
				if shape != null and shape.size.y <= 22:
					walk_floors.append(_bounds(actor))
		# Flat civic streets must not require a jump over a tiny collider seam.
		var far_x: float = {"EchoHaven": 1640.0, "CinderHearth": 4100.0, "StarfallCitadel": 6100.0}[scene_name]
		await _stand_on(room.get_node("Floor"), 300)
		await _street_walk(far_x, scene_name)
		await _street_walk(300, scene_name + "/return")
		var paths: Array[Array] = []
		match scene_name:
			"StarfallCitadel":
				var upper := room.get_node("UpperCity")
				var specifications := [
					["WestGrandStair", "Floor", "UpperCity/ArtisanTerraceWalk"],
					["GardenGrandStair", "Floor", "UpperCity/HangingGardensWalk"],
					["ArtisanSkyStair", "UpperCity/ArtisanTerraceWalk", "UpperCity/CrossCitySkybridge", "UpperCity/HangingGardensWalk"],
					["ArchiveBellStair", "UpperCity/ArtisanTerraceWalk", "UpperCity/BellSquareWalk"],
					["GardenBellStair", "UpperCity/HangingGardensWalk", "UpperCity/BellSquareWalk"],
					["CrownStair", "UpperCity/BellSquareWalk", "UpperCity/CrownObservatoryWalk"],
				]
				for spec in specifications:
					var path: Array = [room.get_node(spec[1])]
					for body in upper.get_children():
						if body is StaticBody2D and String(body.name).begins_with(spec[0] + "Step"):
							path.append(body)
					for index in range(2, spec.size()):
						path.append(room.get_node(spec[index]))
					paths.append(path)
				for names in [
					["Floor", "GateDistrict/Step1", "GateDistrict/Step2", "GateDistrict/Step3", "GateDistrict/Step4", "WestPromenade", "WestDown1", "WestDown2", "WestDown3", "Floor"],
					["Floor", "MarketStep1", "MarketStep2", "MarketBalcony", "MarketDown1", "MarketDown2", "Floor"],
					["Floor", "GardenStep1", "GardenStep2", "GardenBalcony", "LibraryRooftop/LibraryClimb", "LibraryRooftop/LibraryRoofWalk"],
					["Floor", "GardenDown2", "GardenDown1", "GardenBalcony"],
				]:
					paths.append(_nodes(room, names))
			"CinderHearth":
				paths.append(_nodes(room, ["Floor", "UpperVillage/GateStair", "UpperVillage/HearthStair", "UpperVillage/SmithyWalk", "UpperVillage/MarketWalk", "UpperVillage/EastStair", "UpperVillage/ThroneStair", "Floor"]))
				var district := room.get_node("EasternDistricts")
				for spec in [["WestRise", 6, "Floor", "KilnArcade", false], ["ArcadeDescent", 6, "EastMarketStreet", "KilnArcade", true], ["LibraryRise", 7, "EastMarketStreet", "CopperLibraryWalk", false], ["LibraryDescent", 7, "EastMarketStreet", "CopperLibraryWalk", true], ["WatchAscent", 6, "CopperLibraryWalk", "CinderWatch", false]]:
					var path: Array = [room.get_node("Floor") if spec[2] == "Floor" else district.get_node(spec[2])]
					var steps: Array = []
					for index in range(spec[1]):
						steps.append(district.get_node(spec[0] + str(index)))
					if spec[4]:
						steps.reverse()
					path.append_array(steps)
					path.append(district.get_node(spec[3]))
					paths.append(path)
			"EchoHaven":
				paths.append(_nodes(room, ["Floor", "UpperVillage/WestStair", "UpperVillage/UpperStair", "UpperVillage/WestBalcony", "UpperVillage/EastBalcony", "UpperVillage/EastStair", "UpperVillage/GateStair", "Floor"]))
				var expansion := room.get_node("NewDistricts")
				var path: Array = [room.get_node("Floor"), expansion.get_node("OldQuarterBridge")]
				for tier in range(6):
					if tier > 0:
						for index in range(1, 4):
							path.append(expansion.get_node("Tier%02dStair%02d" % [tier, index]))
					for index in range(5):
						path.append(expansion.get_node("Tier%02dStreet%02d" % [tier, index]))
				paths.append(path)
		for path in paths:
			await _route(path, scene_name)
			var reversed := path.duplicate()
			reversed.reverse()
			await _route(reversed, scene_name + "/return")
		room.queue_free()
		await process_frame
	_check(routes_checked == 36 and legs_checked == 412 and street_walks == 6, "Settlement route coverage changed; review the authored paths before updating expected counts")
	_release()
	player.queue_free()
	await process_frame
	state.delete_save()
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("SETTLEMENT TRAVERSAL TEST PASSED: ", routes_checked, " continuous routes, ", legs_checked, " legs, ", street_walks, " no-jump street walks")
		quit(0)
	else:
		print("SETTLEMENT TRAVERSAL TEST FAILED: ", failures.size(), " / ", routes_checked, " routes")
		quit(1)


func _nodes(room: Node, names: Array) -> Array:
	var result: Array = []
	for node_name in names:
		result.append(room.get_node(node_name))
	return result


func _street_walk(goal_x: float, label: String) -> void:
	street_walks += 1
	var reached := false
	for frame in range(4000):
		_steer(goal_x)
		await physics_frame
		if player.is_on_floor() and absf(player.position.x - goal_x) < 4:
			reached = true
			break
	_check(reached, "%s street is not walkable without jumping; stopped at %s" % [label, player.position])
	_release()


func _route(path: Array, label: String) -> void:
	routes_checked += 1
	await _stand_on(path[0], _bounds(path[1]).get_center().x)
	for index in range(1, path.size()):
		legs_checked += 1
		if not await _travel(path[index], index == path.size() - 1):
			_check(false, "%s route %s: cannot reach %s from %s, stopped at %s" % [label, path[1].name, path[index].name, path[index - 1].name, player.position])
			break
	_release()
	player.set_physics_process(false)


func _standing_body() -> StaticBody2D:
	for index in range(player.get_slide_collision_count()):
		var hit := player.get_slide_collision(index)
		if hit.get_normal().y < -0.5 and hit.get_collider() is StaticBody2D:
			return hit.get_collider()
	# Resting floor-snap contacts need not produce a slide collision.
	var feet := player.global_position + Vector2(0, player.player_collision.shape.size.y * 0.5)
	var ray := PhysicsRayQueryParameters2D.create(feet - Vector2(0, 2), feet + Vector2(0, 4), 1, [player.get_rid()])
	var hit := player.get_world_2d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty() and hit.collider is StaticBody2D:
		return hit.collider
	return null


func _travel(to: StaticBody2D, final: bool) -> bool:
	var dest := _bounds(to)
	var half: Vector2 = player.player_collision.shape.size * 0.5
	var safe_left := dest.position.x + half.x + 5
	var safe_right := dest.end.x - half.x - 5
	var aim := clampf(player.position.x, safe_left, safe_right)
	var departure_y := INF
	var lip := aim
	for frame in range(5000):
		var feet := player.position.y + half.y
		if player.is_on_floor():
			if player.position.x >= safe_left - 4 and player.position.x <= safe_right + 4 and absf(feet - dest.position.y) <= 3:
				return true
			# Crossing stairs can land the player above a narrow intermediate
			# step. Major streets/decks and final destinations stay exact.
			if not final and dest.size.x < 200 and player.position.x >= safe_left - 4 and player.position.x <= safe_right + 4 and feet <= dest.position.y and feet >= dest.position.y - 80:
				return true
			var ground := _standing_body()
			if ground == null:
				await physics_frame
				continue
			var source := _bounds(ground)
			# Collision contacts may report just one of several overlapping
			# street bodies. Their combined walkable span is the actual runway.
			for pass_index in range(3):
				for floor_rect in walk_floors:
					if absf(source.position.y - floor_rect.position.y) <= 4 and floor_rect.end.x >= source.position.x and floor_rect.position.x <= source.end.x:
						var left := minf(source.position.x, floor_rect.position.x)
						var right := maxf(source.end.x, floor_rect.end.x)
						source.position.x = left
						source.size.x = right - left
			aim = clampf(player.position.x, safe_left, safe_right)
			if source.position.y < dest.position.y - 3 and maxf(source.position.x, dest.position.x) < minf(source.end.x, dest.end.x):
				# A crossing deck can cover an intermediate stair. Continue
				# across that real deck instead of trying to stand inside it.
				if not final and source.size.x >= dest.size.x * 3 and dest.position.y - source.position.y <= 80 and source.position.x <= dest.position.x and source.end.x >= dest.end.x:
					if absf(player.position.x - aim) < 4:
						return true
					_steer(aim)
					await physics_frame
					continue
				var left := source.position.x - half.x - 4
				var right := source.end.x + half.x + 4
				var left_gap := absf(left - clampf(left, safe_left, safe_right))
				var right_gap := absf(right - clampf(right, safe_left, safe_right))
				lip = left if left_gap < right_gap else right
				if is_equal_approx(left_gap, right_gap):
					lip = left if absf(left - player.position.x) < absf(right - player.position.x) else right
				aim = clampf(lip, safe_left, safe_right)
				departure_y = source.position.y
				_steer(lip)
			else:
				var takeoff := clampf(aim, source.position.x + half.x + 3, source.end.x - half.x - 3)
				_steer(takeoff)
				if absf(player.position.x - takeoff) < 5:
					player.jump_buffer_remaining = 0.12
					departure_y = INF
		else:
			_steer(lip if feet <= departure_y + 16 and departure_y < INF else aim)
		await physics_frame
		if player.position.y > 800:
			return false
	return false
