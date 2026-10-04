extends "res://tests/npc_portrait_smoke.gd"

const ACTORS := {
	"CinderHearth/Mira": "mira", "CinderHearth/Tarin": "tarin",
	"CinderHearth/Quartermaster": "korin", "CinderHearth/Anvil": "selen",
	"EchoHaven/GlowmarketTrader": "nalim", "EchoHaven/Ivara": "ivara",
	"StarfallCitadel/MarketTrader": "nalia", "StarfallCitadel/Apothecary": "aurel",
}


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_settlement_portrait_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var ui := game.get_node("UI")
	var quests := game.get_node("QuestManager")
	var identities := {}
	for resolution in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		await process_frame
		for path in ACTORS:
			var npc := game.get_node(path)
			var portrait: Texture2D = npc.get_portrait_texture()
			_check(portrait != null, "Missing portrait: " + path)
			if portrait == null:
				continue
			_check(portrait.resource_path.ends_with(ACTORS[path] + "_portrait_v1.png"), "Wrong identity: " + path)
			_check(portrait.get_size() == Vector2(256, 256), "Portrait import budget: " + path)
			identities[portrait.resource_path] = true
			ui._on_npc_interaction_requested(npc)
			await process_frame
			if "service_kind" in npc:
				_check(ui.shop_portrait.texture == portrait and ui.shop_portrait.visible, "Service missing portrait: " + path)
				_separate(ui.shop_portrait, [ui.shop_title_label, ui.shop_gold_label, ui.shop_item_list, ui.shop_buy_tab_button, ui.shop_forge_tab_button])
				_check(ui.shop_title_label.get_minimum_size().x <= ui.shop_title_label.size.x, "Service title overflows: " + path)
				_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(ui.shop_panel.get_global_rect()), "Shop outside screen")
				ui._close_shop()
				_check(ui.shop_portrait.texture == null and not paused, "Service close retained art/pause")
			else:
				_check(ui.dialogue_portrait.texture == portrait and ui.dialogue_portrait.visible, "Resident missing portrait: " + path)
				_separate(ui.dialogue_portrait, [ui.speaker_label, ui.dialogue_text, ui.dialogue_primary_button, ui.dialogue_close_button])
				_check(ui.dialogue_text.get_minimum_size().y <= ui.dialogue_text.size.y, "Resident text overflows: " + path)
				if ACTORS[path] in ["mira", "tarin"]:
					var state_key := "hearth_fan_state" if ACTORS[path] == "mira" else "hearth_gate_state"
					for quest_stage in range(4):
						quests.set(state_key, quest_stage)
						ui._update_dialogue_content()
						await process_frame
						_check(ui.dialogue_text.get_minimum_size().y <= ui.dialogue_text.size.y, "Quest stage overflows: " + path)
						_check(ui.dialogue_primary_button.visible == (quest_stage in [0, 2]), "Quest action visibility changed")
						_separate(ui.dialogue_portrait, [ui.dialogue_text, ui.dialogue_primary_button, ui.dialogue_close_button])
					quests.set(state_key, 0)
				else:
					for line in npc.dialogue_lines + npc.timeline_dialogue_lines + npc.victory_dialogue_lines:
						ui.active_town_line = line
						ui._update_dialogue_content()
						await process_frame
						_check(ui.dialogue_text.get_minimum_size().y <= ui.dialogue_text.size.y, "Ivara line overflows")
				ui._close_dialogue()
				_check(ui.dialogue_portrait.texture == null, "Resident close retained art")
		ui._on_npc_interaction_requested(game.get_node("EchoHaven/Calen"))
		_check(not ui.dialogue_portrait.visible, "Portrait leaked to unassigned resident")
		ui._close_dialogue()
	_check(identities.size() == 8, "Batch did not provide eight unique identities")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("SETTLEMENT PORTRAIT TEST PASSED: eight unique identities, 256px imports, resident/quest/shop/forge layout, three viewports, fallback and close cleanup")
		quit(0)
	else:
		quit(1)
