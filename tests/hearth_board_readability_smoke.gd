extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_hearth_board_readability_save.json"
	state.start_new_game("normal")
	var office := Node2D.new()
	office.set_script(load("res://HearthFieldBoard.gd"))
	root.add_child(office)
	await process_frame
	_check(office.rows.size() == 7, "Missing field routes")
	var progression: Dictionary = state.unlocked_shortcuts.duplicate(true)
	for viewport in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = viewport
		root.content_scale_size = viewport
		await process_frame
		_check(office.table.size.x <= 356 and office.table.size.y <= 116, "Table exceeds available area")
		_check(office.board.get_minimum_size().x <= 356 and office.board.get_minimum_size().y <= 34, "Summary overflows")
		_check(office.table.position.y + office.table.size.y < office.board.position.y, "Table overlaps summary")
		for cell in office.table.get_children():
			_check(cell.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Board intercepts gameplay pointer")
		for cells in office.rows.values():
			_check(cells[1].text == "OPEN" and cells[2].text == "OPEN" and cells[3].text == "AFTER BOSS", "Wrong first-clear row")
	_check(state.unlocked_shortcuts == progression, "Viewing board changes progress")
	state.unlock_shortcut("ash_causeway_field_complete")
	state.unlock_shortcut("ash_causeway_guarded_niche_cleared")
	_check(office.rows.causeway[1].text == "DONE" and office.rows.causeway[2].text == "CLEAR", "Live task/guard update failed")
	_check(office.rows.causeway[3].text == "AFTER BOSS", "Premature return readiness")
	state.set_zone_tier("ashen_bastion", 1)
	_check(office.rows.causeway[3].text == "READY" and office.rows.forge[3].text == "TASK/GUARD", "Wrong return eligibility")
	state.unlock_shortcut("ash_causeway_field_return_complete")
	_check(office.rows.causeway[3].text == "WON", "Return victory not displayed")
	_check("TASKS 1/7" in office.board.text and "RETURN VICTORIES 1/7" in office.board.text and "not reward collected" in office.board.text, "Missing accurate counters/legend")
	_check(office.keeper.dialogue_lines.size() > 5 and office.courier.dialogue_lines.size() == 3, "Guidance was lost")
	office.queue_free()
	await process_frame
	var town: Node2D = load("res://CinderHearth.tscn").instantiate()
	root.add_child(town)
	await process_frame
	town.process_mode = Node.PROCESS_MODE_DISABLED
	var town_office := town.get_node("EasternDistricts/FieldOffice")
	var mounted_bounds: Rect2 = town_office.board_mount.global_transform * Rect2(-192, -282, 384, 202)
	for surface in town.get_node("WalkwayArt").surfaces:
		var collision: CollisionShape2D = surface.collision
		var bounds: Rect2 = collision.global_transform * Rect2(-collision.shape.size * 0.5, collision.shape.size)
		_check(not mounted_bounds.intersects(bounds), "Field board overlaps a playable surface")
	_check(town_office.keeper.position == Vector2(-85, -33) and town_office.courier.position == Vector2(55, -33), "Board move changed residents")
	town.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("HEARTH BOARD READABILITY TEST PASSED: seven aligned rows, 3 viewports, live progress, first/return clear states, victory-not-claim legend and retained guidance")
		quit(0)
	else:
		quit(1)
