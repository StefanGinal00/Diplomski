extends "res://tests/shaft_hollow_smoke.gd"

# Let the actual crawler AI patrol its authored high niche for six seconds,
# without a nearby player. A floor-support check at spawn cannot detect this.
const ROOMS := ["ShaftHollow", "DrownedCrossing", "FloodedGallery", "BlackwaterCistern", "WardenApproach"]


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_shaft_guard_patrol_save.json"
	state.start_new_game("normal")
	var probe := Node2D.new()
	probe.add_to_group("player")
	root.add_child(probe)
	var checked := 0
	for tier in [0, 1]:
		state.set_zone_tier("sunken_shaft", tier)
		for scene_name in ROOMS:
			var room := load("res://%s.tscn" % scene_name).instantiate() as Node2D
			room.process_mode = Node.PROCESS_MODE_DISABLED
			root.add_child(room)
			await process_frame
			for actor in room.find_children("*", "CollisionObject2D", true, false):
				actor.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			var route := room.get_node("ExpandedRoute/AuthoredDescent")
			var encounter := route.get_node("HiddenDepthAmbush")
			encounter._on_body_entered(probe)
			await process_frame
			_check(encounter.spawned_enemies.size() == 2, scene_name + ": guardians missing")
			var crawler: CharacterBody2D = encounter.spawned_enemies[0]
			crawler.process_mode = Node.PROCESS_MODE_ALWAYS
			var floor_y: float = route.get_node("Niche4_Crest").global_position.y
			var leftmost := crawler.global_position.x
			var rightmost := leftmost
			for frame in range(360):
				await physics_frame
				leftmost = minf(leftmost, crawler.global_position.x)
				rightmost = maxf(rightmost, crawler.global_position.x)
				if crawler.global_position.y > floor_y + 45:
					break
			_check(rightmost - leftmost > 20.0, scene_name + ": ledge protection froze the patrol")
			_check(crawler.global_position.y < floor_y + 45, "%s tier %d: living guardian fell out of its reward niche at %s" % [scene_name, tier, crawler.global_position])
			_check(not encounter.completed, "A fall incorrectly completed the encounter")
			checked += 1
			room.queue_free()
			await process_frame
	probe.queue_free()
	state.delete_save()
	await process_frame
	if failures.is_empty():
		print("SHAFT GUARD PATROL TEST PASSED: ", checked, " live patrols in authored niches")
		quit(0)
	else:
		print("SHAFT GUARD PATROL TEST FAILED: ", failures.size())
		quit(1)
