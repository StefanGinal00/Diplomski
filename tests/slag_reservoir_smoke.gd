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
	state.save_path = "res://_tmp_slag_reservoir_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var arena = game.get_node("AshArena")
	var reservoir = game.get_node("SlagReservoir")
	var forge = game.get_node("CinderForge")
	var ui = game.get_node("UI")
	var entry_door = arena.get_node("ReservoirDoor")
	var forge_loop = reservoir.get_node("ForgeLoopDoor")
	var forge_return = forge.get_node("ReservoirLoopDoor")
	var lower = reservoir.get_node("LowerValve")
	var upper = reservoir.get_node("UpperValve")
	var cache = reservoir.get_node("CoreCache")
	_check(not entry_door._requirements_met(), "Reservoir opened before Arena victory")
	_check(not forge_loop._requirements_met() and not forge_return._requirements_met(), "Forge loop opened before coolant valves")
	_check(not cache.open(player), "Crucible Core cache opened before coolant valves")
	state.unlock_shortcut("ash_arena_cleared")
	_check(entry_door._requirements_met(), "Arena victory did not open Reservoir")
	state.set_current_room("ash_arena")
	player.global_position = arena.get_node("ReservoirReturn").global_position
	entry_door._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "ash_reservoir" and bool(state.discovered_rooms.get("ash_reservoir", false)), "Reservoir entry failed")
	_check(player.global_position.distance_to(reservoir.get_node("ReservoirEntry").global_position) < 45.0, "Reservoir entry marker is wrong")
	_check(game.get_node("AmbientSoundscape").current_track == "ash_reservoir", "Reservoir ambience did not start")
	_check("OPEN COOLANT VALVES  0/2" in ui.objective_label.text, "Reservoir objective does not show valve count")
	for index in range(1, 6):
		var step = reservoir.get_node("Step%d" % index)
		_check(step.get_node("CollisionShape2D").one_way_collision, "Reservoir step %d blocks ascent" % index)
		if index > 1:
			var previous = reservoir.get_node("Step%d" % (index - 1))
			_check(absf(step.position.x - previous.position.x) <= 130.0 and absf(step.position.y - previous.position.y) <= 60.0, "Reservoir step %d is too far apart" % index)
	_check(reservoir.get_node("Floor").position.y - reservoir.get_node("Step1").position.y <= 85.0, "Reservoir upper route requires Dash")
	_check(not reservoir.get_node("LowerVent").disabled and not reservoir.get_node("UpperVent").disabled, "Reservoir vents began disabled")
	_check(lower.activate(player), "Lower coolant valve did not activate")
	_check(reservoir.get_node("LowerVent").disabled and not reservoir.get_node("UpperVent").disabled, "Lower valve quieted wrong vents")
	_check(not cache.open(player) and not forge_loop._requirements_met(), "One coolant valve opened full reward or loop")
	_check("OPEN COOLANT VALVES  1/2" in ui.objective_label.text, "Valve progress did not reach HUD")
	_check(upper.activate(player), "Upper coolant valve did not activate")
	_check(reservoir.get_node("UpperVent").disabled and forge_loop._requirements_met() and forge_return._requirements_met(), "Two valves did not quiet vents and open loop")
	_check(not lower.activate(player) and not upper.activate(player), "Coolant valves paid or activated twice")
	_check("CLAIM THE HIGH CORE" in ui.objective_label.text, "Reservoir objective did not point to core")
	var gold_before: int = state.gold
	_check(cache.open(player) and state.has_item("crucible_core") and state.gold >= gold_before + 45, "Crucible Core cache did not reward item and gold")
	_check(not cache.open(player), "Crucible Core cache paid twice")
	_check("CRUCIBLE CORE SECURED" in ui.objective_label.text, "Core acquisition did not update HUD")
	ui._update_route_summary()
	_check("COOLANT 2/2" in ui.map_route_label.text and "CACHES 1/5" in ui.map_route_label.text, "World map did not track Reservoir progress")
	player.global_position = reservoir.get_node("ReservoirLamp/RespawnPoint").global_position
	_check(reservoir.get_node("ReservoirLamp")._save_progress(player), "Reservoir lamp did not save progress")
	_check(state.get_discovered_lamps().has("slag_reservoir_lamp"), "Reservoir lamp did not enter travel network")
	state.unlocked_shortcuts.erase("ash_reservoir_lower")
	state.unlocked_shortcuts.erase("ash_reservoir_upper")
	state.opened_caches.erase("ash_reservoir_core")
	state.inventory.erase("crucible_core")
	_check(state.load_game(), "Reservoir save could not reload")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	reservoir = game.get_node("SlagReservoir")
	forge = game.get_node("CinderForge")
	player = game.get_node("Player")
	_check(state.has_item("crucible_core") and reservoir.get_node("CoreCache").opened, "Saved Crucible Core did not restore")
	_check(reservoir.get_node("LowerValve").is_active and reservoir.get_node("UpperValve").is_active and reservoir.get_node("LowerVent").disabled and reservoir.get_node("UpperVent").disabled, "Saved coolant state did not restore")
	_check(reservoir.get_node("ForgeLoopDoor")._requirements_met() and forge.get_node("ReservoirLoopDoor")._requirements_met(), "Saved Forge loop closed")
	reservoir.get_node("ForgeLoopDoor")._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "ash_forge" and player.global_position.distance_to(forge.get_node("ReservoirReturn").global_position) < 45.0, "Reservoir-to-Forge loop failed")
	forge.get_node("ReservoirLoopDoor")._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "ash_reservoir" and player.global_position.distance_to(reservoir.get_node("ForgeLoopEntry").global_position) < 45.0, "Forge-to-Reservoir loop failed")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("SLAG RESERVOIR TEST PASSED")
		quit(0)
	else:
		print("SLAG RESERVOIR TEST FAILED: ", failures)
		quit(1)
