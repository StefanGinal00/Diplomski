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
	state.save_path = "res://_tmp_ash_castellan_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	var player: Player = game.get_node("Player")
	var chapel = game.get_node("AshChapel")
	var throne = game.get_node("CastellanThrone")
	var hearth = game.get_node("CinderHearth")
	var boss = throne.get_node("AshCastellan")
	var ui = game.get_node("UI")
	var soundscape = game.get_node("AmbientSoundscape")
	var gate = chapel.get_node("ThroneDoor")
	_check(not gate._requirements_met(), "Throne opened before the four prerequisites")
	_check(not throne.get_node("HearthShortcut")._requirements_met() and not hearth.get_node("ThroneShortcut")._requirements_met(), "Hearth loop opened before boss defeat")
	state.add_item("barracks_insignia")
	state.add_item("marshal_emblem")
	state.add_item("crucible_core")
	_check(not gate._requirements_met(), "Three items bypassed Chapel bell rite")
	state.unlock_shortcut("ash_chapel_bells")
	_check(gate._requirements_met(), "Full throne requirements stayed locked")
	_check(chapel.get_node("ThroneReturn").position.distance_to(gate.position) > 45.0, "Throne return marker would bounce into gate")
	for platform_name in ["LeftEscape", "HighEscape", "RightEscape"]:
		_check(throne.get_node(platform_name + "/CollisionShape2D").one_way_collision, "Boss escape platform blocks jumping: " + platform_name)
	state.set_current_room("ash_chapel")
	player.global_position = chapel.get_node("ThroneReturn").global_position
	await gate.activate(player)
	_check(state.current_room_id == "ash_throne" and bool(state.discovered_rooms.get("ash_throne", false)), "Throne transition or discovery failed")
	_check(player.global_position.distance_to(throne.get_node("ThroneEntry").global_position) < 45.0, "Throne entry marker is wrong")
	_check(soundscape.current_track == "ash_throne", "Throne ambience did not start")
	_check("DEFEAT THE ASH CASTELLAN" in ui.objective_label.text, "Throne objective missing")
	_check(not throne.get_node("ThroneLamp")._has_nearby_threat(), "Throne lamp is blocked before the fight")
	boss.position.x = 500.0
	_check(throne.get_node("ThroneLamp")._has_nearby_threat(), "Throne lamp can be used while the boss presses the entrance")
	boss.position.x = 700.0
	player.max_health = 100
	player.current_health = 100
	player.global_position = boss.global_position + Vector2(-250.0, 0.0)
	await create_timer(0.3).timeout
	_check(boss.active and soundscape.current_track == "boss", "Castellan did not begin battle music")
	_check("ASH CASTELLAN" in ui.boss_health_label.text, "Castellan health bar is missing")
	boss._start_charge()
	_check(boss.charge_line.visible and boss.charge_windup > 0.0, "Castellan charge has no warning")
	var projectile_count: int = get_nodes_in_group("enemy_projectile").size()
	boss._fire_volley()
	_check(get_nodes_in_group("enemy_projectile").size() >= projectile_count + 2, "Castellan opening volley missing")
	boss._start_eruption()
	_check(boss.eruption_marks[0].visible and boss.eruption_marks[1].visible and boss.eruption_marks[2].visible, "Castellan floor lanes have no warning")
	boss._release_eruption()
	_check(boss.eruption_flash > 0.0, "Castellan floor attack never fired")
	boss.take_damage(13)
	_check(boss.phase == 2, "Castellan did not enter phase two")
	projectile_count = get_nodes_in_group("enemy_projectile").size()
	boss._fire_volley()
	_check(get_nodes_in_group("enemy_projectile").size() >= projectile_count + 3, "Phase two volley did not grow")
	var gold_before: int = state.gold
	boss.take_damage(13)
	await process_frame
	_check(state.has_item("castellan_seal") and bool(state.defeated_bosses.get("ash_castellan", false)), "First Castellan victory did not give seal or defeat flag")
	_check(state.gold >= gold_before + 150 and state.get_zone_tier("ashen_bastion") == 1, "Castellan rewards or awakened tier missing")
	_check(throne.get_node("HearthShortcut")._requirements_met() and hearth.get_node("ThroneShortcut")._requirements_met(), "Castellan defeat did not open Hearth loop")
	_check(soundscape.current_track == "ash_throne" and "AWAKENED CASTELLAN OPTIONAL" in ui.objective_label.text, "Boss music or objective did not clear")
	ui._update_route_summary()
	_check("ASHEN BASTION  2/10" in ui.map_route_label.text and "CASTELLAN REMATCH READY" in ui.map_route_label.text, "World map did not track Castellan victory")
	await throne.get_node("ChapelReturnDoor").activate(player)
	_check(state.current_room_id == "ash_chapel", "Throne return could not reach Chapel")
	await chapel.get_node("ThroneDoor").activate(player)
	_check(throne.has_node("AshCastellan") and throne.get_node("AshCastellan").is_rematch, "Castellan rematch did not appear on immediate return")
	var immediate_rematch = throne.get_node("AshCastellan")
	_check(not immediate_rematch.active and immediate_rematch.get_node("ChallengePrompt").visible, "Optional Castellan rematch began without a challenge")
	player.global_position = immediate_rematch.global_position + Vector2(-95.0, 0.0)
	await process_frame
	_check(not immediate_rematch.active, "Approaching the optional Castellan started combat")
	immediate_rematch.take_damage(1)
	_check(soundscape.current_track == "boss", "Dynamically spawned Castellan rematch has no boss music")
	await throne.get_node("ChapelReturnDoor").activate(player)
	_check(state.current_room_id == "ash_throne" and immediate_rematch.active and throne.get_node("ChapelReturnDoor").status_label.text == "BATTLE SEALED", "Castellan rematch allowed retreat")
	_check(not throne.get_node("ThroneLamp")._save_progress(player), "Throne lamp saved during Castellan rematch")
	immediate_rematch._on_room_changed("ash_chapel")
	_check(not immediate_rematch.active and immediate_rematch.current_health == immediate_rematch.max_health, "Forced encounter reset did not clear the Castellan")
	player.global_position = throne.get_node("ThroneLamp/RespawnPoint").global_position
	_check(throne.get_node("ThroneLamp")._save_progress(player), "Throne lamp did not save")
	_check(state.get_discovered_lamps().has("castellan_throne_lamp"), "Throne lamp did not join travel network")
	state.inventory.erase("castellan_seal")
	state.defeated_bosses.erase("ash_castellan")
	state.zone_tiers["ashen_bastion"] = 0
	_check(state.load_game(), "Castellan save did not reload")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	player = game.get_node("Player")
	throne = game.get_node("CastellanThrone")
	hearth = game.get_node("CinderHearth")
	boss = throne.get_node("AshCastellan")
	_check(boss.is_rematch and boss.max_health == 42, "Awakened Castellan was not restored")
	_check(state.has_item("castellan_seal") and state.get_zone_tier("ashen_bastion") == 1, "Saved victory or Ashen upgrade was lost")
	await throne.get_node("HearthShortcut").activate(player)
	_check(state.current_room_id == "ash_hearth" and player.global_position.distance_to(hearth.get_node("ThroneReturn").global_position) < 45.0, "Throne-to-Hearth shortcut failed")
	await hearth.get_node("ThroneShortcut").activate(player)
	_check(state.current_room_id == "ash_throne" and player.global_position.distance_to(throne.get_node("HearthReturn").global_position) < 45.0, "Hearth-to-Throne shortcut failed")
	var health_before: int = player.max_health
	boss.take_damage(21)
	_check(boss.phase == 2, "Rematch phase two missing")
	boss.take_damage(8)
	_check(boss.phase == 3, "Rematch final phase missing")
	projectile_count = get_nodes_in_group("enemy_projectile").size()
	boss._fire_volley()
	_check(get_nodes_in_group("enemy_projectile").size() >= projectile_count + 5, "Rematch final volley missing")
	boss.take_damage(boss.current_health)
	await process_frame
	_check(bool(state.boss_rematches.get("ash_castellan", false)), "Castellan rematch clear was not recorded")
	_check(state.has_item("castellan_heart") and player.max_health == health_before + 1, "Rematch permanent health reward missing")
	_check(throne.get_node("ThroneLamp")._save_progress(player), "Rematch could not be saved")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	_check(not game.get_node("CastellanThrone").has_node("AshCastellan"), "Cleared Castellan rematch respawned")
	_check(game.get_node("Player").max_health == health_before + 1 and game.get_node("CinderHearth/ThroneShortcut")._requirements_met(), "Saved rematch reward or Hearth loop disappeared")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("ASH CASTELLAN TEST PASSED")
		quit(0)
	else:
		print("ASH CASTELLAN TEST FAILED: ", failures)
		quit(1)
