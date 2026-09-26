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
	state.save_path = "res://_tmp_ash_castellan_rollback.json"
	state.start_new_game("normal")
	state.add_item("barracks_insignia")
	state.add_item("marshal_emblem")
	state.add_item("crucible_core")
	state.unlock_shortcut("ash_chapel_bells")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var chapel = game.get_node("AshChapel")
	var throne = game.get_node("CastellanThrone")
	state.set_current_room("ash_chapel")
	player.global_position = chapel.get_node("ChapelLamp/RespawnPoint").global_position
	_check(chapel.get_node("ChapelLamp")._save_progress(player), "Pre-Castellan lamp did not save")
	player.global_position = chapel.get_node("ThroneReturn").global_position
	await chapel.get_node("ThroneDoor").activate(player)
	_check(state.current_room_id == "ash_throne", "Saved route could not reach the throne")
	var boss = throne.get_node("AshCastellan")
	boss.take_damage(boss.max_health)
	await process_frame
	_check(state.has_item("castellan_seal") and state.get_zone_tier("ashen_bastion") == 1, "Unsaved boss victory was not applied")
	_check(throne.get_node("HearthShortcut")._requirements_met() and game.get_node("BrokenCauseway").has_node("Cache_causeway_embers"), "Unsaved Ashen upgrade did not open content")
	_check(state.load_game(), "Pre-Castellan save could not be restored")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	state = root.get_node("GameState")
	_check(state.current_room_id == "ash_chapel" and not state.has_item("castellan_seal"), "Normal rollback kept unsaved Castellan progress")
	_check(not bool(state.defeated_bosses.get("ash_castellan", false)) and state.get_zone_tier("ashen_bastion") == 0, "Normal rollback kept the Ashen tier upgrade")
	_check(game.get_node("CastellanThrone/AshCastellan").max_health == 26 and not game.get_node("CastellanThrone/AshCastellan").is_rematch, "Normal rollback did not restore the first Castellan fight")
	_check(not game.get_node("CastellanThrone/HearthShortcut")._requirements_met() and not game.get_node("BrokenCauseway").has_node("Cache_causeway_embers"), "Unsaved shortcut or awakened cache survived rollback")
	_check(game.get_node("QuestManager").get_return_contract_tracker_text().is_empty(), "Unsaved Ash return quest survived rollback")
	_check(game.get_node("AshChapel/ThroneDoor")._requirements_met(), "Rollback lost prerequisites already saved at the lamp")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("ASH CASTELLAN ROLLBACK TEST PASSED")
		quit(0)
	else:
		print("ASH CASTELLAN ROLLBACK TEST FAILED: ", failures)
		quit(1)
