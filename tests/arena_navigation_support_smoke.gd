extends "res://tests/biome_population_support_smoke.gd"

const ARENAS := ["VerticalChamber", "ResonanceSanctum", "AshArena", "CastellanThrone", "StarfallEmptyCourt", "StarfallHollowThrone"]


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_arena_navigation_save.json"
	state.start_new_game("normal")
	for scene_name in ARENAS:
		var room := load("res://%s.tscn" % scene_name).instantiate() as Node2D
		room.process_mode = Node.PROCESS_MODE_DISABLED
		root.add_child(room)
		await process_frame
		for node in room.find_children("*", "Node2D", true, false):
			var script: Script = node.get_script()
			var fixed: bool = script != null and FIXED_SCRIPTS.has(script.resource_path)
			var arrival: bool = node is Marker2D and (node.get_parent() == room or String(node.name) == "RespawnPoint")
			if not fixed and not arrival:
				continue
			audited += 1
			_check(_supported(node, room), "Unsupported arena interaction/arrival: %s/%s at %s" % [scene_name, room.get_path_to(node), node.position])
		room.queue_free()
		await process_frame
	state.delete_save()
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("ARENA NAVIGATION SUPPORT TEST PASSED: ", audited)
		quit(0)
	else:
		print("ARENA NAVIGATION SUPPORT TEST FAILED: ", failures.size(), " / ", audited)
		quit(1)
