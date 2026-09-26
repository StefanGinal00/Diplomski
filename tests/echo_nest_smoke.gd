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
	state.save_path = "res://_tmp_echo_nest_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	var player = game.get_node("Player")
	var well = game.get_node("TideWell")
	var nest = game.get_node("EchoNest")
	var nest_door = well.get_node("NestDoor")
	var seal = nest.get_node("NestVeil")
	var shortcut = nest.get_node("ShortcutDoor")
	var ui = game.get_node("UI")
	_check(not nest_door._requirements_met(), "Nest opened before Tide Core")
	_check(not seal.is_open and not seal.get_node("CollisionShape2D").disabled, "Nest veil began open")
	_check(not shortcut._requirements_met(), "Nest shortcut began unlocked")
	_check(get_first_node_in_group("nest_entry") != null and get_first_node_in_group("tide_nest_return") != null and get_first_node_in_group("tide_nest_shortcut_return") != null, "Nest route marker missing")
	state.add_item("tide_core")
	_check(nest_door._requirements_met(), "Tide Core did not unlock Nest")
	nest_door.activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_nest", "Nest entry transition failed")
	_check(game.get_node("AmbientSoundscape").current_track == "echo_nest", "Nest ambience missing")
	_check("3 LEFT" in ui.objective_label.text, "Nest enemy objective missing")
	var brood_one = nest.get_node("BroodlingOne")
	var brood_two = nest.get_node("BroodlingTwo")
	var brood_three = nest.get_node("BroodlingThree")
	player.max_health = 100
	player.current_health = 100
	player.global_position = brood_one.global_position + Vector2(-80.0, 0.0)
	brood_one.attack_cooldown = 0.0
	await create_timer(0.16).timeout
	_check(brood_one.state == brood_one.State.WINDUP and brood_one.warning_icon.visible, "Broodling did not telegraph its leap")
	await create_timer(0.54).timeout
	_check(brood_one.state == brood_one.State.LEAP, "Broodling did not leap after warning")
	brood_one.take_damage(999)
	await process_frame
	_check("2 LEFT" in ui.objective_label.text and not seal.is_open, "Nest veil opened after one enemy")
	brood_two.take_damage(999)
	await process_frame
	_check("1 LEFT" in ui.objective_label.text and not seal.is_open, "Nest veil opened before brood cleared")
	brood_three.take_damage(999)
	await process_frame
	await process_frame
	_check(seal.is_open and seal.get_node("CollisionShape2D").disabled, "Nest veil did not open after brood defeat")
	_check(bool(state.unlocked_shortcuts.get("echo_nest_cleared", false)), "Nest clear event not recorded")
	_check("CLAIM NEST CREST" in ui.objective_label.text, "Nest clear objective missing")
	nest.get_node("NestCrest")._on_body_entered(player)
	await process_frame
	_check(state.has_item("nest_crest"), "Nest Crest not collected")
	_check(shortcut._requirements_met(), "Nest shortcut stayed locked")
	_check("ENTER SANCTUM" in ui.objective_label.text, "Nest reward objective missing")
	nest.get_node("ReturnDoor").activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_tide_well", "Nest return did not reach Well")
	_check(player.global_position.distance_to(well.get_node("NestReturn").global_position) < 45.0, "Nest return reached wrong marker")
	nest_door.activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_nest", "Well could not re-enter Nest")
	var lamp = nest.get_node("NestLamp/RespawnPoint")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), lamp.global_position, "echo_nest_lamp", "Echo Nest Lamp", "echo_nest"), "Nest save failed")
	state.inventory.erase("nest_crest")
	state.unlocked_shortcuts.erase("echo_nest_cleared")
	_check(state.load_game(), "Nest save could not load")
	_check(state.has_item("nest_crest") and bool(state.unlocked_shortcuts.get("echo_nest_cleared", false)), "Nest progress not restored")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	nest = game.get_node("EchoNest")
	seal = nest.get_node("NestVeil")
	_check(seal.is_open and seal.get_node("CollisionShape2D").disabled, "Saved Nest veil did not reopen")
	_check(not nest.has_node("NestCrest"), "Unique Nest Crest respawned")
	_check(nest.get_node("ShortcutDoor")._requirements_met(), "Saved Nest shortcut not restored")
	player = game.get_node("Player")
	nest.get_node("ShortcutDoor").activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_tide_well", "Nest shortcut did not reach Well")
	_check(player.global_position.distance_to(game.get_node("TideWell/NestShortcutReturn").global_position) < 45.0, "Nest shortcut reached wrong marker")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("ECHO NEST TEST PASSED")
		quit(0)
	else:
		print("ECHO NEST TEST FAILED: ", failures)
		quit(1)
