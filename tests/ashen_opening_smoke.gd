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
	state.save_path = "res://_tmp_ashen_opening_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var sanctum = game.get_node("ResonanceSanctum")
	var causeway = game.get_node("BrokenCauseway")
	var forge = game.get_node("CinderForge")
	var ui = game.get_node("UI")
	var ash_gate = sanctum.get_node("AshenGate")
	var fan = forge.get_node("CoolingFan")
	var forge_cache = forge.get_node("ForgeCache")
	var vent = causeway.get_node("FirstVent")
	_check(not ash_gate._requirements_met(), "Ashen gate opened before Matriarch defeat")
	state.add_item("matriarch_seal")
	_check(not ash_gate._requirements_met(), "Matriarch Seal alone bypassed the Ashen boss gate")
	state.inventory.erase("matriarch_seal")
	state.mark_boss_defeated("echo_matriarch")
	_check(not ash_gate._requirements_met(), "Matriarch defeat without seal bypassed the Ashen gate")
	state.add_item("matriarch_seal")
	_check(ash_gate._requirements_met(), "Ashen gate stayed locked after Matriarch defeat and seal")
	_check(not vent.disabled and not forge.get_node("ForgeVent").disabled, "Ashen vents began disabled")
	_check(not forge_cache.open(player), "Forge cache opened before cooling fan")
	for index in range(1, 6):
		var step = causeway.get_node("Step%d" % index)
		_check(step.get_node("CollisionShape2D").one_way_collision, "Causeway step %d blocks upward route" % index)
		if index > 1:
			var previous = causeway.get_node("Step%d" % (index - 1))
			_check(absf(step.position.x - previous.position.x) <= 135.0 and absf(step.position.y - previous.position.y) <= 65.0, "Causeway step %d is too far away" % index)
	_check(causeway.get_node("Floor").position.y - causeway.get_node("Step1").position.y <= 85.0, "Causeway high route cannot be reached without Dash")
	state.set_current_room("echo_sanctum")
	var sanctum_lamp_position: Vector2 = sanctum.get_node("SanctumLamp/RespawnPoint").global_position
	player.global_position = sanctum_lamp_position
	_check(sanctum.get_node("SanctumLamp")._save_progress(player), "Sanctum lamp did not save before Ashen gate")
	ash_gate._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "ash_causeway" and bool(state.discovered_rooms.get("ash_causeway", false)), "Ashen gate did not discover Broken Causeway")
	_check(player.global_position.distance_to(causeway.get_node("CausewayEntry").global_position) < 45.0, "Causeway entry marker is wrong")
	_check(game.get_node("AmbientSoundscape").current_track == "ash_causeway", "Causeway ambience did not start")
	_check("CROSS THE VENTS" in ui.objective_label.text, "Causeway objective is missing")
	_check(causeway.get_node("NearFiend").zone_id == "ashen_bastion" and causeway.get_node("NearFiend").is_in_group("family_demon"), "Ash Fiend has wrong zone or family")
	_check(causeway.get_node("FarSentry").zone_id == "ashen_bastion" and causeway.get_node("FarSentry").is_in_group("family_construct"), "Ash Sentry has wrong zone or family")
	_check(causeway.get_node("FarSentry").projectile_color == Color(1, 0.54, 0.2, 1), "Ash Sentry still fires Shaft-colored bolts")
	var causeway_supply = causeway.get_node("UpperCache")
	var gold_before: int = state.gold
	_check(causeway_supply.open(player) and state.gold >= gold_before + 30 and state.has_item("healing_herb"), "Causeway upper cache did not reward exploration")
	_check(not causeway_supply.open(player), "Causeway cache paid twice")
	state.add_item("tideguard_mantle")
	state.equip_item("tideguard_mantle")
	player.max_health = 100
	player.current_health = 100
	vent.set_process(false)
	player.set_physics_process(false)
	player.global_position = vent.global_position
	await create_timer(0.1).timeout
	vent._advance_phase()
	_check(vent.phase == "warning", "Heat vent did not telegraph its burst")
	vent._advance_phase()
	await create_timer(0.1).timeout
	_check(vent.phase == "active" and vent.get_overlapping_bodies().has(player), "Heat vent did not become active around player")
	var hp_before: int = player.current_health
	vent._process(0.01)
	_check(player.current_health == hp_before - 2, "Heat vent did not deal 2 damage or Tideguard wrongly blocked fire")
	vent._process(0.01)
	_check(player.current_health == hp_before - 2, "Heat vent damaged player repeatedly in one burst")
	player.global_position = causeway.get_node("CausewayEntry").global_position
	player.set_physics_process(true)
	vent.set_process(true)
	state.unequip_defense()
	var causeway_lamp_position: Vector2 = causeway.get_node("CausewayLamp/RespawnPoint").global_position
	player.global_position = causeway_lamp_position
	_check(causeway.get_node("CausewayLamp")._save_progress(player), "Causeway lamp did not save after entry")
	causeway.get_node("ForgeDoor")._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "ash_forge" and bool(state.discovered_rooms.get("ash_forge", false)), "Causeway did not discover Cinder Forge")
	_check(player.global_position.distance_to(forge.get_node("ForgeEntry").global_position) < 45.0, "Forge entry marker is wrong")
	_check(game.get_node("AmbientSoundscape").current_track == "ash_forge", "Forge ambience did not start")
	_check("COOLING FAN" in ui.objective_label.text, "Forge objective did not identify the fan")
	for index in range(1, 7):
		var step = forge.get_node("Step%d" % index)
		_check(step.get_node("CollisionShape2D").one_way_collision, "Forge step %d blocks climbing" % index)
		if index > 1:
			var previous = forge.get_node("Step%d" % (index - 1))
			_check(absf(step.position.x - previous.position.x) <= 145.0 and absf(step.position.y - previous.position.y) <= 75.0, "Forge step %d is too far away" % index)
	_check(fan.activate(player), "Cooling fan did not activate")
	_check(bool(state.unlocked_shortcuts.get("ash_forge_fan", false)) and not fan.activate(player), "Cooling fan did not persist as one-time event")
	_check(vent.disabled and causeway.get_node("SecondVent").disabled and forge.get_node("ForgeVent").disabled, "Cooling fan did not quiet all opening vents")
	_check("FORGE AIRFLOW RESTORED" in ui.objective_label.text, "Forge objective did not update after fan")
	gold_before = state.gold
	_check(forge_cache.open(player) and state.gold >= gold_before + 48 and state.has_item("resonance_shard"), "Forge cache did not award shard and gold")
	_check(not forge_cache.open(player), "Forge cache paid twice")
	forge.get_node("ReturnDoor")._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "ash_causeway" and player.global_position.distance_to(causeway.get_node("ForgeReturn").global_position) < 45.0, "Forge could not return to Causeway")
	_check("VENTS QUIET" in ui.objective_label.text, "Causeway did not show fan effect on return")
	causeway.get_node("SanctumReturnDoor")._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_sanctum" and player.global_position.distance_to(sanctum.get_node("AshenReturn").global_position) < 45.0, "Causeway could not return to Sanctum")
	ash_gate._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "ash_causeway", "Sanctum gate closed after Ashen return")
	causeway.get_node("ForgeDoor")._on_body_entered(player)
	await create_timer(0.5).timeout
	var forge_lamp_position: Vector2 = forge.get_node("ForgeLamp/RespawnPoint").global_position
	player.global_position = forge_lamp_position
	_check(forge.get_node("ForgeLamp")._save_progress(player), "Forge lamp did not save progress")
	_check(state.get_discovered_lamps().size() == 3, "Ashen lamps did not join fast travel")
	state.unlocked_shortcuts.erase("ash_forge_fan")
	state.opened_caches.erase("ash_causeway_supply")
	state.opened_caches.erase("ash_forge_supply")
	state.discovered_rooms.erase("ash_causeway")
	state.discovered_rooms.erase("ash_forge")
	_check(state.load_game(), "Ashen progress did not reload")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	causeway = game.get_node("BrokenCauseway")
	forge = game.get_node("CinderForge")
	ui = game.get_node("UI")
	_check(game.get_node("ResonanceSanctum/AshenGate")._requirements_met(), "Saved Matriarch progress closed Ashen gate")
	_check(forge.get_node("CoolingFan").is_active and causeway.get_node("FirstVent").disabled and causeway.get_node("SecondVent").disabled and forge.get_node("ForgeVent").disabled, "Saved fan did not restore safe vents")
	_check(causeway.get_node("UpperCache").opened and forge.get_node("ForgeCache").opened, "Saved Ashen caches reopened")
	_check(causeway.get_node("CausewayLamp").is_active and forge.get_node("ForgeLamp").is_active, "Saved Ashen lamps went dark")
	ui._update_route_summary()
	_check("ASHEN BASTION  2/3 OPENING ROOMS" in ui.map_route_label.text and "CACHES 2/3" in ui.map_route_label.text and "FAN ON" in ui.map_route_label.text, "World map did not track Ashen opening")
	ui._open_world_map(true, forge.get_node("ForgeLamp"))
	await process_frame
	var route_scroll: ScrollContainer = ui.get_node("WorldMapPanel/RouteScroll")
	_check(ui.map_route_label.size.y >= ui.map_route_label.get_minimum_size().y and route_scroll.get_v_scroll_bar().max_value > route_scroll.size.y, "Ashen summary is not fully available in the scrollable map")
	route_scroll.scroll_vertical = 30
	await process_frame
	_check(route_scroll.scroll_vertical > 0, "World-map route summary cannot scroll to later zones")
	ui.selected_lamp_id = "ash_causeway_lamp"
	ui._update_map_details()
	_check(not ui.map_travel_button.disabled, "Causeway lamp is not reachable from Forge")
	ui._on_map_travel_pressed()
	await create_timer(0.5).timeout
	_check(state.current_room_id == "ash_causeway" and state.checkpoint_lamp_id == "ash_causeway_lamp", "Forge-to-Causeway fast travel failed")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("ASHEN OPENING TEST PASSED")
		quit(0)
	else:
		print("ASHEN OPENING TEST FAILED: ", failures)
		quit(1)
