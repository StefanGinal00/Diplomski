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
	state.save_path = "res://_tmp_starfall_outskirts_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var city = game.get_node("StarfallCitadel")
	var outskirts = game.get_node("StarfallOutskirts")
	var ui = game.get_node("UI")
	var outer_door = city.get_node("OuterWatchGate")
	_check(outer_door.position.x > city.get_node("ObservatoryDoorway").position.x and city.get_node("OuterWatchReturn").position.x < outer_door.position.x, "City exit is not at the far edge with a safe return marker")
	for enemy in get_nodes_in_group("enemy"):
		_check(not city.is_ancestor_of(enemy), "An enemy spawned inside the safe Citadel")
	state.set_current_room("starfall_outskirts")
	_check(outskirts.get_node("DuskShade").is_in_group("family_spirit") and outskirts.get_node("LostWatch").is_in_group("family_construct"), "Outer Watch lacks its two enemy families")
	_check(outskirts.get_node("FirstStep").position.y > outskirts.get_node("SecondStep").position.y and outskirts.get_node("SecondStep").position.y > outskirts.get_node("UpperWatch").position.y, "Outer Watch high route cannot be climbed in stages")
	state.set_current_room("starfall_citadel")
	await outer_door.activate(player)
	_check(state.current_room_id == "starfall_outskirts" and state.timeline_stage == 4, "The outer watch is not part of the fourth region")
	_check(player.global_position.distance_to(outskirts.get_node("Entry").global_position) < 45.0, "City gate placed the player at the wrong outer marker")
	_check(ui.zone_title_label.text == "STARFALL OUTER WATCH" and "DANGER" in ui.objective_label.text, "The outer area does not announce danger")
	_check(game.get_node("AmbientSoundscape").current_track == "starfall_outskirts", "Outer Watch lacks its own ambience")
	var lamp = outskirts.get_node("OuterLamp")
	player.global_position = lamp.get_node("RespawnPoint").global_position
	_check(lamp._save_progress(player) and state.checkpoint_lamp_id == "starfall_outer_lamp", "Outer Watch lamp did not save progress")
	var cache = outskirts.get_node("UpperCache")
	_check(cache.open(player) and not cache.open(player) and bool(state.opened_caches.get("starfall_outer_watch", false)), "Outer Watch cache did not pay exactly once")
	_check("FOUND" in ui.objective_label.text, "Outer Watch objective did not react to the cache")
	_check(lamp._save_progress(player), "Outer Watch cache could not be saved")
	await outskirts.get_node("CityReturnDoor").activate(player)
	_check(state.current_room_id == "starfall_citadel" and player.global_position.distance_to(city.get_node("OuterWatchReturn").global_position) < 45.0, "The outer path cannot return safely to the city")
	_check("SAFE CITY" in ui.objective_label.text, "Returning inside the city did not restore its safe status")
	_check(state.load_game() and state.current_room_id == "starfall_outskirts", "Outer Watch lamp did not restore its room")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	_check(game.get_node("StarfallOutskirts/UpperCache").opened and state.get_discovered_lamps().has("starfall_outer_lamp"), "Outer Watch cache or lamp was not restored")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("STARFALL OUTSKIRTS TEST PASSED")
		quit(0)
	else:
		print("STARFALL OUTSKIRTS TEST FAILED: ", failures)
		quit(1)
