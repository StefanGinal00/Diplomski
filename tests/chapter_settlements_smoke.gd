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
	state.save_path = "res://_tmp_chapter_settlements_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var echo = game.get_node("EchoHaven")
	var ash = game.get_node("CinderHearth")
	var echo_original: String = echo.get_node("AreaSubtitle").text
	var ash_original: String = ash.get_node("AreaSubtitle").text
	var echo_glow: Color = echo.get_node("HavenGlow").color
	var ash_glow: Color = ash.get_node("HearthGlow").color
	state.add_gold(300)
	state.set_current_room("echo_haven")
	_check(state.timeline_stage == 2 and state.get_town_stock_remaining("echo_haven_shop", "healing_herb") == 3, "Early Echo stock or chapter is wrong")
	for _i in range(3):
		_check(state.purchase_town_item("echo_haven_shop", "healing_herb", 1, 18), "Early Echo purchase failed")
	_check(state.get_town_stock_remaining("echo_haven_shop", "healing_herb") == 0, "Early Echo cap was not enforced")
	var echo_lamp = echo.get_node("HavenLamp")
	player.global_position = echo_lamp.get_node("RespawnPoint").global_position
	_check(echo_lamp._save_progress(player), "Echo chapter could not be saved")
	state.set_current_room("ash_causeway")
	_check(state.timeline_stage == 3 and state.get_town_stock_remaining("echo_haven_shop", "healing_herb") == 2 and state.get_town_stock_remaining("echo_haven_shop", "ether_dust") == 4, "Ash chapter did not add bounded Echo supplies")
	_check(echo.get_node("AreaSubtitle").text != echo_original and echo.get_node("MarketSign").text == "ASH TRADE OPEN" and echo.get_node("HavenGlow").color != echo_glow, "Echo settlement did not visibly respond to Ash")
	_check(state.purchase_town_item("echo_haven_shop", "healing_herb", 1, 18), "New Echo supply could not be bought")
	state.set_current_room("echo_haven")
	_check(state.get_town_stock_remaining("echo_haven_shop", "healing_herb") == 1, "Re-entering Echo refilled chapter supplies")
	_check(state.load_game() and state.timeline_stage == 2 and state.get_town_stock_remaining("echo_haven_shop", "healing_herb") == 0, "Lamp load did not roll back the unsaved chapter stock")
	_check(echo.get_node("AreaSubtitle").text == echo_original and echo.get_node("HavenGlow").color == echo_glow, "Echo visuals did not roll back with the lamp")
	state.set_current_room("ash_causeway")
	state.set_current_room("starfall_citadel")
	_check(state.timeline_stage == 4 and state.get_town_stock_remaining("ash_haven_shop", "iron_fragment") == 6 and state.get_town_stock_remaining("ash_haven_shop", "healing_herb") == 5, "Starfall chapter did not add bounded Ash supplies")
	_check(ash.get_node("AreaSubtitle").text != ash_original and ash.get_node("MarketSign").text == "CITADEL TRADE" and ash.get_node("HearthGlow").color != ash_glow, "Ash settlement did not visibly respond to Starfall")
	_check(state.purchase_town_item("ash_haven_shop", "iron_fragment", 1, 24), "New Ash supply could not be bought")
	var city_lamp = game.get_node("StarfallCitadel/GateDistrict/GateLamp")
	player.global_position = city_lamp.get_node("RespawnPoint").global_position
	_check(city_lamp._save_progress(player), "Starfall chapter could not be saved")
	_check(state.purchase_town_item("ash_haven_shop", "iron_fragment", 1, 24), "A second Ash purchase failed")
	_check(state.load_game() and state.get_town_stock_remaining("ash_haven_shop", "iron_fragment") == 5, "Unsaved Ash purchase did not roll back")
	state.set_current_room("ash_hearth")
	_check(state.get_town_stock_remaining("ash_haven_shop", "iron_fragment") == 5, "Backtracking refilled Ash chapter stock")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("CHAPTER SETTLEMENTS TEST PASSED")
		quit(0)
	else:
		print("CHAPTER SETTLEMENTS TEST FAILED: ", failures)
		quit(1)
