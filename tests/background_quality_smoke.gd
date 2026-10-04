extends "res://tests/visual_style_slice_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_background_quality_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var counts := {"profiles": 0, "surfaces": 0, "retired": 0, "equipment": 0}
	for art in game.find_children("*", "Node2D", true, false):
		if art.get_script() == null or art.get_script().resource_path not in ["res://RoomPaintedDepth.gd", "res://RemainingRoomArt.gd"]:
			continue
		_check(art.built, "Unbuilt quality profile")
		counts.profiles += 1
		for kind in ["surfaces", "retired", "equipment"]:
			counts[kind] += art.finish_report[kind].size()
		for surface in art.finish_report.surfaces:
			_check(surface.texture != null and surface.texture_repeat == CanvasItem.TEXTURE_REPEAT_ENABLED, "Untextured terrain")
			_check(surface.has_node("MaterialRim"), "Missing readable collision edge")
		for node in art.finish_report.retired:
			_check(node is Polygon2D and node.get_child_count() == 0 and not node.visible, "Unsafe decorative retirement")
		for plate in art.plates:
			_check(plate.texture.get_width() == 1536, "Background import still downsampled")
	_check(counts.profiles == 33, "Missing art profiles")
	_check(counts.surfaces > 1000, "Generated floors are still plain, not just entry platforms")
	var cistern := game.get_node("BlackwaterCistern")
	_check(not cistern.get_node("Masonry").visible, "Old cistern wall hides painting")
	var tanks := cistern.find_children("CisternPressureCell*", "Polygon2D", true, false)
	_check(tanks.size() == 3, "Expected three landmark pressure cells")
	for tank in tanks:
		_check(tank.texture != null and tank.has_node("RivetedSeam"), "Pressure cell still a flat placeholder")
	var outskirts := game.get_node("StarfallOutskirts")
	for named in ["FarSpire", "BrokenWall", "DustGlow"]:
		_check(not outskirts.get_node(named).visible, "Old outskirts backdrop hides painting")
	var city := game.get_node("StarfallCitadel")
	var panorama := city.get_node("Sky")
	var bounds: Rect2 = city.get_node("RemainingArt").art_bounds
	_check(bounds == Rect2(0, -1950, 6250, 2450), "City sky does not span all districts")
	_check(not city.has_node("VisualStyleSlice/MarketSkyPainting"), "Second city background has returned")
	_check(panorama.material.shader.resource_path.ends_with("city_panorama.gdshader"), "City panorama lacks single upright sky material")
	for path in ["GateDistrict/Backdrop", "WardDistrict/Backdrop", "WardDistrict/DistantTerraces"]:
		_check(not city.get_node(path).visible, "Embedded town scene hides city panorama")
	for path in ["GateDistrict/WatchHouse", "WardDistrict/HouseEast", "WardDistrict/HouseWest"]:
		_check(city.get_node(path).texture != null, "Untextured ground district house")
	print("QUALITY COVERAGE ", counts)
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("BACKGROUND QUALITY TEST PASSED: 33 native-detail profiles, continuous city panorama, explicit occluder retirement, deep terrain materials and cistern equipment")
		quit(0)
	else:
		quit(1)
