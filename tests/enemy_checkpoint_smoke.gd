extends "res://tests/story_lifecycle_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_enemy_checkpoint.json"
	state.start_new_game("normal")
	var game: Node = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var killed: Array[String] = []
	for enemy_name in ["Enemy", "Enemy2", "RangedEnemy"]:
		game.get_node(enemy_name).die()
		killed.append(enemy_name)
	await process_frame
	# Cover authored placements, lazy curated patrols and all four generators.
	for spec in [
		["echo_grotto", "EchoGrotto", ["FarWisp", "WildPatrol0", "LongTraversal/ChoirWisp_00_00"]],
		["shaft_hollow", "ShaftHollow", ["ExpandedRoute/AuthoredDescent/DepthFoe0"]],
		["ash_causeway", "BrokenCauseway", ["AshSwitchback/AshRouteFoe0_0"]],
		["starfall_outskirts", "StarfallOutskirts", ["ExpandedRoute/StarfallDescent/DepthFoe0_0"]],
	]:
		state.set_current_room(spec[0])
		await process_frame
		for relative in spec[2]:
			var path: String = spec[1] + "/" + relative
			var enemy: Node = game.get_node(path)
			enemy.die()
			killed.append(path)
			_check(state.defeated_enemies.get(path, false), "Untracked placement: " + path)
		state.set_current_room("training_passage")
		game.get_node("WorldPopulation").unload_room_population(spec[1])
		await process_frame
	# Save a partially cleared localized ambush and a partially cleared Nest.
	state.set_current_room("shaft_hollow")
	await process_frame
	var trial: Node = game.get_node("ShaftHollow").find_child("HiddenDepthAmbush", true, false)
	var trial_path: NodePath = game.get_path_to(trial)
	trial._on_body_entered(game.get_node("Player"))
	await process_frame
	_check(trial.spawned_enemies.size() == 2, "Ambush fixture did not spawn")
	trial.spawned_enemies[0].die()
	state.set_current_room("echo_nest")
	await process_frame
	game.get_node("EchoNest/BroodlingOne").die()
	await process_frame
	# The checkpoint is in a DIFFERENT zone, after previous rooms unload.
	state.set_current_room("echo_grotto")
	game.get_node("WorldPopulation").unload_room_population("ShaftHollow")
	game.get_node("WorldPopulation").unload_room_population("EchoNest")
	await process_frame
	var player: Node = game.get_node("Player")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position), "Checkpoint failed")
	var saved_kills: Dictionary = state.defeated_enemies.duplicate(true)
	var saved_gold: int = state.gold
	# A kill AFTER the checkpoint must be rolled back along with its rewards.
	game.get_node("EchoGrotto/EchoWisp").die()
	await process_frame
	player.die()
	var previous := game.get_instance_id()
	game.get_node("UI").restart_button.pressed.emit()
	game = await _after_reload(previous)
	if game == null: quit(1); return
	_check(state.defeated_enemies == saved_kills and state.gold == saved_gold, "Death mixed saved and unsaved progress/rewards")
	_check(game.has_node("EchoGrotto/EchoWisp"), "Unsaved enemy death incorrectly persisted")
	for enemy_name in ["Enemy", "Enemy2", "RangedEnemy"]:
		_check(not game.has_node(enemy_name), "Static passage enemy respawned: " + enemy_name)
	for gate in game.find_children("*", "Area2D", true, false):
		if gate is LevelExit and gate.required_enemy_group == &"passage_enemy":
			_check(gate.remaining_enemies == 1, "Passage gate counted saved dead enemies instead of just the live boss")
	for spec in [["echo_grotto", "EchoGrotto"], ["shaft_hollow", "ShaftHollow"], ["ash_causeway", "BrokenCauseway"], ["starfall_outskirts", "StarfallOutskirts"]]:
		state.set_current_room(spec[0])
		await process_frame
		await process_frame
		for path in killed:
			if path.begins_with(spec[1] + "/"):
				_check(not game.has_node(path), "Saved kill respawned on revisit: " + path)
	state.set_current_room("shaft_hollow")
	trial = game.get_node(trial_path)
	trial._on_body_entered(game.get_node("Player"))
	await process_frame
	_check(trial.spawned_enemies.size() == 1 and trial.remaining_foes.size() == 1, "Loaded partial ambush respawned slain foe or lost counter")
	if trial.spawned_enemies.size() == 1: trial.spawned_enemies[0].die()
	_check(trial.completed and state.unlocked_shortcuts.get(trial.completion_event_id, false), "Loaded ambush cannot complete")
	state.set_current_room("echo_nest")
	await process_frame
	await process_frame
	_check(not game.has_node("EchoNest/BroodlingOne"), "Saved Nest guardian respawned")
	_check(not game.get_node("EchoNest/NestVeil").is_open, "Partial Nest incorrectly opened")
	game.get_node("EchoNest/BroodlingTwo").die()
	game.get_node("EchoNest/BroodlingThree").die()
	await process_frame
	_check(game.get_node("EchoNest/NestVeil").is_open, "Restored Nest guardian count softlocked the seal")
	_check(state.gold == saved_gold, "Restoration itself created gold")
	# Backup restore must restore the older defeat ledger, not merge sessions.
	_check(state.save_at_checkpoint(game.get_node("Player"), game.get_node("QuestManager"), Vector2.ZERO), "Second save failed")
	var corrupt := FileAccess.open(state.save_path, FileAccess.WRITE)
	corrupt.store_string("broken isolated test save")
	corrupt.close()
	_check(state.load_game() and state.last_load_used_backup, "Backup recovery failed")
	_check(state.defeated_enemies == saved_kills, "Backup mixed enemy ledgers")
	# Legacy saves are supported but cannot reconstruct unrecorded old kills.
	var legacy: Dictionary = state._build_save_data().duplicate(true)
	legacy.erase("defeated_enemies")
	state._apply_save_data(legacy)
	_check(state.defeated_enemies.is_empty(), "Legacy save retained another session's kills")
	state.defeated_enemies["fixture"] = true
	state.start_new_game("normal")
	_check(state.defeated_enemies.is_empty(), "New game retained prior kills")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("ENEMY CHECKPOINT TEST PASSED")
		quit(0)
	else:
		print("ENEMY CHECKPOINT TEST FAILED: ", failures)
		quit(1)
