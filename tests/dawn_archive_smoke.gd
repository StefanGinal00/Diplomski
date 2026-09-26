extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _clear_echo_threats(echo) -> void:
	for threat in get_nodes_in_group("enemy"):
		if threat is Node2D and echo.get_parent().is_ancestor_of(threat) and echo.global_position.distance_to(threat.global_position) <= echo.threat_radius:
			threat.set("is_dead", true)


func _attune_echo(echo, player: Player) -> bool:
	root.get_node("GameState").set_current_room({"shaft": "shaft_cistern", "echo": "echo_archive", "ash": "ash_chapel"}[echo.echo_id])
	_clear_echo_threats(echo)
	player.global_position = echo.global_position
	echo._on_body_entered(player)
	if not echo.record():
		return false
	echo._process(echo.attune_seconds + 0.1)
	return echo.quest_manager.is_dawn_echo_recorded(echo.echo_id)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_dawn_archive_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	state.set_current_room("shaft_cistern")
	await process_frame
	var player: Player = game.get_node("Player")
	var quest = game.get_node("QuestManager")
	var ui = game.get_node("UI")
	var atley = game.get_node("StarfallCitadel/Atley")
	var shaft = game.get_node("BlackwaterCistern/DawnEcho")
	var echo = game.get_node("PrismArchive/DawnEcho")
	var ash = game.get_node("AshChapel/DawnEcho")
	_check(not shaft.visible and not echo.visible and not ash.visible and not shaft.record() and not quest.start_dawn_archive(), "Dawn Archive was available before the Sovereign fell")
	state.mark_boss_defeated("hollow_sovereign")
	_check(shaft.visible and echo.visible and ash.visible, "Three return-site echoes did not appear after the final victory")
	# Population now loads on entry; do not expect threats in unvisited rooms.
	for site in [shaft, echo, ash]:
		state.set_current_room({"shaft": "shaft_cistern", "echo": "echo_archive", "ash": "ash_chapel"}[site.echo_id])
		await process_frame
		_check(site._has_nearby_threat(), "Visited return-site echo has no local encounter: " + String(site.echo_id))
	state.set_current_room("shaft_cistern")
	_check(shaft.position.distance_to(game.get_node("BlackwaterCistern/MemoryReliquary").position) > 80.0 and ash.position.distance_to(game.get_node("AshChapel/MemoryReliquary").position) > 80.0, "Dawn Echoes overlap the old sigil interactions")
	player.global_position = shaft.global_position
	shaft._on_body_entered(player)
	_check(shaft._has_nearby_threat() and not shaft.record() and shaft.prompt.text == "DEFEAT NEARBY FOES", "An occupied echo did not require its nearby threat to be cleared")
	_clear_echo_threats(shaft)
	_check(shaft.record() and shaft.attune_bar.visible and quest.get_dawn_archive_progress() == 0, "Echo recorded without the listening interval")
	shaft._process(shaft.attune_seconds * 0.5)
	player.global_position += Vector2(150.0, 0.0)
	shaft._process(0.1)
	_check(not shaft.attuning and not shaft.attune_bar.visible and quest.get_dawn_archive_progress() == 0, "Moving away did not interrupt the echo")
	player.global_position = shaft.global_position
	_check(shaft.record(), "Echo could not be restarted after interruption")
	var crawler = game.get_node("BlackwaterCistern/ChannelCrawler")
	crawler.is_dead = false
	shaft._process(0.1)
	_check(not shaft.attuning and quest.get_dawn_archive_progress() == 0, "A returning threat did not interrupt listening")
	crawler.is_dead = true
	_check(shaft.record(), "Echo could not be restarted after clearing a returning threat")
	shaft._process(shaft.attune_seconds + 0.1)
	_check(not shaft.record() and quest.get_dawn_archive_progress() == 1 and shaft.echo_chime.stream != null, "An echo could not be pre-recorded exactly once with a completion cue")
	_check(ui.memory_toast_panel.visible and "FLOOD ECHO" in ui.memory_title_label.text and "made it home" in ui.memory_text_label.text and not paused, "Recorded echo did not reveal its unique non-blocking memory")
	ui._on_npc_interaction_requested(atley)
	_check(ui.dialogue_primary_button.visible and "Blackwater Cistern" in ui.dialogue_text.text, "Atley did not offer the postgame archive")
	ui._on_dialogue_primary_pressed()
	_check(int(quest.dawn_archive_state) == 1 and "Dawn Archive 1/3" in ui.quest_tracker_label.text, "Pre-recorded echo did not count when accepting the archive")
	ui._close_dialogue()
	state.set_current_room("shaft_cistern")
	var lamp = game.get_node("BlackwaterCistern/CisternLamp")
	player.global_position = lamp.get_node("RespawnPoint").global_position
	_check(lamp._save_progress(player), "Dawn Archive checkpoint could not save")
	_check(_attune_echo(echo, player) and _attune_echo(ash, player) and int(quest.dawn_archive_state) == 2, "Three recorded echoes did not ready the return to Atley")
	_check(state.load_game(), "Dawn Archive could not load the previous lamp")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	player = game.get_node("Player")
	quest = game.get_node("QuestManager")
	ui = game.get_node("UI")
	atley = game.get_node("StarfallCitadel/Atley")
	shaft = game.get_node("BlackwaterCistern/DawnEcho")
	echo = game.get_node("PrismArchive/DawnEcho")
	ash = game.get_node("AshChapel/DawnEcho")
	_check(int(quest.dawn_archive_state) == 1 and quest.get_dawn_archive_progress() == 1 and quest.is_dawn_echo_recorded("shaft") and not quest.is_dawn_echo_recorded("echo"), "Unsaved Dawn Echoes survived lamp rollback")
	_check(not ui.memory_toast_panel.visible and ui.memory_reveal_queue.is_empty(), "Saved Dawn Echo replayed its discovery card after loading")
	state.set_current_room("echo_archive")
	await process_frame
	echo._on_body_entered(player)
	_check(shaft.visible and shaft.prompt.text == "ECHO RECORDED" and echo.prompt.text == "DEFEAT NEARBY FOES", "Dawn Echo visuals did not restore from the saved quest snapshot")
	_check(_attune_echo(echo, player) and _attune_echo(ash, player) and int(quest.dawn_archive_state) == 2, "Rolled-back echoes could not be recorded again")
	state.set_current_room("starfall_citadel")
	ui._on_npc_interaction_requested(atley)
	_check("three voices" in ui.dialogue_text.text.to_lower() and ui.dialogue_primary_button.visible, "Atley did not recognize the completed archive")
	var gold_before: int = state.gold
	var skill_before: int = player.skill_points
	var xp_before: int = player.xp
	var expected_level_points: int = int((xp_before + 4) / player.xp_per_level)
	ui._on_dialogue_primary_pressed()
	_check(int(quest.dawn_archive_state) == 3 and state.has_item("dawn_chronicle") and state.gold == gold_before + 120 and player.skill_points == skill_before + 1 + expected_level_points, "Dawn Archive reward was not granted correctly")
	_check(not quest.turn_in_dawn_archive(player) and state.gold == gold_before + 120, "Dawn Archive reward could be claimed twice")
	ui._close_dialogue()
	var city_lamp = game.get_node("StarfallCitadel/GateDistrict/GateLamp")
	player.global_position = city_lamp.get_node("RespawnPoint").global_position
	_check(city_lamp._save_progress(player) and state.load_game(), "Completed Dawn Archive could not be saved")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	quest = game.get_node("QuestManager")
	_check(int(quest.dawn_archive_state) == 3 and quest.get_dawn_archive_progress() == 3 and state.has_item("dawn_chronicle") and not game.get_node("AshChapel/DawnEcho").record(), "Saved Dawn Archive completion did not persist or allowed a duplicate")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("DAWN ARCHIVE TEST PASSED")
		quit(0)
	else:
		print("DAWN ARCHIVE TEST FAILED: ", failures)
		quit(1)
