extends "res://tests/starfall_field_operations_smoke.gd"


func _layout(office: Node) -> void:
	_check(office.table.get_combined_minimum_size().x <= 488, "Office table exceeds board width")
	_check(office.table.position.y + office.table.size.y + 4 <= office.summary.position.y, "Office rows overlap summary")
	_check(office.summary.get_minimum_size().x <= 488 and office.summary.get_minimum_size().y <= 36, "Office summary overflows")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_starfall_office_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player := _prepare(game)
	var city := game.get_node("StarfallCitadel")
	_check(not city.has_node("FieldOffice"), "Office loaded before first city entry")
	var before_gold := int(state.gold)
	var before_inventory: Dictionary = state.inventory.duplicate(true)
	state.set_current_room("starfall_citadel")
	await process_frame
	await physics_frame
	var office := city.get_node("FieldOffice")
	var instance_id := office.get_instance_id()
	_check(office.rows.size() == 7 and "TASKS 0/7" in office.summary.text, "Office lacks seven initial route rows")
	_layout(office)
	for npc in [office.keeper, office.courier]:
		_floor(npc)
		_check(npc.route_markers.size() == 2, "Office NPC has no walking route")
		for marker in npc.route_markers:
			_floor(marker)
		_check(npc.interaction_requested.is_connected(Callable(game.get_node("UI"), "_on_npc_interaction_requested")), "Office NPC not wired to dialogue UI")
		game.get_node("UI")._on_npc_interaction_requested(npc)
		_check(game.get_node("UI").dialogue_panel.visible and not game.get_node("UI").active_town_line.is_empty(), "Office dialogue did not open")
		game.get_node("UI")._close_dialogue()
	for enemy in get_nodes_in_group("enemy"):
		_check(not city.is_ancestor_of(enemy), "Field office created danger in the city")
	office.keeper.position = office.get_node("OfficeStop1").position
	office.keeper.current_stop_marker = office.get_node("OfficeStop1")
	office.courier.position = office.get_node("OfficeStop2").position
	office.courier.current_stop_marker = office.get_node("OfficeStop2")
	office.keeper._try_social_exchange()
	_check(office.keeper.social_remaining > 0 and office.courier.social_remaining > 0, "Office residents cannot converse")
	var prefix := "starfall_outskirts"
	var row: Array = office.rows[prefix]
	state.unlock_shortcut(prefix + "_field_complete")
	_check(row[1].text == "YES" and row[3].text == "LOCKED" and row[4].text == "AFTER BOSS", "Task bypassed guards or boss on board")
	_check("upper hidden alcove" in office.keeper.dialogue_lines[0], "Archivist did not direct player to missing guards")
	state.unlock_shortcut(prefix + "_niche_cleared")
	_check(row[3].text == "READY", "Board missed unsealed discovery")
	_check("collect it" in office.keeper.dialogue_lines[0], "Archivist skipped unclaimed discovery")
	state.open_cache(prefix + "_hidden_depth")
	_check(row[3].text == "TAKEN", "Cache signal did not refresh office")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "office", "Office", "starfall_citadel"), "Office checkpoint save failed")
	state.mark_boss_defeated("hollow_sovereign")
	_check(row[4].text == "READY" and office.rows["starfall_silent_gate"][4].text == "TASK/GUARD", "Boss defeat enabled unfinished routes")
	_check("Sovereign has fallen" in office.courier.dialogue_lines[0], "Courier missed final victory")
	state.unlock_shortcut(prefix + "_field_return_complete")
	_check(row[4].text == "REWARD" and "not been collected" in office.keeper.dialogue_lines[0], "Victory was confused with collected reward")
	state.open_cache(prefix + "_field_return_reserve")
	_check(row[4].text == "TAKEN" and "TAKEN 1/7" in office.summary.text, "Claimed reserve not counted")
	state.set_current_room("training_passage")
	await process_frame
	_check(not office.keeper.can_process(), "Office NPC still processes outside city")
	state.set_current_room("starfall_citadel")
	await process_frame
	_check(city.get_node("FieldOffice").get_instance_id() == instance_id, "Re-entering city duplicated office")
	_check(state.gold == before_gold and state.inventory == before_inventory, "Informational office changed economy")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Office progress reload failed")
	game = _world()
	await process_frame
	player = _prepare(game)
	state.set_current_room("starfall_citadel")
	await process_frame
	office = game.get_node("StarfallCitadel/FieldOffice")
	row = office.rows[prefix]
	_check(row[1].text == "YES" and row[2].text == "YES" and row[3].text == "TAKEN" and row[4].text == "AFTER BOSS", "Office ignored lamp snapshot rollback")
	# A legacy claimed cache must not fabricate task or guard completion.
	state.open_cache("starfall_memory_vault_hidden_depth")
	_check(office.rows["starfall_memory_vault"][3].text == "TAKEN" and office.rows["starfall_memory_vault"][1].text == "-", "Legacy cache invented field progress")
	for id in office.ROUTES:
		state.unlock_shortcut(id + "_field_complete")
		state.unlock_shortcut(id + "_niche_cleared")
		state.open_cache(id + ("_rim" if id == "starfall_ramparts" else "_hidden_depth"))
	state.mark_boss_defeated("hollow_sovereign")
	for id in office.ROUTES:
		state.unlock_shortcut(id + "_field_return_complete")
		state.open_cache(id + "_field_return_reserve")
	await process_frame
	_layout(office)
	_check("TASKS 7/7" in office.summary.text and "TAKEN 7/7" in office.summary.text and "no extra payout" in office.keeper.dialogue_lines[0], "Office completion summary incorrect")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("STARFALL FIELD OFFICE TEST PASSED")
		quit(0)
	else:
		print("STARFALL FIELD OFFICE TEST FAILED: ", failures)
		quit(1)
