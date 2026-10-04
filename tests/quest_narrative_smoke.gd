extends "res://tests/quest_portrait_smoke.gd"

const Narrative = preload("res://QuestNarrative.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_quest_narrative.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var ui := game.get_node("UI")
	var quests := game.get_node("QuestManager")
	var roles := {
		"echo_survey": ["surveyor_npc", "LYRA"],
		"hearth_fan": ["hearth_quest_npc", "MIRA"],
		"hearth_gate": ["hearth_gate_quest_npc", "TARIN"],
		"starfall_route": ["starfall_route_npc", "ROOK"],
		"starfall_courier": ["starfall_route_npc", "ROOK"],
		"dawn_archive": ["dawn_archive_npc", "ATLEY"],
	}
	_check(Narrative.task_note("dawn_archive", 0).is_empty(), "Unaccepted epilogue reveals its resolution")
	state.defeated_bosses["hollow_sovereign"] = true
	for resolution in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		await process_frame
		for task_id in roles:
			var role: Array = roles[task_id]
			var actor := get_first_node_in_group(role[0])
			_check(actor != null, "Missing quest contact: " + role[0])
			ui._on_npc_interaction_requested(actor)
			for phase in range(4):
				if task_id == "starfall_courier": quests.starfall_route_state = 3
				ui.starfall_route_claimed_this_talk = task_id == "starfall_route" and phase == 3
				quests.set(task_id + "_state", phase)
				var quest_before: String = JSON.stringify(quests.get_save_state())
				var state_before: String = JSON.stringify(state._build_save_data())
				ui._on_quest_updated()
				if actor.get_portrait_texture() != null:
					await _inspect_dialogue(ui, actor, role[1], phase in [0, 2])
				else:
					await process_frame
					_check(not ui.dialogue_portrait.visible and ui.dialogue_portrait.texture == null, "Portrait leaked to speaker without art")
					_check(ui.speaker_label.text == role[1] and ui.dialogue_primary_button.visible == (phase in [0, 2]), "Speaker/action mismatch")
					_check(ui.dialogue_text.get_global_rect().end.y < ui.dialogue_close_button.get_global_rect().position.y, "%s phase %d overlaps actions" % [role[1], phase])
					_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(ui.dialogue_panel.get_global_rect()), "Dialogue escapes viewport")
				var note := Narrative.task_note(task_id, phase)
				_check(note.is_empty() or note in ui.quest_tracker_label.text, "Journal lost mission context/outcome")
				_check(("RESOLVED" in note) == (phase == 3), "Mission resolved before reward turn-in")
				_check(JSON.stringify(quests.get_save_state()) == quest_before and JSON.stringify(state._build_save_data()) == state_before, "Story presentation changed progress/rewards")
			ui._close_dialogue()
	for index in range(3):
		quests.quest_index = index
		_check(not Narrative.local_purpose(quests).is_empty(), "Eldric mission lacks story reason")
	quests.quest_index = 1
	_check("not one of the three" in Narrative.local_purpose(quests), "Personal sigil confused with main memories")
	quests.quest_index = 2
	_check("optional" in Narrative.local_purpose(quests), "Rematch became mandatory in journal")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("QUEST NARRATIVE TEST PASSED: six mission arcs, 24 states, three viewports, outcomes and read-only progress")
		quit(0)
	else: quit(1)
