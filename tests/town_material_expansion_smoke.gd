extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_town_material_expansion_save.json"
	state.start_new_game("normal")
	for named in ["EchoHaven", "StarfallCitadel"]:
		var town: Node2D = load("res://%s.tscn" % named).instantiate()
		town.position = Vector2(17000, -8000)
		var art := town.get_node("MaterialExpansion")
		art.owner = null
		town.remove_child(art)
		root.add_child(town)
		await process_frame
		town.process_mode = Node.PROCESS_MODE_DISABLED
		var physics_before := _physics_snapshot(town)
		var originals := {}
		var polygons := {}
		for node in town.find_children("*", "Node2D", true, false):
			originals[node] = [node.global_transform, node.visible, node.z_index]
			if node is Polygon2D:
				polygons[node] = node.polygon.duplicate()
		town.add_child(art)
		await process_frame
		_check(art.built and not art.painted.is_empty(), "Missing material integration")
		_check(art.painted.size() == (57 if named == "EchoHaven" else 27), "Material coverage changed")
		_check(art.get_child_count() == 0 and not art.is_processing(), "Materials add runtime objects/work")
		_check(_physics_snapshot(town) == physics_before, "Materials change physics")
		for node in originals:
			_check([node.global_transform, node.visible, node.z_index] == originals[node], "Materials change visibility or transforms")
		for node in polygons:
			_check(node.polygon == polygons[node], "Materials change original silhouettes")
		var textures := {}
		for plate in art.painted:
			_check(plate.texture.get_width() == 512 and plate.texture.get_height() == 512, "Wrong texture import budget")
			_check(plate.texture.get_image().has_mipmaps(), "Missing texture mipmaps")
			_check(plate.uv.size() == plate.polygon.size(), "UV count mismatch")
			_check(plate.texture_repeat == CanvasItem.TEXTURE_REPEAT_ENABLED, "Surface cannot repeat")
			for point in plate.uv:
				_check(point.is_finite(), "Nonfinite UV")
			textures[plate.texture.resource_path] = true
		_check(textures.size() == 2, "Both new materials must be consumed")
		if named == "EchoHaven":
			_check(art.edges.size() == art.painted.size(), "Echo edge coverage mismatch")
			for plate in art.painted:
				_check(plate.get_parent() is StaticBody2D, "Echo painted a non-walkway")
		else:
			var market := town.get_node("VisualStyleSlice")
			_check(market.facade_materials.size() == 6, "Market must have three painted walls and roofs")
			for plate in market.facade_materials:
				_check(plate.show_behind_parent and plate.texture.get_width() == 512, "Market paint obscures facade detail or exceeds budget")
			for plate in town.get_node("UpperCity").find_children("Facade", "Polygon2D", true, false):
				if String(plate.get_parent().name).begins_with("House"):
					_check(plate in art.painted, "Upper city house missed")
		var count: int = art.painted.size()
		art._build()
		_check(art.painted.size() == count, "Repeated material build")
		town.hide()
		_check(not art.is_visible_in_tree(), "Inactive materials remain visible")
		print("TOWN MATERIAL COVERAGE ", named, ": ", count)
		town.queue_free()
		await process_frame
	state.delete_save()
	if failures.is_empty():
		print("TOWN MATERIAL EXPANSION TEST PASSED: 4 shared 512px mipmapped images, two towns, market/upper city, unchanged geometry/physics/routes and static idempotent application")
		quit(0)
	else:
		quit(1)
