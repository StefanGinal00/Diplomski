extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_prop_clearance_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.get_node("Player").set_physics_process(false)
	await process_frame
	await process_frame
	var route: Node2D = game.get_node("PrismArchive/LongTraversal")
	var checked := 0
	for pair in [[0, "PaintedBookshelf"], [0, "PaintedReadingDesk"], [2, "PaintedBookshelf"], [4, "PaintedCargo"], [7, "PaintedBookshelf"]]:
		var prop: Sprite2D = route.get_node("FieldDressing/Site%d/%s" % pair)
		var bounds := prop.global_transform * prop.get_rect()
		_check(is_zero_approx(prop.position.y), "Prop moved off original floor baseline")
		var supported := false
		for body in route.get_children():
			if not body is StaticBody2D:
				continue
			var collider: CollisionShape2D = body.get_node_or_null("CollisionShape2D")
			if collider == null or not collider.shape is RectangleShape2D or collider.disabled:
				continue
			var size: Vector2 = collider.shape.size
			var terrain := collider.global_transform * Rect2(-size * 0.5, size)
			_check(not bounds.grow(-0.5).intersects(terrain), "Furniture crosses platform: %s / %s" % [prop.get_path(), body.name])
			if absf(terrain.position.y - bounds.end.y) < 0.5 and terrain.position.x <= bounds.position.x and terrain.end.x >= bounds.end.x:
				supported = true
		_check(supported, "Furniture footprint has no complete floor support: " + str(prop.get_path()))
		checked += 1
	var style: Node2D = game.get_node("EchoGrotto/VisualStyleSlice")
	_check(style.surface_one_way.size() == style.surfaces.size(), "Missing ledge metadata")
	var ledges := 0
	for i in range(style.surfaces.size()):
		if not style.surface_one_way[i]:
			continue
		var rect: Rect2 = style.surfaces[i]
		for point in style._terrain_contour(rect, true):
			_check(point.y >= rect.position.y and point.y <= rect.end.y, "Ledge art extends into headroom")
		ledges += 1
	_check(ledges > 20, "Raised Grotto ledges not exercised")
	var camp: Node2D = game.get_node("EchoGrotto/LongTraversal/FieldDressing/Site0")
	var tent: Sprite2D = camp.get_node("PaintedTent")
	var tent_bounds := tent.global_transform * tent.get_rect()
	var overhang: CollisionShape2D = game.get_node("EchoGrotto/LongTraversal/Tier00SideAlcove/CollisionShape2D")
	_check(tent_bounds.position.y > overhang.global_position.y + overhang.shape.size.y * 0.5, "Grotto shelter intersects low overhang")
	var before: Vector2 = tent.position
	for id in ["echo_grotto", "echo_archive", "training_passage", "echo_grotto"]:
		state.set_current_room(id)
		await process_frame
	_check(tent.position == before, "Streaming changed cosmetic anchor")
	print("CLEARANCE COVERAGE ", checked, " archive props; ", ledges, " Grotto ledges")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("ECHO PROP CLEARANCE TEST PASSED")
		quit(0)
	else:
		quit(1)
