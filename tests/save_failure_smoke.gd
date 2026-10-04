extends "res://tests/story_lifecycle_smoke.gd"

class FaultState extends "res://GameState.gd":
	var reject_copy := false
	var reject_destination := ""
	func _copy_save_file(source_path: String, destination_path: String) -> bool:
		if reject_copy: return false
		return super._copy_save_file(source_path, destination_path)
	func _replace_save_file(staging_absolute: String, destination_absolute: String) -> Error:
		if destination_absolute == reject_destination: return ERR_CANT_CREATE
		return super._replace_save_file(staging_absolute, destination_absolute)

func _fault_matrix() -> void:
	# Inject OS-operation failures, not the whole save method. Real JSON files,
	# staging, backup rotation and state publication still execute normally.
	var state := FaultState.new()
	state.save_path = "res://_tmp_save_failure_matrix.json"
	state.delete_save()
	state.reject_destination = ProjectSettings.globalize_path(state.save_path)
	_check(not state.save_at_checkpoint(null, null, Vector2.ZERO, "failed_first"), "Failed first replacement reported success")
	_check(not state.has_checkpoint and not state.has_save_file() and state.discovered_lamps.is_empty(), "Failed first save published a checkpoint")
	state.reject_destination = ""
	_check(state.save_at_checkpoint(null, null, Vector2(10, 20), "old", "Old Lamp"), "Initial matrix save failed")
	var primary := FileAccess.get_file_as_string(state.save_path)
	var backup := FileAccess.get_file_as_string(state.save_path + ".backup")
	var completed := [0]
	var discovered := [0]
	state.save_completed.connect(func(): completed[0] += 1)
	state.lamps_changed.connect(func(): discovered[0] += 1)
	state.gold = 99
	state.defeated_enemies["new_kill"] = true
	state.destroyed_props["new_crate"] = true
	for failure in ["copy", "backup_replace", "primary_replace"]:
		state.reject_copy = failure == "copy"
		state.reject_destination = ProjectSettings.globalize_path(state.save_path + (".backup" if failure == "backup_replace" else "")) if failure != "copy" else ""
		_check(not state.save_at_checkpoint(null, null, Vector2(40, 50), "new", "New Lamp"), "Injected failure reported success: " + failure)
		_check(FileAccess.get_file_as_string(state.save_path) == primary, "Failed write changed primary: " + failure)
		_check(FileAccess.get_file_as_string(state.save_path + ".backup") == backup, "Failed write lost valid backup: " + failure)
		_check(state.checkpoint_lamp_id == "old" and state.checkpoint_position == Vector2(10, 20) and not state.discovered_lamps.has("new"), "Failed write published checkpoint: " + failure)
		_check(completed[0] == 0 and discovered[0] == 0 and not state.checkpoint_write_in_progress, "Failure leaked success signals/write lock")
		_check(state.gold == 99 and state.defeated_enemies.has("new_kill") and state.destroyed_props.has("new_crate"), "Failure discarded live unsaved progress")
	state.reject_copy = false
	state.reject_destination = ""
	var nested := [true]
	var on_rest := func(_lamp: String): nested[0] = state.save_at_checkpoint(null, null, Vector2.ZERO, "recursive")
	state.checkpoint_resting.connect(on_rest)
	_check(state.save_at_checkpoint(null, null, Vector2(40, 50), "new", "New Lamp"), "Retry after failure did not save")
	state.checkpoint_resting.disconnect(on_rest)
	_check(not nested[0] and completed[0] == 1 and discovered[0] == 1, "Reentrant save was not isolated")
	var disk: Dictionary = state._read_save_file(state.save_path)
	_check(disk.gold == 99 and disk.checkpoint_lamp_id == "new" and disk.discovered_lamps.has("new") and disk.defeated_enemies.has("new_kill") and disk.destroyed_props.has("new_crate"), "Successful retry did not serialize complete progress")
	_check(FileAccess.get_file_as_string(state.save_path + ".backup") == primary, "Retry did not retain prior checkpoint backup")
	state.delete_save()
	# First save can succeed without a backup if the primary itself is valid.
	state.reject_copy = true
	_check(state.save_at_checkpoint(null, null, Vector2.ONE, "first"), "Valid first primary rejected because backup unavailable")
	_check(state._read_save_file(state.save_path) is Dictionary and not FileAccess.file_exists(state.save_path + ".backup"), "Initial backup failure misreported disk state")
	state.delete_save()
	state.free()

