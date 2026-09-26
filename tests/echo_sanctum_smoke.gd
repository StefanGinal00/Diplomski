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
	state.save_path = "res://_tmp_echo_sanctum_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	var player = game.get_node("Player")
	var nest = game.get_node("EchoNest")
	var sanctum = game.get_node("ResonanceSanctum")
	var boss = sanctum.get_node("EchoMatriarch")
	var entry_door = nest.get_node("SanctumDoor")
	var shortcut = sanctum.get_node("GrottoShortcut")
	var ashen_gate = sanctum.get_node("AshenGate")
	var ui = game.get_node("UI")
	var soundscape = game.get_node("AmbientSoundscape")
	_check(not entry_door._requirements_met(), "Sanctum opened without relics")
	state.add_item("tide_core")
	_check(not entry_door._requirements_met(), "Sanctum opened without Nest Crest")
	state.add_item("nest_crest")
	_check(not entry_door._requirements_met(), "Sanctum ignored Nest clear event")
	state.unlock_shortcut("echo_nest_cleared")
	_check(entry_door._requirements_met(), "Sanctum stayed locked after full requirements")
	_check(not shortcut._requirements_met(), "Grotto shortcut opened before Matriarch")
	_check(not ashen_gate._requirements_met(), "Ashen Bastion opened before Matriarch")
	_check(sanctum.get_node("LeftPlatform/CollisionShape2D").one_way_collision and sanctum.get_node("RightPlatform/CollisionShape2D").one_way_collision, "Boss platforms block jumps")
	entry_door.activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_sanctum", "Sanctum entry transition failed")
	_check(soundscape.current_track == "echo_sanctum", "Sanctum ambience missing")
	_check("DEFEAT ECHO MATRIARCH" in ui.objective_label.text, "Sanctum objective missing")
	player.max_health = 100
	player.current_health = 100
	player.global_position = boss.global_position + Vector2(-200.0, 92.0)
	await create_timer(0.35).timeout
	_check(boss.active, "Matriarch did not activate")
	_check(soundscape.current_track == "boss", "Matriarch boss music did not start")
	_check("ECHO MATRIARCH" in ui.boss_health_label.text, "Matriarch HUD name missing")
	await sanctum.get_node("ReturnDoor").activate(player)
	_check(state.current_room_id == "echo_sanctum" and sanctum.get_node("ReturnDoor").status_label.text == "BATTLE SEALED", "Matriarch fight allowed retreat")
	var projectile_count: int = get_nodes_in_group("enemy_projectile").size()
	boss._fire_fan()
	_check(get_nodes_in_group("enemy_projectile").size() >= projectile_count + 3, "Matriarch fan attack missing")
	boss._start_pulse()
	_check(boss.pulse_ring.visible, "Matriarch pulse was not telegraphed")
	projectile_count = get_nodes_in_group("enemy_projectile").size()
	boss._fire_ring()
	_check(get_nodes_in_group("enemy_projectile").size() >= projectile_count + 8, "Matriarch ring attack missing")
	boss.take_damage(10)
	_check(boss.phase == 2, "Matriarch did not enter phase two")
	projectile_count = get_nodes_in_group("enemy_projectile").size()
	boss._fire_fan()
	_check(get_nodes_in_group("enemy_projectile").size() >= projectile_count + 5, "Phase two fan attack did not expand")
	boss.take_damage(10)
	_check(state.has_item("matriarch_seal"), "Matriarch Seal not awarded")
	_check(state.has_item("resonance_shard"), "First Matriarch victory did not award a Resonance Shard")
	_check(bool(state.defeated_bosses.get("echo_matriarch", false)), "Matriarch defeat not recorded")
	_check(state.get_zone_tier("echo_grotto") == 1, "Echo zone did not upgrade")
	_check(shortcut._requirements_met(), "Post-boss Grotto shortcut stayed locked")
	_check(ashen_gate._requirements_met(), "Matriarch victory did not open Ashen Bastion")
	_check("AWAKENED MATRIARCH" in ui.objective_label.text, "Post-boss objective missing")
	_check(soundscape.current_track == "echo_sanctum", "Boss music did not end")
	sanctum.get_node("ReturnDoor").activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_nest", "Sanctum return did not reach Nest")
	_check(player.global_position.distance_to(nest.get_node("SanctumReturn").global_position) < 45.0, "Sanctum return reached wrong marker")
	entry_door.activate(player)
	await create_timer(0.5).timeout
	_check(sanctum.has_node("EchoMatriarch") and sanctum.get_node("EchoMatriarch").is_rematch, "Matriarch did not reappear on return")
	_check(not sanctum.get_node("EchoMatriarch").active and sanctum.get_node("EchoMatriarch/ChallengePrompt").visible, "Optional Matriarch rematch began before a challenge")
	shortcut.activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_grotto", "Post-boss shortcut did not reach Grotto")
	_check(player.global_position.distance_to(game.get_node("EchoGrotto/SanctumReturn").global_position) < 45.0, "Post-boss shortcut reached wrong marker")
	var lamp = game.get_node("EchoGrotto/GrottoLamp/RespawnPoint")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), lamp.global_position, "echo_grotto_lamp", "Echo Grotto Lamp", "echo_grotto"), "Post-boss save failed")
	state.inventory.erase("matriarch_seal")
	state.inventory.erase("resonance_shard")
	state.defeated_bosses.erase("echo_matriarch")
	state.zone_tiers["echo_grotto"] = 0
	_check(state.load_game(), "Post-boss save could not load")
	_check(state.has_item("matriarch_seal") and state.has_item("resonance_shard") and bool(state.defeated_bosses.get("echo_matriarch", false)) and state.get_zone_tier("echo_grotto") == 1, "Boss progress or shard not restored")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	var rematch = game.get_node("ResonanceSanctum/EchoMatriarch")
	_check(rematch.is_rematch and rematch.max_health == 34, "Awakened Matriarch rematch missing")
	_check(game.get_node("ResonanceSanctum/GrottoShortcut")._requirements_met(), "Saved Grotto shortcut locked")
	_check(game.get_node("ResonanceSanctum/AshenGate")._requirements_met(), "Saved Matriarch victory closed Ashen Bastion")
	state.set_current_room("echo_nest")
	await process_frame
	_check(game.get_node("EchoNest/BroodlingOne").max_health == 4, "Upgraded Echo Broodling health missing")
	state.set_current_room("echo_gallery")
	await process_frame
	_check(game.get_node("EchoGallery/NearShade").max_health == 5, "Upgraded Echo Shade health missing")
	for room_name in ["EchoGrotto", "EchoGallery", "PrismArchive", "TideWell", "EchoNest"]:
		var room = game.get_node(room_name)
		var cache_found := false
		for child in room.get_children():
			if child.name.begins_with("Cache_"):
				cache_found = true
		_check(cache_found, "Upgraded cache missing in " + room_name)
	_check(game.get_node("EchoGrotto").has_node("grotto_echo_wisp"), "Upgraded Grotto encounter missing")
	_check(game.get_node("EchoGallery").has_node("gallery_echo_shade"), "Upgraded Gallery encounter missing")
	_check(not game.get_node("PrismArchive").has_node("archive_echo_shade") and not game.get_node("TideWell").has_node("tide_echo_wisp"), "Unvisited awakened rooms loaded their encounters eagerly")
	state.set_current_room("echo_archive")
	await process_frame
	_check(game.get_node("PrismArchive").has_node("archive_echo_shade"), "Upgraded Archive encounter missing")
	state.set_current_room("echo_tide_well")
	await process_frame
	_check(game.get_node("TideWell").has_node("tide_echo_wisp"), "Upgraded Tide encounter missing")
	_check(game.get_node("EchoNest").has_node("nest_echo_brood"), "Upgraded Nest encounter missing")
	var shard_count_before_cache: int = int(state.inventory.get("resonance_shard", 0))
	_check(game.get_node("EchoGrotto/Cache_grotto_high").open(game.get_node("Player")), "Upgraded Grotto shard cache did not open")
	_check(int(state.inventory.get("resonance_shard", 0)) == shard_count_before_cache + 1, "Upgraded Grotto cache did not grant its shard")
	_check(game.get_node("TideWell/Surge").idle_duration < 1.7, "Upgraded Tide surge did not accelerate")
	_check(not game.get_node("ResonanceSanctum").has_node("Cache_sanctum_heart"), "Sanctum reward appeared before rematch")
	var rematch_player = game.get_node("Player")
	var original_mana: int = rematch_player.max_mana
	var remote_health: int = rematch.current_health
	rematch.take_damage(1)
	_check(not rematch.active and rematch.current_health == remote_health, "A remote hit started the optional Matriarch rematch")
	var entered_sanctum: bool = await root.get_node("RoomTransition").transition_player(rematch_player, game.get_node("ResonanceSanctum/SanctumEntry").global_position, "echo_sanctum")
	_check(entered_sanctum and state.current_room_id == "echo_sanctum", "Could not return to Sanctum for the rematch")
	rematch_player.global_position = rematch.global_position + Vector2(-100.0, 50.0)
	_check(not rematch.active and rematch.get_node("ChallengePrompt").visible, "Approaching the optional Matriarch started combat")
	rematch.take_damage(18)
	_check(rematch.phase == 2, "Rematch phase two missing")
	rematch.take_damage(6)
	_check(rematch.phase == 3, "Rematch phase three missing")
	projectile_count = get_nodes_in_group("enemy_projectile").size()
	rematch._fire_fan()
	_check(get_nodes_in_group("enemy_projectile").size() >= projectile_count + 7, "Rematch final fan did not expand")
	rematch.take_damage(rematch.current_health)
	await process_frame
	_check(bool(state.boss_rematches.get("echo_matriarch", false)), "Matriarch rematch completion not recorded")
	_check(state.has_item("matriarch_heart") and rematch_player.max_mana == original_mana + 1, "Matriarch Heart mana reward missing")
	_check(state.has_item("resonance_shard", 3), "Matriarch rematch did not award its shard")
	_check(game.get_node("ResonanceSanctum").has_node("Cache_sanctum_heart"), "Sanctum reward cache missing after rematch")
	var sanctum_cache = game.get_node("ResonanceSanctum/Cache_sanctum_heart")
	_check(sanctum_cache.open(rematch_player), "Sanctum cache did not open")
	_check(not sanctum_cache.open(rematch_player), "Sanctum cache rewarded twice")
	rematch_player.global_position = game.get_node("ResonanceSanctum/SanctumLamp/RespawnPoint").global_position
	_check(game.get_node("ResonanceSanctum/SanctumLamp")._save_progress(rematch_player), "Rematch save failed")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	_check(not game.get_node("ResonanceSanctum").has_node("EchoMatriarch"), "Cleared Matriarch rematch respawned")
	_check(game.get_node("ResonanceSanctum/Cache_sanctum_heart").opened, "Sanctum cache reset after save")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("ECHO SANCTUM TEST PASSED")
		quit(0)
	else:
		print("ECHO SANCTUM TEST FAILED: ", failures)
		quit(1)
