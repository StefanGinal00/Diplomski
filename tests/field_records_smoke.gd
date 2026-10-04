extends "res://tests/memory_revelation_smoke.gd"

const Records = preload("res://FieldRecords.gd")
const Cache = preload("res://ResonanceCache.gd")
const ROOMS := {"gallery_supply": "shaft_gallery", "cistern_supply": "shaft_cistern", "gallery_step": "echo_gallery", "archive_shelf": "echo_archive", "ash_forge_supply": "ash_forge", "ash_chapel_reliquary": "ash_chapel", "starfall_vault_depth": "starfall_memory_vault", "starfall_garden_skywalk": "starfall_citadel"}

func _cache(game: Node, id: String) -> Node:
	for node in game.find_children("*", "Area2D", true, false):
		if node.get_script() == Cache and node.cache_id == id: return node
	return null

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_field_records.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player")
	var ui := game.get_node("UI")
	var quests := game.get_node("QuestManager")
	_check(Records.journal(state).is_empty() and Records.count(state) == 0, "New game has pre-discovered records")
	_check(Records.moment("unknown").is_empty(), "Unknown toast accepted")
	state.set_zone_tier("echo_grotto", 1)
	var index := 0
	for id in Records.ENTRIES:
		state.set_current_room(ROOMS[id])
		await process_frame
		var cache := _cache(game, id)
		_check(cache != null, "Record cache not spawned: " + id)
		if cache == null: continue
		_check(cache.has_node("FieldRecordLabel") and "FIELD RECORD" in cache.record_label.text, "Record has no world cue")
		if not cache.required_event_ids.is_empty():
			_check(not cache.open(player) and not Records.found(state, id), "Document bypassed sealed cache")
			for event in cache.required_event_ids: state.unlock_shortcut(event)
		var gold_before: int = state.gold
		_check(cache.open(player), "Native cache could not open: " + id)
		index += 1
		_check(state.gold == gold_before + cache.gold_reward, "Document changed cache gold reward")
		_check(Records.count(state) == index and Records.found(state, id), "Record discovery missing")
		_check(cache.record_label.text == "RECORDED [J]", "Opened cache lost readback hint")
		_check(ui.memory_toast_panel.visible and not paused, "Record discovery paused combat or has no toast")
		_check(Records.ENTRIES[id].text in ui.quest_tracker_label.text, "Full record missing from live journal")
		var before: String = JSON.stringify(state._build_save_data())
		Records.journal(state)
		_check(JSON.stringify(state._build_save_data()) == before, "Reading document changes progress")
		_check(not cache.open(player) and state.gold == gold_before + cache.gold_reward, "Duplicate document repaid rewards")
		for unseen in Records.ENTRIES:
			if not Records.found(state, unseen): _check(Records.ENTRIES[unseen].text not in Records.journal(state), "Unread document spoiled")
		for pair in Records.PAIRS:
			_check((pair[3] in Records.journal(state)) == (Records.found(state, pair[0]) and Records.found(state, pair[1])), "Connection revealed without both sources")
		if index == 1:
			_check(state.save_at_checkpoint(player, quests, player.global_position), "Record snapshot failed")
		_advance_memory(ui)
	_check(index == 8 and "EIGHT ACCOUNTS" in Records.journal(state), "Eight-record conclusion missing")
	for resolution in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		await process_frame
		for id in Records.ENTRIES:
			ui._queue_story_moment("record:" + id, 8)
			await process_frame
			_check(not ui.memory_toast_panel.get_global_rect().intersects(ui.notification_label.get_global_rect()), "Record card covers reward notification")
			_check(ui.memory_text_label.get_minimum_size().y <= ui.memory_text_label.size.y, "Record excerpt overflows card")
			_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(ui.memory_toast_panel.get_global_rect()), "Record card escapes viewport")
			_advance_memory(ui)
	for key in Records.REACTIONS:
		var actor := game.get_node(key)
		actor.current_dialogue_set = -1
		ui._on_npc_interaction_requested(actor)
		await process_frame
		_check(ui.dialogue_text.text == Records.REACTIONS[key][1], "Resident ignores discovered record")
		_check(ui.dialogue_text.get_global_rect().end.y < ui.dialogue_close_button.get_global_rect().position.y, "Record reaction overlaps actions")
		ui._close_dialogue()
	# Mixed queue: a document cannot swallow a native memory revelation.
	ui._queue_story_moment("record:gallery_supply", 1)
	ui._queue_story_moment("memory_sigil_shaft", 1)
	_check(ui.memory_reveal_queue.size() == 1, "Mixed story queue lost entry")
	_advance_memory(ui)
	_check("DROWNED" in ui.memory_title_label.text, "Document replaced the memory sequence")
	_advance_memory(ui)
	_check(state.load_game() and Records.count(state) == 1, "Unsaved records did not roll back")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	ui = game.get_node("UI")
	ui._on_quest_updated()
	_check(Records.ENTRIES.gallery_supply.text in ui.quest_tracker_label.text, "Saved record cannot be reread")
	_check(not ui.memory_toast_panel.visible and ui.memory_reveal_queue.is_empty(), "Reload replays old discoveries")
	_check(_cache(game, "gallery_supply").record_label.text == "RECORDED [J]", "Saved world cue does not restore")
	state.start_new_game("normal")
	_check(Records.journal(state).is_empty(), "New game retains field records")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("FIELD RECORDS TEST PASSED: eight native caches, seals/rewards, cues, journal, pairs, four resident replies, mixed queue and save rollback")
		quit(0)
	else: quit(1)
