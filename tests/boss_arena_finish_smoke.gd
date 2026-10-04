extends "res://tests/boss_combat_presentation_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_boss_arena_finish.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var original := {}
	for named in ["VerticalChamber", "ResonanceSanctum", "AshArena", "CastellanThrone", "StarfallEmptyCourt", "StarfallHollowThrone"]:
		for door in game.get_node(named).get_children():
			if door.is_in_group("room_door"):
				original[door] = [door.transform, door.get_node("CollisionShape2D").shape, door.get_node("CollisionShape2D").shape.size, door.get_node("Frame").polygon.duplicate(), door.target_marker_group, door.target_room_id]
	await process_frame
	await process_frame
	_check(original.size() >= 12, "Too few authored arena doors audited")
	for door in original:
		var old: Array = original[door]
		_check(door.has_meta("arena_material_finished") and door.get_node("Frame").texture != null and door.get_node("Core").texture != null, str(door.get_path()) + ": unfinished materials")
		_check(door.transform == old[0] and door.get_node("CollisionShape2D").shape == old[1] and door.get_node("CollisionShape2D").shape.size == old[2] and door.get_node("Frame").polygon == old[3], "Door geometry changed")
		_check(door.target_marker_group == old[4] and door.target_room_id == old[5], "Door route changed")
		var before: int = door.get_child_count()
		var relic: Node = door.get_parent().get_node("ArenaRelics")
		relic._finish_doors(door.get_parent())
		_check(door.get_child_count() == before, "Repeated finish creates nodes")
	var scenery := game.get_node("TrainingPassageDecor/GeneratedPassageDetails")
	for name in ["CaveTooth5", "SentinelPillar945", "SentinelRune1210", "SentinelDais"]:
		_check(not scenery.get_node(name).visible, "Sentinel prototype decoration still covers art: " + name)
	_check(scenery.get_node("GateArch").texture != null, "Untextured Sentinel arch")
	_check(game.get_node("VerticalChamber/WardenArt").art_bounds.size.y == 395, "Warden upper background gap")
	for name in ["TorchLeft", "TorchRight"]:
		_check(not game.get_node("AshArena/" + name).visible, "Prototype torch overlays painted coliseum")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty(): print("BOSS ARENA FINISH TEST PASSED: ", original.size(), " doors, unchanged routes/collisions, Sentinel retirement, Warden coverage, Marshal decor")
	quit(0 if failures.is_empty() else 1)
