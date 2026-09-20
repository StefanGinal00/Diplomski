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
	state.save_path = "res://_tmp_undertow_vault_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var tide = game.get_node("TideWell")
	var vault = game.get_node("UndertowVault")
	var ui = game.get_node("UI")
	var vault_door = tide.get_node("VaultDoor")
	var upper_seal = vault.get_node("UpperSeal")
	var far_seal = vault.get_node("FarSeal")
	var reliquary = vault.get_node("VaultCache")
	_check(not vault_door._requirements_met(), "Undertow Vault opened before the Tide Core")
	state.add_item("tide_core")
	state.set_current_room("echo_tide_well")
	var tide_lamp_position: Vector2 = tide.get_node("TideLamp/RespawnPoint").global_position
	player.global_position = tide_lamp_position
	_check(tide.get_node("TideLamp")._save_progress(player), "Tide Well lamp did not register before Vault exploration")
	vault_door._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_vault" and bool(state.discovered_rooms.get("echo_vault", false)), "Tide Well did not discover Undertow Vault")
	_check(player.global_position.distance_to(vault.get_node("VaultEntry").global_position) < 45.0, "Vault entry marker is wrong")
	_check(game.get_node("AmbientSoundscape").current_track == "echo_vault", "Vault ambience did not start")
	_check("0/2" in ui.objective_label.text and "SEALS 0/2" in reliquary.prompt.text, "Vault seal hints did not start at zero")
	var gold_before: int = state.gold
	_check(not reliquary.open(player) and state.gold == gold_before and not state.has_item("tideguard_mantle"), "Sealed reliquary paid before either seal")
	_check(upper_seal.activate(player), "Upper Vault seal did not activate")
	_check(not reliquary.open(player) and "SEALS 1/2" in reliquary.prompt.text and "1/2" in ui.objective_label.text, "One Vault seal opened reliquary early")
	_check(far_seal.activate(player), "Far Vault seal did not activate")
	_check("CLAIM THE RELIQUARY" in ui.objective_label.text, "Second seal did not update objective")
	_check(reliquary.open(player) and state.has_item("tideguard_mantle"), "Vault reliquary did not award Tideguard Mantle")
	_check(state.gold >= gold_before + 42 and not reliquary.open(player), "Vault reliquary reward is missing or repeatable")
	_check("TIDEGUARD MANTLE CLAIMED" in ui.objective_label.text, "Vault objective did not show claimed relic")
	_check(state.get_equipped_defense_id().is_empty(), "Tideguard Mantle equipped without player choice")
	ui.selected_item_id = "tideguard_mantle"
	ui._update_item_details()
	_check(ui.item_action_button.text == "Equip" and "tidal surges" in ui.item_description_label.text, "Mantle inventory details are missing")
	ui._on_inventory_action_pressed()
	_check(state.get_equipped_defense_id() == "tideguard_mantle", "Mantle cannot be equipped from inventory")
	var test_surge = load("res://TidePulse.tscn").instantiate()
	game.add_child(test_surge)
	test_surge.global_position = Vector2(-2000, -2000)
	player.set_physics_process(false)
	player.global_position = test_surge.global_position
	await create_timer(0.1).timeout
	test_surge._advance_phase()
	test_surge._advance_phase()
	await create_timer(0.1).timeout
	_check(test_surge.get_overlapping_bodies().has(player), "Surge immunity test could not detect player overlap")
	var hp_before: int = player.current_health
	test_surge._process(0.01)
	_check(player.current_health == hp_before, "Tideguard Mantle did not prevent surge damage")
	_check(state.unequip_defense(), "Tideguard Mantle could not be unequipped")
	player.is_invulnerable = false
	test_surge._process(0.01)
	_check(player.current_health == hp_before - 1, "Unequipped Mantle still prevented surge damage")
	_check(state.equip_item("tideguard_mantle"), "Tideguard Mantle could not be re-equipped")
	player.invulnerability_timer.stop()
	player.is_invulnerable = false
	var hp_before_enemy_hit: int = player.current_health
	player.take_damage(2)
	_check(player.current_health == hp_before_enemy_hit - 2, "Tideguard Mantle incorrectly reduced enemy damage")
	player.heal(3)
	test_surge.queue_free()
	await process_frame
	player.set_physics_process(true)
	state.set_zone_tier("echo_grotto", 1)
	_check(vault.has_node("Cache_vault_undertow"), "Awakened Vault cache is missing")
	vault.get_node("ReturnDoor")._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_tide_well" and player.global_position.distance_to(tide.get_node("VaultReturn").global_position) < 45.0, "Vault return door did not reach Tide Well")
	vault_door._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_vault" and vault.has_node("vault_echo_wisp"), "Awakened Vault encounter did not appear on return")
	var awakened_cache = vault.get_node("Cache_vault_undertow")
	_check(awakened_cache.open(player), "Awakened Vault cache did not open")
	_check(game.get_node("QuestManager")._get_return_cache_count("echo_grotto") == 1, "Awakened Vault cache did not count for Resonance Sweep")
	var vault_lamp_position: Vector2 = vault.get_node("VaultLamp/RespawnPoint").global_position
	player.global_position = vault_lamp_position
	_check(vault.get_node("VaultLamp")._save_progress(player), "Vault lamp did not save progress")
	_check(state.get_discovered_lamps().size() == 2, "Vault lamp did not join the fast-travel network")
	state.unlocked_shortcuts.clear()
	state.opened_caches.clear()
	state.inventory.erase("tideguard_mantle")
	state.equipped_items["defense"] = ""
	state.discovered_rooms.erase("echo_vault")
	_check(state.load_game(), "Vault progress did not reload")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	vault = game.get_node("UndertowVault")
	ui = game.get_node("UI")
	_check(vault.get_node("UpperSeal").is_active and vault.get_node("FarSeal").is_active, "Saved Vault seals did not relight")
	_check(vault.get_node("VaultCache").opened and vault.get_node("Cache_vault_undertow").opened, "Saved Vault caches reopened")
	_check(state.has_item("tideguard_mantle") and state.get_equipped_defense_id() == "tideguard_mantle", "Saved Tideguard Mantle or equipment choice was lost")
	_check(vault.get_node("VaultLamp").is_active and game.get_node("TideWell/TideLamp").is_active, "Saved Vault or Tide lamp did not relight")
	ui._update_route_summary()
	_check("2/8 PLAYABLE ROOMS" in ui.map_route_label.text and "CACHES 2/10" in ui.map_route_label.text, "Map did not track Undertow Vault")
	_check(ui.get_node("WorldMapPanel/RouteScroll").get_global_rect().intersection(ui.map_travel_button.get_global_rect()).get_area() <= 0.0, "World-map route viewport overlaps travel button")
	ui._open_world_map(true, vault.get_node("VaultLamp"))
	ui.selected_lamp_id = "tide_well_lamp"
	ui._update_map_details()
	_check(not ui.map_travel_button.disabled, "Tide Well lamp is not a reachable Vault travel destination")
	ui._on_map_travel_pressed()
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_tide_well" and state.checkpoint_lamp_id == "tide_well_lamp", "Vault-to-Tide fast travel failed")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("UNDERTOW VAULT TEST PASSED")
		quit(0)
	else:
		print("UNDERTOW VAULT TEST FAILED: ", failures)
		quit(1)
