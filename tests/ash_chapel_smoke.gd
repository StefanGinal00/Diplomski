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
	state.save_path = "res://_tmp_ash_chapel_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var reservoir = game.get_node("SlagReservoir")
	var chapel = game.get_node("AshChapel")
	var ui = game.get_node("UI")
	var entry_door = reservoir.get_node("ChapelDoor")
	_check(not entry_door._requirements_met(), "Chapel opened before the Crucible Core")
	_check(not chapel.get_node("ChapelCache").open(player), "Chapel reliquary opened before the bell trial")
	_check(reservoir.get_node("ChapelSpur/CollisionShape2D").one_way_collision, "Chapel spur blocks ascent")
	_check(reservoir.get_node("ChapelSpur").position.y < reservoir.get_node("Step3").position.y - 55.0, "Chapel door is not on its own upper spur")
	_check(reservoir.get_node("ChapelReturn").position.distance_to(entry_door.position) > 45.0, "Chapel return would bounce through the door")
	state.add_item("crucible_core")
	_check(entry_door._requirements_met(), "Crucible Core did not unlock Chapel")
	state.set_current_room("ash_reservoir")
	player.global_position = reservoir.get_node("ChapelReturn").global_position
	await entry_door.activate(player)
	_check(state.current_room_id == "ash_chapel" and bool(state.discovered_rooms.get("ash_chapel", false)), "Chapel entry or discovery failed")
	_check(player.global_position.distance_to(chapel.get_node("ChapelEntry").global_position) < 45.0, "Chapel entry marker is wrong")
	_check(game.get_node("AmbientSoundscape").current_track == "ash_chapel", "Chapel ambience did not start")
	_check("0/3" in ui.objective_label.text, "Chapel HUD did not show bell progress")
	for index in range(1, 7):
		var step = chapel.get_node("Step%d" % index)
		_check(step.get_node("CollisionShape2D").one_way_collision, "Chapel step %d blocks ascent" % index)
		if index == 2 or index == 3 or index == 5 or index == 6:
			var previous = chapel.get_node("Step%d" % (index - 1))
			_check(absf(step.position.x - previous.position.x) <= 125.0 and absf(step.position.y - previous.position.y) <= 60.0, "Chapel step %d is too far apart" % index)
	_check(chapel.get_node("Floor").position.y - chapel.get_node("Step1").position.y <= 85.0, "Chapel high route requires Dash")
	var high = chapel.get_node("HighBell")
	var low = chapel.get_node("LowBell")
	var far = chapel.get_node("FarBell")
	_check(not far.activate(player) and chapel.puzzle_progress == 0, "Wrong first bell did not reset")
	_check(high.activate(player) and chapel.puzzle_progress == 1 and "1/3" in ui.objective_label.text, "High bell did not advance sequence or HUD")
	_check(not far.activate(player) and chapel.puzzle_progress == 0, "Wrong second bell did not reset")
	_check(high.activate(player) and low.activate(player) and far.activate(player), "High-low-far sequence could not be completed")
	_check(chapel.is_complete and bool(state.unlocked_shortcuts.get("ash_chapel_bells", false)), "Chapel completion was not recorded")
	_check(chapel.get_node("LowVent").disabled and chapel.get_node("FarVent").disabled, "Chapel bells did not silence its vents")
	_check(not high.activate(player) and not low.activate(player) and not far.activate(player), "Completed bells activated twice")
	var cache = chapel.get_node("ChapelCache")
	var gold_before: int = state.gold
	_check(cache.open(player) and state.opened_caches.has("ash_chapel_reliquary") and state.gold >= gold_before + 48, "Chapel reliquary did not reward gold and material")
	_check(not cache.open(player), "Chapel reliquary paid twice")
	_check("RELIQUARY CLAIMED" in ui.objective_label.text, "Chapel objective did not update after the cache")
	ui._update_route_summary()
	_check("ASHEN BASTION  2/10" in ui.map_route_label.text and "CACHES 1/15" in ui.map_route_label.text, "World map did not count Chapel")
	player.global_position = chapel.get_node("ChapelLamp/RespawnPoint").global_position
	_check(chapel.get_node("ChapelLamp")._save_progress(player), "Chapel lamp did not save")
	_check(state.get_discovered_lamps().has("ash_chapel_lamp"), "Chapel lamp did not join fast travel")
	state.unlocked_shortcuts.erase("ash_chapel_bells")
	state.opened_caches.erase("ash_chapel_reliquary")
	_check(state.load_game(), "Chapel save could not reload")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	chapel = game.get_node("AshChapel")
	reservoir = game.get_node("SlagReservoir")
	player = game.get_node("Player")
	_check(chapel.is_complete and chapel.get_node("ChapelCache").opened and chapel.get_node("LowVent").disabled, "Saved Chapel state did not restore")
	await chapel.get_node("ReservoirReturnDoor").activate(player)
	_check(state.current_room_id == "ash_reservoir" and player.global_position.distance_to(reservoir.get_node("ChapelReturn").global_position) < 45.0, "Chapel could not return to Reservoir")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("ASH CHAPEL TEST PASSED")
		quit(0)
	else:
		print("ASH CHAPEL TEST FAILED: ", failures)
		quit(1)
