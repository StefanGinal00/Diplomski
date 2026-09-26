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
	state.save_path = "res://_tmp_starfall_outer_route_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var outer: Node2D = game.get_node("StarfallOutskirts")
	var silent: Node2D = game.get_node("StarfallSilentGate")
	var vault: Node2D = game.get_node("StarfallMemoryVault")
	var ui = game.get_node("UI")
	for enemy in get_nodes_in_group("enemy"):
		_check(not game.get_node("StarfallCitadel").is_ancestor_of(enemy), "The new outer route spawned an enemy inside the safe city")
	var outer_final: Rect2 = outer.get_node("ExpandedRoute")._chamber_rect(6)
	_check(outer_final.grow(40.0).has_point(outer.get_node("SilentGateDoor").position + Vector2(0.0, 33.0)), "Outer Watch forward door does not end the final chamber")
	_check(silent.get_node("HighRelay").position.y < silent.get_node("LowRelay").position.y - 700.0 and silent.get_node("LowRelay").position.y < silent.get_node("VaultDoor").position.y - 250.0, "Silent Gate relays do not occupy separate reachable tiers before the exit")
	_check(vault.get_node("LowerFloor").position.y > vault.get_node("LeftFloor").position.y and vault.get_node("UpperBridge").position.y < vault.get_node("LeftFloor").position.y, "Memory Vault does not offer a high and low path")
	state.set_current_room("starfall_outskirts")
	var outer_lamp = outer.get_node("OuterLamp")
	player.global_position = outer_lamp.get_node("RespawnPoint").global_position
	_check(outer_lamp._save_progress(player), "Outer Watch lamp could not save before the relays")
	await outer.get_node("SilentGateDoor").activate(player)
	_check(state.current_room_id == "starfall_ramparts", "First Silent Gate approach skipped Broken Ramparts")
	await game.get_node("StarfallRamparts/UpperShortcutDoor").activate(player)
	_check(state.current_room_id == "starfall_silent_gate" and player.global_position.distance_to(silent.get_node("Entry").global_position) < 45.0, "Outer Watch did not enter Silent Gate at its safe marker")
	_check(ui.zone_title_label.text == "SILENT GATE" and "DANGER" in ui.objective_label.text, "Silent Gate did not announce danger")
	_check(game.get_node("AmbientSoundscape").current_track == "starfall_silent_gate", "Silent Gate ambience did not start")
	var gate = silent.get_node("VaultDoor")
	_check(not gate._requirements_met(), "Memory Vault opened before both relays")
	var denied := [0]
	gate.access_denied.connect(func(_message: String) -> void: denied[0] += 1)
	await gate.activate(player)
	_check(denied[0] == 1 and state.current_room_id == "starfall_silent_gate", "Locked vault gate did not reject explicit entry")
	var high_relay = silent.get_node("HighRelay")
	high_relay._on_body_entered(player)
	_check(not bool(state.unlocked_shortcuts.get("starfall_silent_high", false)), "Touching a relay activated it without a click")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	high_relay._on_input_event(game.get_viewport(), click, 0)
	_check(bool(state.unlocked_shortcuts.get("starfall_silent_high", false)) and not gate._requirements_met(), "Clicking the high relay opened the vault by itself or did not activate it")
	_check(not silent.get_node("HighRelay").activate(player), "High relay activated twice")
	_check("RELAYS 1/2" in ui.objective_label.text, "Relay progress is absent from the objective")
	_check(state.load_game(), "Outer Watch lamp could not restore unsaved relay progress")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	outer = game.get_node("StarfallOutskirts")
	silent = game.get_node("StarfallSilentGate")
	vault = game.get_node("StarfallMemoryVault")
	gate = silent.get_node("VaultDoor")
	_check(not gate._requirements_met() and not bool(state.unlocked_shortcuts.get("starfall_silent_high", false)), "Unsaved relay did not roll back")
	await outer.get_node("SilentGateDoor").activate(player)
	_check(state.current_room_id == "starfall_ramparts", "Unsaved Ramparts traversal did not reset")
	await game.get_node("StarfallRamparts/UpperShortcutDoor").activate(player)
	_check(silent.get_node("LowRelay").activate(player) and not gate._requirements_met(), "Low relay alone opened the vault")
	_check(silent.get_node("HighRelay").activate(player) and gate._requirements_met(), "Both relays did not open the vault")
	await gate.activate(player)
	_check(state.current_room_id == "starfall_memory_vault" and player.global_position.distance_to(vault.get_node("Entry").global_position) < 45.0, "Memory Vault did not open at its entry marker")
	_check(game.get_node("AmbientSoundscape").current_track == "starfall_memory_vault", "Memory Vault ambience did not start")
	var sky_cache = vault.get_node("BridgeCache")
	var pit_cache = vault.get_node("PitCache")
	_check(sky_cache.open(player) and pit_cache.open(player), "The two Vault paths did not give their rewards")
	_check(not sky_cache.open(player) and not pit_cache.open(player), "Vault rewards could be claimed twice")
	var vault_lamp = vault.get_node("VaultLamp")
	player.global_position = vault_lamp.get_node("RespawnPoint").global_position
	_check(vault_lamp._save_progress(player) and state.checkpoint_lamp_id == "starfall_vault_lamp", "Vault lamp did not save progress")
	await vault.get_node("SilentReturnDoor").activate(player)
	_check(state.current_room_id == "starfall_silent_gate" and player.global_position.distance_to(silent.get_node("VaultReturn").global_position) < 45.0, "Vault return route failed")
	await silent.get_node("OuterReturnDoor").activate(player)
	_check(state.current_room_id == "starfall_outskirts" and player.global_position.distance_to(outer.get_node("SilentGateReturn").global_position) < 45.0, "Silent Gate return route failed")
	_check(state.load_game() and state.current_room_id == "starfall_memory_vault", "Vault lamp did not restore its room")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	_check(game.get_node("StarfallSilentGate/VaultDoor")._requirements_met(), "Saved relays did not restore the vault gate")
	_check(game.get_node("StarfallMemoryVault/BridgeCache").opened and game.get_node("StarfallMemoryVault/PitCache").opened, "Saved Vault caches reopened")
	_check(state.get_discovered_lamps().has("starfall_vault_lamp"), "Vault lamp was not discovered after loading")
	game.get_node("UI")._update_route_summary()
	_check("SILENT GATE  DISCOVERED  -  RELAYS 2/2" in game.get_node("UI").map_route_label.text and "MEMORY VAULT  DISCOVERED  -  CACHES 2/2" in game.get_node("UI").map_route_label.text, "Map does not summarize new Starfall route")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("STARFALL OUTER ROUTE TEST PASSED")
		quit(0)
	else:
		print("STARFALL OUTER ROUTE TEST FAILED: ", failures)
		quit(1)
