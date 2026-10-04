extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_rampart_painted_art_save.json"
	state.start_new_game("normal")
	var wing := load("res://ExpeditionWing.tscn").instantiate() as Node2D
	wing.region = "starfall"
	wing.painted_ramparts_enabled = false
	root.add_child(wing)
	await process_frame
	await process_frame
	wing.process_mode = Node.PROCESS_MODE_DISABLED
	var physics_before := _physics_snapshot(wing)
	var originals := {}
	var floors := 0
	for node in wing.find_children("*", "Node2D", true, false):
		originals[node] = [node.transform, node.visible, node.z_index, node.polygon.duplicate() if node is Polygon2D else null]
	for body in wing.get_children():
		if body is StaticBody2D and body.has_node("Visual"):
			var size: Vector2 = body.get_node("CollisionShape2D").shape.size
			if size.x > size.y:
				floors += 1
	var art := Node2D.new()
	art.set_script(load("res://RampartPaintedArt.gd"))
	wing.add_child(art)
	await process_frame
	_check(art.built and art.plates.size() == 24, "Rampart backdrop must cover 12 chambers and 12 links")
	_check(art.surfaces.size() == floors and floors > 50, "Missing supported walking surfaces")
	_check(art.pillars.size() == 4, "Missing landmark pillars")
	_check(_physics_snapshot(wing) == physics_before, "Art modified expedition collision")
	_check(art.find_children("*", "CollisionObject2D", true, false).is_empty(), "Decorative pillar became a gameplay obstacle")
	for node in originals:
		var before: Array = originals[node]
		_check(node.transform == before[0] and node.z_index == before[2], "Art moved an original node")
		if art.retired.has(node):
			_check(node.get_child_count() == 0 and not node.visible, "Retirement affected a gameplay parent")
		else:
			_check(node.visible == before[1], "Unexpected original node hidden")
		if node is Polygon2D:
			_check(node.polygon == before[3], "Art changed room silhouette or platform shape")
	for plate in art.plates:
		_check(plate.z_index == -9 and plate.material == art.material_shared, "Painting overlaps gameplay or duplicates materials")
		_check(plate.texture.get_width() == 1024 and plate.texture.get_image().has_mipmaps(), "Painting import budget invalid")
		for index in range(plate.polygon.size()):
			var expected: Vector2 = (art.to_local(plate.to_global(plate.polygon[index])) - art.art_bounds.position) / art.art_bounds.size * plate.texture.get_size()
			_check(plate.uv[index].distance_to(expected) < 0.01, "Chamber and shaft images do not share continuous UVs")
	for index in range(art.pillars.size()):
		var sprite: Sprite2D = art.pillars[index]
		var bitmap := sprite.texture.get_image()
		_check(bitmap.get_width() == 512 and bitmap.has_mipmaps() and bitmap.get_pixel(0, 0).a < 0.01 and not bitmap.is_invisible(), "Pillar alpha or import invalid")
		var used := bitmap.get_used_rect()
		var bottom: Vector2 = sprite.position + Vector2(used.position.x + used.size.x * 0.5, art.pillar_foot_y) * sprite.scale
		_check(bottom.distance_to(art.pillar_anchors[index]) < 0.01 and sprite.z_index == -7, "Pillar not grounded behind combat")
		var solid_pixels := 0
		for column in range(used.position.x, used.end.x):
			if bitmap.get_pixel(column, art.pillar_foot_y - 1).a >= 0.5:
				solid_pixels += 1
		_check(solid_pixels >= 3, "Pillar ground anchor follows transparent fringe rather than visible stone")
	for surface in art.surfaces:
		_check(surface.has_node("StoneRim") and surface.texture.resource_path.ends_with("starfall_masonry_v1.png"), "Missing stone surface detail")
		_check(surface.get_node("StoneRim").points[0].y == surface.polygon[0].y + 1, "Rim raises jump edge")
	for zoom in [0.6, 1.4]:
		var center: Vector2 = art.to_global(art.art_bounds.get_center())
		root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), root.get_visible_rect().size * 0.5 - center * zoom)
		art._process(0.1)
		var initial: Vector2 = art.material_shared.get_shader_parameter("camera_shift")
		root.canvas_transform.origin -= Vector2(200, 80) * zoom
		art._process(0.1)
		var moved: Vector2 = art.material_shared.get_shader_parameter("camera_shift")
		var haze: Vector2 = art.material_shared.get_shader_parameter("haze_shift")
		_check(moved.x < initial.x and moved.y < initial.y and moved.length() > haze.length(), "Parallax layers do not have separate speeds")
	var stable: Vector2 = art.material_shared.get_shader_parameter("camera_shift")
	wing.position += Vector2(20000, 16000)
	root.canvas_transform.origin -= Vector2(20000, 16000) * 1.4
	art._process(0.1)
	_check((art.material_shared.get_shader_parameter("camera_shift") as Vector2).distance_to(stable) < 0.0001, "Editor origins change parallax")
	var updates: int = art.update_count
	wing.hide()
	art._process(1)
	_check(art.update_count == updates, "Hidden room keeps animating")
	art._build()
	_check(art.plates.size() == 24 and art.pillars.size() == 4 and art.surfaces.size() == floors, "Art duplicates on rebuild")
	print("RAMPART ART COVERAGE: ", art.plates.size(), " backplates, ", floors, " surfaces, ", art.retired.size(), " retired leaves, 4 pillars")
	wing.queue_free()
	await process_frame
	for region in ["shaft", "echo", "ash", "starfall"]:
		var other := load("res://ExpeditionWing.tscn").instantiate() as Node2D
		other.region = region
		root.add_child(other)
		await process_frame
		_check(other.has_node("RampartArt") == (region == "starfall"), "Art opt-in affected another expedition")
		if region == "starfall":
			_check(other.get_node("RampartArt").built, "Default integration did not build art")
		other.queue_free()
		await process_frame
	root.canvas_transform = Transform2D.IDENTITY
	state.delete_save()
	if failures.is_empty():
		print("RAMPART PAINTED ART TEST PASSED: 24 connected backplates, stone surfaces, four alpha props, unchanged physics and original silhouettes, scoped retirement, parallax and opt-in safety")
		quit(0)
	else:
		quit(1)
