extends "res://tests/story_scenes_smoke.gd"

const Safety = preload("res://BossEncounterSafety.gd")
var played: Array[String] = []
var expected_gold := 0
var expected_sp := 0

func _claim_ready(state: Node, ui: Node, quests: Node, player: Node) -> void:
	ui._toggle_quests()
	var count := 0
	while Campaign.next_reward(state, quests.main_quest_rewards) >= 0 and count < 8:
		var index := Campaign.next_reward(state, quests.main_quest_rewards)
		var reward: Dictionary = Campaign.STEPS[index].reward
		var before_gold: int = state.gold
		var before_sp: int = player.skill_points
		ui.get_node("QuestPanel/MainRewardButton").pressed.emit()
		_check(state.gold - before_gold == int(reward.get("gold", 0)), "Flow reward gold mismatch")
		_check(player.skill_points - before_sp == int(reward.get("sp", 0)), "Flow reward SP mismatch")
		expected_gold += int(reward.get("gold", 0))
		expected_sp += int(reward.get("sp", 0))
		count += 1
	ui._close_side_panels()

func _drain(ui: Node, expected: Array) -> void:
	ui._clear_memory_reveals()
	ui._dismiss_zone_title()
	ui.boss_health_panel.hide()
	var found: Array[String] = []
	for index in range(5):
		if ui.campaign_scene_queue.is_empty(): break
		ui._process_campaign_scenes(3.1)
		if ui.story_player.active_id.is_empty(): break
		found.append(ui.story_player.active_id)
		played.append(ui.story_player.active_id)
		ui.story_player.finish()
	_check(found == expected, "Flow scene order: expected %s, got %s" % [expected, found])
	_check(ui.campaign_scene_queue.is_empty(), "Flow retained a queued scene")

func _victory(state: Node, ui: Node, id: String) -> void:
	state.set_current_room(Safety.ROOMS[id])
	for boss in get_nodes_in_group("boss"):
		if str(boss.get("boss_id")) == id:
			boss.battle_started.emit()
			boss.take_damage(9999)
			_check(bool(state.defeated_bosses.get(id, false)), "Native boss victory not recorded: " + id)
			return
	_check(false, "Native boss missing: " + id)

