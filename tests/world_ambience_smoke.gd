extends "res://tests/boss_combat_presentation_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_world_ambience.json"
	state.start_new_game("normal")
	var bytes := 0
	for named in ["field_machinery_atlas_v1", "regional_hanging_vines_v1", "steam_water_hazards_v1", "fire_soul_hazards_v1", "rubble_root_hazards_v1"]:
		var texture: Texture2D = load("res://art/visual_slice/%s.png" % named)
		var image := texture.get_image()
		_check(texture.get_width() <= 1024 and image.has_mipmaps() and image.get_pixel(0, 0).a < 0.01, "New atlas exceeds import budget or has no alpha/mipmaps: " + named)
		bytes += image.get_data_size()
	_check(bytes < 16 * 1024 * 1024, "Five atlases exceed 16 MiB decoded import budget")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var ambience: Node = finish.ambience
	var growth_count := 0
	for named in ["ShaftDriftworks", "AshEmberspine", "StarfallRamparts"]:
		var growth := game.get_node(named + "/ExpeditionNatureArt")
		_check(growth.built and growth.props.size() > 10, "Expedition still lacks grounded nature art: " + named)
		var old_count: int = growth.props.size()
		growth._build()
		_check(growth.props.size() == old_count, "Nature props duplicate on rebuild")
		for leaf in growth.retired: _check(not leaf.visible, "Expedition triangle reappeared")
		for prop in growth.props:
			_check(is_equal_approx(prop.rect.end.y, prop.support.position.y), "Floating expedition flora")
			for solid in growth.floors: _check(not prop.rect.grow(-0.05).intersects(solid), "Flora intersects a platform")
		growth_count += growth.props.size()
	state.set_current_room("shaft_drift")
	await process_frame
	await process_frame
	finish.finish_room("shaft_drift")
	var room := game.get_node("ShaftDriftworks")
	var machine: Node2D
	for node in finish._members(room):
		if node.name == "FieldMachineArt" and node.kind == "flywheel": machine = node
	_check(machine != null, "Flywheel is still prototype geometry")
	if machine != null:
		for retired in machine.retired: _check(not retired.visible, "Flywheel's giant cyan spoke remains")
		_check(machine.wheel.texture is AtlasTexture and machine.wheel.texture.get_size().x * machine.wheel.scale.x <= 60.01, "Flywheel art is oversized")
		machine.animate(2)
		_check(machine.wheel.rotation > 0, "Flywheel never turns")
	var big_view := Rect2(room.global_position - Vector2(10000, 10000), Vector2(30000, 30000))
	ambience.set_low_quality(false)
	ambience.select_visible(big_view)
	_check(ambience.active.size() > 0 and ambience.active.size() <= 18, "Standard animation cap exceeded")
	ambience.set_low_quality(true)
	ambience.select_visible(big_view)
	_check(ambience.active.size() <= 8, "Low-cost animation cap exceeded")
	var vines := 0
	for node in ambience.candidates:
		_check(not node.is_processing(), "Each decorative object has its own frame callback")
		if node.has_meta("wind_vine"):
			vines += 1
			_check(node.texture.atlas == ambience.VINES and node.offset.y > 0, "Vine not textured or anchored at the top")
			_check(is_equal_approx(node.scale.x, node.scale.y), "New vine artwork is stretched")
	_check(vines > 0, "No hanging vegetation in the room")
	var candidates: int = ambience.candidates.size()
	finish.finish_room("shaft_drift")
	_check(candidates == ambience.candidates.size(), "Room revisit duplicated animations")
	ambience.select_visible(Rect2(Vector2(1000000, 1000000), Vector2(1, 1)))
	_check(ambience.active.is_empty(), "Offscreen decorations remain active")
	ambience._process(0.11)
	_check(ambience.air.count == 8, "Low-cost air did not reduce particles")
	_check(finish.background.material.get_shader_parameter("wind_time") == ambience.age, "Mist motion disconnected")
	state.set_current_room("training_passage")
	await process_frame
	await process_frame
	_check(ambience.room_id == "training_passage" and not machine in ambience.active, "Previous room keeps animating")
	print("AMBIENCE BUDGET: ", bytes, " bytes decoded for 5 atlases; max 18/8 animated props, 18/8 motes; ", growth_count, " grounded expedition plants/minerals")
	game.queue_free()
	await process_frame
	state.delete_save()
	print("WORLD AMBIENCE TEST PASSED" if failures.is_empty() else "TEST FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)
