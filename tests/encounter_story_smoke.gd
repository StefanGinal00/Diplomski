extends "res://tests/memory_revelation_smoke.gd"

const Story = preload("res://EncounterStory.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_encounter_story.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var ui := game.get_node("UI")
	_check(Story.journal(state).is_empty(), "Undiscovered encounters spoil journal")
	for room_id in Story.APPROACHES:
		state.discovered_rooms[room_id] = true
		var before: String = JSON.stringify(state._build_save_data())
		_check(Story.APPROACHES[room_id][2] in Story.journal(state), "Discovered approach missing")
		for unseen in Story.APPROACHES:
			if not state.discovered_rooms.get(unseen, false):
				_check(Story.APPROACHES[unseen][2] not in Story.journal(state), "Undiscovered approach spoiled")
		_check(JSON.stringify(state._build_save_data()) == before, "Approach prose changes progress")
	# Six cards and six short arrival lines fit the existing UI, without a new panel.
	for resolution in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		await process_frame
		for room_id in Story.APPROACHES:
			ui._show_zone_title(room_id)
			await process_frame
			_check(ui.zone_subtitle_label.get_minimum_size().x <= 374, "Approach subtitle exceeds panel: " + room_id)
		ui._dismiss_zone_title()
		for boss_id in Story.AFTERMATH:
			ui._queue_story_moment("victory:" + boss_id, 0)
			await process_frame
			_check(ui.memory_title_label.text == Story.AFTERMATH[boss_id][0] and not paused, "Aftermath missing or blocking play")
			_check(ui.memory_text_label.get_minimum_size().y <= ui.memory_text_label.size.y, "Aftermath text clipped")
			_check(ui.memory_status_label.get_minimum_size().x <= ui.memory_status_label.size.x, "Aftermath status clipped")
			_check(not ui.memory_toast_panel.get_global_rect().intersects(ui.notification_label.get_global_rect()), "Aftermath covers rewards")
			_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(ui.memory_toast_panel.get_global_rect()), "Aftermath outside viewport")
			_advance_memory(ui)
	# Drive native deaths: the state must be recorded before a story can appear.
	for boss in get_nodes_in_group("boss"):
		var id: String = str(boss.get("boss_id"))
		if not Story.AFTERMATH.has(id): continue
		ui._present_encounter_story(id)
		_check(ui.memory_reveal_queue.is_empty() and not ui.memory_toast_panel.visible, "Victory announced before death")
		boss.take_damage(999)
		_check(Story.cleared(state, id) and ui.presented_encounter_stories.has(id), "Native defeat lost story: " + id)
		ui._dismiss_zone_title()
		ui._show_next_memory_reveal()
		_check(ui.memory_title_label.text == Story.AFTERMATH[id][0], "Wrong native defeat card")
		if id == "ash_castellan":
			state.current_room_id = "ash_throne"
			ui._update_objective_label()
			_check(ui.objective_label.get_minimum_size().x <= ui.objective_panel.size.x, "Castellan aftermath objective overflows HUD")
		_advance_memory(ui)
		ui._on_boss_defeated(boss)
		_check(not ui.memory_toast_panel.visible and ui.memory_reveal_queue.is_empty(), "Duplicate defeat repeats story")
		if boss.get("is_rematch") != null:
			ui.presented_encounter_stories.erase(id)
			boss.is_rematch = true
			ui._on_boss_defeated(boss)
			_check(not ui.memory_toast_panel.visible and ui.memory_reveal_queue.is_empty(), "Rematch repeats first victory")
	# Marshal's individual death is not enough: surviving guards must still fall.
	ui._present_encounter_story("ember_marshal")
	_check(not ui.memory_toast_panel.visible, "Marshal story appeared before arena clear")
	ui._show_zone_banner("AWAKENED", "STRONGER ENEMIES", 2.8)
	state.unlock_shortcut("ash_arena_cleared")
	_check(ui.zone_title_panel.visible and not ui.memory_toast_panel.visible and ui.memory_reveal_queue.size() == 1, "Aftermath swallowed warning or failed to wait")
	ui._dismiss_zone_title()
	ui._process(0.0)
	_check(ui.memory_title_label.text == Story.AFTERMATH.ember_marshal[0], "Arena completion lost Marshal aftermath")
	_check(Story.AFTERMATH.ember_marshal[1] in ui.quest_tracker_label.text, "Marshal conclusion cannot be reread")
	_advance_memory(ui)
	# Existing memories/records keep their order and three-sigil counters.
	ui._queue_story_moment("record:gallery_supply", 1)
	ui._queue_story_moment("victory:void_sentinel", 0)
	ui._queue_story_moment("memory_sigil_shaft", 1)
	_advance_memory(ui)
	_check(ui.memory_title_label.text == Story.AFTERMATH.void_sentinel[0], "Mixed queue lost aftermath")
	_advance_memory(ui)
	_check("MEMORY 1/3" in ui.memory_status_label.text, "Aftermath changed memory counter")
	_advance_memory(ui)
	_check(state.save_at_checkpoint(game.get_node("Player"), game.get_node("QuestManager"), Vector2.ZERO), "Encounter save failed")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Encounter save load failed")
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	ui = game.get_node("UI")
	_check(not ui.memory_toast_panel.visible and ui.memory_reveal_queue.is_empty(), "Reload repeats victory stories")
	_check(Story.AFTERMATH.ember_marshal[1] in Story.journal(state), "Saved Marshal conclusion lost")
	for room_id in Story.APPROACHES:
		if room_id == "starfall_hollow_throne": continue
		_check(Story.arrival(room_id, state) == Story.RETURNS[room_id], "Return still describes a living guardian")
	ui._queue_story_moment("victory:void_sentinel", 0)
	ui._show_final_ending()
	_check(not ui.memory_toast_panel.visible and ui.memory_reveal_queue.is_empty(), "Aftermath obscures finale")
	ui._close_final_ending()
	state.start_new_game("normal")
	_check(Story.journal(state).is_empty() and ui.presented_encounter_stories.is_empty(), "New game retains encounter story")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("ENCOUNTER STORY TEST PASSED: native deaths, six approaches/aftermaths, three viewports, warnings, rematches, mixed queue, save/load and finale")
		quit(0)
	else: quit(1)
