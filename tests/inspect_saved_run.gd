extends "res://tests/story_lifecycle_smoke.gd"
## Optional diagnostic: caller supplies an isolated copy, never the live save.
func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_review_actual_save_copy.json"
	if not FileAccess.file_exists(state.save_path):
		print("No isolated diagnostic snapshot supplied")
		quit(2)
		return
	_check(state.load_game(), "Snapshot failed to load")
	var saved: Dictionary = state.defeated_enemies.duplicate(true)
	var game: Node = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	for key in saved:
		if not str(key).begins_with("encounter:"):
			_check(not game.has_node(str(key)), "Saved placement alive after cold load: " + str(key))
	state.set_current_room("training_passage")
	await process_frame
	for key in ["Enemy", "Enemy2", "RangedEnemy"]:
		_check(not game.has_node(key), "Saved opening enemy alive on revisit: " + key)
	game.get_node("Player").die()
	var previous := game.get_instance_id()
	game.get_node("UI").restart_button.pressed.emit()
	game = await _after_reload(previous)
	if game == null: quit(1); return
	state.set_current_room("training_passage")
	await process_frame
	for key in ["Enemy", "Enemy2", "RangedEnemy"]:
		_check(not game.has_node(key), "Saved opening enemy alive after death: " + key)
	_check(state.defeated_enemies == saved, "Reload mixed snapshot ledger")
	game.queue_free()
	await process_frame
	state.delete_save()
	print("SAVED RUN DIAGNOSTIC TEST PASSED" if failures.is_empty() else "TEST FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)
