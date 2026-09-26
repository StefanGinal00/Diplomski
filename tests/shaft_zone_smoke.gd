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
	state.save_path = "res://_tmp_shaft_zone_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var shaft = game.get_node("VerticalChamber")
	var grotto = game.get_node("EchoGrotto")
	var ui = game.get_node("UI")
	var boss = shaft.get_node("AbyssWarden")
	var gate = shaft.get_node("GrottoGate")
	var lower_lift = shaft.get_node("LowerLift")
	var player = game.get_node("Player")
	var soundscape = game.get_node("AmbientSoundscape")
	var sentinel = game.get_node("SentinelBoss")
	sentinel.take_damage(sentinel.max_health)
	_check(bool(state.defeated_bosses.get("void_sentinel", false)), "First boss completion not recorded")
	_check(not gate._has_required_item(), "Gate opened before Warden Seal")
	_check(get_first_node_in_group("grotto_entry") != null, "Grotto entry missing")
	_check(grotto.get_node("ReturnDoor").target_marker_group == &"shaft_return", "Return door target wrong")
	state.set_current_room("sunken_shaft")
	_check(soundscape.current_track == "sunken_shaft", "Shaft ambience did not start")
	_check("THREATS REMAINING" in ui.objective_label.text, "Shaft objective missing")
	ui._on_boss_battle_started(boss)
	_check("ABYSS WARDEN" in ui.boss_health_label.text, "Warden HUD name missing")
	player.max_health = 100
	player.current_health = 100
	player.global_position = boss.global_position + Vector2(-125.0, 0.0)
	await create_timer(2.5).timeout
	_check(boss.active, "Warden did not activate near player")
	_check(soundscape.current_track == "boss", "Boss music did not start")
	await shaft.get_node("ReturnDoor").activate(player)
	_check(state.current_room_id == "sunken_shaft" and shaft.get_node("ReturnDoor").status_label.text == "BATTLE SEALED", "Warden fight allowed retreat to the passage")
	var position_before_lift: Vector2 = player.global_position
	await lower_lift._use_lift(player)
	_check(player.global_position.distance_to(position_before_lift) < 1.0, "Shaft lift bypassed the Warden fight lock")
	boss.take_damage(boss.max_health)
	_check(soundscape.current_track == "sunken_shaft", "Boss music did not end")
	_check(state.has_item("warden_seal"), "Warden Seal not rewarded")
	_check(bool(state.defeated_bosses.get("abyss_warden", false)), "Boss completion not recorded")
	_check(state.get_zone_tier("sunken_shaft") == 1, "Tier upgrade missing")
	_check(gate._has_required_item(), "Gate stayed locked")
	_check("AWAKENED WARDEN OPTIONAL" in ui.objective_label.text, "Post-boss objective missing")
	_check(state.unlock_shortcut("shaft_lift"), "Lift could not unlock")
	lower_lift._update_visuals()
	_check("SHAFT LIFT" in lower_lift.prompt.text, "Lift did not show unlocked state")
	gate.activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_grotto", "Gate transition did not reach grotto")
	_check(soundscape.current_track == "echo_grotto", "Grotto ambience did not start")
	grotto.get_node("ReturnDoor").activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "sunken_shaft", "Grotto return did not reach shaft")
	_check(shaft.has_node("AbyssWarden") and shaft.get_node("AbyssWarden").is_rematch, "Warden did not reappear on return")
	_check(not shaft.get_node("AbyssWarden").active and shaft.get_node("AbyssWarden/ChallengePrompt").visible, "Passing the optional Warden rematch started a locked fight")
	lower_lift._use_lift(player)
	await create_timer(0.5).timeout
	_check(player.global_position.distance_to(shaft.get_node("UpperLiftMarker").global_position) < 40.0, "Lift did not reach upper marker")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "shaft_test_lamp", "Test Lamp", "sunken_shaft"), "Save failed")
	soundscape.set_enabled(false)
	state.defeated_bosses.clear()
	state.unlocked_shortcuts.clear()
	state.inventory.erase("warden_seal")
	state.zone_tiers["sunken_shaft"] = 0
	_check(state.load_game(), "Load failed")
	_check(state.has_item("warden_seal"), "Seal not restored")
	_check(bool(state.unlocked_shortcuts.get("shaft_lift", false)), "Lift not restored")
	_check(state.get_zone_tier("sunken_shaft") == 1, "Tier not restored")
	game.queue_free()
	await process_frame
	var reloaded_game = load("res://Game.tscn").instantiate()
	root.add_child(reloaded_game)
	current_scene = reloaded_game
	await process_frame
	await process_frame
	var rematch = reloaded_game.get_node("VerticalChamber/AbyssWarden")
	_check(rematch.is_rematch and rematch.max_health == 25, "Awakened Warden rematch missing")
	_check(not reloaded_game.has_node("SentinelBoss"), "First boss respawned")
	_check(reloaded_game.get_node("ExitPortal").is_unlocked, "First zone exit did not reopen")
	_check(reloaded_game.has_node("Cache_passage_return"), "Training Passage return cache missing")
	_check(reloaded_game.get_node("VerticalChamber").has_node("Cache_shaft_rim"), "Shaft rim cache missing")
	_check(reloaded_game.get_node("VerticalChamber").has_node("Cache_shaft_depth"), "Shaft depth cache missing")
	_check(reloaded_game.get_node("VerticalChamber").has_node("shaft_echo_wisp"), "Upgraded Shaft encounter missing")
	_check(reloaded_game.get_node("VerticalChamber/UpperShaftSentry").max_health == 4, "Upgraded sentry health missing")
	_check(reloaded_game.get_node("VerticalChamber/ShaftCrawler").max_health == 5, "Upgraded crawler health missing")
	_check(reloaded_game.get_node("VerticalChamber/GrottoGate")._has_required_item(), "Reloaded gate locked")
	_check(not reloaded_game.get_node("AmbientSoundscape").enabled, "Music preference did not survive scene reload")
	var reloaded_player = reloaded_game.get_node("Player")
	var quest_manager = reloaded_game.get_node("QuestManager")
	quest_manager.quest_index = 2
	quest_manager.quest_state = 0
	_check(quest_manager.start_quest(), "Awakened Warden trial did not start")
	var original_max_health: int = reloaded_player.max_health
	_check(not rematch.active and rematch.get_node("ChallengePrompt").visible, "Loaded Warden rematch is not optional")
	reloaded_player.global_position = rematch.global_position + Vector2(-85.0, 0.0)
	await process_frame
	_check(not rematch.active, "Approaching the optional Warden started combat")
	rematch.take_damage(1)
	_check(rematch.active and not rematch.get_node("ChallengePrompt").visible, "Attacking did not begin the Warden rematch")
	rematch.take_damage(rematch.current_health)
	_check(bool(state.boss_rematches.get("abyss_warden", false)), "Warden rematch completion not recorded")
	_check(state.has_item("warden_heart") and reloaded_player.max_health == original_max_health + 1, "Warden Heart HP reward missing")
	_check(quest_manager.quest_state == 2, "Awakened Warden trial did not advance")
	_check(quest_manager.turn_in_quest(reloaded_player) and quest_manager.quest_state == 3, "Awakened Warden trial reward missing")
	_check(not quest_manager.turn_in_quest(reloaded_player), "Awakened Warden trial could be claimed twice")
	var rim_cache = reloaded_game.get_node("VerticalChamber/Cache_shaft_rim")
	_check(rim_cache.open(reloaded_player), "Shaft cache could not be opened")
	_check(not rim_cache.open(reloaded_player), "Shaft cache could be farmed twice")
	_check(state.save_at_checkpoint(reloaded_player, reloaded_game.get_node("QuestManager"), reloaded_player.global_position, "shaft_test_lamp", "Test Lamp", "sunken_shaft"), "Rematch save failed")
	reloaded_game.queue_free()
	await process_frame
	reloaded_game = load("res://Game.tscn").instantiate()
	root.add_child(reloaded_game)
	current_scene = reloaded_game
	await process_frame
	await process_frame
	_check(not reloaded_game.get_node("VerticalChamber").has_node("AbyssWarden"), "Cleared Warden rematch respawned")
	_check(reloaded_game.get_node("VerticalChamber/Cache_shaft_rim").opened, "Opened cache reset after save")
	state.delete_save()
	reloaded_game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("SHAFT ZONE TEST PASSED")
		quit(0)
	else:
		print("SHAFT ZONE TEST FAILED: ", failures)
		quit(1)