func _memories(state: Node) -> void:
	for id in ["memory_sigil_shaft", "memory_sigil_echo", "memory_sigil_ash"]: state.add_item(id)

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_campaign_flow.json"
	for early_memories in [true, false]:
		state.start_new_game("normal")
		played.clear()
		expected_gold = 0
		expected_sp = 0
		var game: Node2D = load("res://Game.tscn").instantiate()
		root.add_child(game)
		current_scene = game
		await process_frame
		game.process_mode = Node.PROCESS_MODE_DISABLED
		var ui := game.get_node("UI")
		ui.set_process(false)
		var quests := game.get_node("QuestManager")
		var player := game.get_node("Player")
		var cinema: Node = ui.story_player
		cinema.play("opening")
		cinema.finish()
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.set_physics_process(false)
		player.set_process(false)
		var floor_body := StaticBody2D.new()
		var collision := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(1000, 40)
		collision.shape = rectangle
		floor_body.add_child(collision)
		root.add_child(floor_body)
		floor_body.position = Vector2(-9000, -8900)
		player.global_position = Vector2(-9000, -9000)
		for frame in range(35):
			await physics_frame
			player.velocity = Vector2(0, 600)
			player.move_and_slide()
		_check(player.is_on_floor(), "Flow fixture not grounded")
		if early_memories:
			_memories(state)
			_check(Campaign.completed_count(state) == 0 and ui.campaign_scene_queue.is_empty(), "Early memories skipped main-road stages")
		var stage := 0
		for id in ["void_sentinel", "abyss_warden", "echo_matriarch"]:
			_victory(state, ui, id)
			stage += 1
			_check(Campaign.completed_count(state) == stage, "Boss stage not advanced")
			_drain(ui, [Scenes.BOSS_SCENES[id]])
			if not early_memories: _claim_ready(state, ui, quests, player)
		state.unlock_shortcut("ash_forge_fan")
		state.add_item("barracks_insignia")
		state.add_item("marshal_emblem")
		_check(Campaign.completed_count(state) == 3, "Marshal item bypassed four-wave completion")
		state.unlock_shortcut("ash_arena_cleared")
		_check(Campaign.completed_count(state) == 4, "Fortress mechanisms failed to advance main quest")
		_drain(ui, ["marshal", "fortress"])
		if not early_memories: _claim_ready(state, ui, quests, player)
		_victory(state, ui, "ash_castellan")
		_check(Campaign.completed_count(state) == (6 if early_memories else 5), "Early/late memories lost ordered progress")
		_drain(ui, ["castellan", "memories"] if early_memories else ["castellan"])
		if not early_memories: _claim_ready(state, ui, quests, player)
		_victory(state, ui, "starfall_guardian")
		_drain(ui, ["guardian"])
		if not early_memories:
			_memories(state)
			_drain(ui, ["memories"])
			_claim_ready(state, ui, quests, player)
		state.set_current_room("starfall_sunless_passage")
		_check(Campaign.completed_count(state) == 7, "Sunless arrival failed to advance native quest UI")
		if not early_memories: _claim_ready(state, ui, quests, player)
		# Snapshot the pre-victory save, then finish without saving over it yet.
		_check(state.save_at_checkpoint(player, quests, player.global_position), "Pre-finale snapshot failed")
		await process_frame
		_victory(state, ui, "hollow_sovereign")
		_check(Campaign.completed_count(state) == 8 and cinema.active_id == "ending", "Final victory did not finish campaign/start scene")
		ui._open_ending_rewards()
		_check(not ui.quest_panel.visible and cinema.active_id == "ending", "Reward shortcut bypassed active ending cinema")
		cinema.finish()
		_check(played.size() == 8 and ui.ending_panel.visible, "Campaign missed an interlude or epilogue")
		var pending_count := 8 if early_memories else 1
		_check(("%d chapter reward" % pending_count) in ui.get_node("EndingPanel/SaveHint").text, "Epilogue reward count incorrect")
		for resolution in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
			root.size = resolution
			await process_frame
			var reward_button: Button = ui.get_node("EndingPanel/RewardsButton")
			var hint: Label = ui.get_node("EndingPanel/SaveHint")
			_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(ui.ending_panel.get_global_rect()), "Epilogue outside viewport")
			_check(not reward_button.get_global_rect().intersects(ui.ending_continue_button.get_global_rect()), "Epilogue actions overlap")
			_check(reward_button.get_minimum_size().x <= reward_button.size.x and hint.get_minimum_size().y <= hint.size.y, "Epilogue reward content clipped")
		var before_gold: int = state.gold
		# Native button on one route, advertised keyboard action on the other.
		ui._show_notification("OLD VICTORY NOTICE")
		if early_memories: ui.get_node("EndingPanel/RewardsButton").pressed.emit()
		else:
			var action := InputEventAction.new()
			action.action = "quest_log"
			action.pressed = true
			ui._unhandled_input(action)
		_check(ui.quest_panel.visible and paused and not ui.ending_panel.visible, "Epilogue did not hand off to paused quest log")
		_check(is_zero_approx(ui.notification_label.modulate.a), "Stale victory notice covers reward journal")
		_check(state.gold == before_gold, "Opening epilogue rewards auto-paid a bundle")
		ui._close_side_panels()
		_claim_ready(state, ui, quests, player)
		_check(expected_gold == 820 and expected_sp == 5 and quests.main_quest_rewards.size() == 8, "Full campaign bundle totals incorrect")
		_check(state.has_item("wayfarer_mantle") and not quests.claim_main_reward(7, player), "Final mantle missing or duplicate payout")
		# Unwatched old events stay available but never interrupt postgame lamp rests.
		state.story_scenes_seen.erase("sentinel")
		_check(Scenes.pending(state).is_empty() and Scenes.unlocked(state, "sentinel"), "Postgame forces old scene or removes replay")
		state.story_scenes_seen.erase("ending")
		_check(Scenes.pending(state) == "ending", "Interrupted finale loses priority to an old chapter")
		state.story_scenes_seen["ending"] = true
		cinema.play("sentinel")
		cinema.cancel()
		_check(not state.story_scenes_seen.has("sentinel"), "Replay cancellation marks an unwatched scene")
		_check("Campaign rewards claimed" in Campaign.ending_reward_hint(state, quests.main_quest_rewards), "Claimed finale still advertises pending reward")
		if early_memories:
			# Victory, receipts and acknowledgments roll back together before lamp save.
			_check(state.load_game() and not state.has_item("wayfarer_mantle") and not state.defeated_bosses.get("hollow_sovereign", false), "Unsaved finale did not roll back")
			_check(not state.story_scenes_seen.get("ending", false) and Campaign.completed_count(state) == 7, "Scene/quest rollback disagrees with victory")
		else:
			_check(state.save_at_checkpoint(player, quests, player.global_position) and state.load_game(), "Completed campaign cannot save/load")
			_check(state.has_item("wayfarer_mantle") and state.story_scenes_seen.get("ending", false) and Campaign.completed_count(state) == 8, "Saved finale lost reward, scene or progress")
			_check(quests.main_quest_rewards.size() == 8 and not quests.claim_main_reward(7, player) and Scenes.pending(state).is_empty(), "Saved postgame replays or repays completed content")
		game.queue_free()
		floor_body.queue_free()
		await process_frame
		state.delete_save()
	if failures.is_empty():
		print("CAMPAIGN FLOW TEST PASSED: two event-driven campaigns, native bosses, early/late memories, ordered scenes, 820 gold/5 SP bundles, finale handoff, three sizes, postgame replay, save and rollback")
		quit(0)
	else: quit(1)
