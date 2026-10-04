extends "res://tests/quest_portrait_smoke.gd"

const Route = preload("res://StoryRoute.gd")
const Story = preload("res://MainStory.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_story_route.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var ui := game.get_node("UI")
	var quests := game.get_node("QuestManager")
	for mask in range(8):
		state.inventory.clear()
		if mask & 1: state.inventory["tide_core"] = 1
		if mask & 2: state.inventory["nest_crest"] = 1
		state.unlocked_shortcuts["echo_nest_cleared"] = bool(mask & 4)
		var before: String = JSON.stringify(state._build_save_data())
		var line := Route.echo_goal(state)
		var expected := "Explore the Tide Well" if not mask & 1 else ("Clear the Echo Nest" if mask != 7 else "Enter Resonance Sanctum")
		_check(line.begins_with(expected), "Echo guidance skips missing gate: %d" % mask)
		_check(JSON.stringify(state._build_save_data()) == before, "Echo guidance mutates state")
	for mask in range(32):
		state.inventory.clear()
		for index in range(3):
			if mask & (1 << index): state.inventory[["barracks_insignia", "marshal_emblem", "crucible_core"][index]] = 1
		state.unlocked_shortcuts["ash_forge_fan"] = bool(mask & 8)
		state.unlocked_shortcuts["ash_chapel_bells"] = bool(mask & 16)
		var before: String = JSON.stringify(state._build_save_data())
		var expected := "The three marks"
		if not mask & 1: expected = "Clear the Ember Barracks" if mask & 8 else "Restart the Cinder Forge"
		elif not mask & 2: expected = "Complete the Cinder Coliseum"
		elif not mask & 4: expected = "Balance the Slag Reservoir"
		elif not mask & 16: expected = "Ring the Ashen Chapel"
		_check(Route.ash_goal(state).begins_with(expected), "Ash guidance skips missing gate: %d" % mask)
		_check(JSON.stringify(state._build_save_data()) == before, "Ash guidance mutates state")
	# Read actual scene door requirements, not a duplicate fictional progression.
	for spec in [["AshChapel", "marshal_emblem", "ash_chapel_bells"], ["EchoNest", "nest_crest", "echo_nest_cleared"]]:
		var room: Node = load("res://" + spec[0] + ".tscn").instantiate()
		var found := false
		for door in room.find_children("*", "Area2D", true, false):
			if door.get("required_item_ids") != null and spec[1] in door.required_item_ids:
				found = spec[2] in door.required_event_ids
		_check(found, "Story no longer matches native door: " + spec[0])
		room.free()
	state.defeated_bosses = {"void_sentinel": true, "abyss_warden": true, "echo_matriarch": true}
	_check("first Coliseum trial" in Story.journal(state) and not "Coliseum trial are optional" in Story.journal(state), "Required Coliseum mislabeled optional")
	state.defeated_bosses["ash_castellan"] = true
	state.discovered_rooms["starfall_sunless_passage"] = true
	state.inventory["memory_sigil_shaft"] = 1
	state.inventory["memory_sigil_echo"] = 1
	_check("requires memories from: Ashen Chapel." in Story.journal(state), "Late missing-memory return route incorrect")
	for trace in quests.ECHO_TRACE_IDS: quests.echo_traces[trace] = true
	for report in quests.STARFALL_REPORT_IDS: quests.starfall_reports[report] = true
	quests.hearth_gate_defeated = {"first": true, "second": true}
	state.unlocked_shortcuts["ash_forge_fan"] = true
	var contacts := [
		["echo_survey", "surveyor_npc", "LYRA", "already found", 80],
		["hearth_fan", "hearth_quest_npc", "MIRA", "already restored", 50],
		["hearth_gate", "hearth_gate_quest_npc", "TARIN", "before I could ask", 25],
		["starfall_route", "starfall_route_npc", "ROOK", "already gathered", 100],
	]
	for resolution in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		await process_frame
		for spec in contacts:
			quests.set(spec[0] + "_state", 0)
			ui._on_npc_interaction_requested(get_first_node_in_group(spec[1]))
			_check(spec[3] in ui.dialogue_text.text, "Early work not acknowledged: " + spec[0])
			await _check_layout(ui)
			ui._close_dialogue()
		state.defeated_bosses.clear()
		quests.echo_survey_state = 3
		quests.hearth_fan_state = 3
		for mask in range(8):
			state.inventory.clear()
			if mask & 1: state.inventory["tide_core"] = 1
			if mask & 2: state.inventory["nest_crest"] = 1
			state.unlocked_shortcuts["echo_nest_cleared"] = bool(mask & 4)
			ui._on_npc_interaction_requested(get_first_node_in_group("surveyor_npc"))
			_check(ui.dialogue_text.text == Route.echo_goal(state), "Lyra lost current route hint")
			await _check_layout(ui)
			ui._close_dialogue()
		for mask in range(4):
			state.inventory.clear()
			if mask & 1: state.inventory["marshal_emblem"] = 1
			if mask & 2: state.inventory["crucible_core"] = 1
			ui._on_npc_interaction_requested(get_first_node_in_group("hearth_quest_npc"))
			await _check_layout(ui)
			ui._close_dialogue()
		for sovereign in [false, true]:
			state.defeated_bosses["hollow_sovereign"] = sovereign
			for spec in [["eldric", "Caretaker"], ["lyra", "EchoHaven/LyraSurveyor"], ["mira", "CinderHearth/Mira"]]:
				quests.quest_index = 2
				quests.quest_state = 3
				quests.echo_survey_state = 3
				quests.hearth_fan_state = 3
				var actor := game.get_node_or_null(spec[1])
				if spec[0] == "mira": actor = get_first_node_in_group("hearth_quest_npc")
				ui._on_npc_interaction_requested(actor)
				_check(ui.dialogue_text.text == Route.contact_line(spec[0], state), "Completed contact ignores story")
				await _check_layout(ui)
				ui._close_dialogue()
	# Real connected buttons after victory: unclaimed work must remain claimable.
	for spec in contacts:
		quests.set(spec[0] + "_state", 0)
		ui._on_npc_interaction_requested(get_first_node_in_group(spec[1]))
		var gold_before: int = state.gold
		ui.dialogue_primary_button.pressed.emit()
		_check(quests.get(spec[0] + "_state") == 2, "Early work forced a repeat: " + spec[0])
		ui.dialogue_primary_button.pressed.emit()
		_check(quests.get(spec[0] + "_state") == 3 and state.gold == gold_before + spec[4], "Early-work reward failed")
		ui._close_dialogue()
		ui._on_npc_interaction_requested(get_first_node_in_group(spec[1]))
		ui.dialogue_primary_button.pressed.emit()
		_check(state.gold == gold_before + spec[4], "Repeated dialogue duplicated reward")
		ui._close_dialogue()
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("STORY ROUTE TEST PASSED: 40 gate combinations, native requirements, late memories, four early tasks, three return contacts, three viewports, rewards once")
		quit(0)
	else: quit(1)

func _check_layout(ui: Node) -> void:
	await process_frame
	_check(ui.dialogue_text.get_minimum_size().y <= 82, "Continuity dialogue exceeds text budget: " + ui.dialogue_text.text)
	_check(ui.dialogue_text.get_global_rect().end.y < ui.dialogue_close_button.get_global_rect().position.y, "Continuity dialogue overlaps actions")
	_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(ui.dialogue_panel.get_global_rect()), "Continuity dialogue escapes viewport")
