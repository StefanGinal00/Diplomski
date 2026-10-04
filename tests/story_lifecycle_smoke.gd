extends "res://tests/story_scenes_smoke.gd"

func _after_reload(previous_id: int) -> Node:
	for frame in range(120):
		await process_frame
		if is_instance_valid(current_scene) and current_scene.get_instance_id() != previous_id:
			current_scene.process_mode = Node.PROCESS_MODE_DISABLED
			await process_frame
			await process_frame
			return current_scene
	_check(false, "Native reload never installed a replacement scene")
	return null

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_story_lifecycle.json"
	state.start_new_game("normal")
	var game: Node = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var ui: Node = game.get_node("UI")
	var player: Node = game.get_node("Player")
	var quests: Node = game.get_node("QuestManager")
	state.story_scenes_seen["opening"] = true
	state.mark_boss_defeated("void_sentinel")
	state.story_scenes_seen["sentinel"] = true
	_check(quests.claim_main_reward(0, player), "Lifecycle initial reward unavailable")
	_check(state.save_at_checkpoint(player, quests, player.global_position), "Lifecycle checkpoint failed")
	await process_frame
	var saved_gold: int = state.gold
	state.mark_boss_defeated("abyss_warden")
	_check(quests.claim_main_reward(1, player), "Lifecycle unsaved reward unavailable")
	ui.story_player.play("haven")
	ui.campaign_scene_queue.append("echo")
	player.die()
	_check(ui.game_over_panel.visible and not ui.story_player.is_open() and ui.campaign_scene_queue.is_empty(), "Native death left story modal/queue active")
	_check(not state.story_scenes_seen.has("haven"), "Interrupted scene marked watched")
	var old_music: WeakRef = weakref(game.get_node("AmbientSoundscape"))
	var old_id := game.get_instance_id()
	ui.restart_button.pressed.emit()
	game = await _after_reload(old_id)
	if game == null: quit(1); return
	ui = game.get_node("UI")
	player = game.get_node("Player")
	quests = game.get_node("QuestManager")
	_check(old_music.get_ref() == null and not player.is_dead and not paused, "Reload retained old music/player/pause")
	_check(state.gold == saved_gold and not state.has_item("guardian_band") and not state.defeated_bosses.get("abyss_warden", false), "Native lamp return retained unsaved rewards or victory")
	_check(quests.main_quest_rewards.size() == 1 and not quests.claim_main_reward(0, player), "Native reload lost reward receipt")
	_check(not ui.story_player.is_open() and ui.campaign_scene_queue.is_empty(), "Saved return forced opening or stale scene")
	_check(game.get_node("AmbientSoundscape").current_track == state.current_room_id, "Reload retained battle/ending music")
	# Real backup recovery must restore the older receipt/scene snapshot together.
	state.add_gold(50)
	_check(state.save_at_checkpoint(player, quests, player.global_position), "Backup fixture second save failed")
	await process_frame
	var corrupt := FileAccess.open(state.save_path, FileAccess.WRITE)
	corrupt.store_string("intentionally invalid isolated test save")
	corrupt.close()
	old_id = game.get_instance_id()
	ui._continue_saved_game()
	game = await _after_reload(old_id)
	if game == null: quit(1); return
	ui = game.get_node("UI")
	player = game.get_node("Player")
	quests = game.get_node("QuestManager")
	_check(state.gold == saved_gold and quests.main_quest_rewards.size() == 1 and state.story_scenes_seen.get("sentinel", false), "Backup mixed narrative and reward snapshots")
	_check(not ui.story_player.is_open() and not paused, "Backup recovery forced a scene or left a pause")
	# With no lamp, a normal death starts a new run, including the opening.
	state.delete_save()
	player.die()
	old_id = game.get_instance_id()
	ui.restart_button.pressed.emit()
	game = await _after_reload(old_id)
	if game == null: quit(1); return
	ui = game.get_node("UI")
	player = game.get_node("Player")
	quests = game.get_node("QuestManager")
	_check(ui.story_player.active_id == "opening" and paused, "Fresh normal restart skipped the opening")
	_check(not state.opening_after_reload and not state._build_save_data().has("opening_after_reload"), "Opening handoff repeated or leaked into the save")
	_check(state.gold == 0 and quests.main_quest_rewards.is_empty() and state.story_scenes_seen.is_empty(), "Fresh normal restart retained campaign data")
	ui.story_player.finish()
	ui._play_reload_opening()
	_check(not ui.story_player.is_open(), "Consumed opening request repeated the intro")
	# Start a hardcore session, save it, then exercise the actual death/retry button.
	game.get_node("AmbientSoundscape").set_enabled(false)
	state.start_new_game("hardcore")
	state.story_scenes_seen["opening"] = true
	_check(state.save_at_checkpoint(player, quests, player.global_position), "Hardcore fixture save failed")
	await process_frame
	player.die()
	_check(not state.has_save_file(), "Hardcore death retained primary or backup")
	old_id = game.get_instance_id()
	ui.restart_button.pressed.emit()
	game = await _after_reload(old_id)
	if game == null: quit(1); return
	ui = game.get_node("UI")
	_check(state.game_mode == "hardcore" and ui.story_player.active_id == "opening" and paused, "Hardcore retry skipped new-run opening")
	_check(not game.get_node("AmbientSoundscape").enabled, "Fresh run ignored mute preference")
	for voice in game.get_node("AmbientSoundscape").players:
		_check(not voice.playing and voice.stream == null, "Muted restart retained music")
	ui.story_player.finish()
	game.get_node("Player").die()
	old_id = game.get_instance_id()
	ui.switch_mode_button.pressed.emit()
	game = await _after_reload(old_id)
	if game == null: quit(1); return
	ui = game.get_node("UI")
	_check(state.game_mode == "normal" and ui.story_player.active_id == "opening" and paused, "Hardcore-to-normal restart skipped opening")
	ui.story_player.finish()
	_check(not paused and not ui.ending_panel.visible and not ui.game_over_panel.visible, "Fresh run retained old modal")
	# Restart Journey returns to the menu, not straight into another intro.
	old_id = game.get_instance_id()
	ui._restart_journey()
	game = await _after_reload(old_id)
	if game == null: quit(1); return
	ui = game.get_node("UI")
	_check(ui.main_menu_panel.visible and paused and not state.session_started and not ui.story_player.is_open(), "Restart Journey bypassed clean main menu")
	ui.normal_mode_button.pressed.emit()
	_check(state.session_started and ui.story_player.active_id == "opening" and not ui.main_menu_panel.visible, "Menu new-game button lost opening after restart")
	ui.story_player.finish()
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("STORY LIFECYCLE TEST PASSED: native death/reload, saved and backup receipt/scene rollback, old audio release, no-lamp and hardcore retries, one-shot intro, mute, mode switch and clean main-menu restart")
		quit(0)
	else: quit(1)
