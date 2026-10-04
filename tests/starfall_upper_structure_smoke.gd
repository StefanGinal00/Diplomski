extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_starfall_upper_structure_save.json"
	state.start_new_game("normal")
	var city: Node2D = load("res://StarfallCitadel.tscn").instantiate()
	city.position = Vector2(19000, -12000)
	root.add_child(city)
	await process_frame
	await process_frame
	city.process_mode = Node.PROCESS_MODE_DISABLED
	var upper := city.get_node("UpperCity")
	var walk := upper.get_node("WalkwayArt")
	var sky := upper.get_node("SkylineArt")
	for art in [walk, sky]:
		for plate in art.retired:
			plate.show()
		for collection in [art.retired, art.surfaces, art.windows, art.towers, art.arcades, art.masonry]:
			collection.clear()
		art.built = false
	var physics_before := _physics_snapshot(city)
	var original := {}
	for node in upper.find_children("*", "Node2D", true, false):
		original[node] = [node.global_transform, node.visible, node.z_index, node.polygon.duplicate() if node is Polygon2D else null]
	walk._build()
	sky._build()
	_check(walk.surfaces.size() == 84 and walk.retired.size() == 88, "Missing upper walkway surfaces/retired terrace undersides")
	_check(walk.arcades.size() == 4 and sky.arcades.is_empty(), "Missing district-specific shallow arcades")
	_check(walk.masonry.size() == 9, "Six stair spines and three bell supports need material")
	for plate in walk.masonry:
		_check(plate.texture == walk.MASONRY and plate.uv.size() == plate.polygon.size(), "Invalid civic masonry material")
		_check(plate.texture_repeat == CanvasItem.TEXTURE_REPEAT_ENABLED, "Civic masonry stretches instead of tiling")
	for index in range(walk.arcades.size()):
		var arcade: Dictionary = walk.arcades[index]
		_check(arcade.district == index and arcade.rect.size.y <= 85, "Arcade identity or shallow envelope changed")
	_check(sky.towers.size() == 4 and sky.windows.size() == 136 and sky.retired.size() == 136, "Missing distant architecture")
	_check(walk.z_index == -1 and sky.z_index == -6, "Art depth no longer separates walkways/skyline/actors")
	var counts := {"step": 0, "bridge": 0, "terrace": 0}
	for surface in walk.surfaces:
		counts[surface.kind] += 1
		var collision: CollisionShape2D = surface.body.get_node("CollisionShape2D")
		var expected := Rect2(walk.to_local(collision.to_global(-collision.shape.size * 0.5)), collision.shape.size)
		_check(surface.rect == expected, "Walkway facing does not match actual collider")
		_check(collision.one_way_collision, "One-way traversal changed")
	_check(counts == {"step": 79, "bridge": 1, "terrace": 4}, "Walkway types changed")
	_check(_physics_snapshot(city) == physics_before, "Structure art changed physics")
	for node in original:
		var before: Array = original[node]
		var replaced: bool = node is Polygon2D and (node in walk.retired or node in sky.retired)
		_check(node.global_transform == before[0] and node.z_index == before[2], "Structure art moved an existing object")
		_check(node.visible == (false if replaced else before[1]), "Structure art hid unrelated content")
		if node is Polygon2D:
			_check(node.polygon == before[3], "Structure art changed a silhouette")
	for art in [walk, sky]:
		_check(art.get_child_count() == 0 and not art.is_processing(), "Structure art needs per-frame processing or extra nodes")
		for plate in art.retired:
			_check(plate.get_child_count() == 0, "Structure art hid a subtree")
		var count: int = art.retired.size()
		art._build()
		_check(art.retired.size() == count, "Structure art rebuild duplicated objects")
	city.hide()
	_check(not walk.is_visible_in_tree() and not sky.is_visible_in_tree(), "Structure art remains visible outside room")
	city.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("STARFALL UPPER STRUCTURE TEST PASSED: 79 steps, 4 district arcades/terraces, bridge, 4 detailed towers/136 windows; unchanged geometry, collision and object transforms")
		quit(0)
	else:
		quit(1)
