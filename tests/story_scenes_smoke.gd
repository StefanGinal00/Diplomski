extends "res://tests/boss_combat_presentation_smoke.gd"
const Scenes = preload("res://StoryScenes.gd")
const Campaign = preload("res://MainQuest.gd")

func _complete(state: Node, stages: int) -> void:
	for index in range(stages):
		for goal in Campaign.STEPS[index].goals:
			match goal[0]:
				"boss": state.defeated_bosses[goal[1]] = true
				"item": state.inventory[goal[1]] = 1
				"event": state.unlocked_shortcuts[goal[1]] = true
				"room": state.discovered_rooms[goal[1]] = true

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_story_scenes.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var ui := game.get_node("UI")
	var player := game.get_node("Player")
	var quests := game.get_node("QuestManager")
	var cinema: Node = ui.story_player
	_check(not cinema.is_open(), "Direct test/scene boot unexpectedly played intro")
	_check(not cinema.play("haven") and not cinema.play("memories"), "Future chapter can be spoiled")
	ui._start_new_mode("normal")
	_check(cinema.is_open() and cinema.active_id == "opening" and paused, "Actual new-game UI failed to play opening")
	var gold: int = state.gold
	var points: int = player.skill_points
	var receipt_before: Dictionary = quests.main_quest_rewards.duplicate()
	# Drive the same timeline as _process deterministically, without real-time sleeps.
	_check(cinema.text_label.visible_characters == 0, "Text did not start hidden")
	cinema._tick(1.35)
	_check(cinema.text_label.visible_characters > 0 and cinema.text_label.visible_characters < cinema.text_label.get_total_character_count(), "Narration does not reveal gradually while paused")
	cinema.advance()
	_check(cinema.page == 0 and cinema.text_label.visible_characters == -1, "First click must reveal, not discard unread text")
	cinema.advance()
	_check(cinema.page == 1 and not state.story_scenes_seen.has("opening"), "Page advance prematurely marked whole scene")
	_check(cinema.illustration.texture.resource_path == Scenes.SCENES.opening.images[1], "Image did not follow narration")
	cinema._tick(0.4)
	_check(cinema.outgoing.texture != null and cinema.illustration.modulate.a > 0.0 and cinema.illustration.modulate.a < 1.0, "Crossfade missing")
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	cinema._input(escape)
	_check(not cinema.is_open() and not paused and state.story_scenes_seen.opening, "Skip did not close/restore/acknowledge")
	cinema._tick(999.0)
	_check(not cinema.is_open() and cinema.illustration.texture == null and cinema.outgoing.texture == null, "Skipped timeline kept running or retained images")
	_check(state.gold == gold and player.skill_points == points and quests.main_quest_rewards == receipt_before, "Intro grants rewards")
	_complete(state, 2)
	state.story_scenes_seen["sentinel"] = true
	_check(Scenes.pending(state) == "haven" and not Scenes.unlocked(state, "memories"), "Chapter thresholds incorrect")
	ui._on_quest_updated()
	_check(not cinema.is_open(), "Quest update interrupted gameplay with cinema")
	# Auto offer requires a safe lamp, not just any save or boss/claim event.
	player.global_position = Vector2(-9999, -9999)
	ui._play_pending_story()
	_check(not cinema.is_open(), "Chapter opened away from lamp")
	var lamp := game.get_node("EchoHaven/HavenLamp")
	player.global_position = lamp.global_position
	ui.boss_health_panel.show()
	ui._play_pending_story()
	_check(not cinema.is_open(), "Chapter covered boss warning")
	ui.boss_health_panel.hide()
	var room_transition := root.get_node("RoomTransition")
	room_transition.is_transitioning = true
	ui._play_pending_story()
	_check(not cinema.is_open(), "Lamp offer overlapped room transition")
	room_transition.is_transitioning = false
	_check(state.save_at_checkpoint(player, quests, player.global_position), "Chapter rest save failed")
	await process_frame
	_check(cinema.active_id == "haven" and paused, "Safe-rest completion did not offer unlocked chapter")
	while cinema.is_open(): cinema.advance()
	_check(not paused and state.story_scenes_seen.haven, "Chapter completion did not restore play")
	_check(state.save_at_checkpoint(player, quests, player.global_position), "Viewed-scene save failed")
	await process_frame
	_check(not cinema.is_open(), "Viewed chapter repeated at next rest")
	_complete(state, 6)
	for id in ["echo", "marshal", "fortress", "castellan"]: state.story_scenes_seen[id] = true
	_check(Scenes.pending(state) == "memories", "Memory synthesis did not unlock from six main stages")
	_check(cinema.play("memories"), "Timed replay failed")
	cinema.auto_button.button_pressed = false
	cinema._tick(120.0)
	_check(cinema.page == 0 and cinema.is_open(), "Manual mode auto-advanced")
	cinema.auto_button.button_pressed = true
	cinema._tick(1.0)
	_check(cinema.page == 0, "Reenabling auto skipped reading hold")
	for index in range(3):
		cinema._tick(cinema.reveal_end + cinema.hold_seconds + 0.1)
	_check(not cinema.is_open() and not paused, "Automatic sequence did not complete and restore pause")
	cinema.play("memories")
	cinema.cancel()
	cinema.play("opening")
	cinema._tick(0.2)
	_check(cinema.page == 0 and cinema.active_id == "opening", "Old scene timer advanced new replay")
	cinema.cancel()
	# Thirty-one pages, three viewport sizes; no textbox/button collisions.
	state.defeated_bosses["starfall_guardian"] = true
	state.defeated_bosses["hollow_sovereign"] = true
	for resolution in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		await process_frame
		for id in Scenes.ORDER:
			_check(Scenes.SCENES[id].images.size() == Scenes.SCENES[id].pages.size(), "Missing image/narration pairing")
			_check(Scenes.SCENES[id].images[0] != Scenes.SCENES[id].images[1] and Scenes.SCENES[id].images[1] != Scenes.SCENES[id].images[2], "Repeated scene illustration")
			_check(cinema.play(id), "Unlocked replay failed")
			_check(cinema.illustration.texture != null and cinema.illustration.texture.get_width() >= 1600, "Cutscene missing high-resolution art")
			for page in range(Scenes.SCENES[id].pages.size()):
				_check(cinema.illustration.texture.resource_path == Scenes.SCENES[id].images[page], "Wrong illustration for page")
				_check(cinema.illustration.texture.get_width() >= 1600, "Page art below target resolution")
				cinema.advance() # reveal the complete text, then inspect and continue
				await process_frame
				_check(cinema.text_label.get_minimum_size().y <= cinema.text_label.size.y, "Narration clipped")
				_check(cinema.text_label.get_global_rect().end.y <= cinema.next_button.get_global_rect().position.y, "Narration overlaps controls")
				_check(not cinema.next_button.get_global_rect().intersects(cinema.skip_button.get_global_rect()), "Scene controls overlap")
				_check(not cinema.auto_button.get_global_rect().intersects(cinema.skip_button.get_global_rect()), "Auto control overlaps skip")
				_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(cinema.next_button.get_global_rect()), "Scene controls outside viewport")
				cinema.advance()
	# Opening library from a paused quest log must return to that paused log.
	ui._toggle_quests()
	ui.get_node("QuestPanel/StoryScenesButton").pressed.emit()
	_check(cinema.is_open() and paused and cinema.replay_list.get_child_count() == Scenes.ORDER.size(), "Replay library unavailable")
	cinema.replay_list.get_child(Scenes.ORDER.find("haven")).pressed.emit()
	_check(cinema.active_id == "haven", "Replay button opened wrong chapter")
	cinema.finish()
	_check(paused and ui.quest_panel.visible, "Closing replay unpaused behind quest log")
	ui._close_side_panels()
	_check(state.gold == gold and player.skill_points == points and quests.main_quest_rewards == receipt_before, "Scenes changed main rewards")
	_check(state.load_game(), "Viewed-scene snapshot cannot load")
	_check(state.story_scenes_seen.has("haven") and not state.story_scenes_seen.has("memories"), "Unsaved scene acknowledgments did not roll back")
	var legacy: Dictionary = state._build_save_data().duplicate(true)
	legacy.erase("story_scenes_seen")
	state._apply_save_data(legacy)
	_check(Scenes.pending(state).is_empty() and Scenes.unlocked(state, "haven"), "Legacy save forces scene backlog or loses replay")
	cinema.play("haven")
	ui._show_final_ending()
	_check(not cinema.is_open() and ui.ending_panel.visible and paused, "Cutscene obscures finale")
	ui._close_final_ending()
	state.start_new_game("normal")
	_check(state.story_scenes_seen.is_empty() and not Scenes.unlocked(state, "haven"), "New game retains old scenes")
	cinema.play("opening")
	ui._on_player_died()
	_check(not cinema.is_open() and ui.game_over_panel.visible and not state.story_scenes_seen.has("opening"), "Death did not cancel an unacknowledged scene")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("STORY SCENES TEST PASSED: 31 paired shots across ten events, gradual text, crossfade, auto/manual, interruption cleanup, chapter gating, safe rest, three sizes, pause ownership, save rollback, legacy migration and finale")
		quit(0)
	else: quit(1)
