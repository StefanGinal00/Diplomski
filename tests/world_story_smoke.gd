extends "res://tests/boss_combat_presentation_smoke.gd"

const Voices = preload("res://ResidentStory.gd")
const World = preload("res://WorldStory.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_world_story.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var ui := game.get_node("UI")
	var cases := 0
	_check(World.chronicle(state).is_empty(), "New journey reveals future history")
	for resolution in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		await process_frame
		for key in Voices.VOICES:
			var actor := game.get_node(key)
			var row: Array = Voices.VOICES[key]
			_check(Voices.identity(actor) == key, "Story voice is bound to wrong resident")
			for phase in range(4):
				state.defeated_bosses.clear()
				state.inventory.clear()
				if phase > 0: state.defeated_bosses[row[0]] = true
				if phase == 2 and not String(row[3]).is_empty(): state.inventory[row[3]] = 1
				if phase == 3: state.defeated_bosses["hollow_sovereign"] = true
				actor.current_dialogue_set = -1
				var selected: Dictionary = Voices.resolve(actor, state)
				_check(selected.is_empty() == (phase == 0), "Future voice leaked before guardian defeat")
				var lines: PackedStringArray = actor.dialogue_lines if selected.is_empty() else selected.lines
				var before: String = JSON.stringify(state._build_save_data())
				for index in range(lines.size()):
					ui._on_npc_interaction_requested(actor)
					await process_frame
					_check(ui.dialogue_text.text == lines[index], "Dialogue order/identity mismatch: " + key)
					_check(not ui.dialogue_primary_button.visible, "Story resident granted a quest action")
					_check(ui.dialogue_text.get_global_rect().end.y < ui.dialogue_close_button.get_global_rect().position.y, "Text overlap: %s phase %d line %d" % [key, phase, index])
					_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(ui.dialogue_panel.get_global_rect()), "Story panel escapes viewport")
					ui._close_dialogue()
					cases += 1
				_check(actor.get_next_line() == lines[0], "Conversation loop skips first line")
				_check(JSON.stringify(state._build_save_data()) == before, "Conversation mutated progress")
	# Mission consequences use current progress before saving, and never phase 2.
	var quests := game.get_node("QuestManager")
	state.defeated_bosses.clear()
	state.inventory.clear()
	for key in Voices.LOCAL_OUTCOMES:
		var actor := game.get_node(key)
		var outcome: Array = Voices.LOCAL_OUTCOMES[key]
		quests.set(outcome[0], 2)
		_check(Voices.resolve(actor, state).is_empty(), "Unclaimed task announced its outcome")
		quests.set(outcome[0], 3)
		var live: Dictionary = Voices.resolve(actor, state)
		_check(live.lines[0] == outcome[1][0], "Unsaved task outcome is stale")
		for line in live.lines:
			ui._on_npc_interaction_requested(actor)
			ui.active_town_line = line
			ui._update_dialogue_content()
			await process_frame
			_check(ui.dialogue_text.get_global_rect().end.y < ui.dialogue_close_button.get_global_rect().position.y, "Task reaction text overlaps actions: " + key)
			ui._close_dialogue()
		var voice: Array = Voices.VOICES[key]
		state.defeated_bosses[voice[0]] = true
		if not String(voice[3]).is_empty():
			state.inventory[voice[3]] = 1
			_check(voice[4][0] in Voices.resolve(actor, state).lines, "Task reaction hid collected memory forever")
		quests.set(outcome[0], 0)
		state.defeated_bosses.clear()
		state.inventory.clear()
	# History is selective, not a spoiler dump. Rematches cannot duplicate it.
	state.start_new_game("normal")
	for event in World.VICTORIES:
		state.defeated_bosses[event[0]] = true
		var history := World.chronicle(state)
		_check(event[2] in history, "Missing victory consequence")
		state.boss_rematches[event[0]] = true
		_check(World.chronicle(state) == history, "Rematch duplicated/rewrote history")
	state.discovered_rooms["echo_haven"] = true
	_check("WHISPERLIGHT" in World.chronicle(state) and "A CITY, NOT A THRONE" not in World.chronicle(state), "Discovery history leaks unseen city")
	var calen := game.get_node("EchoHaven/Calen")
	calen.current_dialogue_set = -1
	calen.get_next_line()
	_check(state.save_at_checkpoint(game.get_node("Player"), quests, Vector2.ZERO), "Story snapshot failed")
	state.start_new_game("normal")
	_check(calen.get_next_line() == calen.dialogue_lines[0], "New game retains epilogue voice")
	# start_new_game intentionally deletes the save: establish a fresh rollback fixture.
	state.defeated_bosses["echo_matriarch"] = true
	_check(state.save_at_checkpoint(game.get_node("Player"), quests, Vector2.ZERO), "Rollback snapshot failed")
	state.defeated_bosses["hollow_sovereign"] = true
	calen.get_next_line()
	_check(state.load_game(), "Story snapshot load failed")
	_check(calen.get_next_line() == Voices.VOICES["EchoHaven/Calen"][1][0], "Reload retained future voice or line index")
	# Atley only interprets all three memories after they have actually been found.
	var atley := game.get_node("StarfallCitadel/Atley")
	for mask in range(8):
		state.inventory.clear()
		var memories := ["memory_sigil_shaft", "memory_sigil_echo", "memory_sigil_ash"]
		for index in range(3):
			if mask & (1 << index): state.inventory[memories[index]] = 1
		ui._on_npc_interaction_requested(atley)
		await process_frame
		_check(("throne fears" in ui.dialogue_text.text) == (mask == 7), "Atley interprets uncollected memories")
		_check(ui.dialogue_text.get_global_rect().end.y < ui.dialogue_close_button.get_global_rect().position.y, "Atley interpretation overlaps actions")
		ui._close_dialogue()
	ui._show_zone_title("echo_haven")
	_check(ui.zone_subtitle_label.text == World.ARRIVALS.echo_haven, "Settlement arrival missing story")
	state.defeated_bosses["hollow_sovereign"] = true
	ui._show_zone_title("echo_haven")
	_check(ui.zone_subtitle_label.text == World.RETURN_ARRIVALS.echo_haven, "Post-victory arrival unchanged")
	ui._show_final_ending()
	await process_frame
	_check(ui.ending_panel.visible and paused, "Ending lost pause/presentation")
	var ending := ui.get_node("EndingPanel/StoryScroll/StoryLabel") as Label
	_check("Eldric" in ending.text and "The road remains" in ending.text, "Ending lacks opening callback")
	_check(ui.get_node("EndingPanel/StoryScroll").get_global_rect().end.y < ui.get_node("EndingPanel/SaveHint").get_global_rect().position.y, "Ending scroll overlaps save hint")
	ui._close_final_ending()
	_check(not paused, "Ending did not restore control")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("WORLD STORY TEST PASSED: ", cases, " resident lines, 12 voices, three viewports, progress/rollback, memory gates, arrivals and ending")
		quit(0)
	else: quit(1)
