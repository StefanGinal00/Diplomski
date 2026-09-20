extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_ashen_rollback_save.json"
	state.start_new_game("normal")
	state.mark_boss_defeated("echo_matriarch")
	state.add_item("matriarch_seal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var causeway = game.get_node("BrokenCauseway")
	var forge = game.get_node("CinderForge")
	var barracks = game.get_node("EmberBarracks")
	state.set_current_room("ash_causeway")
	var lamp_position: Vector2 = causeway.get_node("CausewayLamp/RespawnPoint").global_position
	player.global_position = lamp_position
	_check(causeway.get_node("CausewayLamp")._save_progress(player), "Pre-fan Ashen checkpoint could not save")
	_check(causeway.get_node("UpperCache").open(player), "Unsaved Causeway cache could not open")
	_check(forge.get_node("CoolingFan").activate(player), "Unsaved cooling fan could not start")
	_check(forge.get_node("ForgeCache").open(player), "Unsaved Forge cache could not open")
	state.set_current_room("ash_barracks")
	_check(barracks.start_trial(player), "Unsaved Barracks trial could not start")
	for enemy in barracks.get_node("WaveEnemies").get_children():
		if enemy.is_in_group("enemy"):
			enemy.take_damage(999)
	await process_frame
	await process_frame
	for enemy in barracks.get_node("WaveEnemies").get_children():
		if enemy.is_in_group("enemy") and not enemy.is_queued_for_deletion():
			enemy.take_damage(999)
	await process_frame
	await process_frame
	_check(barracks.completed and state.has_item("barracks_insignia"), "Unsaved Barracks trial did not complete")
	_check(barracks.get_node("BarracksCache").open(player), "Unsaved Barracks cache could not open")
	var arena = game.get_node("AshArena")
	state.set_current_room("ash_arena")
	_check(arena.start_trial(player), "Unsaved Arena could not start")
	for wave_index in range(4):
		for enemy in arena.get_node("Combatants").get_children():
			if enemy.is_in_group("enemy") and not enemy.is_queued_for_deletion():
				enemy.take_damage(999)
		await create_timer(1.75).timeout
	_check(arena.completed and state.has_item("marshal_emblem"), "Unsaved Arena did not complete")
	_check(arena.get_node("ArenaCache").open(player), "Unsaved Arena cache could not open")
	var reservoir = game.get_node("SlagReservoir")
	state.set_current_room("ash_reservoir")
	_check(reservoir.get_node("LowerValve").activate(player) and reservoir.get_node("UpperValve").activate(player), "Unsaved Reservoir valves did not open")
	_check(reservoir.get_node("CoreCache").open(player) and state.has_item("crucible_core"), "Unsaved Crucible Core could not be claimed")
	_check(causeway.get_node("FirstVent").disabled and forge.get_node("ForgeVent").disabled, "Unsaved fan did not change vents")
	_check(state.load_game(), "Normal-mode Ashen checkpoint did not load")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	causeway = game.get_node("BrokenCauseway")
	forge = game.get_node("CinderForge")
	barracks = game.get_node("EmberBarracks")
	arena = game.get_node("AshArena")
	reservoir = game.get_node("SlagReservoir")
	_check(state.current_room_id == "ash_causeway" and game.get_node("ResonanceSanctum/AshenGate")._requirements_met(), "Rollback lost the saved Ashen entry")
	_check(not forge.get_node("CoolingFan").is_active and not bool(state.unlocked_shortcuts.get("ash_forge_fan", false)), "Unsaved cooling fan survived rollback")
	_check(not causeway.get_node("FirstVent").disabled and not causeway.get_node("SecondVent").disabled and not forge.get_node("ForgeVent").disabled, "Unsaved vent shutdown survived rollback")
	_check(not causeway.get_node("UpperCache").opened and not forge.get_node("ForgeCache").opened, "Unsaved Ashen caches survived rollback")
	_check(not barracks.completed and not state.has_item("barracks_insignia") and not bool(state.unlocked_shortcuts.get("ash_barracks_cleared", false)), "Unsaved Barracks reward survived rollback")
	_check(not barracks.get_node("BarracksCache").opened and not barracks.get_node("BarracksVent").disabled, "Unsaved Barracks cache or vent survived rollback")
	_check(not barracks.get_node("CausewayLoopDoor")._requirements_met() and not causeway.get_node("BarracksLoopDoor")._requirements_met(), "Unsaved Barracks loop survived rollback")
	_check(not arena.completed and not state.has_item("marshal_emblem") and not bool(state.unlocked_shortcuts.get("ash_arena_cleared", false)), "Unsaved Arena victory survived rollback")
	_check(not arena.get_node("ArenaCache").opened and not bool(state.discovered_rooms.get("ash_arena", false)), "Unsaved Arena cache or discovery survived rollback")
	_check(not reservoir.get_node("LowerValve").is_active and not reservoir.get_node("UpperValve").is_active and not state.has_item("crucible_core"), "Unsaved Reservoir valves or core survived rollback")
	_check(not reservoir.get_node("CoreCache").opened and not reservoir.get_node("ForgeLoopDoor")._requirements_met() and not forge.get_node("ReservoirLoopDoor")._requirements_met(), "Unsaved Reservoir cache or Forge loop survived rollback")
	_check(causeway.get_node("CausewayLamp").is_active, "Saved Causeway lamp was lost on rollback")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("ASHEN ROLLBACK TEST PASSED")
		quit(0)
	else:
		print("ASHEN ROLLBACK TEST FAILED: ", failures)
		quit(1)
