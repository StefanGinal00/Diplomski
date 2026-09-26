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
	state.save_path = "res://_tmp_echo_survey_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var ui = game.get_node("UI")
	var player = game.get_node("Player")
	var quests = game.get_node("QuestManager")
	var lyra = game.get_node("EchoHaven/LyraSurveyor")
	lyra.interaction_requested.emit(lyra)
	_check(ui.dialogue_panel.visible and ui.speaker_label.text == "LYRA", "Lyra is not connected to the dialogue UI")
	ui._on_dialogue_primary_pressed()
	_check(int(quests.echo_survey_state) == 1, "Echo Survey did not start")
	_check("Echo Survey 0/3" in ui.quest_tracker_label.text, "Quest menu does not track the survey")
	ui._close_dialogue()
	var gallery_trace = game.get_node("EchoGallery/GalleryTrace")
	gallery_trace._on_body_entered(player)
	_check(quests.get_echo_survey_progress() == 1 and quests.has_collected_quest_item("echo_trace_gallery"), "Gallery trace did not count")
	_check("ECHO TRACE FOUND" in ui.notification_label.text, "Picking up a quest trace gave no feedback")
	quests.report_item_collected("echo_trace_gallery")
	_check(quests.get_echo_survey_progress() == 1, "A trace counted twice")
	state.start_merchant_quest()
	ui._toggle_quests()
	await process_frame
	var quest_scroll = ui.quest_panel.get_node("QuestScroll")
	_check(ui.quest_tracker_label.get_minimum_size().y <= ui.quest_tracker_label.size.y, "Quest text is clipped with concurrent side quests: label min=%s actual=%s, scroll=%s bar max=%s" % [ui.quest_tracker_label.get_minimum_size().y, ui.quest_tracker_label.size.y, quest_scroll.size.y, quest_scroll.get_v_scroll_bar().max_value])
	ui._toggle_quests()
	_check(state.save_at_checkpoint(player, quests, player.global_position, "survey_test", "Survey Test", "echo_grotto"), "Partial survey did not save")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Partial survey did not load")
	var resumed = load("res://Game.tscn").instantiate()
	root.add_child(resumed)
	current_scene = resumed
	await process_frame
	await process_frame
	var resumed_quests = resumed.get_node("QuestManager")
	var resumed_ui = resumed.get_node("UI")
	var resumed_player = resumed.get_node("Player")
	_check(resumed_quests.get_echo_survey_progress() == 1 and int(resumed_quests.echo_survey_state) == 1, "Partial survey state was not restored")
	_check(not resumed.get_node("EchoGallery").has_node("GalleryTrace"), "Collected Gallery trace respawned after load")
	_check(resumed.get_node("PrismArchive").has_node("ArchiveTrace") and resumed.get_node("TideWell").has_node("WellTrace"), "Uncollected traces disappeared")
	resumed.get_node("PrismArchive/ArchiveTrace")._on_body_entered(resumed_player)
	resumed.get_node("TideWell/WellTrace")._on_body_entered(resumed_player)
	_check(resumed_quests.get_echo_survey_progress() == 3 and int(resumed_quests.echo_survey_state) == 2, "Survey was not ready after three traces")
	_check("RETURN TO LYRA" in resumed_ui.notification_label.text, "Final quest trace did not point back to Lyra")
	_check("Return to Lyra" in resumed_ui.quest_tracker_label.text, "Quest menu did not point back to Lyra")
	var resumed_lyra = resumed.get_node("EchoHaven/LyraSurveyor")
	resumed_lyra.interaction_requested.emit(resumed_lyra)
	_check(resumed_ui.speaker_label.text == "LYRA" and resumed_ui.dialogue_primary_button.visible, "Ready survey cannot be turned in")
	resumed_ui._on_dialogue_primary_pressed()
	_check(int(resumed_quests.echo_survey_state) == 3 and state.gold == 80 and state.has_item("ether_dust", 2), "Survey reward missing")
	_check(not resumed_quests.turn_in_echo_survey(resumed_player) and state.gold == 80, "Survey reward can be claimed twice")
	resumed_ui._close_dialogue()
	_check(state.save_at_checkpoint(resumed_player, resumed_quests, resumed_player.global_position, "survey_test", "Survey Test", "echo_grotto"), "Completed survey did not save")
	resumed.queue_free()
	await process_frame
	_check(state.load_game(), "Completed survey did not load")
	var completed = load("res://Game.tscn").instantiate()
	root.add_child(completed)
	current_scene = completed
	await process_frame
	_check(int(completed.get_node("QuestManager").echo_survey_state) == 3 and state.gold == 80, "Completed survey was not restored")
	state.delete_save()
	completed.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("ECHO SURVEY TEST PASSED")
		quit(0)
	else:
		print("ECHO SURVEY TEST FAILED: ", failures)
		quit(1)