func _run() -> void:
	_fault_matrix()
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_save_failure_native.json"
	state.start_new_game("normal")
	var game: Node = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Node = game.get_node("Player")
	var upper: Node = game.get_node("VerticalChamber/UpperCheckpoint")
	var crossing: Node = game.get_node("DrownedCrossing/CrossingLamp")
	var ui: Node = game.get_node("UI")
	state.set_current_room("sunken_shaft")
	player.global_position = upper.respawn_point.global_position
	_check(upper._save_progress(player), "Native initial save failed")
	var snapshot: Dictionary = state._build_save_data().duplicate(true)
	var primary := FileAccess.get_file_as_string(state.save_path)
	var backup := FileAccess.get_file_as_string(state.save_path + ".backup")
	var old_respawn: Vector2 = player.respawn_position
	# Real open failure: an empty directory occupies ONLY this test's temporary
	# save path. No user save or parent directory is modified.
	var obstruction := ProjectSettings.globalize_path(state.save_path + ".tmp")
	_check(DirAccess.make_dir_absolute(obstruction) == OK, "Could not create isolated failure fixture")
	state.set_current_room("shaft_crossing")
	player.global_position = crossing.respawn_point.global_position
	_check(not crossing._save_progress(player), "Blocked temporary path reported success")
	_check(not crossing.is_active and player.respawn_position == old_respawn, "Failed lamp changed active light/player checkpoint")
	_check(state.checkpoint_lamp_id == snapshot.checkpoint_lamp_id and state.last_saved_unix_time == snapshot.last_saved_unix_time and state.discovered_lamps == snapshot.discovered_lamps, "Failed lamp changed checkpoint metadata")
	_check(state.player_state == snapshot.player_state and state.quest_state == snapshot.quest_state, "Failed lamp retained temporary captures")
	_check(FileAccess.get_file_as_string(state.save_path) == primary and FileAccess.get_file_as_string(state.save_path + ".backup") == backup, "Open failure changed a valid save")
	var blocked := [0]
	crossing.rest_blocked.connect(func(_message: String): blocked[0] += 1)
	crossing.process_mode = Node.PROCESS_MODE_ALWAYS
	await crossing._begin_rest(player)
	_check(blocked[0] == 1 and not crossing.is_resting and not player.is_safe_resting, "Failed timed rest left player locked or suppressed error")
	_check(player.respawn_position == old_respawn and state.checkpoint_lamp_id == snapshot.checkpoint_lamp_id, "Failed timed rest moved checkpoint")
	crossing.process_mode = Node.PROCESS_MODE_INHERIT
	_check(DirAccess.remove_absolute(obstruction) == OK, "Could not remove empty failure fixture")
	_check(crossing._save_progress(player), "Native retry failed")
	old_respawn = player.respawn_position
	var old_lamp: String = state.checkpoint_lamp_id
	primary = FileAccess.get_file_as_string(state.save_path)
	_check(DirAccess.make_dir_absolute(obstruction) == OK, "Could not create travel failure fixture")
	ui._open_world_map(true, crossing)
	ui.selected_lamp_id = upper.lamp_id
	await ui._on_map_travel_pressed()
	_check(state.current_room_id == "sunken_shaft" and player.global_position.distance_to(upper.respawn_point.global_position) < 45, "Save failure incorrectly undid completed travel")
	_check(state.checkpoint_lamp_id == old_lamp and player.respawn_position == old_respawn, "Failed travel autosave moved respawn")
	_check("SAVE FAILED" in ui.notification_label.text and not ui.map_allows_travel and not paused, "Failed travel autosave was silent or left UI blocked")
	_check(FileAccess.get_file_as_string(state.save_path) == primary, "Failed travel overwrote previous checkpoint")
	_check(DirAccess.remove_absolute(obstruction) == OK, "Could not remove empty travel fixture")
	# Death must use the real prior checkpoint, not the unsaved travel target.
	player.die()
	var old_id := game.get_instance_id()
	ui.restart_button.pressed.emit()
	game = await _after_reload(old_id)
	if game == null: quit(1); return
	_check(state.current_room_id == "shaft_crossing" and state.checkpoint_lamp_id == old_lamp, "Native death loaded failed travel checkpoint")
	_check(game.get_node("Player").global_position.distance_to(old_respawn) < 45, "Native death respawned at failed target")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("SAVE FAILURE TEST PASSED: open/copy/replace, retry, reentry, native travel and death rollback")
		quit(0)
	else:
		print("SAVE FAILURE TEST FAILED: ", failures)
		quit(1)
