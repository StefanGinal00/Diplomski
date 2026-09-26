extends "res://tests/biome_population_support_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_expedition_support_save.json"
	state.start_new_game("normal")
	for region in ["shaft", "echo", "ash", "starfall"]:
		var wing := load("res://ExpeditionWing.tscn").instantiate() as Node2D
		wing.region = region
		wing.process_mode = Node.PROCESS_MODE_DISABLED
		root.add_child(wing)
		await process_frame
		var patrols := wing.find_children("Patrol*", "Node2D", false, false)
		for i in range(patrols.size()):
			for j in range(i + 1, patrols.size()):
				_check(patrols[i].position.distance_to(patrols[j].position) >= 70, "Stacked expedition patrols: %s/%s and %s" % [region, patrols[i].name, patrols[j].name])
		for guard in wing.find_children("BranchGuard*", "Node2D", false, false):
			if guard.get_script().resource_path in ["res://EchoShade.gd", "res://RootStalker.gd"]:
				_check(is_equal_approx(float(guard.get("anchor_x")), guard.global_position.x), "Expedition guard patrol origin differs from its spawn")
		for node in wing.find_children("*", "Node2D", true, false):
			var script: Script = node.get_script()
			if script != null and script.resource_path == "res://ShaftWisp.gd":
				continue
			if not (node is Marker2D or node.is_in_group("enemy") or node.is_in_group("neutral_creature") or node.is_in_group("breakable") or (script != null and FIXED_SCRIPTS.has(script.resource_path))):
				continue
			audited += 1
			_check(_supported(node, wing), "Unsupported expedition placement: %s/%s at %s" % [region, wing.get_path_to(node), node.position])
		wing.queue_free()
		await process_frame
	state.delete_save()
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("EXPEDITION POPULATION SUPPORT TEST PASSED: ", audited)
		quit(0)
	else:
		print("EXPEDITION POPULATION SUPPORT TEST FAILED: ", failures.size(), " / ", audited)
		quit(1)
