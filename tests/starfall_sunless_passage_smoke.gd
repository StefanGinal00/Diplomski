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
	state.save_path = "res://_tmp_starfall_sunless_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	var player: Player = game.get_node("Player")
	var crucible: Node2D = game.get_node("StarfallSoulCrucible")
	var passage: Node2D = game.get_node("StarfallSunlessPassage")
	var ui = game.get_node("UI")
	var ambience = game.get_node("AmbientSoundscape")
	var crucible_final: Rect2 = crucible.get_node("ExpandedRoute")._chamber_rect(6)
	_check(crucible_final.grow(40.0).has_point(crucible.get_node("SunlessDoor").position + Vector2(0.0, 33.0)) and crucible.get_node("SunlessDoor").position.y > crucible.get_node("LowChannel").position.y + 250.0, "Sunless entrance is not beyond the lower Crucible route")
	_check(passage.get_node("RecoveryFloor").position.y > passage.get_node("LeftFloor").position.y + 80.0, "Sunless chasm lacks a lower recovery floor")
	_check(passage.get_node("RecoveryFloor").position.y - passage.get_node("LeftRecoveryStep").position.y <= 80.0 and passage.get_node("LeftRecoveryStep").position.y - passage.get_node("LeftFloor").position.y <= 80.0, "Left recovery requires double jump")
	_check(passage.get_node("RecoveryFloor").position.y - passage.get_node("RightRecoveryStep").position.y <= 80.0 and passage.get_node("RightRecoveryStep").position.y - passage.get_node("RightFloor").position.y <= 80.0, "Right recovery requires double jump")
	state.set_current_room("starfall_sunless_passage")
	_check(passage.get_node("LostShade").is_in_group("family_spirit") and passage.get_node("SunlessSentry").is_in_group("family_construct"), "Sunless Passage enemy families are missing")
	_check(passage.has_node("HollowThroneDoor") and not passage.get_node("HollowThroneDoor")._requirements_met(), "Hollow Throne opened without three bosses and sigils")
	state.set_current_room("starfall_soul_crucible")
	await crucible.get_node("SunlessDoor").activate(player)
	_check(state.current_room_id == "starfall_sunless_passage" and player.global_position.distance_to(passage.get_node("Entry").global_position) < 45.0, "Crucible door did not enter Sunless Passage")
	_check(ui.zone_title_label.text == "SUNLESS PASSAGE" and "BRIDGES FADING" in ui.objective_label.text, "Sunless Passage title or objective is missing")
	_check(ambience.current_track == "starfall_sunless_passage", "Sunless Passage ambience did not start")
	var lamp = passage.get_node("SunlessLamp")
	player.global_position = lamp.get_node("RespawnPoint").global_position
	_check(lamp._save_progress(player) and state.get_discovered_lamps().has("starfall_sunless_lamp"), "Sunless lamp did not save or join travel network")
	var bridge = passage.get_node("BridgeOne")
	_check(not bridge.stabilized and bridge.phase == "solid", "Light bridge was stable before the Dawn Anchor")
	bridge._advance_phase()
	_check(bridge.phase == "warning" and bridge.edge.default_color.a > 0.8, "Light bridge lacks a visible warning")
	bridge._advance_phase()
	await physics_frame
	_check(bridge.phase == "ghost" and bridge.collision_shape.disabled, "Light bridge did not become intangible after warning")
	bridge._advance_phase()
	await physics_frame
	_check(bridge.phase == "solid" and not bridge.collision_shape.disabled, "Light bridge did not become solid again")
	var basin_cache = passage.get_node("BasinCache")
	var dawn_cache = passage.get_node("DawnCache")
	_check(not dawn_cache.open(player), "Dawn cache opened before the anchor")
	_check(basin_cache.open(player) and not basin_cache.open(player), "Lower recovery cache did not award exactly once")
	_check(passage.get_node("LowerPulse").phase != "disabled" and not passage.get_node("FarPulse").disabled, "Lower pulses were quiet before the anchor")
	_check(passage.get_node("DawnAnchor").activate(player), "Dawn Anchor could not be lit")
	await physics_frame
	for bridge_name in ["BridgeOne", "BridgeTwo", "BridgeThree", "BridgeFour", "BridgeFive"]:
		var lit_bridge = passage.get_node(bridge_name)
		_check(lit_bridge.stabilized and lit_bridge.phase == "stable" and not lit_bridge.collision_shape.disabled, "%s was not stabilized" % bridge_name)
	_check(passage.get_node("LowerPulse").disabled and passage.get_node("FarPulse").disabled and "BRIDGES STABLE" in ui.objective_label.text, "Dawn Anchor did not quiet the lower path and update HUD")
	_check(dawn_cache.open(player) and not dawn_cache.open(player), "Dawn cache did not unlock exactly once")
	await passage.get_node("CrucibleReturnDoor").activate(player)
	_check(state.current_room_id == "starfall_soul_crucible" and player.global_position.distance_to(crucible.get_node("SunlessReturn").global_position) < 45.0, "Sunless return did not reach Crucible")
	await crucible.get_node("SunlessDoor").activate(player)
	_check(state.current_room_id == "starfall_sunless_passage", "Sunless route is not reversible")
	_check(state.load_game(), "Pre-anchor lamp could not roll back Sunless progress")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	player = game.get_node("Player")
	passage = game.get_node("StarfallSunlessPassage")
	_check(not bool(state.unlocked_shortcuts.get("starfall_sunless_anchor", false)) and not passage.get_node("BridgeOne").stabilized and not passage.get_node("DawnCache").opened and not passage.get_node("BasinCache").opened, "Unsaved Sunless progress survived lamp rollback")
	_check(passage.get_node("DawnAnchor").activate(player), "Dawn Anchor could not be relit after rollback")
	_check(passage.get_node("BasinCache").open(player) and passage.get_node("DawnCache").open(player), "Sunless caches could not be reclaimed after rollback")
	lamp = passage.get_node("SunlessLamp")
	player.global_position = lamp.get_node("RespawnPoint").global_position
	_check(lamp._save_progress(player) and state.load_game(), "Solved Sunless progress could not be saved and reloaded")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	passage = game.get_node("StarfallSunlessPassage")
	_check(bool(state.unlocked_shortcuts.get("starfall_sunless_anchor", false)) and passage.get_node("BridgeOne").stabilized and passage.get_node("DawnCache").opened and passage.get_node("BasinCache").opened, "Saved Dawn Anchor or caches did not persist")
	game.get_node("UI")._update_route_summary()
	_check("SUNLESS PASSAGE  DISCOVERED  -  BRIDGES STABLE  -  CACHES 2/2" in game.get_node("UI").map_route_label.text, "Map omitted Sunless Passage progress")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("STARFALL SUNLESS PASSAGE TEST PASSED")
		quit(0)
	else:
		print("STARFALL SUNLESS PASSAGE TEST FAILED: ", failures)
		quit(1)
