extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_settlement_street_art_save.json"
	state.start_new_game("normal")
	for scene_name in ["EchoHaven", "EchoHavenOutskirts", "CinderHearth"]:
		var room: Node2D = load("res://%s.tscn" % scene_name).instantiate()
		room.position = Vector2(15000, -7000)
		_check(room.has_node("StreetArt"), "Missing painted street coverage: " + scene_name)
		if not room.has_node("StreetArt"):
			room.free()
			continue
		var art := room.get_node("StreetArt")
		art.owner = null
		room.remove_child(art)
		root.add_child(room)
		await process_frame
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var physics_before := _physics_snapshot(room)
		var original := {}
		for node in room.find_children("*", "Node2D", true, false):
			original[node] = [node.global_transform, node.visible, node.z_index]
		var geometry := {}
		for node in room.find_children("*", "Polygon2D", true, false):
			geometry[node] = node.polygon
		var count := room.find_children("*", "", true, false).size()
		room.add_child(art)
		await process_frame
		await process_frame
		_check(art.built and not art.props.is_empty(), "Street art did not build")
		_check(art.stalls_fitted, "Street awning layout not resolved")
		_check(art.z_index < 0 and not art.is_processing() and not art.is_physics_processing(), "Street art obscures actors or has per-frame work")
		_check(art.get_child_count() == 0, "Decorative pass added scene objects")
		_check(room.find_children("*", "", true, false).size() == count + 1, "Street art changed actor/node count")
		_check(_physics_snapshot(room) == physics_before, "Street art changed physics")
		for node in geometry:
			_check(node.polygon == geometry[node], "Street art changed original polygon")
		for node in original:
			_check(node.global_transform == original[node][0] and node.z_index == original[node][2], "Street art moved/re-layered original node")
			var was_retired: bool = node is Polygon2D and node in art.retired
			_check(node.visible == (false if was_retired else original[node][1]), "Unexpected visibility change")
		for node in art.retired:
			_check(node is Polygon2D and node.get_child_count() == 0, "Retired non-leaf/gameplay node")
			_check(node.get_parent().name in ["NewDistricts", "GateApproach", "EasternDistricts", "HavenGarden", "HearthPlanters"] or String(node.get_parent().name).begins_with("AshGarden"), "Retired out-of-scope prop")
		var district := room.get_node("EasternDistricts" if scene_name == "CinderHearth" else ("GateApproach" if scene_name == "EchoHavenOutskirts" else "NewDistricts"))
		var feet := 0
		for node in district.get_children():
			if node is Polygon2D and String(node.name).begins_with("BenchFoot"):
				feet += 1
				_check(not node.visible and node in art.retired, "Unpainted bench foot remains visible: " + scene_name + " " + str(node.name))
		_check(feet == (0 if scene_name == "CinderHearth" else 12), "Bench foot fixture coverage: " + scene_name)
		var kinds := {}
		var craft_stalls := 0
		var canopies := 0
		var counters := 0
		var openings := preload("res://SettlementCanopyPlacement.gd").openings(art)
		for prop in art.props:
			_check(prop.bounds.has_area() and prop.bounds.position.is_finite() and prop.bounds.size.is_finite(), "Invalid prop bounds")
			kinds[prop.kind] = int(kinds.get(prop.kind, 0)) + 1
			if prop.kind in ["bench", "stall"]:
				var offset := (16.0 if scene_name == "CinderHearth" else 8.0) if prop.kind == "bench" else (51.0 if scene_name == "CinderHearth" else 37.0)
				_check(not is_nan(art._floor_y(Vector2(prop.bounds.get_center().x, prop.bounds.end.y+offset), 4 if prop.kind == "bench" else 10)), "Painted street prop lacks a real floor: " + scene_name + " " + str(prop.kind))
			if prop.kind == "stall":
				_check(prop.has("layout") and not prop.layout.is_empty(), "Street stall lacks clear supported layout: " + scene_name)
				if prop.has("layout") and not prop.layout.is_empty():
					var layout: Dictionary = prop.layout
					_check(absf(art.to_global(layout.at).y-layout.support.position.y)<0.01, "Street posts float")
					if layout.mode=="counter":
						counters += 1
						for opening in openings: _check(not layout.counter.intersects(opening), "Open counter blocks an opening")
						for floor_rect in art.floor_surfaces: _check(not (art.global_transform*Rect2(layout.counter.position,layout.counter.size-Vector2(0,0.1))).intersects(floor_rect), "Open counter cut by ceiling")
						continue
					canopies += 1
					var world: Rect2 = art.global_transform * Rect2(layout.at.x-layout.width/2,layout.at.y,layout.width,1)
					_check(world.position.x>=layout.support.position.x and world.end.x<=layout.support.end.x, "Street canopy overhangs unsupported gap")
					for opening in openings:
						_check(not layout.cloth.intersects(opening) and not layout.posts[0].intersects(opening) and not layout.posts[1].intersects(opening), "Street canopy/post blocks an opening")
					var body := Rect2(layout.cloth.position,Vector2(layout.width,layout.height-1))
					for floor_rect in art.floor_surfaces:
						_check(not (art.global_transform*body).intersects(floor_rect), "Street canopy is sliced by a balcony")
			if prop.craft:
				craft_stalls += 1
				_check(prop.kind == "stall", "Craft goods assigned to a non-stall")
		_check(craft_stalls == (1 if scene_name == "EchoHaven" else 0), "Moon Forge lacks its distinct smithing display")
		_check(canopies == (5 if scene_name == "CinderHearth" else (2 if scene_name=="EchoHavenOutskirts" else 3)) and counters == (0 if scene_name=="EchoHaven" else 1), "Street layout fixture coverage")
		_check(kinds.get("bench", 0) == 6 and kinds.get("stall", 0) == (6 if scene_name == "CinderHearth" else 3), "Missing benches/stalls")
		# Outskirts garden wedges were already retired by the earlier gate pass;
		# keep those hidden instead of duplicating their grounded replacements.
		_check(kinds.get("plant", 0) == (57 if scene_name == "CinderHearth" else (0 if scene_name == "EchoHavenOutskirts" else 39)), "Missing flora")
		if scene_name == "CinderHearth":
			_check(kinds.get("barrel", 0) == 15 and kinds.get("cart", 0) == 3 and kinds.get("wheel", 0) == 6, "Missing caravan props")
		var props_before: Array = art.props.duplicate(true)
		var retired_before: Array = art.retired.duplicate()
		art._build()
		art._fit_stalls()
		_check(art.props == props_before and art.retired == retired_before, "Non-idempotent art build")
		room.hide()
		await process_frame
		_check(not art.is_visible_in_tree() and not art.is_processing(), "Inactive room street art remains active")
		print("STREET ART ", scene_name, ": ", kinds, " clear supported canopies=",canopies," compact open counters=",counters)
		room.queue_free()
		await process_frame
	state.delete_save()
	if failures.is_empty():
		print("SETTLEMENT STREET ART TEST PASSED: static props/flora, exact coverage, scoped visibility, unchanged nodes/physics/polygons/routes, idempotence and inactive-room hiding")
		quit(0)
	else:
		quit(1)
