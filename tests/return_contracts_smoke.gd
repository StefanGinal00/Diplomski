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
	state.save_path = "res://_tmp_return_contracts_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player = game.get_node("Player")
	var ui = game.get_node("UI")
	var quests = game.get_node("QuestManager")
	_check(quests.get_return_contract_tracker_text().is_empty(), "Return quests appeared before any zone upgrade")
	quests.start_echo_survey()
	state.start_merchant_quest()
	state.set_zone_tier("sunken_shaft", 1)
	_check("SUNKEN SHAFT AWAKENED" in ui.zone_title_label.text and ui.zone_title_panel.visible, "Shaft difficulty increase was not announced")
	_check("Shaft Vigil" in ui.quest_tracker_label.text and "0/3 foes" in ui.quest_tracker_label.text, "Shaft return quest did not unlock")
	state.set_zone_tier("echo_grotto", 1)
	_check("ECHO GROTTO AWAKENED" in ui.zone_title_label.text, "Echo difficulty increase was not announced")
	_check("Resonance Sweep" in ui.quest_tracker_label.text, "Echo return quest did not unlock")
	var quest_scroll = ui.quest_panel.get_node("QuestScroll")
	_check(quest_scroll.clip_contents and ui.quest_tracker_label.get_parent() == quest_scroll, "Quest log cannot scroll its active missions")
	ui._toggle_quests()
	await process_frame
	_check(ui.quest_tracker_label.get_minimum_size().y <= ui.quest_tracker_label.size.y, "Return quests are clipped inside the quest log")
	if ui.quest_tracker_label.size.y > quest_scroll.size.y:
		_check(quest_scroll.get_v_scroll_bar().max_value > quest_scroll.size.y, "Overflowing return quests cannot scroll")
	ui._toggle_quests()
	var first_sentry = game.get_node("VerticalChamber/UpperShaftSentry")
	var first_crawler = game.get_node("VerticalChamber/ShaftCrawler")
	first_sentry.take_damage(first_sentry.max_health)
	first_crawler.take_damage(first_crawler.max_health)
	_check(int(quests.return_contract_kills.get("sunken_shaft", 0)) == 2, "Upgraded Shaft kills were not tracked")
	var rim_cache = game.get_node("VerticalChamber/Cache_shaft_rim")
	_check(rim_cache.open(player), "Shaft return cache could not open")
	_check(not bool(quests.return_contract_done.get("sunken_shaft", false)), "Shaft quest completed before its kill goal")
	_check("2/3 foes" in ui.quest_tracker_label.text and "1/1 caches" in ui.quest_tracker_label.text, "Quest log did not show partial return progress")
	state.set_current_room("sunken_shaft")
	_check(state.save_at_checkpoint(player, quests, player.global_position, "return_test", "Return Test", "sunken_shaft"), "Partial return quests did not save")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Partial return quests did not load")
	var resumed = load("res://Game.tscn").instantiate()
	root.add_child(resumed)
	current_scene = resumed
	await process_frame
	await process_frame
	var resumed_quests = resumed.get_node("QuestManager")
	var resumed_ui = resumed.get_node("UI")
	var resumed_player = resumed.get_node("Player")
	_check(int(resumed_quests.return_contract_kills.get("sunken_shaft", 0)) == 2 and state.opened_caches.has("shaft_rim"), "Partial Shaft quest reset after load")
	_check("AWAKENED" in resumed_ui.zone_subtitle_label.text, "Re-entering an upgraded zone does not show the stronger-enemy warning")
	var dynamic_wisp = resumed.get_node("VerticalChamber/shaft_echo_wisp")
	dynamic_wisp.take_damage(dynamic_wisp.max_health)
	_check(bool(resumed_quests.return_contract_done.get("sunken_shaft", false)), "Dynamic upgraded enemy did not count toward Shaft quest")
	_check(state.has_item("iron_fragment", 2), "Shaft quest material reward missing")
	_check("Shaft Vigil" not in resumed_ui.quest_tracker_label.text, "Completed Shaft quest stayed in active quests")
	for path in ["EchoGallery/NearShade", "EchoGallery/FarShade", "PrismArchive/ArchiveShade", "EchoNest/BroodlingOne"]:
		var enemy = resumed.get_node(path)
		enemy.take_damage(enemy.max_health)
	_check(int(resumed_quests.return_contract_kills.get("echo_grotto", 0)) == 4, "Upgraded Echo kills were not tracked")
	var gold_before_caches: int = state.gold
	_check(resumed.get_node("EchoGrotto/Cache_grotto_high").open(resumed_player), "Grotto return cache could not open")
	_check(not bool(resumed_quests.return_contract_done.get("echo_grotto", false)), "Echo quest completed after only one cache")
	_check(resumed.get_node("EchoGallery/Cache_gallery_step").open(resumed_player), "Gallery return cache could not open")
	_check(bool(resumed_quests.return_contract_done.get("echo_grotto", false)), "Echo return quest did not complete")
	_check(state.gold == gold_before_caches + 28 + 30 + 100 and state.has_item("ether_dust", 2), "Echo quest reward or cache payouts are incorrect")
	await process_frame
	_check("RETURN QUEST COMPLETE" in resumed_ui.notification_label.text, "Cache item notification hid the return quest completion")
	var gold_after_reward: int = state.gold
	resumed_quests._check_return_contract_completed("echo_grotto")
	_check(state.gold == gold_after_reward, "Echo quest reward can be claimed twice")
	_check(resumed_quests.get_return_contract_tracker_text().is_empty(), "Completed return quests remain active")
	_check(state.save_at_checkpoint(resumed_player, resumed_quests, resumed_player.global_position, "return_test", "Return Test", "echo_grotto"), "Completed return quests did not save")
	resumed.queue_free()
	await process_frame
	_check(state.load_game(), "Completed return quests did not load")
	var completed = load("res://Game.tscn").instantiate()
	root.add_child(completed)
	current_scene = completed
	await process_frame
	var completed_quests = completed.get_node("QuestManager")
	_check(bool(completed_quests.return_contract_done.get("sunken_shaft", false)) and bool(completed_quests.return_contract_done.get("echo_grotto", false)), "Return quest completions were not restored")
	_check(state.gold == gold_after_reward and completed_quests.get_return_contract_tracker_text().is_empty(), "Return quest reward or active state changed on reload")
	state.delete_save()
	completed.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("RETURN CONTRACTS TEST PASSED")
		quit(0)
	else:
		print("RETURN CONTRACTS TEST FAILED: ", failures)
		quit(1)
