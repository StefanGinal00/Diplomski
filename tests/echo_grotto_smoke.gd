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
	state.save_path = "res://_tmp_echo_grotto_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var grotto = game.get_node("EchoGrotto")
	var player = game.get_node("Player")
	var ui = game.get_node("UI")
	var lower = grotto.get_node("LowerResonator")
	var upper = grotto.get_node("UpperResonator")
	state.set_current_room("echo_grotto")
	_check("0/2" in ui.objective_label.text, "Grotto objective did not begin at 0/2")
	_check(grotto.get_node("FirstPlatform").position.y - grotto.get_node("SecondPlatform").position.y < 70.0, "Upper path jump is too high")
	_check(grotto.get_node("SecondPlatform").position.y - grotto.get_node("ThirdPlatform").position.y < 70.0, "Last upper path jump is too high")
	_check(grotto.get_node("FirstPlatform/CollisionShape2D").one_way_collision and grotto.get_node("SecondPlatform/CollisionShape2D").one_way_collision and grotto.get_node("ThirdPlatform/CollisionShape2D").one_way_collision, "Upper path platforms block jumps from below")
	_check(lower.attune(player), "Lower resonator did not attune")
	_check(not state.has_item("echo_charm"), "Charm rewarded before both resonators")
	_check("1/2" in ui.objective_label.text, "Grotto objective did not update to 1/2")
	_check(upper.attune(player), "Upper resonator did not attune")
	_check(state.has_item("echo_charm"), "Echo Charm was not rewarded")
	_check("ENTER THE GALLERY" in ui.objective_label.text, "Grotto objective did not point to the next room")
	_check(not upper.attune(player) and int(state.inventory.get("echo_charm", 0)) == 1, "Echo Charm can be farmed")
	player.current_mana = 0
	player.mana_regen_delay_remaining = 0.0
	player.mana_regen_progress = 0.0
	player._update_mana(2.0)
	_check(player.current_mana == 3, "Echo Charm mana regeneration bonus missing")
	var respawn = grotto.get_node("GrottoLamp/RespawnPoint")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), respawn.global_position, "echo_grotto_lamp", "Echo Grotto Lamp", "echo_grotto"), "Grotto save failed")
	state.unlocked_shortcuts.clear()
	state.inventory.erase("echo_charm")
	_check(state.load_game(), "Grotto save could not load")
	_check(state.has_item("echo_charm"), "Echo Charm not restored by load")
	_check(bool(state.unlocked_shortcuts.get("echo_resonator_lower", false)) and bool(state.unlocked_shortcuts.get("echo_resonator_upper", false)), "Resonators not restored by load")
	game.queue_free()
	await process_frame
	var reloaded_game = load("res://Game.tscn").instantiate()
	root.add_child(reloaded_game)
	current_scene = reloaded_game
	await process_frame
	_check("RESONATOR ACTIVE" in reloaded_game.get_node("EchoGrotto/LowerResonator/Prompt").text, "Lower resonator visual not restored")
	_check("RESONATOR ACTIVE" in reloaded_game.get_node("EchoGrotto/UpperResonator/Prompt").text, "Upper resonator visual not restored")
	_check(reloaded_game.get_node("EchoGrotto/ReturnDoor").target_marker_group == &"shaft_return", "Grotto return path missing")
	state.delete_save()
	reloaded_game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("ECHO GROTTO TEST PASSED")
		quit(0)
	else:
		print("ECHO GROTTO TEST FAILED: ", failures)
		quit(1)
