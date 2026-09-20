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
	state.save_path = "res://_tmp_crystal_causeway_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var gallery = game.get_node("EchoGallery")
	var causeway = game.get_node("CrystalCauseway")
	var tide = game.get_node("TideWell")
	var player: Player = game.get_node("Player")
	var near_bridge = causeway.get_node("PhaseBridgeNear")
	var far_bridge = causeway.get_node("PhaseBridgeFar")
	var anchor = causeway.get_node("Anchor")
	var tide_door = causeway.get_node("TideLoopDoor")
	var reverse_door = tide.get_node("CausewayDoor")
	_check(not gallery.get_node("CausewayDoor")._requirements_met(), "Causeway opened before Gallery Prism")
	_check(not tide_door._requirements_met() and not reverse_door._requirements_met(), "Tide loop opened before anchor")
	state.add_item("gallery_prism")
	state.set_current_room("echo_gallery")
	gallery.get_node("CausewayDoor")._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_causeway" and bool(state.discovered_rooms.get("echo_causeway", false)), "Gallery did not discover Crystal Causeway")
	_check(player.global_position.distance_to(causeway.get_node("GalleryEntry").global_position) < 45.0, "Causeway entry marker is wrong")
	_check(game.get_node("AmbientSoundscape").current_track == "echo_causeway", "Causeway ambience did not start")
	_check("STABILIZE ANCHOR" in game.get_node("UI").objective_label.text, "Causeway objective is missing")
	_check(near_bridge.phase == "solid" and far_bridge.phase == "solid" and far_bridge.phase_remaining > near_bridge.phase_remaining, "Phase bridges did not start staggered")
	near_bridge._advance_phase()
	_check(near_bridge.phase == "warning" and not near_bridge.get_node("CollisionShape2D").disabled, "Phase bridge warning removed collision too early")
	near_bridge._advance_phase()
	await physics_frame
	_check(near_bridge.phase == "ghost" and near_bridge.get_node("CollisionShape2D").disabled, "Phase bridge did not become intangible")
	near_bridge._advance_phase()
	await physics_frame
	_check(near_bridge.phase == "solid" and not near_bridge.get_node("CollisionShape2D").disabled, "Phase bridge did not become solid again")
	var supply = causeway.get_node("CausewayCache")
	var gold_before: int = state.gold
	_check(supply.open(player), "Causeway supply cache did not open")
	_check(state.gold >= gold_before + 34 and state.has_item("ether_dust"), "Causeway supply payout is missing")
	_check(not supply.open(player), "Causeway supply paid twice")
	_check(anchor.activate(player), "Crystal anchor did not activate")
	_check(tide_door._requirements_met() and reverse_door._requirements_met(), "Anchor did not open both Tide doors")
	_check("TIDE LOOP OPEN" in game.get_node("UI").objective_label.text, "Anchor objective did not update")
	tide_door._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_tide_well" and player.global_position.distance_to(tide.get_node("CausewayReturn").global_position) < 45.0, "Causeway did not reach the upper Tide Well")
	reverse_door._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_causeway" and player.global_position.distance_to(causeway.get_node("TideEntry").global_position) < 45.0, "Tide Well could not return to Causeway")
	state.set_zone_tier("echo_grotto", 1)
	_check(near_bridge.cycle_speed > 1.0 and causeway.has_node("Cache_causeway_afterglow"), "Awakened Causeway timing or cache is missing")
	tide_door._on_body_entered(player)
	await create_timer(0.5).timeout
	reverse_door._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(causeway.has_node("causeway_echo_wisp"), "Awakened Causeway encounter did not spawn on return")
	var awakened_cache = causeway.get_node("Cache_causeway_afterglow")
	_check(awakened_cache.open(player), "Awakened Causeway cache did not open")
	_check(game.get_node("QuestManager")._get_return_cache_count("echo_grotto") == 1, "Awakened Causeway cache did not count for Resonance Sweep")
	state.set_current_room("echo_tide_well")
	var lamp_position: Vector2 = tide.get_node("TideLamp/RespawnPoint").global_position
	player.global_position = lamp_position
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), lamp_position, "tide_well_lamp", "Tide Well Lamp", "echo_tide_well"), "Causeway progress did not save")
	state.unlocked_shortcuts.clear()
	state.opened_caches.clear()
	state.discovered_rooms.erase("echo_causeway")
	_check(state.load_game(), "Causeway progress did not reload")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	causeway = game.get_node("CrystalCauseway")
	_check(causeway.get_node("Anchor").is_active and causeway.get_node("TideLoopDoor")._requirements_met(), "Saved Causeway anchor did not reopen Tide loop")
	_check(game.get_node("TideWell/CausewayDoor")._requirements_met(), "Saved return door from Tide Well closed")
	_check(causeway.get_node("CausewayCache").opened and causeway.get_node("Cache_causeway_afterglow").opened, "Saved Causeway caches reopened")
	game.get_node("UI")._update_route_summary()
	_check("3/8 PLAYABLE ROOMS" in game.get_node("UI").map_route_label.text and "CACHES 2/10" in game.get_node("UI").map_route_label.text, "Map did not track Causeway progress")
	_check(game.get_node("UI/WorldMapPanel/RouteScroll").get_global_rect().intersection(game.get_node("UI").map_travel_button.get_global_rect()).get_area() <= 0.0, "World-map route viewport overlaps travel button")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("CRYSTAL CAUSEWAY TEST PASSED")
		quit(0)
	else:
		print("CRYSTAL CAUSEWAY TEST FAILED: ", failures)
		quit(1)
