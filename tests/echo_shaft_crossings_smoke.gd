extends "res://tests/basic_jump_routes_smoke.gd"

# Terrain-only, isolated real-controller hops across BOTH shaft rims.
# No combat/balance or continuous-room acceptance is implied by this suite.
const ECHO_ROOMS := ["EchoGrotto", "EchoGallery", "PrismArchive", "TideWell", "EchoNest", "CrystalCauseway", "UndertowVault"]


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_shaft_crossings_save.json"
	state.start_new_game("normal")
	var template := load("res://Game.tscn").instantiate() as Node
	player = template.get_node("Player")
	template.remove_child(player)
	template.free()
	root.add_child(player)
	player.double_jump_unlocked = false
	player.dash_unlocked = false
	player.set_physics_process(false)
	var crossings := 0
	var shafts := 0
	var approaches := 0
	for scene_name in ECHO_ROOMS:
		var room := load("res://%s.tscn" % scene_name).instantiate() as Node2D
		room.process_mode = Node.PROCESS_MODE_DISABLED
		root.add_child(room)
		await process_frame
		for actor in room.find_children("*", "CollisionObject2D", true, false):
			actor.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if actor is Area2D or actor.is_in_group("enemy") or actor.is_in_group("neutral_creature") or actor.is_in_group("breakable"):
				actor.collision_layer = 0
				actor.collision_mask = 0
		var route := room.get_node("LongTraversal")
		if scene_name == "PrismArchive":
			var crate := route.get_node("AlcoveCrate06") as StaticBody2D
			var takeoff := route.get_node("Chamber06Floor0") as StaticBody2D
			_check(_bounds(crate).end.x + 24 < _bounds(takeoff).end.x - 16, "Archive optional crate blocks the mandatory shaft takeoff overhead")
		var room_shafts := 0
		for bridge in route.get_children():
			if not bridge is StaticBody2D or not String(bridge.name).ends_with("Rise01"):
				continue
			var span := _bounds(bridge)
			var link := int(String(bridge.name).substr(4, 2))
			var upper_tier := link - 1 if route._chamber_rect(link - 1).end.y < route._chamber_rect(link).end.y else link
			var lower_tier := link if upper_tier == link - 1 else link - 1
			var bottom: StaticBody2D = bridge
			for step in route.get_children():
				if step is StaticBody2D and String(step.name).begins_with("Tier%02dRise" % link) and step.position.y > bottom.position.y:
					bottom = step
			var bottom_rect := _bounds(bottom)
			var entry: StaticBody2D
			var entry_gap := INF
			for floor_body in route.get_children():
				if not floor_body is StaticBody2D or not String(floor_body.name).begins_with("Chamber%02dFloor" % lower_tier):
					continue
				var floor_rect := _bounds(floor_body)
				var gap := maxf(bottom_rect.position.x, floor_rect.position.x) - minf(bottom_rect.end.x, floor_rect.end.x)
				if gap < entry_gap:
					entry_gap = gap
					entry = floor_body
			approaches += 1
			_check(entry != null and entry_gap <= 70, "%s/%s bottom approach unreachable: %.1f px" % [scene_name, bottom.name, entry_gap])
			if entry != null and entry_gap <= 70:
				await _hop(entry, bottom, scene_name + "/shaft-entry")
			var rims := 0
			room_shafts += 1
			for side in [-1.0, 1.0]:
				var rim: StaticBody2D
				var nearest := INF
				for candidate in route.get_children():
					if not candidate is StaticBody2D or not String(candidate.name).begins_with("Chamber%02dFloor" % upper_tier):
						continue
					var floor_rect := _bounds(candidate)
					var rise := span.position.y - floor_rect.position.y
					if rise < 0 or rise > 80 or (floor_rect.get_center().x - span.get_center().x) * side <= 0:
						continue
					var gap := maxf(span.position.x, floor_rect.position.x) - minf(span.end.x, floor_rect.end.x)
					if gap < nearest:
						rim = candidate
						nearest = gap
				# Some edge shafts genuinely have no corridor on the outer side.
				if rim == null or nearest > 300:
					continue
				crossings += 1
				rims += 1
				_check(nearest <= 70, "%s/%s has an unreachable opposite rim: %.1f px" % [scene_name, bridge.name, nearest])
				if nearest <= 70:
					await _hop(bridge, rim, scene_name + "/across-shaft")
			_check(rims > 0, scene_name + "/" + str(bridge.name) + " has no tested rim")
		_check(room_shafts == int(route.profile["tiers"]) - 1, scene_name + ": missing shaft coverage")
		shafts += room_shafts
		room.queue_free()
		await process_frame
	_check(shafts == 60 and approaches == shafts and crossings > shafts, "Echo shaft coverage unexpectedly shrank")
	print("ECHO CROSSING COVERAGE: ", shafts, " shafts, ", crossings, " rims, ", approaches, " bottom approaches, ", jumps, " hops")
	_release()
	player.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("ECHO SHAFT CROSSINGS TEST PASSED: ", crossings, " rims + ", approaches, " bottom approaches / ", jumps, " real-controller hops across seven rooms")
		quit(0)
	else:
		print("ECHO SHAFT CROSSINGS TEST FAILED: ", failures.size())
		quit(1)
