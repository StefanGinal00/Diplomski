extends "res://tests/enemy_attack_art_smoke.gd"
const VARIANTS := [
	[false, "basic_arrow", "hunter_bow"],
	[false, "basic_arrow", "thorn_bow"],
	[false, "ember_arrow", "hunter_bow"],
	[true, "arc_bolt", "apprentice_staff"],
	[true, "arc_bolt", "sunder_staff"],
	[true, "frost_orb", "apprentice_staff"],
]

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_player_projectile_flight.json"
	state.start_new_game("normal")
	var room := Node2D.new()
	room.process_mode = Node.PROCESS_MODE_DISABLED
	room.rotation = 0.27
	root.add_child(room)
	for variant in VARIANTS:
		for rate in [30, 60, 120]:
			for aim in [Vector2.LEFT, Vector2.RIGHT, Vector2(-1, -1).normalized(), Vector2(1, 1).normalized()]:
				var shot: Node2D = load("res://PlayerMagicProjectile.tscn" if variant[0] else "res://PlayerArrow.tscn").instantiate()
				room.add_child(shot)
				if variant[0]:
					shot.setup(aim, null, variant[1], 0, variant[2])
				else:
					shot.setup(aim, null, variant[1], 0, 0, variant[2])
				var art := shot.get_node("Appearance")
				art._process(0)
				var animated: bool = variant[0] or variant[1] == "ember_arrow"
				var before := [shot.global_transform, shot.speed, shot.damage, shot.lifetime, shot.remaining_hits, shot.get_node("CollisionShape2D").shape.get_rid()]
				var elapsed := 0.0
				var times := [0.04, 0.10, 0.16, 0.22]
				for index in times.size():
					while elapsed < times[index] - 0.000001:
						var delta := minf(1.0 / rate, times[index] - elapsed)
						elapsed += delta
						art._process(delta)
						_check(art.animation_frame in [1, 2, 3], "Flight plays anticipation/breakup cell")
					_check(art.animation_frame == ([1, 2, 3, 2][index] if animated else 1), "Flight frame depends on FPS")
				_check(before == [shot.global_transform, shot.speed, shot.damage, shot.lifetime, shot.remaining_hits, shot.get_node("CollisionShape2D").shape.get_rid()], "Flight art changes native combat")
				_check(shot.global_transform.x.normalized().is_equal_approx(aim), "Painted flight lost global aim")
				_check(art.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, "Flight mipmaps missing")
				if variant[0]:
					_check(art.material is ShaderMaterial and art.material.get_shader_parameter("accent") == shot.core.color, "Spell palette does not follow weapon")
					var rect: Rect2 = art.flight_rect()
					_check(rect.end.x <= 7 and rect.position.x >= -21 and rect.size.y <= 18, "Flight extends too far beyond native core")
				shot.hide()
				_check(not art.active and art.animation_frame == 1 and art.flight_age == 0, "Hidden shot retains painted flight")
				shot.free()
	# Shader instances must not leak the Sunder palette onto an existing Arc.
	var shots: Array[Node2D] = []
	for weapon in ["apprentice_staff", "sunder_staff"]:
		var shot: Node2D = load("res://PlayerMagicProjectile.tscn").instantiate()
		room.add_child(shot)
		shot.setup(Vector2.RIGHT, null, "arc_bolt", 0, weapon)
		shot.get_node("Appearance")._process(0)
		shots.append(shot)
	var first: ShaderMaterial = shots[0].get_node("Appearance").material
	var second: ShaderMaterial = shots[1].get_node("Appearance").material
	_check(first != second and first.get_shader_parameter("accent") != second.get_shader_parameter("accent"), "Spell palettes shared mutable state")
	room.free()
	state.delete_save()
	if failures.is_empty():
		print("TEST PASSED: 72 flight variants/rates/directions, 1-2-3-2 sequence, isolated palettes, bounds, hidden reset and unchanged native combat")
	quit(0 if failures.is_empty() else 1)
