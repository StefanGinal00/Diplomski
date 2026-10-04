extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_prop_audit.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	game.get_node("Player").set_physics_process(false)
	await process_frame
	await process_frame
	for data in [["EchoGrotto", 0], ["PrismArchive", 0], ["PrismArchive", 2], ["PrismArchive", 4], ["PrismArchive", 7]]:
		var route: Node2D = game.get_node(data[0] + "/LongTraversal")
		var site: Node2D = route.get_node("FieldDressing/Site%d" % data[1])
		print("SITE ", data, " ", site.position)
		for body in route.get_children():
			if not body is StaticBody2D:
				continue
			var shape: CollisionShape2D = body.get_node_or_null("CollisionShape2D")
			if shape == null or not shape.shape is RectangleShape2D:
				continue
			var delta: Vector2 = site.to_local(shape.global_position)
			if absf(delta.y) < 180 and absf(delta.x) < 1000:
				print("  ", body.name, " center=", delta, " size=", shape.shape.size, " one_way=", shape.one_way_collision)
	game.queue_free()
	await process_frame
	state.delete_save()
	quit()
