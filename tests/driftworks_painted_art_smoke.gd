extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_driftworks_painted_art_save.json"
	state.start_new_game("normal")
	var wing := load("res://ExpeditionWing.tscn").instantiate() as Node2D
	wing.region = "shaft"
	wing.painted_driftworks_enabled = false
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
	art.set_script(load("res://DriftworksPaintedArt.gd"))
	wing.add_child(art)
	await process_frame
	_check(art.built and art.plates.size() == 24, "Missing Driftworks chamber/link painting")
	_check(art.surfaces.size() == floors and floors > 50 and art.carts.size() == 4, "Missing iron surfaces or ore carts")
	_check(_physics_snapshot(wing) == physics_before, "Driftworks art changed collision/one-way state")
	_check(art.find_children("*", "CollisionObject2D", true, false).is_empty(), "Ore cart became a gameplay obstacle")
	for node in originals:
		var old: Array = originals[node]
		_check(node.transform == old[0] and node.z_index == old[2], "Driftworks art moved original node")
		_check(node.visible == (false if art.retired.has(node) else old[1]), "Unexpected scenery retirement")
		if art.retired.has(node):
			_check(node.get_child_count() == 0 and (String(node.name).contains("PumpRib") or String(node.name).contains("PipeCap") or String(node.name).contains("Outline")), "Art retired gameplay machinery")
		if node is Polygon2D:
			_check(node.polygon == old[3], "Driftworks art altered geometry")
	for plate in art.plates:
		_check(plate.texture.resource_path.ends_with("driftworks_depth_v1.png") and plate.texture.get_width() == 1024 and plate.texture.get_image().has_mipmaps(), "Wrong mine painting/import")
		_check(plate.z_index == -9 and plate.material == art.material_shared, "Mine painting overlaps actors")
		for index in range(plate.polygon.size()):
			var expected: Vector2 = (art.to_local(plate.to_global(plate.polygon[index])) - art.art_bounds.position) / art.art_bounds.size * plate.texture.get_size()
			_check(plate.uv[index].distance_to(expected) < 0.01, "Mine chamber/shaft UV discontinuity")
	for surface in art.surfaces:
		_check(surface.texture.resource_path.ends_with("drift_iron_v1.png") and surface.texture.get_width() == 512 and surface.texture.get_image().has_mipmaps(), "Missing budgeted iron texture")
		_check(surface.get_node("StoneRim").points[0].y == surface.polygon[0].y + 1, "Metal rim moved jump edge")
	for index in range(art.carts.size()):
		var sprite: Sprite2D = art.carts[index]
		var bitmap := sprite.texture.get_image()
		var used := bitmap.get_used_rect()
		_check(bitmap.get_width() == 512 and bitmap.has_mipmaps() and bitmap.get_pixel(0, 0).a < 0.01 and not bitmap.is_invisible(), "Cart texture/alpha invalid")
		var bottom: Vector2 = sprite.position + Vector2(used.position.x + used.size.x * 0.5, art.cart_foot_y) * sprite.scale
		_check(bottom.distance_to(art.cart_anchors[index]) < 0.01 and sprite.z_index == -7, "Cart is not grounded behind combat")
		var solid_pixels := 0
		for x in range(used.position.x, used.end.x):
			if bitmap.get_pixel(x, art.cart_foot_y - 1).a >= 0.5:
				solid_pixels += 1
		_check(solid_pixels >= 3, "Cart anchor follows transparent fringe")
	var center: Vector2 = art.to_global(art.art_bounds.get_center())
	root.canvas_transform.origin = root.get_visible_rect().size * 0.5 - center
	art._process(0.1)
	var initial: Vector2 = art.material_shared.get_shader_parameter("camera_shift")
	root.canvas_transform.origin -= Vector2(200, 80)
	art._process(0.1)
	var moved: Vector2 = art.material_shared.get_shader_parameter("camera_shift")
	_check(moved.x < initial.x and moved.y < initial.y, "Mine parallax does not follow camera")
	var updates: int = art.update_count
	wing.hide()
	art._process(1)
	_check(art.update_count == updates, "Hidden mine art keeps processing")
	art._build()
	_check(art.plates.size() == 24 and art.carts.size() == 4 and art.surfaces.size() == floors, "Mine art duplicates on rebuild")
	print("DRIFTWORKS ART COVERAGE: 24 backplates, ", floors, " surfaces, ", art.retired.size(), " retired leaves, 4 carts")
	wing.queue_free()
	await process_frame
	for region in ["shaft", "echo", "ash", "starfall"]:
		var other := load("res://ExpeditionWing.tscn").instantiate() as Node2D
		other.region = region
		root.add_child(other)
		await process_frame
		_check(other.has_node("DriftworksArt") == (region == "shaft"), "Mine art leaked into another expedition")
		if region == "shaft":
			_check(other.get_node("DriftworksArt").built, "Default mine art integration failed")
		other.queue_free()
		await process_frame
	root.canvas_transform = Transform2D.IDENTITY
	state.delete_save()
	if failures.is_empty():
		print("DRIFTWORKS PAINTED ART TEST PASSED: 24 masked paintings, iron surfaces, grounded alpha carts, unchanged original geometry/physics, safe retirement, hidden sleep and region opt-in")
		quit(0)
	else:
		quit(1)
