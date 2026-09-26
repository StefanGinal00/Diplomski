extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _physics_snapshot(room: Node) -> Dictionary:
	var result := {}
	for collider in room.find_children("*", "CollisionShape2D", true, false):
		result[str(room.get_path_to(collider))] = [collider.global_transform, collider.disabled, collider.shape.get_rid(), collider.one_way_collision]
	return result


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_visual_style_slice_save.json"
	state.start_new_game("normal")
	for scene_name in ["EchoGrotto", "StarfallCitadel"]:
		var room: Node2D = load("res://%s.tscn" % scene_name).instantiate()
		var art := room.get_node("VisualStyleSlice")
		art.owner = null
		room.remove_child(art)
		root.add_child(room)
		await process_frame
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var before := _physics_snapshot(room)
		room.add_child(art)
		await process_frame
		await process_frame
		_check(art.built, "Art did not build: " + scene_name)
		_check(_physics_snapshot(room) == before, "Art changed collision state: " + scene_name)
		_check(art.find_children("*", "CollisionObject2D", true, false).is_empty(), "Art introduced gameplay colliders")
		_check(art.plates.size() == (10 if scene_name == "EchoGrotto" else 1), "Missing background plates")
		_check(not art.surfaces.is_empty(), "Missing terrain facing")
		for plate in art.plates:
			_check(plate.texture != null and plate.texture.get_width() >= 1024, "Missing project-local painting")
			_check(plate.uv.size() == plate.polygon.size(), "Invalid background UV")
			_check(plate.z_index < -1 and not plate.z_as_relative, "Background obscures gameplay")
		var first: Polygon2D = art.plates[0]
		art._process(0.1)
		var initial: Vector2 = first.material.get_shader_parameter("camera_shift")
		root.canvas_transform.origin += Vector2(90, 20)
		art._process(0.1)
		_check(first.material.get_shader_parameter("camera_shift") != initial, "Background does not respond to camera")
		var time: float = art.elapsed
		room.hide()
		art._process(1.0)
		_check(art.elapsed == time, "Hidden room kept animating")
		room.queue_free()
		await process_frame
		root.canvas_transform = Transform2D.IDENTITY
	state.delete_save()
	if failures.is_empty():
		print("VISUAL STYLE SLICE TEST PASSED: two scenes, 11 paintings, unchanged colliders, camera response, inactive-room sleep")
		quit(0)
	else:
		quit(1)
