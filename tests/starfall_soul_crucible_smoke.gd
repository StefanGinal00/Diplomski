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
	state.save_path = "res://_tmp_starfall_crucible_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	var player: Player = game.get_node("Player")
	var court: Node2D = game.get_node("StarfallEmptyCourt")
	var crucible: Node2D = game.get_node("StarfallSoulCrucible")
	var boss = court.get_node("Guardian")
	var ui = game.get_node("UI")
	var ambience = game.get_node("AmbientSoundscape")
	_check(court.get_node("CrucibleDoor").position.y < court.get_node("Guardian").position.y - 90.0, "Crucible entrance is not on a distinct upper spur")
	_check(crucible.get_node("HighChannel").position.y < crucible.get_node("LowChannel").position.y - 150.0, "Crucible channels do not use both routes")
	_check(crucible.get_node("UpperWalk").position.y < crucible.get_node("Floor").position.y - 150.0, "Crucible upper bypass is missing")
	_check(crucible.get_node("Floor").position.y - crucible.get_node("LowReturnStep").position.y <= 80.0 and crucible.get_node("LowReturnStep").position.y - crucible.get_node("ReturnStep").position.y <= 80.0 and crucible.get_node("ReturnStep").position.y - crucible.get_node("EntryLedge").position.y <= 80.0, "Return to Crucible entry requires a double jump")
	_check(crucible.get_node("Floor").position.y - crucible.get_node("LowHighStep").position.y <= 80.0 and crucible.get_node("LowHighStep").position.y - crucible.get_node("HighStep").position.y <= 80.0, "Upper channel climb requires a double jump")
	state.set_current_room("starfall_soul_crucible")
	_check(crucible.get_node("BoundShade").is_in_group("family_spirit") and crucible.get_node("CrucibleSentry").is_in_group("family_construct"), "Crucible enemy families are missing")
	var crucible_final: Rect2 = crucible.get_node("ExpandedRoute")._chamber_rect(6)
	_check(crucible.has_node("SunlessDoor") and crucible_final.grow(40.0).has_point(crucible.get_node("SunlessDoor").position + Vector2(0.0, 33.0)) and crucible.get_node("SunlessDoor").position.y > crucible.get_node("LowChannel").position.y + 250.0, "Sunless Passage door does not end the Crucible route")
	state.set_current_room("starfall_empty_court")
	player.global_position = court.get_node("CrucibleDoor").global_position
	await physics_frame
	_check(not boss.active, "Upper spur accidentally started the Guardian fight")
	await court.get_node("CrucibleDoor").activate(player)
	_check(state.current_room_id == "starfall_soul_crucible" and player.global_position.distance_to(crucible.get_node("Entry").global_position) < 45.0, "Upper door did not enter Soul Crucible")
	_check(not boss.active and ui.zone_title_label.text == "SOUL CRUCIBLE" and "CHANNELS 0/2" in ui.objective_label.text, "Crucible announcement or objective is missing")
	_check(ambience.current_track == "starfall_soul_crucible", "Crucible ambience did not start")
	var lamp = crucible.get_node("CrucibleLamp")
	player.global_position = lamp.get_node("RespawnPoint").global_position
	_check(lamp._save_progress(player), "Crucible lamp could not save the unsolved circuit")
	_check(state.get_discovered_lamps().has("starfall_crucible_lamp"), "Crucible lamp is not in the travel network")
	var cache = crucible.get_node("StabilizedCache")
	_check(not cache.open(player), "Crucible cache opened before channels were attuned")
	var pulse = crucible.get_node("NearPulse")
	_check(not pulse.disabled and not crucible.get_node("MiddlePulse").disabled and not crucible.get_node("FarPulse").disabled, "Soul Pulses were quiet before stabilization")
	pulse.phase = "idle"
	pulse._advance_phase()
	_check(pulse.phase == "warning" and pulse.warning_line.default_color.a > 0.8 and not pulse.monitoring, "Soul Pulse lacks a safe warning phase")
	_check(crucible.get_node("HighChannel").activate(player), "Upper channel could not be attuned")
	_check(not bool(state.unlocked_shortcuts.get("starfall_crucible_stabilized", false)) and not pulse.disabled, "One channel incorrectly stabilized the circuit")
	_check(crucible.get_node("LowChannel").activate(player), "Lower channel could not be attuned")
	_check(bool(state.unlocked_shortcuts.get("starfall_crucible_stabilized", false)) and pulse.disabled and crucible.get_node("MiddlePulse").disabled and crucible.get_node("FarPulse").disabled, "Both channels did not quiet all Soul Pulses")
	_check("PULSES QUIET" in crucible.get_node("CircuitStatus").text and "PULSES QUIET" in ui.objective_label.text, "Circuit feedback did not update")
	var gold_before_cache: int = state.gold
	_check(cache.open(player) and not cache.open(player) and state.gold == gold_before_cache + 65, "Stabilized cache did not award exactly once")
	await crucible.get_node("CourtReturnDoor").activate(player)
	_check(state.current_room_id == "starfall_empty_court" and player.global_position.distance_to(court.get_node("CrucibleReturn").global_position) < 45.0 and not boss.active, "Crucible return triggered the Guardian or missed the Court upper ledge")
	await court.get_node("CrucibleDoor").activate(player)
	_check(state.current_room_id == "starfall_soul_crucible", "Crucible path is not reversible")
	_check(state.load_game(), "Pre-circuit lamp could not load")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	player = game.get_node("Player")
	crucible = game.get_node("StarfallSoulCrucible")
	cache = crucible.get_node("StabilizedCache")
	_check(not bool(state.unlocked_shortcuts.get("starfall_crucible_high", false)) and not bool(state.unlocked_shortcuts.get("starfall_crucible_low", false)) and not crucible.get_node("NearPulse").disabled and not cache.opened, "Unsaved channels or reward survived lamp rollback")
	_check(crucible.get_node("LowChannel").activate(player) and crucible.get_node("HighChannel").activate(player), "Channels could not be reactivated after rollback")
	_check(cache.open(player), "Cache could not be opened after rollback")
	lamp = crucible.get_node("CrucibleLamp")
	player.global_position = lamp.get_node("RespawnPoint").global_position
	_check(lamp._save_progress(player), "Crucible lamp could not save solved circuit")
	_check(state.load_game(), "Saved Crucible progress could not reload")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	crucible = game.get_node("StarfallSoulCrucible")
	_check(bool(state.unlocked_shortcuts.get("starfall_crucible_stabilized", false)) and crucible.get_node("NearPulse").disabled and crucible.get_node("StabilizedCache").opened, "Saved circuit or cache did not persist")
	game.get_node("UI")._update_route_summary()
	_check("SOUL CRUCIBLE  DISCOVERED  -  CHANNELS 2/2  -  CACHE 1/1" in game.get_node("UI").map_route_label.text, "Map omitted Crucible progress")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("STARFALL SOUL CRUCIBLE TEST PASSED")
		quit(0)
	else:
		print("STARFALL SOUL CRUCIBLE TEST FAILED: ", failures)
		quit(1)
