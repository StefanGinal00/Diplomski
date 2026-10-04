extends "res://tests/preview_projectiles.gd"

const Impact = preload("res://ProjectileImpact.gd")


func _burst(parent: Node, index: int, at: Vector2, kind: String, zoom: float) -> void:
	var shot := _shot(parent, index, at, Vector2.LEFT if index % 2 else Vector2.RIGHT)
	var art := shot.get_node("Appearance")
	var effect := Impact.spawn(shot, shot.global_position, shot.direction, art.style, art.core_color, kind)
	effect.set_process(false)
	effect.age = 0.055
	effect.scale = Vector2.ONE * zoom
	effect.queue_redraw()
	shot.queue_free()


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_projectile_impact_preview_save.json"
	state.start_new_game("normal")
	var gallery := Node2D.new()
	root.add_child(gallery)
	var backdrop := Polygon2D.new()
	backdrop.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)])
	backdrop.color = Color("172b38")
	gallery.add_child(backdrop)
	_label(gallery, "CONTACT EFFECTS / enlarged 5x / frozen at 55ms", Vector2(40, 22), 24)
	var captions := ["Hunter", "Thorn", "Ember", "Arc", "Sunder", "Frost"]
	for row in range(3):
		var kind: String = ["actor", "terrain", "breakable"][row]
		_label(gallery, kind.to_upper(), Vector2(25, 130 + row * 195), 16)
		for index in range(6):
			var at := Vector2(170 + index * 195, 210 + row * 195)
			if row == 0:
				_label(gallery, captions[index], Vector2(at.x - 30, 85))
			_burst(gallery, index, at, kind, 5.0)
	await _capture("projectile_impacts")
	for effect in get_nodes_in_group(Impact.GROUP):
		effect.age = 0.16
		effect.queue_redraw()
	# Keep the stage label truthful for the later breakup-frame sample.
	for child in gallery.get_children():
		if child is Label and child.text.begins_with("CONTACT EFFECTS"):
			child.text = "CONTACT EFFECTS / enlarged 5x / frozen at 160ms"
	await _capture("projectile_impacts_late")
	gallery.queue_free()
	await process_frame
	var room: Node2D = load("res://EchoGrotto.tscn").instantiate()
	root.add_child(room)
	await process_frame
	await process_frame
	room.process_mode = Node.PROCESS_MODE_DISABLED
	var stage := Node2D.new()
	root.add_child(stage)
	for index in range(6):
		_burst(stage, index, Vector2(295 + (index % 3) * 135, 80 + (index / 3) * 60), "actor" if index < 3 else "terrain", 1.0)
	root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2(640, 360) - Vector2(460, 65) * 2.5)
	room.get_node("VisualStyleSlice")._process(0.1)
	await _capture("projectile_impacts_grotto")
	stage.queue_free()
	room.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
