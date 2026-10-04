extends "res://tests/shaft_guard_combat_smoke.gd"
const GUIDE_ART := preload("res://EchoGuideAppearance.gd")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_guide_art_save.json"
	state.start_new_game("normal")
	player = _player()
	player.get_node("Camera2D").enabled = false
	for region in GUIDE_ART.SHEETS:
		await _native_cycle(region)
	player.queue_free()
	await process_frame
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.get_node("Player").set_physics_process(false)
	await process_frame
	var ids := {}
	for data in [["echo_gallery", "EchoGallery", "gallery"], ["echo_archive", "PrismArchive", "archive"], ["echo_nest", "EchoNest", "nest"], ["echo_tide_well", "TideWell", "tide"], ["echo_causeway", "CrystalCauseway", "causeway"], ["echo_vault", "UndertowVault", "vault"]]:
		var room := game.get_node(data[1]) as Node2D
		var dressing := room.get_node("LongTraversal/FieldDressing")
		_check(not dressing.has_node("FieldGuide"), "Unvisited guide eagerly loaded")
		state.set_current_room(data[0])
		await process_frame
		var actor := dressing.get_node("FieldGuide") as Area2D
		var art := actor.get_node("FieldAppearance")
		_check(art.region == data[2] and art.is_visible_in_tree(), "Guide role not selected")
		ids[data[0]] = actor.get_instance_id()
		var foot: Vector2 = actor.to_global(Vector2(0, 24))
		var supported := false
		for body in room.find_children("*", "StaticBody2D", true, false):
			var collider := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if collider == null or not collider.shape is RectangleShape2D:
				continue
			var rect: Rect2 = collider.global_transform * Rect2(-collider.shape.size * 0.5, collider.shape.size)
			if foot.x > rect.position.x + 12 and foot.x < rect.end.x - 12 and absf(foot.y - rect.position.y) <= 1:
				supported = true
		_check(supported, "Painted guide feet not on actual floor: " + data[1])
		var text: String = actor.get_next_line()
		_check(not text.is_empty(), "Guide lost contextual dialogue")
		for label in [actor.get_node("NameLabel"), actor.get_node("InteractionPrompt")]:
			var label_rect: Rect2 = label.get_global_transform() * Rect2(Vector2.ZERO, label.size)
			for body in room.find_children("*", "StaticBody2D", true, false):
				var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
				if collision != null and collision.shape is RectangleShape2D and not collision.disabled:
					var terrain: Rect2 = collision.global_transform * Rect2(-collision.shape.size * 0.5, collision.shape.size)
					_check(not label_rect.intersects(terrain), "Guide label overlaps terrain: " + data[1] + "/" + String(label.name))
		if data[2] == "nest":
			_check(not dressing.get_node("Site0/SilkAwning").visible and dressing.get_node("Site0/PaintedTent").visible, "Duplicate silk tent contour visible")
		state.set_current_room("training_passage")
		_check(not art.can_process(), "Inactive guide art processing")
		state.set_current_room(data[0])
		_check(actor.get_instance_id() == ids[data[0]], "Reentry duplicated field guide")
	state.set_current_room("echo_grotto")
	var grotto_guide := game.get_node("EchoGrotto/LongTraversal/FieldDressing/FieldGuide")
	_check(grotto_guide.get_node_or_null("FieldAppearance") != null and grotto_guide.get_node("FieldAppearance").region == "echo", "Leth's Choir Listener appearance was not applied on room entry")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("ECHO GUIDE APPEARANCE TEST PASSED: ten unique guide sheets, four poses each, including streamed Leth, native patrol/dialogue/facing, transparent mipmapped sheets, floor support, lazy spawn/reentry/inactive processing")
		quit(0)
	else:
		quit(1)


func _native_cycle(region: String) -> void:
	var camp := Node2D.new()
	root.add_child(camp)
	for side in [-1, 1]:
		var marker := Marker2D.new()
		marker.name = "Stop%d" % side
		marker.position.x = side * 28
		camp.add_child(marker)
	var actor: Area2D = load("res://TownResident.tscn").instantiate()
	actor.route_marker_names = PackedStringArray(["Stop-1", "Stop1"])
	actor.walk_speed = 16
	camp.add_child(actor)
	actor.set_process(false)
	var art := GUIDE_ART.attach(actor, region)
	art.set_process(false)
	_check(GUIDE_ART.attach(actor, region) == art, "Duplicate appearance attachment")
	var collider := actor.get_node("CollisionShape2D")
	var shape_rid: RID = collider.shape.get_rid()
	var shape_transform: Transform2D = collider.transform
	var poses := {}
	var facings := {}
	for tick in range(180):
		actor._process(0.1)
		art._process(0.1)
		poses[art.frame] = true
		facings[art.flip_h] = true
	_check(poses.has(0) and poses.has(1) and poses.has(2) and facings.size() == 2, "Native patrol pose/facing coverage incomplete")
	for side in [-1, 1]:
		player.position = actor.global_position + Vector2(side * 20, 0)
		actor._on_body_entered(player)
		actor.set_player_dialogue_active(true)
		var before: Vector2 = actor.position
		actor._process(0.1)
		art._process(0.1)
		_check(art.frame == 3 and art.flip_h == (side < 0) and actor.position == before, "Talk pose/facing/native stop wrong")
		_check(not actor.prompt.visible, "Talking prompt still visible")
		actor.set_player_dialogue_active(false)
		_check(actor.prompt.visible and actor.prompt.position.y < actor.name_label.position.y, "Talk prompt lost/under terrain")
		actor._on_body_exited(player)
	actor.hide()
	actor.position.x += 1000
	art._process(1)
	actor.show()
	art._process(0)
	_check(art.frame == 0 and art.travel == 0, "Hidden relocation became walking")
	_check(collider.transform == shape_transform and collider.shape.get_rid() == shape_rid and collider.shape.radius == 34, "Appearance modified talk reach")
	for leaf in ["Coat", "Face", "Accent", "ResidentMotion"]:
		_check(not actor.get_node(leaf).visible, "Old guide art still visible")
	_check(not actor.get_node("ResidentMotion").is_processing(), "Hidden polygon animator active")
	var pixels: Image = art.texture.get_image()
	_check(pixels.has_mipmaps() and pixels.get_size() == Vector2i(1254, 1254), "Guide native resolution/mipmaps lost")
	for at in [Vector2i.ZERO, Vector2i(626, 0), Vector2i(627, 627), Vector2i(1253, 1253)]:
		_check(pixels.get_pixelv(at).a == 0, "Opaque guide background/gutter")
	for pose in range(4):
		art._apply_pose(pose, false)
		_check(art.scale.x == art.scale.y and art.position.y == 24, "Guide distorted/ungrounded")
	camp.queue_free()
	await process_frame
