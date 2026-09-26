extends "res://tests/starfall_population_support_smoke.gd"

const SCENES := ["ShaftHollow", "DrownedCrossing", "FloodedGallery", "BlackwaterCistern", "WardenApproach", "EchoGrotto", "EchoGallery", "PrismArchive", "TideWell", "EchoNest", "CrystalCauseway", "UndertowVault", "BrokenCauseway", "CinderForge", "EmberBarracks", "SlagReservoir", "AshChapel", "CinderHearthOutskirts"]
const PUZZLE_SCRIPTS := ["res://SluiceValve.gd", "res://ShaftRelay.gd", "res://CisternDial.gd", "res://DawnEcho.gd", "res://TownResident.gd"]


func _supported(actor: Node2D, room: Node2D) -> bool:
	for floor_node in room.find_children("*", "StaticBody2D", true, false):
		if floor_node.is_in_group("breakable"):
			continue
		for collision in floor_node.get_children():
			if not collision is CollisionShape2D or collision.disabled or not collision.shape is RectangleShape2D:
				continue
			var size: Vector2 = collision.shape.size
			if size.x < 35 or size.y > 40:
				continue
			var relative: Vector2 = collision.to_local(actor.global_position)
			if absf(relative.x) <= size.x * 0.5 - 10 and relative.y < -size.y * 0.5 and relative.y >= -125:
				return true
	return false


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_biome_support_save.json"
	state.start_new_game("normal")
	for scene_name in SCENES:
		var room := load("res://%s.tscn" % scene_name).instantiate() as Node2D
		room.process_mode = Node.PROCESS_MODE_DISABLED
		root.add_child(room)
		await process_frame
		for expansion_name in ["ExpandedRoute", "LongTraversal", "AshSwitchback"]:
			var expansion := room.get_node_or_null(expansion_name)
			if expansion == null:
				continue
			var points: Array = expansion.get_replay_spawn_points()
			points.append(expansion.get_replay_cache_position())
			for point in points:
				var probe := Node2D.new()
				room.add_child(probe)
				probe.position = point
				_check(point.is_finite() and _supported(probe, room), "Unsupported replay point: %s at %s" % [scene_name, point])
				probe.free()
		for node in room.find_children("*", "Node2D", true, false):
			var script: Script = node.get_script()
			# Echo's wisps deliberately hover above gaps. Shaft wisps use supported
			# corridor anchors too, so their original obsolete locations are checked.
			if script != null and script.resource_path == "res://ShaftWisp.gd" and room.has_node("LongTraversal"):
				continue
			var targeted: bool = node is Marker2D or node.is_in_group("enemy") or node.is_in_group("neutral_creature") or node.is_in_group("breakable") or (script != null and (FIXED_SCRIPTS.has(script.resource_path) or PUZZLE_SCRIPTS.has(script.resource_path)))
			if not targeted:
				continue
			audited += 1
			_check(_supported(node, room), "Unsupported placement: %s/%s at %s" % [scene_name, room.get_path_to(node), node.position])
		room.queue_free()
		await process_frame
	state.delete_save()
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("BIOME POPULATION SUPPORT TEST PASSED: ", audited, " placements")
		quit(0)
	else:
		print("BIOME POPULATION SUPPORT TEST FAILED: ", failures.size(), " / ", audited)
		quit(1)
