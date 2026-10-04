extends "res://tests/story_scenes_smoke.gd"

func _run() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_campaign_scenes.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var ui := game.get_node("UI")
	ui.set_process(false)
	var cinema: Node = ui.story_player
	var player := game.get_node("Player")
	# Keep the collision body in physics space while disabling movement logic.
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.set_physics_process(false)
	player.set_process(false)
	state.story_scenes_seen["opening"] = true
	for id in Scenes.ORDER:
		var data: Dictionary = Scenes.SCENES[id]
		_check(data.pages.size() >= 3 and data.pages.size() <= 4 and data.images.size() == data.pages.size(), "Scene lacks 3-4 paired shots: " + id)
		var unique := {}
		for path in data.images:
			unique[path] = true
			_check(ResourceLoader.exists(path), "Missing illustration: " + path)
		_check(unique.size() == data.pages.size(), "Repeated shot within event: " + id)
		if id != "opening": _check(not Scenes.unlocked(state, id), "Future event unlocked: " + id)
	# A real physics floor far from campaign threats isolates presentation safety.
	var floor_body := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(1000, 40)
	floor_shape.shape = rectangle
	floor_body.add_child(floor_shape)
	root.add_child(floor_body)
	floor_body.position = Vector2(-9000, -8900)
	player.global_position = Vector2(-9000, -9000)
	for frame in range(35):
		await physics_frame
		player.velocity = Vector2(0, 600)
		player.move_and_slide()
	_check(player.is_on_floor(), "Safety fixture did not ground player")
	ui._dismiss_zone_title()
	# Real boss deaths enqueue their matching sequence only once.
	for boss in get_nodes_in_group("boss"):
		var boss_id := str(boss.get("boss_id"))
		if boss_id not in Scenes.BOSS_SCENES or boss_id in ["ember_marshal", "hollow_sovereign"]: continue
		var id: String = Scenes.BOSS_SCENES[boss_id]
		boss.take_damage(9999)
		_check(id in ui.campaign_scene_queue and Scenes.unlocked(state, id), "Native boss did not queue scene: " + boss_id)
		ui._present_encounter_story(boss_id)
		_check(ui.campaign_scene_queue.count(id) == 1, "Duplicate native defeat queued twice")
		ui._clear_memory_reveals()
		ui._dismiss_zone_title()
		ui.boss_health_panel.show()
		ui._process_campaign_scenes(10.0)
		_check(not cinema.is_open(), "Scene interrupted boss warning")
		ui.boss_health_panel.hide()
		var threat := Node2D.new()
		root.add_child(threat)
		threat.add_to_group("enemy_projectile")
		threat.global_position = player.global_position
		ui._process_campaign_scenes(10.0)
		_check(not cinema.is_open(), "Scene interrupted nearby projectile")
		threat.remove_from_group("enemy_projectile")
		threat.queue_free()
		ui._process_campaign_scenes(1.0)
		_check(not cinema.is_open(), "Post-battle delay missing")
		# Safety must be continuous, including transitions, dash and attack release.
		var transition := root.get_node("RoomTransition")
		transition.is_transitioning = true
		ui._process_campaign_scenes(10.0)
		transition.is_transitioning = false
		_check(not cinema.is_open() and is_equal_approx(ui.campaign_scene_delay, 3.0), "Door transition did not reset quiet window")
		ui._process_campaign_scenes(2.0)
		player.is_dashing = true
		ui._process_campaign_scenes(10.0)
		player.is_dashing = false
		_check(not cinema.is_open() and is_equal_approx(ui.campaign_scene_delay, 3.0), "Dash interrupted by cinema")
		player.attack_visual_timer.start()
		ui._process_campaign_scenes(10.0)
		player.attack_visual_timer.stop()
		_check(not cinema.is_open(), "Attack release interrupted by cinema")
		ui._process_campaign_scenes(2.5)
		_check(not cinema.is_open(), "Unsafe intervals accumulated into premature playback")
		threat = Node2D.new()
		root.add_child(threat)
		threat.add_to_group("enemy_projectile")
		threat.global_position = player.global_position
		ui._process_campaign_scenes(0.1)
		threat.remove_from_group("enemy_projectile")
		threat.queue_free()
		ui._process_campaign_scenes(0.6)
		_check(not cinema.is_open(), "New threat failed to restart the full quiet window")
		ui._process_campaign_scenes(3.0)
		_check(cinema.active_id == id and paused, "Safe native aftermath did not play: " + id)
		var snapshot: String = JSON.stringify([state.gold, state.inventory, state.defeated_bosses])
		while cinema.is_open(): cinema.advance()
		_check(JSON.stringify([state.gold, state.inventory, state.defeated_bosses]) == snapshot, "Scene changed boss rewards/progress")
		ui._queue_campaign_scene(id)
		_check(ui.campaign_scene_queue.is_empty(), "Acknowledged boss sequence repeated")
	# Marshal requires the whole arena, not an individual death or emblem pickup.
	state.inventory["marshal_emblem"] = 1
	ui._present_encounter_story("ember_marshal")
	_check(not Scenes.unlocked(state, "marshal") and ui.campaign_scene_queue.is_empty(), "Marshal sequence before all waves")
	state.unlock_shortcut("ash_arena_cleared")
	_check("marshal" in ui.campaign_scene_queue, "Arena completion failed to queue story")
	ui.campaign_scene_queue.clear()
	ui._clear_memory_reveals()
	_complete(state, 4)
	ui._on_quest_updated()
	_check(Scenes.unlocked(state, "fortress") and not Scenes.unlocked(state, "memories"), "Quest milestone gating wrong")
	_check("fortress" in ui.campaign_scene_queue, "Main quest completion did not queue illustration")
	_complete(state, 6)
	ui._on_quest_updated()
	_check(Scenes.unlocked(state, "memories"), "Three memories quest lacks sequence")
	_check("memories" in ui.campaign_scene_queue, "Memory quest completion did not queue illustration")
	# Native finale overlays the existing save/reward ending, returning to it.
	var final_boss := game.get_node("StarfallHollowThrone/HollowSovereign")
	state.current_room_id = "starfall_hollow_throne"
	final_boss.take_damage(9999)
	_check(cinema.active_id == "ending" and ui.ending_panel.visible and paused, "Native final boss did not start four-shot ending")
	for index in range(4):
		_check(cinema.page == index, "Ending skipped a shot")
		cinema.advance()
		cinema.advance()
	_check(not cinema.is_open() and ui.ending_panel.visible and paused, "Ending did not return to paused reward/save epilogue")
	ui._close_final_ending()
	_check(not paused, "Final epilogue did not restore gameplay")
	# Scrollable replay reaches the tenth chapter without leaking future titles.
	cinema.open_library()
	await process_frame
	await process_frame
	cinema.replay_list.get_child(9).grab_focus()
	await process_frame
	await process_frame
	_check(cinema.replay_scroll.scroll_vertical > 0, "Replay library cannot reach final chapter")
	cinema.finish()
	# Catalog migration avoids old-save movie backlogs but retains replay access.
	var legacy: Dictionary = state._build_save_data().duplicate(true)
	legacy.erase("story_scene_catalog")
	legacy.story_scenes_seen = {"opening": true, "haven": true, "memories": true}
	state._apply_save_data(legacy)
	_check(Scenes.pending(state).is_empty() and Scenes.unlocked(state, "ending"), "Catalog migration forces backlog or loses replay")
	ui.campaign_scene_queue.append("echo")
	ui._on_player_died()
	_check(ui.campaign_scene_queue.is_empty() and not cinema.is_open(), "Death retained pending movie")
	state.start_new_game("normal")
	_check(state.story_scenes_seen.is_empty() and ui.campaign_scene_queue.is_empty(), "New game retains story state")
	game.queue_free()
	floor_body.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("CAMPAIGN SCENES TEST PASSED: ten 3-4 shot scenes, native deaths, arena completion, safety/delay, quest gates, native four-shot finale, scrolling replay, migration and cleanup")
		quit(0)
	else: quit(1)
