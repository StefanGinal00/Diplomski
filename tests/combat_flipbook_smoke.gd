extends "res://tests/enemy_attack_art_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_combat_flipbook.json"
	state.start_new_game("normal")
	var book = preload("res://CombatFlipbook.gd")
	var hashes := {}
	var sheets: Array = book.SHEETS.duplicate()
	sheets.append(preload("res://CompactMobAppearance.gd").SHEET)
	for sheet in sheets:
		var image: Image = sheet.get_image()
		_check(image.has_mipmaps(), "Flipbook missing mipmaps")
		for index in range(24):
			var cell := image.get_region(Rect2i(index % 6 * 256, index / 6 * 256, 256, 256))
			_check(not cell.is_invisible() and cell.get_pixel(0, 0).a == 0, "Missing paint / opaque cell corner")
			hashes[hash(cell.get_data())] = true
	_check(hashes.size() == 144, "Expected 120 VFX frames and 24 unique body poses")
	for rate in [30, 60, 120]:
		var seen := {}
		var travel := {}
		for tick in range(rate):
			var age: float = float(tick) / float(rate)
			seen[book.phase(age, 0.3)] = true
			travel[book.phase(age, 0.3, true)] = true
		_check(seen.keys().all(func(f): return f in [2, 3, 4, 5]) and seen.size() == 4, "Release timeline at %d fps" % rate)
		_check(travel.size() == 3 and not travel.has(4) and not travel.has(5), "Live bolt plays breakup frames")
	var room := Node2D.new()
	root.add_child(room)
	room.process_mode = Node.PROCESS_MODE_DISABLED
	for actor_name in ["Enemy", "AshFiend", "RootStalker", "ShaftSentry", "AshSentry"]:
		var actor: Node2D = load("res://%s.tscn" % actor_name).instantiate()
		room.add_child(actor)
		var body := actor.get_node("PaintedMobAppearance")
		var hp: int = actor.current_health
		var shape = actor.get_node("CollisionShape2D").shape
		# Runtime bodies now use tightly registered walk/attack AtlasTextures,
		# not the original six-by-four prototype grid tested above as an asset.
		_check(body.texture is AtlasTexture and body.has_meta("atlas_frame"), "Missing registered body atlas")
		_check(body.heated == (actor_name == "AshSentry"), "Sentry palette identity")
		var collision: CollisionShape2D = actor.get_node("CollisionShape2D")
		var expected_foot := actor.to_global(Vector2(0, collision.position.y + shape.size.y * 0.5))
		for facing in [false, true]:
			body.face_left = facing
			for frame_index in range(6):
				body._apply_pose(frame_index)
				var painted_foot: Vector2 = body.to_global(Vector2(0, -body.texture.get_height() * 0.5 + float(body.get_meta("contact_row"))))
				_check(body.pose == frame_index and absf(painted_foot.y - expected_foot.y) < 0.001,
					actor_name + " opaque foot anchor changed at pose " + str(frame_index))
				_check(body.scale.x == body.scale.y and body.flip_h == facing, "Body proportions/facing changed")
		if actor_name == "RootStalker":
			actor.phase = "warning"
			body._process(0)
			_check(body.pose == 3, "Root windup")
			actor.phase = "burst"
			body._process(0)
			_check(body.pose == 4, "Root burst")
			actor.phase = "recovery"
			body._process(0)
			_check(body.pose == 5, "Root recovery")
		elif actor_name in ["ShaftSentry", "AshSentry"]:
			actor.windup_remaining = 0.4
			body._process(0)
			_check(body.pose == 3, "Sentry windup")
			actor.windup_remaining = 0
		body.contact()
		_check(body.pose == 4, "Contact/shot release not same tick")
		body._process(0.15)
		_check(body.pose == 5, "Missing recovery pose")
		_check(actor.current_health == hp and actor.get_node("CollisionShape2D").shape == shape, "Body art changes gameplay")
		actor.hide()
		_check(body.release_remaining == 0 and body.pose == 0, "Hidden room retained release")
		actor.free()
	var neutral: Node2D = load("res://NeutralCreature.tscn").instantiate()
	room.add_child(neutral)
	_check(not neutral.has_node("PaintedMobAppearance"), "Neutral fauna appearance overwritten")
	neutral.free()
	var effect := Burst.spawn(room, Vector2.ZERO, Color.WHITE, "pillar", Vector2(32, 75), 0.32, 13)
	_check(effect.animation_frame == 2, "Instant damage needs immediate full-power frame")
	effect._process(0.1)
	_check(effect.animation_frame == 3, "Burst did not advance actual image")
	effect._process(0.1)
	_check(effect.animation_frame == 4, "Burst did not break up")
	effect._process(0.08)
	_check(effect.animation_frame == 5, "Burst did not dissipate")
	effect._process(0.1)
	await process_frame
	_check(not is_instance_valid(effect), "Flipbook leaked")
	room.free()
	state.delete_save()
	if failures.is_empty():
		print("TEST PASSED: 144 unique frames, 30/60/120fps timelines, body state/floor/palette, visibility, gameplay invariants")
	quit(0 if failures.is_empty() else 1)
