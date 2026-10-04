extends "res://tests/preview_characters.gd"


func _shot(parent: Node, index: int, at: Vector2, aim: Vector2) -> Node2D:
	var magical := index >= 3
	var shot: Node2D = load("res://PlayerMagicProjectile.tscn" if magical else "res://PlayerArrow.tscn").instantiate()
	parent.add_child(shot)
	shot.position = at
	if magical:
		shot.setup(aim, null, "frost_orb" if index == 5 else "arc_bolt", 0, "sunder_staff" if index == 4 else "apprentice_staff")
	else:
		shot.setup(aim, null, "ember_arrow" if index == 2 else "basic_arrow", 0, 0, "thorn_bow" if index == 1 else "hunter_bow")
	shot.process_mode = Node.PROCESS_MODE_DISABLED
	shot.get_node("Appearance")._process(0.1)
	return shot


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_projectile_preview_save.json"
	state.start_new_game("normal")
	var gallery := Node2D.new()
	root.add_child(gallery)
	var backdrop := Polygon2D.new()
	backdrop.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)])
	backdrop.color = Color("172b38")
	gallery.add_child(backdrop)
	_label(gallery, "PROJECTILES / painted spell and flame flight", Vector2(40, 22), 26)
	_label(gallery, "Upper rows: enlarged 6x / Lower row: 2.5x gameplay zoom", Vector2(40, 64), 18)
	var captions := ["Hunter arrow", "Thorn arrow", "Ember arrow", "Arc bolt", "Sunder arc", "Frost orb"]
	for index in range(6):
		var x := 115.0 + index * 210.0
		_label(gallery, captions[index], Vector2(x - 75, 120))
		for row in range(3):
			var shot := _shot(gallery, index, Vector2(x, 220 + row * 175), Vector2(-1, -1) if row == 1 else Vector2.RIGHT)
			shot.scale *= 2.5 if row == 2 else 6.0
	await _capture("projectile_variants")
	for shot in get_nodes_in_group("player_projectile"):
		shot.get_node("Appearance")._process(0.06)
	await _capture("projectile_variants_frame3")
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
		_shot(stage, index, Vector2(295 + (index % 3) * 135, 80 + (index / 3) * 60), Vector2(-1, -0.5) if index % 2 else Vector2.RIGHT)
	root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2(640, 360) - Vector2(460, 65) * 2.5)
	room.get_node("VisualStyleSlice")._process(0.1)
	await _capture("projectiles_grotto")
	stage.queue_free()
	room.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
