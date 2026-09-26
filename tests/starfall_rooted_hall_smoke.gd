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
	state.save_path = "res://_tmp_starfall_rooted_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var vault: Node2D = game.get_node("StarfallMemoryVault")
	var rooted: Node2D = game.get_node("StarfallRootedHall")
	var ui = game.get_node("UI")
	var vault_expansion = vault.get_node("ExpandedRoute")
	var vault_final: Rect2 = vault_expansion._chamber_rect(6)
	var vault_upper: Rect2 = vault_expansion._chamber_rect(1)
	_check(vault_final.grow(40.0).has_point(vault.get_node("RootedHallDoor").position + Vector2(0.0, 33.0)) and vault_upper.grow(40.0).has_point(vault.get_node("RootShortcutDoor").position + Vector2(0.0, 33.0)), "Vault exits do not end the deep route and upper skyway spur")
	_check(rooted.get_node("Climb1").position.y > rooted.get_node("Climb2").position.y and rooted.get_node("Climb2").position.y > rooted.get_node("UpperRootWalk").position.y, "Rooted Hall control cannot be reached by staged jumps")
	state.set_current_room("starfall_rooted_hall")
	_check(rooted.get_node("FirstStalker").is_in_group("family_beast") and rooted.get_node("FarStalker").is_in_group("family_beast"), "Rooted Hall is missing its Beast enemy family")
	for enemy in get_nodes_in_group("enemy"):
		_check(not game.get_node("StarfallCitadel").is_ancestor_of(enemy), "Rooted Hall added an enemy inside the safe city")
	state.set_current_room("starfall_memory_vault")
	var lamp = vault.get_node("VaultLamp")
	player.global_position = lamp.get_node("RespawnPoint").global_position
	_check(lamp._save_progress(player), "Vault lamp could not save before Rooted Hall")
	_check(not vault.get_node("RootShortcutDoor")._requirements_met(), "Upper Vault shortcut opened before Root Control")
	await vault.get_node("RootedHallDoor").activate(player)
	_check(state.current_room_id == "starfall_rooted_hall" and player.global_position.distance_to(rooted.get_node("Entry").global_position) < 45.0, "Vault forward door did not enter Rooted Hall")
	_check(ui.zone_title_label.text == "ROOTED HALL" and "ROOTS ACTIVE" in ui.objective_label.text, "Rooted Hall did not announce its danger")
	_check(game.get_node("AmbientSoundscape").current_track == "starfall_rooted_hall", "Rooted Hall ambience did not start")
	var first_snare = rooted.get_node("FirstSnare")
	var second_snare = rooted.get_node("SecondSnare")
	_check(not first_snare.disabled and not second_snare.disabled, "Root snares are quiet before the control")
	first_snare.phase = "idle"
	first_snare._advance_phase()
	_check(first_snare.phase == "warning" and first_snare.warning_line.default_color.a > 0.8, "Root snare has no visible warning before damage")
	var stalker = rooted.get_node("FirstStalker")
	player.global_position = stalker.global_position + Vector2(75, 0)
	stalker.attack_cooldown = 0.0
	await physics_frame
	await process_frame
	_check(stalker.phase == "warning" and stalker.warning_line.visible and not stalker.strike_area.monitoring, "Root Stalker attacks without its warning phase")
	stalker.take_damage(1)
	_check(stalker.phase == "recovery" and not stalker.warning_line.visible, "Hitting Root Stalker did not interrupt its windup")
	var far_stalker = rooted.get_node("FarStalker")
	player.global_position = far_stalker.global_position + Vector2(50, 0)
	far_stalker.target_player = player
	far_stalker._begin_warning()
	_check(far_stalker.warning_line.visible and not far_stalker.strike_area.monitoring, "Root Stalker burst did not start with a safe warning")
	var health_before: int = player.current_health
	far_stalker._begin_burst()
	await create_timer(0.15).timeout
	_check(player.current_health == health_before - 2, "Telegraphed thorn burst did not hit once for 2 damage: %d -> %d, phase %s, overlaps %d" % [health_before, player.current_health, far_stalker.phase, far_stalker.strike_area.get_overlapping_bodies().size()])
	var control = rooted.get_node("RootControl")
	control._on_body_entered(player)
	_check(not bool(state.unlocked_shortcuts.get("starfall_root_channels", false)), "Touching Root Control activated it")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	control._on_input_event(game.get_viewport(), click, 0)
	_check(bool(state.unlocked_shortcuts.get("starfall_root_channels", false)) and first_snare.disabled and second_snare.disabled, "Root Control did not quiet both snares")
	_check(rooted.get_node("VaultShortcutDoor")._requirements_met() and vault.get_node("RootShortcutDoor")._requirements_met(), "Root Control did not open both shortcut doors")
	_check("ROOTS QUIET" in ui.objective_label.text, "HUD did not update after quieting the roots")
	_check(state.load_game(), "Vault lamp could not roll back unsaved Root Control")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	vault = game.get_node("StarfallMemoryVault")
	rooted = game.get_node("StarfallRootedHall")
	_check(not rooted.get_node("FirstSnare").disabled and not rooted.get_node("VaultShortcutDoor")._requirements_met(), "Unsaved Root Control did not roll back")
	await vault.get_node("RootedHallDoor").activate(player)
	_check(rooted.get_node("RootControl").activate(player), "Root Control could not be used after rollback")
	_check(rooted.get_node("HighCache").open(player) and not rooted.get_node("HighCache").open(player), "High Root cache did not award exactly once")
	await rooted.get_node("VaultShortcutDoor").activate(player)
	_check(state.current_room_id == "starfall_memory_vault" and player.global_position.distance_to(vault.get_node("RootShortcutReturn").global_position) < 45.0, "Rooted upper shortcut did not reach Vault skyway")
	await vault.get_node("RootShortcutDoor").activate(player)
	_check(state.current_room_id == "starfall_rooted_hall" and player.global_position.distance_to(rooted.get_node("ShortcutReturn").global_position) < 45.0, "Vault skyway did not return to Rooted Hall")
	await rooted.get_node("VaultReturnDoor").activate(player)
	_check(state.current_room_id == "starfall_memory_vault" and player.global_position.distance_to(vault.get_node("RootedReturn").global_position) < 45.0, "Rooted Hall floor return failed")
	player.global_position = vault.get_node("VaultLamp/RespawnPoint").global_position
	_check(vault.get_node("VaultLamp")._save_progress(player), "Root Control and cache could not be saved at the Vault lamp")
	_check(state.load_game(), "Saved Rooted Hall progress did not load")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	_check(game.get_node("StarfallRootedHall/FirstSnare").disabled and game.get_node("StarfallRootedHall/SecondSnare").disabled, "Saved roots resumed after reload")
	_check(game.get_node("StarfallRootedHall/HighCache").opened and game.get_node("StarfallMemoryVault/RootShortcutDoor")._requirements_met(), "Saved cache or shortcut was lost")
	game.get_node("UI")._update_route_summary()
	_check("ROOTED HALL  DISCOVERED  -  ROOTS QUIET  -  CACHE 1/1" in game.get_node("UI").map_route_label.text, "Map did not summarize Rooted Hall")
	state.set_current_room("starfall_rooted_hall")
	var saved_stalker = game.get_node("StarfallRootedHall/FirstStalker")
	var old_health: int = saved_stalker.max_health
	state.set_zone_tier("starfall_reach", 1)
	_check(saved_stalker.max_health == old_health + 1 and game.get_node("StarfallRootedHall/FirstSnare").warning_duration < 0.9, "Rooted Hall does not scale when Starfall is awakened")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("STARFALL ROOTED HALL TEST PASSED")
		quit(0)
	else:
		print("STARFALL ROOTED HALL TEST FAILED: ", failures)
		quit(1)
