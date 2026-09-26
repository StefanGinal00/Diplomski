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
	state.save_path = "res://_tmp_drowned_crossing_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var shaft = game.get_node("VerticalChamber")
	var crossing = game.get_node("DrownedCrossing")
	var hollow = game.get_node("ShaftHollow")
	var player: Player = game.get_node("Player")
	var surge = crossing.get_node("SluiceSurge")
	var valve = crossing.get_node("Valve")
	var supply = crossing.get_node("CrossingCache")
	_check(not valve.is_active and not surge.disabled, "Crossing valve or surge started in the wrong state")
	_check(not crossing.get_node("HollowDoor")._requirements_met(), "Hollow loop opened before its relay")
	state.set_current_room("sunken_shaft")
	shaft.get_node("CrossingDoor").activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "shaft_crossing" and bool(state.discovered_rooms.get("shaft_crossing", false)), "Lower Shaft did not discover Drowned Crossing")
	_check(player.global_position.distance_to(crossing.get_node("ShaftEntry").global_position) < 45.0, "Crossing Shaft entry marker is wrong")
	_check(game.get_node("AmbientSoundscape").current_track == "shaft_crossing", "Crossing ambience did not start")
	_check("DRAIN THE VALVE" in game.get_node("UI").objective_label.text, "Crossing objective is missing")
	surge._advance_phase()
	_check(surge.phase == "warning" and not surge.monitoring, "Surge warning is not telegraphed safely")
	surge._advance_phase()
	await physics_frame
	_check(surge.phase == "active" and surge.monitoring, "Surge never entered its damaging phase")
	var gold_before: int = state.gold
	_check(supply.open(player), "First-visit Crossing supply cache did not open")
	_check(state.gold >= gold_before + 30 and state.has_item("iron_fragment"), "Crossing supply reward is missing")
	_check(not supply.open(player), "Crossing supply cache can be opened twice")
	_check(valve.activate(player), "Crossing valve did not activate")
	await physics_frame
	_check(valve.is_active and surge.disabled and not surge.monitoring, "Valve did not disable the surge")
	_check(not valve.activate(player), "Crossing valve activated twice")
	_check("CURRENTS CALMED" in game.get_node("UI").objective_label.text and "SAFE" not in game.get_node("UI").objective_label.text, "Drained Crossing objective is missing or falsely promises safety")
	state.unlock_shortcut("shaft_hollow_relay")
	_check(crossing.get_node("HollowDoor")._requirements_met() and hollow.get_node("CrossingDoor")._requirements_met(), "Relay did not unlock both Crossing-Hollow doors")
	crossing.get_node("HollowDoor").activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "shaft_hollow" and player.global_position.distance_to(hollow.get_node("CrossingEntry").global_position) < 45.0, "Crossing to Hollow transition failed")
	hollow.get_node("CrossingDoor").activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "shaft_crossing" and player.global_position.distance_to(crossing.get_node("HollowEntry").global_position) < 45.0, "Hollow to Crossing transition failed")
	state.set_zone_tier("sunken_shaft", 1)
	_check(crossing.has_node("Cache_crossing_dregs"), "Awakened Crossing cache did not appear")
	crossing.get_node("HollowDoor").activate(player)
	await create_timer(0.5).timeout
	hollow.get_node("CrossingDoor").activate(player)
	await create_timer(0.5).timeout
	_check(crossing.has_node("Cache_crossing_dregs") and crossing.has_node("crossing_echo_wisp"), "Awakened Crossing cache or encounter is missing")
	var awakened_cache = crossing.get_node("Cache_crossing_dregs")
	_check(awakened_cache.open(player), "Awakened Crossing cache did not open")
	_check(game.get_node("QuestManager")._get_return_cache_count("sunken_shaft") == 1, "Awakened Crossing cache did not count for Shaft Vigil")
	var lamp_position: Vector2 = crossing.get_node("CrossingLamp/RespawnPoint").global_position
	player.global_position = lamp_position
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), lamp_position, "drowned_crossing_lamp", "Drowned Crossing Lamp", "shaft_crossing"), "Crossing progress did not save")
	state.unlocked_shortcuts.clear()
	state.opened_caches.clear()
	state.discovered_rooms.erase("shaft_crossing")
	_check(state.load_game(), "Crossing progress did not load")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	crossing = game.get_node("DrownedCrossing")
	_check(bool(state.unlocked_shortcuts.get("shaft_sluice_valve", false)) and bool(state.discovered_rooms.get("shaft_crossing", false)), "Saved Crossing valve or room discovery was lost")
	_check(crossing.get_node("Valve").is_active and crossing.get_node("SluiceSurge").disabled, "Saved valve did not restore the drained surge")
	_check(crossing.get_node("CrossingCache").opened and crossing.get_node("Cache_crossing_dregs").opened, "Saved Crossing caches reopened")
	game.get_node("UI")._update_route_summary()
	_check("3/7 PLAYABLE ROOMS" in game.get_node("UI").map_route_label.text and "CACHES 2/14" in game.get_node("UI").map_route_label.text, "Map did not track Crossing progress")
	_check(game.get_node("UI/WorldMapPanel/RouteScroll").get_global_rect().intersection(game.get_node("UI").map_travel_button.get_global_rect()).get_area() <= 0.0, "World-map route viewport overlaps travel button")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("DROWNED CROSSING TEST PASSED")
		quit(0)
	else:
		print("DROWNED CROSSING TEST FAILED: ", failures)
		quit(1)
