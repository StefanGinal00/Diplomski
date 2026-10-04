extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_starfall_upper_art_save.json"
	state.start_new_game("normal")
	var city: Node2D = load("res://StarfallCitadel.tscn").instantiate()
	city.position = Vector2(18000, -9000)
	root.add_child(city)
	await process_frame
	await process_frame
	city.process_mode = Node.PROCESS_MODE_DISABLED
	var upper := city.get_node("UpperCity")
	var art := upper.get_node("CivicArt")
	for plate in art.replaced:
		plate.show()
	for collection in [art.windows, art.doors, art.lamps, art.gardens, art.awnings, art.houses, art.bells, art.replaced]:
		collection.clear()
	art.built = false
	var physics_before := _physics_snapshot(city)
	var originals := {}
	for node in upper.find_children("*", "Node2D", true, false):
		originals[node] = [node.global_transform, node.z_index, node.visible, node.polygon.duplicate() if node is Polygon2D else null]
	art._build()
	_check(art.windows.size() == 40 and art.doors.size() == 10 and art.houses.size() == 10, "Upper-house detail coverage changed")
	_check(art.lamps.size() == 12 and art.gardens.size() == 12 and art.replaced.size() == 105, "Detail coverage includes lamp posts, tripod and retired schematic lens/pedestal")
	_check(art.bells.size() == 3 and art.telescope_points.size() == 2, "Missing upper-city landmarks")
	_check(art.awnings.size() == 3, "Three workshop canopies need timber material")
	for plate in upper.find_children("WorkshopAwning*", "Polygon2D", true, false):
		_check(plate.texture == art.TIMBER and plate.uv.size() == plate.polygon.size(), "Untextured workshop canopy")
	var nodes: Array[Node] = []
	nodes.assign(upper.find_children("*","",true,false))
	var support := preload("res://WorldSupport.gd")
	var floors := support.floors(nodes)
	for rect in art.lamps:
		var at: Vector2 = art.to_global(Vector2(rect.get_center().x,rect.position.y+108))
		var floor_rect := support.below(at,floors,2)
		_check(floor_rect.has_area() and absf(floor_rect.position.y-at.y)<0.01,"Painted upper lamp not on real deck top")
	_check(art.get_child_count() == 0 and not art.is_processing(), "Static art adds objects or per-frame work")
	_check(_physics_snapshot(city) == physics_before, "Art changed physics")
	for node in originals:
		var before: Array = originals[node]
		_check(node.global_transform == before[0] and node.z_index == before[1], "Art moved an existing node")
		var was_replaced: bool = node in art.replaced
		_check(node.visible == (false if was_replaced else before[2]), "Art hid something outside its replacement set")
		if node is Polygon2D:
			_check(node.polygon == before[3], "Art changed original geometry")
	for plate in art.replaced:
		_check(plate.get_child_count() == 0, "Art hid an interaction/child subtree")
	for collection in [art.windows, art.doors, art.lamps, art.gardens, art.houses]:
		for rect in collection:
			_check(rect.size.x > 0 and rect.size.y > 0 and rect.position.is_finite(), "Invalid art bounds")
	art._build()
	_check(art.replaced.size() == 105, "Repeated build duplicated art")
	city.hide()
	_check(not art.is_visible_in_tree(), "Hidden city retains art")
	city.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("STARFALL UPPER ART TEST PASSED: 10 facades, 40 windows, 10 doors, 12 lanterns, 12 planters, 3 bells, telescope; static, idempotent, unchanged routes/geometry/physics")
		quit(0)
	else:
		quit(1)
