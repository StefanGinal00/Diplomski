extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _kill_wave(barracks: Node2D) -> void:
	for enemy in barracks.get_node("WaveEnemies").get_children():
		if enemy.is_in_group("enemy") and not enemy.is_queued_for_deletion():
			enemy.take_damage(999)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_ember_barracks_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var forge = game.get_node("CinderForge")
	var barracks = game.get_node("EmberBarracks")
	var causeway = game.get_node("BrokenCauseway")
	var ui = game.get_node("UI")
	var forge_door = forge.get_node("BarracksDoor")
	var loop_door = barracks.get_node("CausewayLoopDoor")
	var causeway_loop = causeway.get_node("BarracksLoopDoor")
	var beacon = barracks.get_node("BarracksBeacon")
	var cache = barracks.get_node("BarracksCache")
	_check(not forge_door._requirements_met(), "Barracks opened before cooling fan")
	_check(not loop_door._requirements_met() and not causeway_loop._requirements_met(), "Barracks loop opened before trial")
	_check(not cache.open(player), "Barracks cache opened before trial")
	_check(not barracks.get_node("BarracksVent").disabled, "Barracks heat vent started disabled")
	state.unlock_shortcut("ash_forge_fan")
	_check(forge_door._requirements_met(), "Cooling fan did not open Barracks")
	state.set_current_room("ash_forge")
	player.global_position = forge.get_node("BarracksReturn").global_position
	forge_door.activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "ash_barracks" and bool(state.discovered_rooms.get("ash_barracks", false)), "Forge door did not discover Barracks")
	_check(player.global_position.distance_to(barracks.get_node("BarracksEntry").global_position) < 45.0, "Barracks entry marker is wrong")
	_check(game.get_node("AmbientSoundscape").current_track == "ash_barracks", "Barracks ambience did not start")
	_check("ACTIVATE THE BARRACKS" in ui.objective_label.text, "Barracks objective is missing")
	_check(beacon.get_node("Prompt").text == "[E] START BARRACKS TRIAL", "Barracks beacon prompt is missing")
	_check(barracks.start_trial(player), "Barracks trial would not start")
	_check(barracks.wave == 1 and barracks.enemies_remaining == 2, "First Barracks wave has wrong roster")
	_check("WAVE 1/2" in ui.objective_label.text, "First wave progress did not reach HUD")
	_check(not barracks.start_trial(player), "Barracks trial could start twice")
	state.set_current_room("ash_forge")
	await process_frame
	_check(not barracks.active and barracks.wave == 0 and not bool(state.unlocked_shortcuts.get("ash_barracks_cleared", false)), "Leaving did not reset unfinished trial")
	state.set_current_room("ash_barracks")
	_check(barracks.start_trial(player), "Trial did not restart after leaving")
	var xp_before: int = player.skill_points * player.xp_per_level + player.xp
	_kill_wave(barracks)
	await process_frame
	await process_frame
	_check(barracks.wave == 2 and barracks.enemies_remaining == 2, "Second Barracks wave did not spawn")
	_check(player.skill_points * player.xp_per_level + player.xp == xp_before, "Unfinished wave granted farmable XP")
	var second_wave_sentry: bool = false
	for enemy in barracks.get_node("WaveEnemies").get_children():
		if enemy.is_in_group("enemy") and enemy.is_in_group("family_construct"):
			second_wave_sentry = true
	_check(second_wave_sentry, "Second wave lacks Ash Sentry")
	var gold_before: int = state.gold
	_kill_wave(barracks)
	await process_frame
	await process_frame
	_check(barracks.completed and bool(state.unlocked_shortcuts.get("ash_barracks_cleared", false)), "Trial clear did not persist in game state")
	_check(state.has_item("barracks_insignia") and state.gold == gold_before + 45, "Trial did not award one-time insignia and gold")
	_check(player.skill_points * player.xp_per_level + player.xp == xp_before + 4, "Trial did not award its one-time XP")
	_check(not barracks.start_trial(player) and state.gold == gold_before + 45, "Cleared trial paid twice")
	var rewarded_skill_points: int = player.skill_points
	var rewarded_xp: int = player.xp
	_check(loop_door._requirements_met() and causeway_loop._requirements_met(), "Trial did not unlock two-way Causeway loop")
	_check(barracks.get_node("BarracksVent").disabled, "Trial did not quiet Barracks vent")
	_check(cache.open(player) and state.opened_caches.has("ash_barracks_supply"), "Barracks cache did not unlock")
	_check(not cache.open(player), "Barracks cache paid twice")
	ui._update_route_summary()
	_check("ASHEN BASTION  2/10 PLAYABLE ROOMS" in ui.map_route_label.text and "CACHES 1/15" in ui.map_route_label.text and "BARRACKS CLEARED" in ui.map_route_label.text, "Map did not track Barracks progress")
	player.global_position = barracks.get_node("BarracksLamp/RespawnPoint").global_position
	_check(barracks.get_node("BarracksLamp")._save_progress(player), "Barracks lamp did not save trial")
	_check(state.get_discovered_lamps().has("ember_barracks_lamp"), "Barracks lamp did not enter travel network")
	state.unlocked_shortcuts.erase("ash_barracks_cleared")
	state.opened_caches.erase("ash_barracks_supply")
	state.inventory.erase("barracks_insignia")
	_check(state.load_game(), "Barracks lamp save could not reload")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	barracks = game.get_node("EmberBarracks")
	causeway = game.get_node("BrokenCauseway")
	player = game.get_node("Player")
	_check(barracks.completed and not barracks.active and state.has_item("barracks_insignia"), "Saved trial did not restore")
	_check(player.skill_points == rewarded_skill_points and player.xp == rewarded_xp, "Saved Barracks XP reward did not restore")
	_check(barracks.get_node("BarracksCache").opened and barracks.get_node("BarracksVent").disabled, "Saved cache or quieted vent did not restore")
	_check(barracks.get_node("CausewayLoopDoor")._requirements_met() and causeway.get_node("BarracksLoopDoor")._requirements_met(), "Saved two-way loop closed")
	barracks.get_node("CausewayLoopDoor").activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "ash_causeway" and player.global_position.distance_to(causeway.get_node("BarracksReturn").global_position) < 45.0, "Barracks-to-Causeway loop failed")
	causeway.get_node("BarracksLoopDoor").activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "ash_barracks" and player.global_position.distance_to(barracks.get_node("BarracksLoopEntry").global_position) < 45.0, "Causeway-to-Barracks loop failed")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("EMBER BARRACKS TEST PASSED")
		quit(0)
	else:
		print("EMBER BARRACKS TEST FAILED: ", failures)
		quit(1)
