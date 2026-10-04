extends "res://tests/boss_combat_presentation_smoke.gd"

const Story = preload("res://MainStory.gd")
const BOSSES := ["void_sentinel", "abyss_warden", "echo_matriarch", "ash_castellan"]

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_main_story.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.process_mode = Node.PROCESS_MODE_DISABLED
	await process_frame
	var ui := game.get_node("UI")
	var quests := game.get_node("QuestManager")
	var player := game.get_node("Player")
	var cases := 0
	for cleared in range(5):
		for mask in range(8):
			for reached in [false, true]:
				state.defeated_bosses.clear()
				for index in range(cleared): state.defeated_bosses[BOSSES[index]] = true
				state.inventory.clear()
				for index in range(3):
					if mask & (1 << index): state.inventory[Story.MEMORIES[index][0]] = 1
				state.discovered_rooms["starfall_sunless_passage"] = reached
				var before: String = JSON.stringify(state._build_save_data())
				var expected: int = cleared if cleared < 4 else (5 if mask == 7 and reached else 4)
				_check(Story.chapter(state) == expected, "Wrong chapter for guardian/memory/route combination")
				ui._on_quest_updated()
				var text: String = ui.quest_tracker_label.text
				_check(text.begins_with("MAIN STORY - ") and "LOCAL TASKS" in text, "Main/local journal split missing")
				for index in range(3):
					_check((String(Story.MEMORIES[index][2]) in text) == bool(mask & (1 << index)), "Unknown memory spoiler or lost collected text")
				_check(JSON.stringify(state._build_save_data()) == before, "Reading journal mutated gameplay/save state")
				cases += 1
	# Rematches never move the main story; rollback derives from native save.
	var chapter_before := Story.chapter(state)
	state.boss_rematches["abyss_warden"] = true
	_check(Story.chapter(state) == chapter_before, "Optional rematch changes main chapter")
	_check(state.save_at_checkpoint(player, quests, player.global_position), "Isolated story save failed")
	state.defeated_bosses["hollow_sovereign"] = true
	_check(Story.chapter(state) == 6 and "Dawn Archive" in Story.journal(state), "Epilogue handoff missing")
	_check(state.load_game() and Story.chapter(state) == chapter_before, "Reload did not roll narrative back")
	# Eldric never calls a living boss defeated, or a defeated boss still alive.
	quests.quest_index = 0
	quests.quest_state = 2
	ui.active_dialogue_npc = null
	ui._update_dialogue_content()
	_check("already opened" in ui.dialogue_text.text, "Eldric ignores early Sentinel victory")
	state.defeated_bosses.erase("void_sentinel")
	ui._update_dialogue_content()
	_check("Sentinel still" in ui.dialogue_text.text, "Eldric skips remaining boss")
	state.start_new_game("normal")
	_check(Story.chapter(state) == 0 and not "MEMORIES CARRIED" in Story.journal(state), "New game retains old story")
	ui.zone_title_panel.show()
	ui._toggle_quests()
	_check(ui.quest_panel.visible and not ui.zone_title_panel.visible and paused, "Chapter journal covered by arrival title or did not pause")
	ui._close_side_panels()
	ui.zone_title_panel.show()
	ui._on_npc_interaction_requested(game.get_node("StarfallCitadel/Rook"))
	await process_frame
	_check(not ui.zone_title_panel.visible and ui.dialogue_text.get_minimum_size().y <= 82, "Rook offer hidden or overflowing")
	_check(ui.dialogue_text.get_global_rect().end.y < ui.dialogue_close_button.get_global_rect().position.y, "Rook offer overlaps actions")
	ui._close_dialogue()
	state.defeated_bosses["void_sentinel"] = true
	quests.quest_index = 0
	quests.quest_state = 0
	ui._update_dialogue_content()
	_check("You opened the road" in ui.dialogue_text.text, "Late Eldric offer contradicts defeated Sentinel")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty(): print("MAIN STORY TEST PASSED: ", cases, " progress combinations, journal integration, spoilers, no mutation, rematches, save rollback, new game, Eldric handoff")
	quit(0 if failures.is_empty() else 1)
