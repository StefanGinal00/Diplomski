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
	state.save_path = "res://_tmp_blackwater_cistern_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var crossing = game.get_node("DrownedCrossing")
	var gallery = game.get_node("FloodedGallery")
	var cistern = game.get_node("BlackwaterCistern")
	var ui = game.get_node("UI")
	var near_dial = cistern.get_node("NearDial")
	var high_dial = cistern.get_node("HighDial")
	var far_dial = cistern.get_node("FarDial")
	var surge = cistern.get_node("CisternSurge")
	var supply = cistern.get_node("CisternCache")
	_check(not gallery.get_node("CisternDoor")._requirements_met(), "Gallery-to-Cistern passage opened before pump")
	_check(not cistern.get_node("GalleryShortcutDoor")._requirements_met(), "Cistern-to-Gallery passage opened before pump")
	for step_name in ["StepNear", "StepRise", "StepHigh", "StepDial", "StepCache", "StepFar"]:
		_check(cistern.get_node("%s/CollisionShape2D" % step_name).one_way_collision, "%s prevents climbing" % step_name)
	state.set_current_room("shaft_crossing")
	var crossing_lamp_position: Vector2 = crossing.get_node("CrossingLamp/RespawnPoint").global_position
	player.global_position = crossing_lamp_position
	_check(crossing.get_node("CrossingLamp")._save_progress(player), "Crossing lamp did not save before Cistern exploration")
	crossing.get_node("CisternDoor").activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "shaft_cistern" and bool(state.discovered_rooms.get("shaft_cistern", false)), "Crossing did not discover Blackwater Cistern")
	_check(player.global_position.distance_to(cistern.get_node("CrossingEntry").global_position) < 45.0, "Cistern entrance marker is wrong")
	_check(game.get_node("AmbientSoundscape").current_track == "shaft_cistern", "Cistern ambience did not start")
	_check("DIALS 0/3" in ui.objective_label.text, "Cistern objective did not begin at zero")
	_check(not high_dial.activate(player) and cistern.puzzle_progress == 0, "High dial skipped the near dial")
	_check(near_dial.activate(player) and cistern.puzzle_progress == 1, "Near dial did not start pressure sequence")
	_check(not far_dial.activate(player) and cistern.puzzle_progress == 0, "Wrong dial did not reset the unfinished sequence")
	_check("DIALS 0/3" in ui.objective_label.text, "Objective did not show reset sequence")
	_check(not supply.open(player) and not surge.disabled, "Cistern reward or surge changed before pump activation")
	_check(near_dial.activate(player) and high_dial.activate(player), "Near-to-high dial order failed")
	_check(cistern.puzzle_progress == 2 and "DIALS 2/3" in ui.objective_label.text, "Cistern sequence stopped before far dial")
	_check(far_dial.activate(player), "Far dial did not complete pressure sequence")
	_check(cistern.is_complete and bool(state.unlocked_shortcuts.get("shaft_cistern_pump", false)), "Pump completion was not recorded")
	_check(surge.disabled and cistern.get_node("GalleryShortcutDoor")._requirements_met() and gallery.get_node("CisternDoor")._requirements_met(), "Pump did not calm surge and open both Gallery doors")
	_check("PUMP ACTIVE" in ui.objective_label.text and not near_dial.activate(player), "Completed pressure sequence can be repeated")
	var gold_before: int = state.gold
	_check(supply.open(player) and state.has_item("life_bloom") and state.gold >= gold_before + 38, "Cistern supply did not award the Life Bloom and gold")
	_check(not supply.open(player), "Cistern supply paid twice")
	cistern.get_node("GalleryShortcutDoor").activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "shaft_gallery" and player.global_position.distance_to(gallery.get_node("CisternReturn").global_position) < 45.0, "Cistern passage did not reach Gallery")
	gallery.get_node("CisternDoor").activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "shaft_cistern" and player.global_position.distance_to(cistern.get_node("GalleryEntry").global_position) < 45.0, "Gallery could not return through Cistern")
	state.set_zone_tier("sunken_shaft", 1)
	_check(cistern.has_node("Cache_cistern_echo"), "Awakened Cistern cache is missing")
	cistern.get_node("GalleryShortcutDoor").activate(player)
	await create_timer(0.5).timeout
	gallery.get_node("CisternDoor").activate(player)
	await create_timer(0.5).timeout
	_check(cistern.has_node("cistern_echo_wisp"), "Awakened Cistern encounter did not appear on return")
	_check(cistern.get_node("Cache_cistern_echo").open(player), "Awakened Cistern cache did not open")
	_check(game.get_node("QuestManager")._get_return_cache_count("sunken_shaft") == 1, "Awakened Cistern cache did not count for Shaft Vigil")
	var cistern_lamp_position: Vector2 = cistern.get_node("CisternLamp/RespawnPoint").global_position
	player.global_position = cistern_lamp_position
	_check(cistern.get_node("CisternLamp")._save_progress(player), "Cistern lamp did not save progress")
	_check(state.get_discovered_lamps().size() == 2, "Cistern lamp did not join fast travel")
	state.unlocked_shortcuts.erase("shaft_cistern_pump")
	state.opened_caches.erase("cistern_supply")
	state.opened_caches.erase("cistern_echo")
	state.discovered_rooms.erase("shaft_cistern")
	_check(state.load_game(), "Cistern progress did not reload")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	cistern = game.get_node("BlackwaterCistern")
	gallery = game.get_node("FloodedGallery")
	ui = game.get_node("UI")
	_check(cistern.is_complete and cistern.puzzle_progress == 3 and cistern.get_node("CisternSurge").disabled, "Saved pump did not restore")
	_check(cistern.get_node("GalleryShortcutDoor")._requirements_met() and gallery.get_node("CisternDoor")._requirements_met(), "Saved Gallery loop closed")
	_check(cistern.get_node("CisternCache").opened and cistern.get_node("Cache_cistern_echo").opened, "Saved Cistern caches reopened")
	_check(cistern.get_node("CisternLamp").is_active, "Saved Cistern lamp went dark")
	ui._update_route_summary()
	_check("3/7 PLAYABLE ROOMS" in ui.map_route_label.text and "CACHES 2/14" in ui.map_route_label.text, "World map did not track Cistern room and caches")
	_check(ui.get_node("WorldMapPanel/RouteScroll").get_global_rect().intersection(ui.map_travel_button.get_global_rect()).get_area() <= 0.0, "World-map route viewport overlaps travel button")
	ui._open_world_map(true, cistern.get_node("CisternLamp"))
	ui.selected_lamp_id = "drowned_crossing_lamp"
	ui._update_map_details()
	_check(not ui.map_travel_button.disabled, "Crossing lamp cannot be reached from Cistern")
	ui._on_map_travel_pressed()
	await create_timer(0.5).timeout
	_check(state.current_room_id == "shaft_crossing" and state.checkpoint_lamp_id == "drowned_crossing_lamp", "Cistern-to-Crossing fast travel failed")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("BLACKWATER CISTERN TEST PASSED")
		quit(0)
	else:
		print("BLACKWATER CISTERN TEST FAILED: ", failures)
		quit(1)
