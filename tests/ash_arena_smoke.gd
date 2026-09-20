extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _kill_wave(arena: Node2D) -> void:
	for enemy in arena.get_node("Combatants").get_children():
		if enemy.is_in_group("enemy") and not enemy.is_queued_for_deletion():
			enemy.take_damage(999)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_ash_arena_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var barracks = game.get_node("EmberBarracks")
	var arena = game.get_node("AshArena")
	var ui = game.get_node("UI")
	var arena_door = barracks.get_node("ArenaDoor")
	var cache = arena.get_node("ArenaCache")
	_check(not arena_door._requirements_met(), "Arena opened before Barracks trial")
	_check(not cache.open(player), "Arena cache opened before victory")
	_check(not arena.start_trial(player), "Arena could start before entry and prerequisite")
	state.unlock_shortcut("ash_barracks_cleared")
	_check(arena_door._requirements_met(), "Barracks victory did not open Arena")
	state.set_current_room("ash_barracks")
	player.global_position = barracks.get_node("ArenaReturn").global_position
	arena_door._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "ash_arena" and bool(state.discovered_rooms.get("ash_arena", false)), "Arena transition or discovery failed")
	_check(player.global_position.distance_to(arena.get_node("ArenaEntry").global_position) < 45.0, "Arena entry marker is wrong")
	_check(game.get_node("AmbientSoundscape").current_track == "ash_arena", "Arena ambience did not start")
	_check("SOUND THE WAR BELL" in ui.objective_label.text, "Arena objective is missing")
	_check(arena.start_trial(player), "War bell would not start Arena")
	_check(arena.wave == 1 and arena.enemies_remaining == 2 and not arena.start_trial(player), "First wave roster or duplicate start is wrong")
	_check("WAVE 1/4" in ui.objective_label.text, "Wave 1 HUD objective is missing")
	var xp_before: int = player.skill_points * player.xp_per_level + player.xp
	var gold_before: int = state.gold
	_kill_wave(arena)
	await process_frame
	_check(arena.intermission and arena.enemies_remaining == 0, "Wave 1 did not enter a breathing pause")
	_check(player.skill_points * player.xp_per_level + player.xp == xp_before and state.gold == gold_before, "Wave enemies granted farmable rewards")
	state.set_current_room("ash_barracks")
	await process_frame
	_check(not arena.active and arena.wave == 0 and not arena.intermission, "Retreat did not reset Arena")
	state.set_current_room("ash_arena")
	await create_timer(1.7).timeout
	_check(arena.wave == 0 and arena.enemies_remaining == 0, "Abandoned wave timer spawned enemies after retreat")
	_check(arena.start_trial(player), "Arena could not restart after retreat")
	for expected_wave in range(1, 5):
		_check(arena.wave == expected_wave, "Arena skipped wave %d" % expected_wave)
		if expected_wave == 4:
			var marshal = arena.marshal
			_check(marshal != null and marshal.is_in_group("mini_boss") and arena.enemies_remaining == 3, "Final wave lacks Marshal and two guards")
			_check(marshal.is_in_group("family_demon") and marshal.current_health == marshal.max_health, "Marshal family or health is wrong")
			marshal.take_damage(int(marshal.max_health / 2))
			_check(marshal.phase == 2 and marshal.current_health > 0, "Marshal did not enter phase two")
			marshal._start_charge()
			_check(marshal.get_node("Telegraph").visible and marshal.windup_remaining > 0.0, "Marshal charge has no warning")
			marshal._fire_volley()
			var projectiles := 0
			for node in arena.get_node("Combatants").get_children():
				projectiles += int(node.is_in_group("enemy_projectile"))
			_check(projectiles == 3, "Marshal phase two did not fire three bolts")
		_kill_wave(arena)
		await create_timer(1.75).timeout
		await process_frame
	_check(arena.completed and bool(state.unlocked_shortcuts.get("ash_arena_cleared", false)), "Arena victory was not recorded")
	_check(state.has_item("marshal_emblem") and state.gold == gold_before + 100, "Arena did not award emblem and 100 Gold once")
	_check(player.skill_points * player.xp_per_level + player.xp == xp_before + 7, "Arena did not award 7 XP once")
	_check(not arena.start_trial(player) and state.gold == gold_before + 100, "Cleared Arena restarted or paid twice")
	var rewarded_skill_points: int = player.skill_points
	var rewarded_xp: int = player.xp
	_check(cache.open(player) and state.opened_caches.has("ash_arena_victory"), "Arena victor cache did not unlock")
	_check(not cache.open(player), "Arena victor cache paid twice")
	ui._update_route_summary()
	_check("ARENA CLEARED" in ui.map_route_label.text and "CACHES 1/5" in ui.map_route_label.text, "World map did not track Arena victory")
	player.global_position = arena.get_node("ArenaLamp/RespawnPoint").global_position
	_check(arena.get_node("ArenaLamp")._save_progress(player), "Arena lamp did not save victory")
	_check(state.get_discovered_lamps().has("ash_arena_lamp"), "Arena lamp did not enter travel network")
	state.unlocked_shortcuts.erase("ash_arena_cleared")
	state.inventory.erase("marshal_emblem")
	state.opened_caches.erase("ash_arena_victory")
	_check(state.load_game(), "Arena save could not reload")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	arena = game.get_node("AshArena")
	player = game.get_node("Player")
	_check(arena.completed and state.has_item("marshal_emblem") and arena.get_node("ArenaCache").opened, "Saved Arena clear, emblem or cache did not restore")
	_check(player.skill_points == rewarded_skill_points and player.xp == rewarded_xp, "Saved Arena XP reward did not restore")
	arena.get_node("ReturnDoor")._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "ash_barracks" and player.global_position.distance_to(game.get_node("EmberBarracks/ArenaReturn").global_position) < 45.0, "Arena return passage failed")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("ASH ARENA TEST PASSED")
		quit(0)
	else:
		print("ASH ARENA TEST FAILED: ", failures)
		quit(1)
