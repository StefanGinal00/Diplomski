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
	state.save_path = "res://_tmp_hollow_throne_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	var player: Player = game.get_node("Player")
	var cistern: Node2D = game.get_node("BlackwaterCistern")
	var chapel: Node2D = game.get_node("AshChapel")
	var passage: Node2D = game.get_node("StarfallSunlessPassage")
	var throne: Node2D = game.get_node("StarfallHollowThrone")
	var gate = passage.get_node("HollowThroneDoor")
	var ui = game.get_node("UI")
	var ambience = game.get_node("AmbientSoundscape")
	_check(not gate._requirements_met(), "Final gate opened before main bosses and Memory Sigils")
	_check(not cistern.get_node("MemoryReliquary").open(player) and not chapel.get_node("MemoryReliquary").open(player), "Sigil reliquaries opened before local puzzles")
	var shaft_niche := cistern.get_node("ExpandedRoute/AuthoredDescent/Niche1_Crest") as StaticBody2D
	_check(absf(cistern.get_node("MemoryReliquary").position.y - shaft_niche.position.y) < 60.0 and shaft_niche.position.y < cistern.get_node("ExpandedRoute/AuthoredDescent/T1_Bridge4").position.y - 150.0 and chapel.get_node("MemoryReliquary").position.y < chapel.get_node("Floor").position.y - 120.0, "Memory Sigils are not on optional upper paths")
	state.unlock_shortcut("shaft_cistern_pump")
	state.unlock_shortcut("ash_chapel_bells")
	_check(cistern.get_node("MemoryReliquary").open(player) and not cistern.get_node("MemoryReliquary").open(player) and state.has_item("memory_sigil_shaft"), "Shaft Memory Sigil was not unique")
	_check(chapel.get_node("MemoryReliquary").open(player) and not chapel.get_node("MemoryReliquary").open(player) and state.has_item("memory_sigil_ash"), "Ash Memory Sigil was not unique")
	_check(not gate._requirements_met(), "Final gate ignored missing bosses or Echo Sigil")
	state.add_item("memory_sigil_echo")
	for boss_id in ["abyss_warden", "echo_matriarch", "ash_castellan"]:
		state.mark_boss_defeated(boss_id)
	_check(gate._requirements_met(), "Three main bosses and Memory Sigils did not open final gate")
	_check(not gate.required_boss_ids.has("starfall_guardian"), "Optional Starfall Guardian became a final gate prerequisite")
	var approach_lamp = passage.get_node("SunlessLamp")
	player.global_position = approach_lamp.get_node("RespawnPoint").global_position
	_check(approach_lamp._save_progress(player), "Sunless approach lamp could not save before the final battle")
	state.set_current_room("starfall_sunless_passage")
	await gate.activate(player)
	_check(state.current_room_id == "starfall_hollow_throne" and player.global_position.distance_to(throne.get_node("Entry").global_position) < 45.0, "Final gate did not enter Hollow Throne")
	_check(ui.zone_title_label.text == "HOLLOW THRONE" and "HOLLOW SOVEREIGN" in ui.objective_label.text, "Final room title or objective is missing")
	_check(ambience.current_track == "starfall_hollow_throne", "Throne ambience did not begin")
	var boss = throne.get_node("HollowSovereign")
	var cache = throne.get_node("VictoryCache")
	var lamp = throne.get_node("ThroneLamp")
	_check(throne.get_node("FallenSpan").position.y < boss.position.y - 70.0, "Expanded arena lacks a raised central rift escape route")
	_check(not boss.active and not cache.open(player), "Sovereign battle or cache activated at the entry lamp")
	_check(not lamp.visible and not lamp.is_revealed, "Final arena lamp appeared before the Sovereign was defeated")
	player.max_health = 100
	player.current_health = 100
	player.global_position = boss.global_position + Vector2(-300.0, 0.0)
	await create_timer(0.18).timeout
	_check(boss.active and ambience.current_track == "hollow_boss" and ui.boss_health_panel.visible, "Final boss did not activate its own battle music and HUD")
	await throne.get_node("SunlessReturnDoor").activate(player)
	_check(state.current_room_id == "starfall_hollow_throne" and throne.get_node("SunlessReturnDoor").status_label.text == "BATTLE SEALED", "Final battle allowed retreat through return door")
	_check(lamp._has_nearby_threat() and not lamp._save_progress(player), "Final battle allowed lamp rest")
	var forced_transition: bool = await root.get_node("RoomTransition").transition_player(player, passage.get_node("ThroneReturn").global_position, "starfall_sunless_passage")
	_check(not forced_transition and state.current_room_id == "starfall_hollow_throne", "Direct transition bypassed final battle lock")
	boss._start_pattern("lunge")
	_check(boss.telegraph_line.visible and boss.windup_remaining > 0.0, "Sovereign lunge lacks a warning")
	boss._release_pattern()
	_check(boss.charge_remaining > 0.0 and boss.warning_cue.stream != null and boss.impact_cue.stream != null, "Sovereign lunge or its sound cues did not fire")
	boss._start_pattern("volley")
	_check(boss.telegraph_line.visible, "Sovereign volley lacks an aim warning")
	var projectile_count: int = get_nodes_in_group("enemy_projectile").size()
	boss._release_pattern()
	_check(get_nodes_in_group("enemy_projectile").size() >= projectile_count + 3, "First-phase Sovereign volley has too few projectiles")
	boss._start_pattern("runes")
	_check(boss.rune_indices.size() == 1 and boss.floor_marks[boss.rune_indices[0]].visible, "Sovereign floor rune is not marked")
	boss._release_pattern()
	boss.take_damage(15)
	_check(boss.phase == 2, "Sovereign did not enter phase two")
	boss._start_pattern("starfall")
	_check(boss.column_marks[0].visible and boss.column_marks[1].visible, "Sovereign starfall columns are not marked")
	boss._release_pattern()
	boss._start_pattern("nova")
	_check(boss.nova_ring.visible, "Sovereign nova lacks an area warning")
	boss._release_pattern()
	boss.take_damage(13)
	_check(boss.phase == 3, "Sovereign did not enter final phase")
	boss._start_pattern("soul_lock")
	_check(boss.lock_mark.visible and boss.locked_point.distance_to(player.global_position) < 1.0, "Sovereign soul lock did not mark the player's position")
	boss._release_pattern()
	boss._start_pattern("rift")
	_check(boss.rift_mark.visible and boss.rift_hint.visible and boss.rift_mark.global_position.y > throne.global_position.y + 400.0, "Sovereign floor rift lacks a readable arena warning")
	player.global_position = throne.global_position + Vector2(970.0, 400.0)
	player.is_invulnerable = false
	var health_before_rift: int = player.current_health
	boss._release_pattern()
	_check(player.current_health < health_before_rift, "Sovereign floor rift did not harm a grounded player")
	player.global_position = throne.global_position + Vector2(1100.0, 285.0)
	player.is_invulnerable = false
	health_before_rift = player.current_health
	boss._start_pattern("rift")
	boss._release_pattern()
	_check(player.current_health == health_before_rift, "Raised arena route did not avoid floor rift")
	boss._start_pattern("volley")
	projectile_count = get_nodes_in_group("enemy_projectile").size()
	boss._release_pattern()
	_check(get_nodes_in_group("enemy_projectile").size() >= projectile_count + 7, "Final-phase Sovereign volley did not widen")
	var gold_before: int = state.gold
	boss.take_damage(boss.current_health)
	await process_frame
	_check(bool(state.defeated_bosses.get("hollow_sovereign", false)) and bool(state.unlocked_shortcuts.get("starfall_sovereign_defeated", false)) and state.has_item("sovereign_crown"), "Final victory state or Crown was not awarded")
	_check(lamp.visible and lamp.is_revealed, "Final arena lamp did not appear after the Sovereign was defeated")
	_check(state.gold == gold_before + 250 and "REST AT A LAMP TO SAVE" in ui.objective_label.text, "Final victory rewards or save reminder are missing")
	_check(ui.ending_panel.visible and ui.ending_backdrop.visible and paused and ambience.current_track == "finale", "Final victory did not open the epilogue and switch to finale music")
	ui._close_final_ending()
	_check(not paused and not ui.ending_panel.visible, "Epilogue did not return to exploration")
	_check(cache.open(player) and not cache.open(player), "Hollow Throne victory cache did not open once")
	await throne.get_node("SunlessReturnDoor").activate(player)
	_check(state.current_room_id == "starfall_sunless_passage", "Throne return did not reopen after victory")
	_check(state.load_game(), "Approach lamp could not roll back unsaved final victory")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	player = game.get_node("Player")
	passage = game.get_node("StarfallSunlessPassage")
	throne = game.get_node("StarfallHollowThrone")
	boss = throne.get_node("HollowSovereign")
	cache = throne.get_node("VictoryCache")
	_check(not boss.is_dead and not cache.opened and not state.has_item("sovereign_crown"), "Unsaved final victory survived lamp rollback")
	await passage.get_node("HollowThroneDoor").activate(player)
	player.global_position = boss.global_position + Vector2(-300.0, 0.0)
	await create_timer(0.18).timeout
	boss.take_damage(boss.current_health)
	await process_frame
	ui = game.get_node("UI")
	_check(ui.ending_panel.visible, "Second final victory did not reopen the epilogue")
	ui._close_final_ending()
	_check(cache.open(player), "Final cache stayed sealed after a second victory")
	lamp = throne.get_node("ThroneLamp")
	player.global_position = lamp.get_node("RespawnPoint").global_position
	_check(lamp._save_progress(player) and state.load_game(), "Saved final victory could not reload")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	throne = game.get_node("StarfallHollowThrone")
	_check(not throne.has_node("HollowSovereign") and throne.get_node("VictoryCache").opened and state.has_item("sovereign_crown"), "Saved Sovereign defeat or reward did not persist")
	game.get_node("UI")._update_route_summary()
	_check("HOLLOW THRONE  DISCOVERED  -  SOVEREIGN DEFEATED  -  CACHE 1/1" in game.get_node("UI").map_route_label.text and "MEMORY SIGILS  3/3" in game.get_node("UI").map_route_label.text, "Map omitted final route completion")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("STARFALL HOLLOW THRONE TEST PASSED")
		quit(0)
	else:
		print("STARFALL HOLLOW THRONE TEST FAILED: ", failures)
		quit(1)
