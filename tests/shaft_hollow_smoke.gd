extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _wait_for_transition(player: Player) -> void:
	var transition := root.get_node("RoomTransition")
	var deadline := Time.get_ticks_msec() + 5000
	while transition.is_transitioning and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(not transition.is_transitioning, "Room transition timed out")
	# This test checks arrival contracts, not walking/falling after arrival.
	player.set_physics_process(false)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_shaft_hollow_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var shaft = game.get_node("VerticalChamber")
	var hollow = game.get_node("ShaftHollow")
	var player: Player = game.get_node("Player")
	var relay = hollow.get_node("Relay")
	var lower_door = hollow.get_node("LowerReturnDoor")
	var reverse_door = shaft.get_node("HollowLowerDoor")
	shaft.get_node("HollowUpperDoor").activate(player)
	await _wait_for_transition(player)
	_check(state.current_room_id == "shaft_hollow" and bool(state.discovered_rooms.get("shaft_hollow", false)), "Upper Shaft door did not discover Wisp Hollow")
	_check(not lower_door._requirements_met() and not reverse_door._requirements_met(), "Lower Hollow loop opened before its relay")
	_check(not relay.activate(player) and not bool(state.unlocked_shortcuts.get("shaft_hollow_relay", false)), "Relay ignored living guardian wisps")
	_check(player.global_position.distance_to(hollow.get_node("UpperEntry").global_position) < 45.0, "Upper Hollow entry marker is wrong")
	_check(game.get_node("AmbientSoundscape").current_track == "shaft_hollow", "Wisp Hollow ambience did not start")
	_check("CLEAR HOLLOW WISPS" in game.get_node("UI").objective_label.text, "Wisp Hollow objective is missing")
	for guardian_name in ["HollowWispNear", "HollowWispFar"]:
		var guardian = hollow.get_node(guardian_name)
		guardian.take_damage(guardian.max_health)
	_check(relay._remaining_guardians() == 0, "Hollow guardian defeats were not recognized")
	_check(relay.activate(player), "Relay did not activate after guardians were cleared")
	_check(lower_door._requirements_met() and reverse_door._requirements_met(), "Relay did not open both lower doors")
	_check("RELAY ACTIVE" in game.get_node("UI").objective_label.text, "Relay completion was not shown in objective")
	lower_door.activate(player)
	await _wait_for_transition(player)
	_check(state.current_room_id == "sunken_shaft", "Hollow lower door did not reach Sunken Shaft")
	_check(player.global_position.distance_to(shaft.get_node("HollowLowerReturn").global_position) < 45.0, "Lower Shaft return marker is wrong")
	state.set_zone_tier("sunken_shaft", 1)
	_check(not hollow.has_node("hollow_echo_wisp"), "Awakened Hollow patrol spawned while its room was inactive")
	reverse_door.activate(player)
	await _wait_for_transition(player)
	_check(hollow.has_node("Cache_hollow_resonance") and hollow.has_node("hollow_echo_wisp"), "Awakened Hollow cache or encounter missing after room entry")
	_check(state.current_room_id == "shaft_hollow" and player.global_position.distance_to(hollow.get_node("LowerEntry").global_position) < 45.0, "Lower door cannot return to Hollow")
	_check("AWAKENED" in game.get_node("UI").zone_subtitle_label.text, "Awakened warning is absent in Hollow")
	var cache = hollow.get_node("Cache_hollow_resonance")
	var gold_before: int = state.gold
	_check(cache.open(player), "Awakened Hollow cache could not be opened")
	_check(state.gold >= gold_before + 32 and state.has_item("iron_fragment"), "Hollow cache payout is missing")
	_check(game.get_node("QuestManager")._get_return_cache_count("sunken_shaft") == 1, "Hollow cache did not count toward Shaft Vigil")
	_check(not cache.open(player), "Hollow cache can be farmed repeatedly")
	state.set_current_room("sunken_shaft")
	var lamp_position: Vector2 = shaft.get_node("UpperCheckpoint/RespawnPoint").global_position
	player.global_position = lamp_position
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), lamp_position, "sunken_shaft_lamp", "Sunken Shaft Lamp", "sunken_shaft"), "Hollow progress did not save")
	state.unlocked_shortcuts.clear()
	state.opened_caches.clear()
	state.discovered_rooms.erase("shaft_hollow")
	_check(state.load_game(), "Hollow progress did not load")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	hollow = game.get_node("ShaftHollow")
	_check(bool(state.unlocked_shortcuts.get("shaft_hollow_relay", false)) and bool(state.discovered_rooms.get("shaft_hollow", false)), "Hollow relay or discovery did not survive load")
	_check(hollow.get_node("Relay").is_active and hollow.get_node("LowerReturnDoor")._requirements_met(), "Saved Hollow relay did not restore visuals or door")
	_check(hollow.get_node("Cache_hollow_resonance").opened, "Saved Hollow cache reopened")
	game.get_node("UI")._update_route_summary()
	_check("2/7 PLAYABLE ROOMS" in game.get_node("UI").map_route_label.text and "CACHES 1/14" in game.get_node("UI").map_route_label.text, "Map did not track Hollow room and cache")
	_check(game.get_node("UI/WorldMapPanel/RouteScroll").get_global_rect().intersection(game.get_node("UI").map_travel_button.get_global_rect()).get_area() <= 0.0, "World-map route viewport overlaps travel button")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("SHAFT HOLLOW TEST PASSED")
		quit(0)
	else:
		print("SHAFT HOLLOW TEST FAILED: ", failures)
		quit(1)
