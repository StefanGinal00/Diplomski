extends "res://tests/starfall_spawn_restore_smoke.gd"

const BIOME_CASES := [
	["shaft_hollow", "ShaftHollow", "HollowWispNear", "anchor_position"],
	["shaft_hollow", "ShaftHollow", "HollowSentry", ""],
	["shaft_cistern", "BlackwaterCistern", "ChannelCrawler", "start_x"],
	["shaft_approach", "WardenApproach", "PitSentry", ""],
	["echo_gallery", "EchoGallery", "LongTraversal/WhisperShade_01_00", "anchor_x"],
	["echo_causeway", "CrystalCauseway", "LongTraversal/ShardShade_03_01", "anchor_x"],
	["ash_causeway", "BrokenCauseway", "CinderShelfFiend", ""],
	["ash_forge", "CinderForge", "SmelterFiend", ""],
	["ash_barracks", "EmberBarracks", "GallerySentry", ""],
	["ash_reservoir", "SlagReservoir", "UpperSentry", ""],
	["ash_chapel", "AshChapel", "ChancelFiend", ""],
	["ash_hearth_outskirts", "CinderHearthOutskirts", "GateWatchSentry", ""],
]


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_biome_spawn_restore_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	game.get_node("Player").set_physics_process(false)
	var population := game.get_node("WorldPopulation")
	for entry in BIOME_CASES:
		state.set_current_room(entry[0])
		var room := game.get_node(entry[1])
		_freeze(room)
		var enemy := room.get_node(entry[2]) as Node2D
		var anchor: Variant = null
		if entry[3] != "":
			anchor = enemy.get(entry[3])
			var correct: bool = anchor.is_equal_approx(enemy.global_position) if anchor is Vector2 else is_equal_approx(float(anchor), enemy.global_position.x)
			_check(correct, "%s patrol retained obsolete spawn origin" % entry[2])
		enemy.position.x -= 21
		enemy.set("current_health", int(enemy.get("max_health")) - 1)
		var stored := enemy.position
		var health := int(enemy.get("current_health"))
		state.set_current_room("training_passage")
		state.set_current_room(entry[0])
		_freeze(room)
		_check(enemy.position.is_equal_approx(stored), "%s teleported on quick return" % entry[2])
		state.set_current_room("training_passage")
		population.unload_room_population(entry[1])
		await process_frame
		_check(not room.has_node(entry[2]), "%s failed to unload" % entry[2])
		state.set_current_room(entry[0])
		_freeze(room)
		enemy = room.get_node(entry[2]) as Node2D
		_check(enemy.position.is_equal_approx(stored) and int(enemy.get("current_health")) == health, "%s lost restored movement or health" % entry[2])
		if entry[3] != "":
			_check(enemy.get(entry[3]) == anchor, "%s changed patrol origin on reload" % entry[2])
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("BIOME SPAWN RESTORE TEST PASSED: ", BIOME_CASES.size(), " actors")
		quit(0)
	else:
		print("BIOME SPAWN RESTORE TEST FAILED: ", failures)
		quit(1)
