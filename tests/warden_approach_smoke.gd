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
	state.save_path = "res://_tmp_warden_approach_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var gallery = game.get_node("FloodedGallery")
	var approach = game.get_node("WardenApproach")
	var shaft = game.get_node("VerticalChamber")
	var ui = game.get_node("UI")
	var bridge = approach.get_node("Bridge")
	var crank = approach.get_node("CounterweightCrank")
	var gallery_door = gallery.get_node("WardenShortcutDoor")
	var shaft_door = shaft.get_node("GalleryShortcutDoor")
	_check(not gallery_door._requirements_met() and not shaft_door._requirements_met(), "Approach route opened before Gallery controls")
	_check(not bridge.is_active and bridge.get_node("CollisionShape2D").disabled, "Counterweight bridge started solid")
	for index in range(1, 8):
		var step = approach.get_node("UpperStep%d" % index)
		_check(step.get_node("CollisionShape2D").one_way_collision, "Approach upper step %d blocks climbing" % index)
		if index > 1:
			var previous = approach.get_node("UpperStep%d" % (index - 1))
			_check(absf(step.position.x - previous.position.x) <= 130.0 and absf(step.position.y - previous.position.y) <= 60.0, "Approach upper step %d is too far from previous step" % index)
	_check(approach.get_node("PitFloor").position.y - approach.get_node("RecoveryLeft").position.y <= 70.0, "Approach pit has no reachable recovery ledge")
	_check(approach.get_node("NearSpikes").damage == 1 and approach.get_node("FarSpikes").damage == 1, "Approach pit hazards are missing")
	state.set_current_room("sunken_shaft")
	var shaft_lamp_position: Vector2 = shaft.get_node("UpperCheckpoint/RespawnPoint").global_position
	player.global_position = shaft_lamp_position
	_check(shaft.get_node("UpperCheckpoint")._save_progress(player), "Shaft lamp did not register before Approach visit")
	state.unlock_shortcut("shaft_gallery_lower")
	_check(not gallery_door._requirements_met(), "One Gallery control opened Approach")
	state.unlock_shortcut("shaft_gallery_upper")
	_check(gallery_door._requirements_met() and shaft_door._requirements_met(), "Gallery controls did not open both Approach entrances")
	state.set_current_room("shaft_gallery")
	gallery_door._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "shaft_approach" and bool(state.discovered_rooms.get("shaft_approach", false)), "Gallery did not discover Warden Approach")
	_check(player.global_position.distance_to(approach.get_node("GalleryEntry").global_position) < 45.0, "Approach Gallery entry marker is wrong")
	_check(game.get_node("AmbientSoundscape").current_track == "shaft_approach", "Approach ambience did not start")
	_check("CLIMB THE GANTRY" in ui.objective_label.text, "Approach objective did not point to upper route")
	var supply = approach.get_node("UpperCache")
	var gold_before: int = state.gold
	_check(supply.open(player) and state.gold >= gold_before + 34 and state.has_item("iron_fragment"), "Approach upper cache did not reward exploration")
	_check(not supply.open(player), "Approach upper cache paid twice")
	_check(crank.activate(player), "Far counterweight could not be lowered")
	await process_frame
	_check(bridge.is_active and not bridge.get_node("CollisionShape2D").disabled, "Counterweight did not create a solid return bridge")
	_check("BRIDGE LOWERED" in ui.objective_label.text and not crank.activate(player), "Bridge objective or one-time activation is wrong")
	approach.get_node("ArenaDoor")._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "sunken_shaft" and player.global_position.distance_to(shaft.get_node("GalleryReturn").global_position) < 45.0, "Approach did not reach Warden arena")
	shaft_door._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "shaft_approach" and player.global_position.distance_to(approach.get_node("ShaftEntry").global_position) < 45.0, "Warden arena could not return to Approach")
	state.set_zone_tier("sunken_shaft", 1)
	_check(approach.has_node("Cache_approach_afterglow"), "Awakened Approach cache is missing")
	approach.get_node("GalleryReturnDoor")._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "shaft_gallery", "Approach could not return to Gallery")
	gallery_door._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "shaft_approach" and approach.has_node("approach_echo_wisp"), "Awakened Approach encounter did not appear on return")
	_check(approach.get_node("Cache_approach_afterglow").open(player), "Awakened Approach cache did not open")
	_check(game.get_node("QuestManager")._get_return_cache_count("sunken_shaft") == 1, "Approach cache did not count for Shaft Vigil")
	var approach_lamp_position: Vector2 = approach.get_node("ApproachLamp/RespawnPoint").global_position
	player.global_position = approach_lamp_position
	_check(approach.get_node("ApproachLamp")._save_progress(player), "Approach lamp did not save progress")
	_check(state.get_discovered_lamps().size() == 2, "Approach lamp did not join fast-travel network")
	state.unlocked_shortcuts.erase("shaft_approach_bridge")
	state.opened_caches.erase("approach_supply")
	state.opened_caches.erase("approach_afterglow")
	state.discovered_rooms.erase("shaft_approach")
	_check(state.load_game(), "Approach progress did not reload")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	approach = game.get_node("WardenApproach")
	ui = game.get_node("UI")
	_check(approach.get_node("Bridge").is_active and not approach.get_node("Bridge/CollisionShape2D").disabled, "Saved bridge did not restore its collision")
	_check(approach.get_node("CounterweightCrank").is_active and approach.get_node("UpperCache").opened and approach.get_node("Cache_approach_afterglow").opened, "Saved Approach crank or caches reset")
	_check(approach.get_node("ApproachLamp").is_active, "Saved Approach lamp went dark")
	ui._update_route_summary()
	_check("3/6 PLAYABLE ROOMS" in ui.map_route_label.text and "CACHES 2/11" in ui.map_route_label.text, "Map did not track Approach room and caches")
	_check(ui.get_node("WorldMapPanel/RouteScroll").get_global_rect().intersection(ui.map_travel_button.get_global_rect()).get_area() <= 0.0, "World-map route viewport overlaps travel button")
	ui._open_world_map(true, approach.get_node("ApproachLamp"))
	ui.selected_lamp_id = "sunken_shaft_lamp"
	ui._update_map_details()
	_check(not ui.map_travel_button.disabled, "Shaft lamp is not reachable from Approach")
	ui._on_map_travel_pressed()
	await create_timer(0.5).timeout
	_check(state.current_room_id == "sunken_shaft" and state.checkpoint_lamp_id == "sunken_shaft_lamp", "Approach-to-Shaft fast travel failed")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("WARDEN APPROACH TEST PASSED")
		quit(0)
	else:
		print("WARDEN APPROACH TEST FAILED: ", failures)
		quit(1)
