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
	state.save_path = "res://_tmp_starfall_route_save.json"
	state.start_new_game("normal")
	state.defeated_bosses["ash_castellan"] = true
	state.add_item("castellan_seal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var city: Node2D = game.get_node("StarfallCitadel")
	var quest = game.get_node("QuestManager")
	var ui = game.get_node("UI")
	var rook = city.get_node("Rook")
	_check(rook.is_in_group("starfall_route_npc"), "Rook is not the city quest giver")
	_check(city.get_node("WatchReport").position.y < city.get_node("WestPromenade").position.y and city.get_node("MarketReport").position.y < city.get_node("MarketBalcony").position.y and city.get_node("GardenReport").position.y < city.get_node("GardenBalcony").position.y, "City reports are not on the three upper paths")
	state.set_current_room("ash_throne")
	await game.get_node("CastellanThrone/StarfallDoor").activate(player)
	_check(state.current_room_id == "starfall_citadel", "City route cannot be entered")
	city.get_node("WatchReport")._on_body_entered(player)
	_check(quest.get_starfall_route_progress() == 1 and int(quest.starfall_route_state) == 0, "A report found before accepting the task was lost")
	rook.interaction_requested.emit(rook)
	_check(ui.speaker_label.text == "ROOK" and ui.dialogue_primary_button.visible and "100 Gold" in ui.dialogue_text.text, "Rook does not show the route and rewards")
	ui._on_dialogue_primary_pressed()
	_check(int(quest.starfall_route_state) == 1 and "Lantern Route 1/3" in ui.quest_tracker_label.text and "REPORTS 1/3" in ui.objective_label.text, "City task did not start with visible pre-collected progress")
	ui._close_dialogue()
	var gate_lamp = city.get_node("GateDistrict/GateLamp")
	player.global_position = gate_lamp.get_node("RespawnPoint").global_position
	_check(gate_lamp._save_progress(player), "City quest progress could not be saved")
	city.get_node("MarketReport")._on_body_entered(player)
	city.get_node("GardenReport")._on_body_entered(player)
	_check(quest.get_starfall_route_progress() == 3 and int(quest.starfall_route_state) == 2, "Three city reports did not make the quest ready")
	quest.report_item_collected("starfall_report_garden")
	_check(quest.get_starfall_route_progress() == 3, "The same city report counted twice")
	_check(state.load_game(), "Saved city quest could not reload")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	player = game.get_node("Player")
	city = game.get_node("StarfallCitadel")
	quest = game.get_node("QuestManager")
	ui = game.get_node("UI")
	rook = city.get_node("Rook")
	_check(int(quest.starfall_route_state) == 1 and quest.get_starfall_route_progress() == 1, "Unsaved city reports did not roll back")
	_check(not is_instance_valid(city.get_node_or_null("WatchReport")) and city.has_node("MarketReport") and city.has_node("GardenReport"), "Saved and unsaved report pickups restored incorrectly")
	city.get_node("MarketReport")._on_body_entered(player)
	city.get_node("GardenReport")._on_body_entered(player)
	_check(int(quest.starfall_route_state) == 2 and "Return the three reports to Rook" in ui.quest_tracker_label.text and "RETURN TO ROOK" in ui.objective_label.text, "City quest does not point back to its giver")
	rook.interaction_requested.emit(rook)
	var gold_before: int = state.gold
	var dust_before: int = int(state.inventory.get("ether_dust", 0))
	var points_before: int = player.skill_points
	var xp_before: int = player.xp
	var xp_per_level: int = player.xp_per_level
	ui._on_dialogue_primary_pressed()
	_check(int(quest.starfall_route_state) == 3 and state.gold == gold_before + 100 and int(state.inventory.get("ether_dust", 0)) == dust_before + 2, "City quest item or gold reward was wrong")
	var earned_levels := floori(float(xp_before + 4) / float(xp_per_level))
	_check(player.skill_points == points_before + 1 + earned_levels and player.xp == (xp_before + 4) % xp_per_level, "City quest skill or XP reward was wrong")
	_check(not ui.dialogue_primary_button.visible and not "Lantern Route" in ui.quest_tracker_label.text, "Completed city quest still offers a claim")
	ui._on_dialogue_primary_pressed()
	_check(state.gold == gold_before + 100, "City quest rewarded twice")
	ui._close_dialogue()
	var garden_lamp = city.get_node("GardenLamp")
	player.global_position = garden_lamp.get_node("RespawnPoint").global_position
	_check(garden_lamp._save_progress(player), "Completed city quest could not be saved")
	_check(state.load_game(), "City reward save could not reload")
	_check(int(state.quest_state.get("starfall_route_state", -1)) == 3 and state.gold == gold_before + 100, "Saved city reward was lost")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("STARFALL ROUTE TEST PASSED")
		quit(0)
	else:
		print("STARFALL ROUTE TEST FAILED: ", failures)
		quit(1)
