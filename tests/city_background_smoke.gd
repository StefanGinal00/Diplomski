extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_city_background_save.json"
	state.start_new_game("normal")
	for visit in range(2):
		var city: Node2D = load("res://StarfallCitadel.tscn").instantiate()
		var sky := city.get_node("Sky") as Polygon2D
		# Check the saved scene before any @tool/_ready callback can repair it.
		_check(sky.texture != null, "Serialized city sky has no image")
		_check(sky.material is ShaderMaterial, "Serialized city sky has no material")
		_check(sky.material.shader.resource_path.ends_with("city_panorama.gdshader"), "Serialized city uses a different background")
		_check(sky.uv.size() == sky.polygon.size(), "Serialized sky has incomplete UVs")
		var expected := PackedVector2Array([Vector2(0, -1950), Vector2(6250, -1950), Vector2(6250, 500), Vector2(0, 500)])
		_check(sky.polygon == expected, "Serialized sky misses a city district")
		root.add_child(city)
		await process_frame
		await process_frame
		city.process_mode = Node.PROCESS_MODE_DISABLED
		var art := city.get_node("RemainingArt")
		_check(art.plates.size() == 1 and art.plates[0] == sky, "City has multiple background plates")
		_check(city.get_node("VisualStyleSlice").plates.is_empty(), "Facade module added a second painting")
		_check(not city.has_node("VisualStyleSlice/MarketSkyPainting"), "Old market rectangle returned")
		_check(sky.texture.resource_path.ends_with("citadel_sky_depth_v1.png"), "Runtime swapped the serialized city image")
		var before := _physics_snapshot(city)
		art._build()
		city.get_node("VisualStyleSlice")._build()
		_check(art.plates.size() == 1 and _physics_snapshot(city) == before, "Rebuild duplicates scenery or changes physics")
		city.queue_free()
		await process_frame
	state.delete_save()
	if failures.is_empty():
		print("CITY BACKGROUND TEST PASSED: serialized full-height sky, single painting owner, repeat visits and collision-safe rebuild")
		quit(0)
	else:
		quit(1)
