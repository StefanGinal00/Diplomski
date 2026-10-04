extends "res://tests/preview_characters.gd"

func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_world_life_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	state.set_current_room("shaft_drift")
	await process_frame
	await process_frame
	var finish := game.get_node("WorldPresentationFinish")
	finish.finish_room("shaft_drift")
	finish.reader.set_process(false)
	game.get_node("UI")._dismiss_zone_title()
	var player := game.get_node("Player")
	var camera: Camera2D = player.get_node("Camera2D")
	var room := game.get_node("ShaftDriftworks")
	var site := room.get_node("FieldDressing/Site5")
	player.global_position = site.global_position + Vector2(-56, -30)
	_set_camera(camera, finish)
	finish.reader._refresh_nearest()
	finish.ambience._process(0.3)
	await _capture("worldlife_flywheel")
	finish.reader.open_nearest()
	await _capture("worldlife_reading")
	finish.reader.close()
	var leak := room.get_node("Infrastructure/PressureLeak1")
	player.global_position = leak.global_position + Vector2(-113, 24)
	_set_camera(camera, finish)
	finish.reader._refresh_nearest()
	for phase in ["idle", "warning", "active", "disabled"]:
		leak.phase = phase
		leak.disabled = phase == "disabled"
		leak.get_node("HazardArt").refresh()
		leak.get_node("HazardArt").age = 0.25
		leak.get_node("HazardArt").refresh()
		await _capture("worldlife_steam_" + phase)
	# Isolated native scenes at the same camera, for actual-size family comparison.
	leak.hide()
	for item in [["HeatVent", "fire"], ["RootSnare", "roots"], ["SoulPulse", "soul"], ["TidePulse", "water"], ["ShaftRouteHazard", "rockfall"]]:
		var effect: Area2D = load("res://%s.tscn" % item[0]).instantiate()
		if item[0] == "ShaftRouteHazard": effect.hazard_kind = "rockfall"
		room.add_child(effect)
		effect.global_position = leak.global_position
		if item[1] == "water": effect.global_position.y += 34
		effect.phase = "active"
		effect.get_node("HazardArt").refresh()
		effect.get_node("HazardArt").age = 0.25
		effect.get_node("HazardArt").refresh()
		await _capture("worldlife_" + item[1])
		effect.queue_free()
		await process_frame
	# Two fixed-camera snapshots of real wall vegetation, driven by the budget.
	for vine in finish.ambience.candidates:
		if not vine.has_meta("wind_vine"): continue
		player.global_position = vine.global_position + Vector2(-45, 40)
		_set_camera(camera, finish)
		finish.reader._refresh_nearest()
		for moment in [0, 1]:
			finish.ambience.selection_clock = 1
			finish.ambience._process(1.7)
			await _capture("worldlife_vines_%d" % moment)
		break
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)

func _set_camera(camera: Camera2D, finish: Node) -> void:
	camera.reset_smoothing()
	camera.force_update_scroll()
	finish.background._process(0)
	finish._process(0.2)
