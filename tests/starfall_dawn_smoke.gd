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
	state.save_path = "res://_tmp_starfall_dawn_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	var player: Player = game.get_node("Player")
	var city = game.get_node("StarfallCitadel")
	var ambience = game.get_node("AmbientSoundscape")
	var ui = game.get_node("UI")
	var liora = city.get_node("Liora")
	var atley = city.get_node("Atley")
	var lamp = city.get_node("GateDistrict/GateLamp")
	var original_glow: Color = city.lantern_glows[0].color
	_check(not city.victory_active and not city.dawn_rays[0].visible and "lanterns" in liora.get_next_line(), "Citadel began in post-victory state")
	state.set_current_room("starfall_citadel")
	_check(ambience.current_track == "starfall_citadel", "Pre-victory Citadel music is wrong")
	player.global_position = lamp.get_node("RespawnPoint").global_position
	_check(lamp._save_progress(player), "Pre-victory Citadel lamp could not save")
	state.mark_boss_defeated("hollow_sovereign")
	_check(city.victory_active and city.dawn_rays[0].visible and city.lantern_glows[0].color != original_glow, "Citadel lights did not answer the Sovereign's defeat")
	_check("throne" in liora.get_next_line() and "new volume" in atley.get_next_line(), "Citadel residents did not react to the ending")
	liora._show_social_line()
	_check("lamps" in liora.social_bubble.text, "Resident overhead conversation did not update after victory")
	state.set_current_room("starfall_outskirts")
	state.set_current_room("starfall_citadel")
	_check(ambience.current_track == "starfall_citadel_dawn" and "new light" in ui.zone_subtitle_label.text, "Returning to the Citadel did not announce the dawn")
	_check(state.load_game() and not city.victory_active and city.lantern_glows[0].color == original_glow and not city.dawn_rays[0].visible, "Unsaved victory visuals did not roll back at the lamp")
	_check(ambience.current_track == "starfall_citadel" and "lanterns" in liora.get_next_line(), "Unsaved victory music or dialogue did not roll back")
	state.mark_boss_defeated("hollow_sovereign")
	_check(lamp._save_progress(player) and state.load_game(), "Saved Citadel victory could not reload")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	city = game.get_node("StarfallCitadel")
	ambience = game.get_node("AmbientSoundscape")
	_check(city.victory_active and city.dawn_rays[0].visible and ambience.current_track == "starfall_citadel_dawn", "Saved victory did not restore Citadel dawn on a fresh scene")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("STARFALL DAWN TEST PASSED")
		quit(0)
	else:
		print("STARFALL DAWN TEST FAILED: ", failures)
		quit(1)
