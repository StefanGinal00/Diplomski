extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_resident_conversation_preview_save.json"
	state.start_new_game("normal")
	var room: Node2D = load("res://EchoHaven.tscn").instantiate()
	root.add_child(room)
	await process_frame
	await process_frame
	room.process_mode = Node.PROCESS_MODE_DISABLED
	var first := room.get_node("Neris")
	var second := room.get_node("Calen")
	first.position = room.get_node("WestGatheringNeris").position
	second.position = room.get_node("WestGatheringCalen").position
	first.current_stop_marker = room.get_node("WestGatheringNeris")
	second.current_stop_marker = room.get_node("WestGatheringCalen")
	first._end_social_exchange(true)
	first.social_cooldown = 0
	second.social_cooldown = 0
	first._try_social_exchange()
	root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2(640, 360) - Vector2(495, 75) * 2.5)
	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	_label(overlay, "ECHO HAVEN / staged conversation / normal zoom", Vector2(28, 20), 20)
	for phase_name in ["opening", "reply"]:
		if phase_name == "reply":
			first._update_social(1.8)
			second._update_social(1.8)
		first.get_node("ResidentMotion")._process(0.1)
		second.get_node("ResidentMotion")._process(0.1)
		await _capture("resident_" + phase_name)
	room.queue_free()
	overlay.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
