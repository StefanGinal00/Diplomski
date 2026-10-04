extends "res://tests/story_lifecycle_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_opening_checkpoint_regression.json"
	state.session_started = false
	var game: Node = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("UI")._start_new_mode("normal")
	game.get_node("UI").story_player.cancel()
	paused = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Node = game.get_node("Player")
	for named in ["Enemy", "Enemy2", "RangedEnemy"]:
		var enemy: Node = game.get_node(named)
		print("TRACK ", named, " ", enemy.get_signal_connection_list("defeated"))
		enemy.take_damage(999)
		_check(state.defeated_enemies.get(named, false), "Opening kill absent from ledger: " + named)
	await process_frame
	var lamp: Node = game.get_node("Checkpoint")
	_check(lamp._save_progress(player), "Native opening lamp save failed")
	var data: Dictionary = state._read_save_file(state.save_path)
	for named in ["Enemy", "Enemy2", "RangedEnemy"]:
		_check(data.defeated_enemies.get(named, false), "Opening kill absent on disk: " + named)
	player.die()
	var previous := game.get_instance_id()
	game.get_node("UI").restart_button.pressed.emit()
	game = await _after_reload(previous)
	if game == null: quit(1); return
	for named in ["Enemy", "Enemy2", "RangedEnemy"]:
		_check(not game.has_node(named), "Opening enemy respawned: " + named)
	game.queue_free()
	await process_frame
	state.delete_save()
	print("OPENING CHECKPOINT REGRESSION TEST PASSED" if failures.is_empty() else "TEST FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)
