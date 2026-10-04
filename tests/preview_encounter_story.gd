extends "res://tests/preview_characters.gd"

func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_encounter_story_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var ui := game.get_node("UI")
	for id in ["void_sentinel", "abyss_warden", "echo_matriarch"]:
		state.defeated_bosses[id] = true
	var boss: Node2D
	for actor in get_nodes_in_group("boss"):
		if str(actor.get("boss_id")) == "ash_castellan": boss = actor
	var camera := Camera2D.new()
	root.add_child(camera)
	camera.global_position = boss.global_position + Vector2(0, -80)
	camera.zoom = Vector2(1.2, 1.2)
	camera.make_current()
	camera.force_update_scroll()
	game.get_node("Player").global_position = boss.global_position + Vector2(-170, 0)
	state.set_current_room("ash_throne")
	# Render the actual room title without the separate first-region chapter banner.
	ui._show_zone_title("ash_throne")
	await create_timer(0.35).timeout
	await _capture("encounter_castellan_approach")
	boss.take_damage(999)
	await create_timer(0.35).timeout
	await _capture("encounter_awakening_first")
	await create_timer(3.1).timeout
	ui._process(0.0)
	await create_timer(0.3).timeout
	await _capture("encounter_castellan_aftermath")
	ui._clear_memory_reveals()
	state.discovered_rooms["ash_arena"] = true
	state.unlock_shortcut("ash_arena_cleared")
	await create_timer(0.3).timeout
	await _capture("encounter_marshal_aftermath")
	ui._clear_memory_reveals()
	ui._toggle_quests()
	await process_frame
	await process_frame
	var text: String = ui.quest_tracker_label.text
	var prefix := text.substr(0, text.find("AT THE THRESHOLD"))
	# Measure the same wrapped label to scroll to the new section in the full journal.
	var measure := Label.new()
	measure.add_theme_font_size_override("font_size", 14)
	measure.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	measure.size.x = ui.quest_tracker_label.size.x
	measure.text = prefix
	measure.visible = false
	ui.add_child(measure)
	await process_frame
	ui.quest_tracker_label.get_parent().scroll_vertical = int(measure.get_minimum_size().y)
	measure.queue_free()
	await _capture("encounter_journal")
	ui._close_side_panels()
	game.queue_free()
	camera.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
