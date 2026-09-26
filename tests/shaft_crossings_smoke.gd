extends "res://tests/remaining_jump_routes_smoke.gd"

# Focused basic-jump regression for crossing BOTH rims of a shaft mouth.
# Like the existing jump tests, each hop starts on its real takeoff ledge.
# This does not claim continuous room traversal, combat or human pacing.
const CROSSING_ROOMS := ["ShaftHollow", "DrownedCrossing", "FloodedGallery", "BlackwaterCistern", "WardenApproach", "StarfallOutskirts", "StarfallSilentGate", "StarfallMemoryVault", "StarfallRootedHall", "StarfallSoulCrucible", "StarfallSunlessPassage"]
var mouths := 0


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_shaft_crossings_save.json"
	state.start_new_game("normal")
	var template := load("res://Game.tscn").instantiate() as Node
	player = template.get_node("Player")
	template.remove_child(player)
	template.free()
	root.add_child(player)
	player.double_jump_unlocked = false
	player.dash_unlocked = false
	player.set_physics_process(false)
	for scene_name in CROSSING_ROOMS:
		var room := load("res://%s.tscn" % scene_name).instantiate() as Node2D
		room.process_mode = Node.PROCESS_MODE_DISABLED
		root.add_child(room)
		await process_frame
		for actor in room.find_children("*", "CollisionObject2D", true, false):
			actor.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if actor is Area2D or actor.is_in_group("enemy") or actor.is_in_group("neutral_creature") or actor.is_in_group("breakable"):
				actor.collision_layer = 0
				actor.collision_mask = 0
		var route := room.get_node("ExpandedRoute")
		var holder: Node2D = route.generated
		var prior_mouths := mouths
		for tier in range(route.plan["levels"].size()):
			var floors: Array[StaticBody2D] = []
			for child in holder.get_children():
				if child is StaticBody2D and String(child.name).begins_with("Chamber%d_Floor" % tier):
					floors.append(child)
			floors.sort_custom(func(a: StaticBody2D, b: StaticBody2D) -> bool: return a.position.x < b.position.x)
			for index in range(floors.size() - 1):
				if _bounds(floors[index + 1]).position.x - _bounds(floors[index]).end.x <= 65:
					continue
				mouths += 1
				var path: Array[StaticBody2D] = [floors[index]]
				for child in holder.get_children():
					if child is StaticBody2D and String(child.name).begins_with("ShaftCrossing%d_%d_" % [tier, index]):
						path.append(child)
				_check(path.size() > 1, "%s tier %d has an unbridged shaft mouth" % [scene_name, tier])
				path.append(floors[index + 1])
				for direction in range(2):
					for leg in range(path.size() - 1):
						await _hop(path[leg], path[leg + 1], scene_name + "/rim%d" % tier)
					path.reverse()
		_check(mouths > prior_mouths, "No crossing coverage for " + scene_name)
		room.queue_free()
		await process_frame
	_release()
	player.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("SHAFT CROSSINGS TEST PASSED: ", mouths, " mouths, ", jumps, " basic-jump hops in ", CROSSING_ROOMS.size(), " rooms")
		quit(0)
	else:
		print("SHAFT CROSSINGS TEST FAILED: ", failures.size())
		quit(1)
