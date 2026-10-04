extends "res://tests/enemy_attack_art_smoke.gd"
const Impact = preload("res://ProjectileImpact.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_player_impact_flipbook.json"
	state.start_new_game("normal")
	var room := Node2D.new()
	room.process_mode = Node.PROCESS_MODE_DISABLED
	room.rotation = 0.31
	room.scale = Vector2(1.4, 0.8)
	root.add_child(room)
	var source := Node2D.new()
	room.add_child(source)
	for style in ["thorn", "ember", "arc", "frost"]:
		for kind in ["actor", "terrain", "breakable"]:
			for rate in [30, 60, 120]:
				for aim in [Vector2.RIGHT, Vector2.LEFT, Vector2(1, -1).normalized(), Vector2(-1, 1).normalized()]:
					var fx := Impact.spawn(source, Vector2(35, 80), aim, style, Color.CYAN, kind)
					fx.process_mode = Node.PROCESS_MODE_DISABLED
					_check(fx.painted_frame() == 4, "Contact begins with windup/flight")
					_check(fx.global_position.is_equal_approx(Vector2(35, 80)) and fx.global_transform.x.is_equal_approx(aim), "Painted contact lost world registration")
					_check(fx.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, "Missing mipmap filtering")
					var frames: Array[int] = []
					for tick in range(ceili(Impact.DURATION * rate) + 1):
						if not fx.is_queued_for_deletion():
							frames.append(fx.painted_frame())
							var rect: Rect2 = fx.painted_rect()
							_check(rect.size.x <= 26 and rect.size == Vector2.ONE * rect.size.x, "Impact exceeds compact bounds")
							if kind == "terrain":
								_check(is_zero_approx(rect.end.x), "Painted terrain impact reaches forward into wall")
							fx._process(1.0 / rate)
					_check(4 in frames and 5 in frames and not fx.visible and fx.is_queued_for_deletion(), "Contact frames or expiry missing")
					var end_age: float = fx.age
					fx._process(1)
					_check(fx.age == end_age, "Queued effect keeps processing")
					fx.free()
	source.hide()
	_check(Impact.spawn(source, Vector2.ZERO, Vector2.RIGHT, "arc", Color.WHITE, "actor") == null, "Hidden emitter spawns contact")
	source.show()
	room.hide()
	_check(Impact.spawn(source, Vector2.ZERO, Vector2.RIGHT, "arc", Color.WHITE, "actor") == null, "Hidden room spawns contact")
	room.show()
	for i in range(40):
		Impact.spawn(source, Vector2.ZERO, Vector2.RIGHT, "frost", Color.WHITE, "actor")
	_check(get_nodes_in_group(Impact.GROUP).size() == 24, "Painted contact bypasses shared impact cap")
	state.checkpoint_resting.emit("test_lamp")
	await process_frame
	_check(get_nodes_in_group(Impact.GROUP).is_empty(), "Painted contact persists after rest")
	room.free()
	state.delete_save()
	if failures.is_empty():
		print("TEST PASSED: 144 painted contact cases, four materials/directions, three surfaces and frame rates, wall bounds, world registration, expiry, hidden suppression and cap")
	quit(0 if failures.is_empty() else 1)
