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
	state.save_path = "res://_tmp_starfall_court_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	var player: Player = game.get_node("Player")
	var rooted: Node2D = game.get_node("StarfallRootedHall")
	var court: Node2D = game.get_node("StarfallEmptyCourt")
	var boss = court.get_node("Guardian")
	var cache = court.get_node("VictoryCache")
	var ui = game.get_node("UI")
	var ambience = game.get_node("AmbientSoundscape")
	var rooted_final: Rect2 = rooted.get_node("ExpandedRoute")._chamber_rect(6)
	_check(rooted_final.grow(40.0).has_point(rooted.get_node("CourtDoor").position + Vector2(0.0, 33.0)), "Court entrance does not end Rooted Hall's final chamber")
	_check(not cache._requirements_met(state) and not cache.open(player), "Guardian cache opens before victory")
	state.set_current_room("starfall_rooted_hall")
	await rooted.get_node("CourtDoor").activate(player)
	_check(state.current_room_id == "starfall_empty_court" and player.global_position.distance_to(court.get_node("Entry").global_position) < 45.0, "Rooted Hall door did not enter Empty Court")
	_check(ui.zone_title_label.text == "EMPTY COURT" and "STARFALL GUARDIAN" in ui.objective_label.text, "Empty Court title or objective missing")
	_check(ambience.current_track == "starfall_empty_court", "Empty Court ambience did not start")
	await court.get_node("RootReturnDoor").activate(player)
	_check(state.current_room_id == "starfall_rooted_hall", "Court return should be open before the Guardian fight")
	await rooted.get_node("CourtDoor").activate(player)
	var lamp = court.get_node("CourtLamp")
	_check(not lamp._has_nearby_threat(), "Pre-fight lamp blocked by distant Guardian")
	player.global_position = lamp.get_node("RespawnPoint").global_position
	_check(lamp._save_progress(player), "Court lamp could not save before fight")
	_check(state.get_discovered_lamps().has("starfall_court_lamp"), "Court lamp missing from travel network")
	player.max_health = 100
	player.current_health = 100
	player.global_position = boss.global_position + Vector2(-260.0, 0.0)
	await create_timer(0.2).timeout
	_check(boss.active and ambience.current_track == "boss" and ui.boss_health_panel.visible, "Guardian battle did not activate music and boss HUD")
	await court.get_node("RootReturnDoor").activate(player)
	_check(state.current_room_id == "starfall_empty_court" and boss.active and court.get_node("RootReturnDoor").status_label.text == "BATTLE SEALED", "Guardian fight did not seal the return door")
	_check(lamp._has_nearby_threat() and not lamp._save_progress(player), "Court lamp allowed a save during the boss fight")
	ui._open_world_map(true, lamp)
	_check(not ui.world_map_panel.visible, "Fast-travel map opened during the Guardian fight")
	var forced_transition: bool = await root.get_node("RoomTransition").transition_player(player, rooted.get_node("CourtReturn").global_position, "starfall_rooted_hall")
	_check(not forced_transition and state.current_room_id == "starfall_empty_court", "Direct room transition bypassed the Guardian lock")
	boss._start_charge()
	_check(boss.charge_line.visible and boss.charge_windup > 0.0, "Guardian charge has no warning")
	boss._start_volley()
	_check(boss.volley_line.visible and boss.volley_windup > 0.0, "Guardian volley has no aiming warning")
	var projectile_count: int = get_nodes_in_group("enemy_projectile").size()
	boss._fire_volley()
	_check(get_nodes_in_group("enemy_projectile").size() >= projectile_count + 3, "Guardian first-phase volley is missing projectiles")
	boss._start_pulse()
	_check(boss.pulse_indices.size() == 1 and boss.floor_marks[boss.pulse_indices[0]].visible, "Guardian floor strike is not marked")
	boss._release_pulse()
	_check(boss.pulse_flash > 0.0, "Guardian floor strike never fired")
	boss.take_damage(11)
	_check(boss.phase == 2, "Guardian did not enter phase two")
	projectile_count = get_nodes_in_group("enemy_projectile").size()
	boss._fire_volley()
	_check(get_nodes_in_group("enemy_projectile").size() >= projectile_count + 5, "Guardian phase-two volley did not widen")
	boss._start_pulse()
	_check(boss.pulse_indices.size() == 2 and boss.pulse_indices[0] != boss.pulse_indices[1], "Phase-two pulse does not leave one safe lane")
	var gold_before: int = state.gold
	var shards_before: int = int(state.inventory.get("resonance_shard", 0))
	var points_before: int = player.skill_points
	boss.take_damage(boss.current_health)
	await process_frame
	_check(bool(state.defeated_bosses.get("starfall_guardian", false)) and bool(state.unlocked_shortcuts.get("starfall_court_cleared", false)), "Guardian defeat and Court event were not saved in live state")
	_check(state.gold == gold_before + 110 and int(state.inventory.get("resonance_shard", 0)) == shards_before + 1 and player.skill_points >= points_before + 2, "Guardian first-clear rewards are wrong")
	_check(cache._requirements_met(state) and cache.open(player) and not cache.open(player), "Relic cache did not unlock exactly once")
	_check("COURT CLEAR" in ui.objective_label.text, "HUD did not record Guardian victory")
	await court.get_node("RootReturnDoor").activate(player)
	_check(state.current_room_id == "starfall_rooted_hall" and ambience.current_track == "starfall_rooted_hall", "Court return did not reopen after Guardian victory")
	await rooted.get_node("CourtDoor").activate(player)
	_check(state.load_game(), "Pre-fight Court lamp could not roll back unsaved victory")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	player = game.get_node("Player")
	court = game.get_node("StarfallEmptyCourt")
	boss = court.get_node("Guardian")
	cache = court.get_node("VictoryCache")
	lamp = court.get_node("CourtLamp")
	_check(not boss.is_dead and not cache.opened and not cache._requirements_met(state), "Unsaved Guardian victory did not roll back")
	_check(state.gold == gold_before and int(state.inventory.get("resonance_shard", 0)) == shards_before, "Unsaved Court rewards survived lamp rollback")
	boss.take_damage(boss.current_health)
	await process_frame
	_check(cache.open(player), "Guardian relic stayed sealed after a second victory")
	_check(lamp._save_progress(player), "Court lamp could not save victory")
	_check(state.load_game(), "Saved Court victory could not reload")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	court = game.get_node("StarfallEmptyCourt")
	player = game.get_node("Player")
	_check(not court.has_node("Guardian") and court.get_node("VictoryCache").opened, "Saved Guardian victory or cache did not persist")
	game.get_node("UI")._update_route_summary()
	_check("EMPTY COURT  DISCOVERED  -  GUARDIAN DEFEATED  -  CACHE 1/1" in game.get_node("UI").map_route_label.text, "Map omitted Court victory")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("STARFALL EMPTY COURT TEST PASSED")
		quit(0)
	else:
		print("STARFALL EMPTY COURT TEST FAILED: ", failures)
		quit(1)
