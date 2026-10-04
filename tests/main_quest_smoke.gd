extends "res://tests/boss_combat_presentation_smoke.gd"

const Campaign = preload("res://MainQuest.gd")

func _fulfill(state: Node, index: int) -> void:
	for goal in Campaign.STEPS[index].goals:
		match goal[0]:
			"boss": state.defeated_bosses[goal[1]] = true
			"item": state.inventory[goal[1]] = 1
			"event": state.unlocked_shortcuts[goal[1]] = true
			"room": state.discovered_rooms[goal[1]] = true

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_main_quest.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player := game.get_node("Player")
	var quests := game.get_node("QuestManager")
	var ui := game.get_node("UI")
	# Every possible stage-order combination: later work never skips an earlier stage.
	for mask in range(256):
		state.defeated_bosses.clear()
		state.inventory.clear()
		state.unlocked_shortcuts.clear()
		state.discovered_rooms.clear()
		for index in range(8):
			if mask & (1 << index): _fulfill(state, index)
		var expected := 0
		while expected < 8 and mask & (1 << expected): expected += 1
		var before: String = JSON.stringify(state._build_save_data())
		_check(Campaign.completed_count(state) == expected, "Main quest skipped a prerequisite: %d" % mask)
		_check(Campaign.next_reward(state, {}) == (0 if expected > 0 else -1), "Out-of-order reward became available")
		Campaign.journal(state, {})
		_check(JSON.stringify(state._build_save_data()) == before, "Reading campaign grants progress/rewards")
		_check(not quests.claim_main_reward(expected, player), "Claimed incomplete or later stage")
	# Claim through the actual journal button; all three rewards are supplied.
	state.start_new_game("normal")
	_check(quests.main_quest_rewards.is_empty(), "New game retains main receipts")
	state.mark_boss_defeated("void_sentinel")
	_check(ui.get_node("QuestPanel/MainRewardButton").visible, "Native boss progress did not enable claim")
	ui._toggle_quests()
	var gold_before: int = state.gold
	ui.get_node("QuestPanel/MainRewardButton").pressed.emit()
	_check(state.gold == gold_before + 30 and state.has_item("healing_herb", 2) and state.has_item("iron_fragment", 2), "First bundle is not three real rewards")
	_check(quests.main_quest_rewards.get("road_out", false) and not ui.get_node("QuestPanel/MainRewardButton").visible, "First reward did not close")
	ui._close_side_panels()
	_check(not quests.claim_main_reward(0, player), "Duplicate stage reward paid")
	for index in range(1, 8): _fulfill(state, index)
	_check(state.save_at_checkpoint(player, quests, Vector2.ZERO), "Campaign snapshot failed")
	var saved_gold: int = state.gold
	var saved_sp: int = player.skill_points
	# Early objectives are retained; old saves without receipts can claim manually.
	var legacy: Dictionary = quests.get_save_state()
	legacy.erase("main_quest_rewards")
	quests.apply_save_state(legacy)
	_check(quests.main_quest_rewards.is_empty() and Campaign.next_reward(state, quests.main_quest_rewards) == 0 and state.gold == saved_gold, "Legacy migration auto-paid or skipped rewards")
	quests.main_quest_rewards = {"road_out": true}
	var side_before: int = quests.quest_state
	var reentries: Array[bool] = []
	var callback := func(_gold: int): reentries.append(quests.claim_main_reward(Campaign.next_reward(state, quests.main_quest_rewards), player))
	state.gold_changed.connect(callback)
	for index in range(1, 8):
		var reward: Dictionary = Campaign.STEPS[index].reward
		_check(reward.items.size() + int(reward.has("gold")) + int(reward.has("sp")) == 3, "Stage does not offer a three-part bundle")
		var previous_gold: int = state.gold
		var previous_sp: int = player.skill_points
		var inventory: Dictionary = state.inventory.duplicate()
		_check(quests.claim_main_reward(index, player), "Completed stage cannot be claimed: %d" % index)
		_check(state.gold == previous_gold + int(reward.get("gold", 0)) and player.skill_points == previous_sp + int(reward.get("sp", 0)), "Gold/SP reward mismatch")
		for id in reward.items:
			_check(state.ITEM_DEFINITIONS.has(id) and int(state.inventory[id]) == int(inventory.get(id, 0)) + int(reward.items[id]), "Bundle item mismatch: " + id)
		_check(not quests.claim_main_reward(index, player), "Stage repeated its payout")
	state.gold_changed.disconnect(callback)
	_check(not reentries.has(true), "Signal reentry claimed another bundle")
	_check(quests.quest_state == side_before and quests.main_quest_rewards.size() == 8, "Main line changed side task or lost a stage")
	_check(state.has_item("wayfarer_mantle") and Campaign.next_reward(state, quests.main_quest_rewards) == -1, "First-clear reward missing")
	_check(state.load_game() and state.gold == saved_gold and not state.has_item("wayfarer_mantle"), "Unsaved rewards did not roll back")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	player = game.get_node("Player")
	quests = game.get_node("QuestManager")
	ui = game.get_node("UI")
	_check(quests.main_quest_rewards.size() == 1 and player.skill_points == saved_sp, "Receipt/player rollback disagrees")
	for resolution in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		ui._on_quest_updated()
		ui.quest_panel.show()
		await process_frame
		var button := ui.get_node("QuestPanel/MainRewardButton") as Button
		_check(button.visible and button.get_minimum_size().x <= button.size.x, "Reward action clipped")
		_check(not button.get_global_rect().intersects(ui.get_node("QuestPanel/QuestScroll").get_global_rect()), "Claim button covers journal")
		_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(ui.quest_panel.get_global_rect()), "Campaign UI outside viewport")
		_check("LOCAL TASKS - OPTIONAL" in ui.quest_tracker_label.text and "READY TO CLAIM" in ui.quest_tracker_label.text, "Main/side quest split missing")
	ui.quest_panel.hide()
	for index in range(1, 8): _check(quests.claim_main_reward(index, player), "Rollback cannot reclaim unsaved bundle")
	# The unique finale item works only while equipped, replacing other defense gear.
	_check(not state.get_item_definition("wayfarer_mantle").droppable, "Unique first-clear item can be lost")
	_check(state.equip_item("wayfarer_mantle", "defense"), "First-clear mantle cannot be equipped")
	_check(is_equal_approx(player.get_effective_dash_cooldown(), player.dash_cooldown * 0.8), "Mantle dash effect missing")
	player.dash_unlocked = false
	_check(not player.try_dash(), "Mantle bypassed the Dash skill unlock")
	for damage in [1, 2, 3, 4]:
		player.current_health = 10
		player.max_health = 10
		player.is_invulnerable = false
		player.take_damage(damage)
		_check(player.current_health == 10 - (damage - 1 if damage >= 3 else damage), "Mantle mitigation does not match description")
	state.unequip_defense()
	_check(is_equal_approx(player.get_effective_dash_cooldown(), player.dash_cooldown), "Mantle effect remains unequipped")
	player.current_health = 10
	player.is_invulnerable = false
	player.take_damage(3)
	_check(player.current_health == 7, "Mantle mitigation remains unequipped")
	_check(state.save_at_checkpoint(player, quests, Vector2.ZERO) and state.load_game(), "Final reward save failed")
	_check(state.quest_state.main_quest_rewards.size() == 8 and state.has_item("wayfarer_mantle") and not quests.claim_main_reward(7, player), "Final reward did not persist exactly once")
	state.start_new_game("normal")
	_check(quests.main_quest_rewards.is_empty() and not state.has_item("wayfarer_mantle") and Campaign.completed_count(state) == 0, "New game retained clear reward")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("MAIN QUEST TEST PASSED: 256 progression combinations, eight three-part bundles, native claim UI, reentry/duplicates, old saves, rollback, three viewports and unique mantle effects")
		quit(0)
	else: quit(1)
