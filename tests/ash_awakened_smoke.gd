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
	state.save_path = "res://_tmp_ash_awakened_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var quests = game.get_node("QuestManager")
	var ui = game.get_node("UI")
	_check(quests.get_return_contract_tracker_text().is_empty(), "Ash return quest appeared before boss defeat")
	state.mark_boss_defeated("ash_castellan")
	state.add_item("castellan_seal")
	state.set_zone_tier("ashen_bastion", 1)
	_check("ASHEN BASTION AWAKENED" in ui.zone_title_label.text, "Ashen difficulty increase was not announced")
	_check("Ember Reckoning" in ui.quest_tracker_label.text and "0/4 foes" in ui.quest_tracker_label.text, "Ash return quest did not activate")
	# Awakened reinforcements, like authored actors, load only on room entry.
	_check(not game.has_node("EmberBarracks/barracks_ash_fiend"), "Unvisited awakened room loaded enemies eagerly")
	for room_and_cache in [
		["BrokenCauseway", "Cache_causeway_embers", "causeway_ash_fiend", "ash_causeway"],
		["CinderForge", "Cache_forge_cinders", "forge_ash_sentry", "ash_forge"],
		["EmberBarracks", "Cache_barracks_embers", "barracks_ash_fiend", "ash_barracks"],
		["AshArena", "Cache_arena_cinders", "arena_ash_sentry", "ash_arena"],
		["SlagReservoir", "Cache_reservoir_embers", "reservoir_ash_fiend", "ash_reservoir"],
		["AshChapel", "Cache_chapel_cinders", "chapel_ash_sentry", "ash_chapel"],
	]:
		state.set_current_room(room_and_cache[3])
		await process_frame
		var room = game.get_node(room_and_cache[0])
		_check(room.has_node(room_and_cache[1]) and room.has_node(room_and_cache[2]), "Awakened cache or encounter missing in " + room_and_cache[0])
	for enemy in get_nodes_in_group("enemy"):
		_check(not game.get_node("CinderHearth").is_ancestor_of(enemy), "Safe Cinder Hearth gained enemies")
	_check(game.get_node("BrokenCauseway/NearFiend").max_health == 5 and game.get_node("CinderForge/UpperSentry").max_health == 5, "Ashen enemies did not gain health")
	for path in ["BrokenCauseway/causeway_ash_fiend", "CinderForge/forge_ash_sentry", "EmberBarracks/barracks_ash_fiend", "AshArena/arena_ash_sentry"]:
		var enemy = game.get_node(path)
		enemy.take_damage(enemy.max_health)
	_check(int(quests.return_contract_kills.get("ashen_bastion", 0)) == 4, "Ash return quest did not count upgraded foes")
	var cache1 = game.get_node("BrokenCauseway/Cache_causeway_embers")
	var cache2 = game.get_node("CinderForge/Cache_forge_cinders")
	_check(cache1.open(player), "First Ash return cache did not open")
	_check(not bool(quests.return_contract_done.get("ashen_bastion", false)), "Ash return quest completed with one cache")
	_check(cache2.open(player), "Second Ash return cache did not open")
	_check(bool(quests.return_contract_done.get("ashen_bastion", false)), "Ash return quest did not complete")
	_check(state.has_item("iron_fragment", 4) and state.gold >= 42 + 45 + 130, "Ash caches or quest rewards missing")
	_check("Ember Reckoning" not in quests.get_return_contract_tracker_text(), "Completed Ash quest stayed active")
	ui._update_route_summary()
	_check("CACHES 2/15" in ui.map_route_label.text and "CASTELLAN REMATCH READY" in ui.map_route_label.text, "Map did not track awakened Ashen progress")
	_check(state.save_at_checkpoint(player, quests, player.global_position, "ash_awakened_test", "Ash Test", "ash_causeway"), "Awakened Ash progress did not save")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Awakened Ash save did not load")
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	quests = game.get_node("QuestManager")
	_check(bool(quests.return_contract_done.get("ashen_bastion", false)) and quests.get_return_contract_tracker_text().is_empty(), "Completed Ash return quest did not persist")
	_check(game.get_node("BrokenCauseway/Cache_causeway_embers").opened and game.get_node("CinderForge/Cache_forge_cinders").opened, "Awakened Ash caches reopened after load")
	_check(game.get_node("CastellanThrone/AshCastellan").is_rematch, "Awakened Castellan not available after save")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("ASH AWAKENED TEST PASSED")
		quit(0)
	else:
		print("ASH AWAKENED TEST FAILED: ", failures)
		quit(1)
