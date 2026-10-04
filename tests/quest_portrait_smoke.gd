extends "res://tests/npc_portrait_smoke.gd"


func _inspect_dialogue(ui: Node, actor: Node, speaker: String, action_expected: bool) -> void:
	ui._update_dialogue_content()
	await process_frame
	_check(ui.dialogue_portrait.visible and ui.dialogue_portrait.texture == actor.portrait_texture, speaker + " portrait missing or mixed up")
	_check(ui.speaker_label.text == speaker, "Speaker identity changed")
	_check(ui.dialogue_primary_button.visible == action_expected, speaker + " quest action visibility changed")
	_separate(ui.dialogue_portrait, [ui.speaker_label, ui.dialogue_text, ui.dialogue_primary_button, ui.dialogue_close_button])
	_check(ui.dialogue_text.get_minimum_size().y <= 82, speaker + " line exceeds reserved text height")
	_check(ui.dialogue_text.get_global_rect().end.y < ui.dialogue_close_button.get_global_rect().position.y, speaker + " text overlaps actions")
	_check(not ui.dialogue_primary_button.get_global_rect().intersects(ui.dialogue_close_button.get_global_rect()), "Quest/close buttons overlap")
	_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(ui.dialogue_panel.get_global_rect()), "Quest panel escapes viewport")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_quest_portrait_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var ui := game.get_node("UI")
	var quests := game.get_node("QuestManager")
	var eldric := game.get_node("Caretaker")
	var lyra := game.get_node("EchoHaven/LyraSurveyor")
	var calen := game.get_node("EchoHaven/Calen")
	var gold_before: int = state.gold
	for data in [[eldric, "eldric"], [lyra, "lyra"]]:
		var texture: Texture2D = data[0].get_portrait_texture()
		_check(texture != null and texture.resource_path.ends_with(data[1] + "_portrait_v1.png"), "Quest portrait assignment incorrect")
		_check(texture.get_size() == Vector2(256, 256), "Quest portrait import budget incorrect")
	for resolution in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		await process_frame
		eldric.interaction_requested.emit(eldric)
		_check(ui.dialogue_panel.visible and not ui.player.is_physics_processing(), "Eldric interaction did not pause player")
		for quest_index in range(3):
			quests.quest_index = quest_index
			for phase in range(4 if quest_index == 2 else 3):
				quests.quest_state = phase
				await _inspect_dialogue(ui, eldric, "ELDRIC", phase in [0, 2])
		ui._close_dialogue()
		lyra.interaction_requested.emit(lyra)
		for phase in range(4):
			quests.echo_survey_state = phase
			await _inspect_dialogue(ui, lyra, "LYRA", phase in [0, 2])
		ui._close_dialogue()
		ui._on_npc_interaction_requested(calen)
		_check(not ui.dialogue_portrait.visible and ui.dialogue_portrait.texture == null and ui.dialogue_text.offset_left == 20, "Quest portrait leaked to resident without art")
		ui._close_dialogue()
	_check(state.gold == gold_before, "Inspecting portrait states granted rewards")
	# Drive the actual connected button and quest APIs, not only layout fixtures.
	quests.quest_index = 0
	quests.quest_state = 0
	quests.quest_progress = 0
	quests.defeated_enemies = 0
	eldric.interaction_requested.emit(eldric)
	ui.dialogue_primary_button.pressed.emit()
	_check(quests.quest_state == 1 and not ui.dialogue_primary_button.visible, "Accept Mission stopped working")
	for _index in range(3):
		quests.report_enemy_defeated()
	ui._update_dialogue_content()
	_check(quests.quest_state == 2 and ui.dialogue_primary_button.visible, "Completed quest cannot be claimed")
	ui.dialogue_primary_button.pressed.emit()
	_check(state.gold == gold_before + 30 and quests.quest_index == 1, "Quest reward/advance changed")
	_check(ui.dialogue_portrait.texture == eldric.portrait_texture, "Quest advance lost Eldric portrait")
	ui._close_dialogue()
	quests.echo_survey_state = 0
	quests.echo_traces.clear()
	lyra.interaction_requested.emit(lyra)
	ui.dialogue_primary_button.pressed.emit()
	_check(quests.echo_survey_state == 1, "Accept Survey stopped working")
	for trace_id in quests.ECHO_TRACE_IDS:
		quests.report_item_collected(trace_id)
	ui._update_dialogue_content()
	ui.dialogue_primary_button.pressed.emit()
	_check(quests.echo_survey_state == 3 and state.gold == gold_before + 110 and state.has_item("ether_dust", 2), "Survey reward changed")
	ui.dialogue_primary_button.pressed.emit()
	_check(state.gold == gold_before + 110, "Survey reward duplicated")
	_check(ui.dialogue_portrait.texture == lyra.portrait_texture and not ui.dialogue_primary_button.visible, "Completed survey presentation incorrect")
	ui._close_dialogue()
	_check(ui.player.is_physics_processing() and not ui.dialogue_portrait.visible, "Close did not restore player/hide art")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("QUEST PORTRAIT TEST PASSED: Eldric/Lyra identity, 14 dialogue states, three viewports, actions, rewards, fallback and close")
		quit(0)
	else:
		quit(1)
