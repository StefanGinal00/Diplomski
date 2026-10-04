extends "res://tests/visual_style_slice_smoke.gd"

const ART := preload("res://EchoNestArt.gd")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_nest_art_save.json"
	state.start_new_game("normal")
	for key in ART.SOURCES:
		var texture: Texture2D = load(ART.SOURCES[key][0])
		var picture := texture.get_image()
		_check(texture.get_width() >= 1024 and picture.has_mipmaps(), "Nest source resolution/mipmaps missing")
		_check(picture.detect_alpha() != Image.ALPHA_NONE and picture.get_pixel(0, 0).a == 0, "Nest source not transparent")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.get_node("Player").set_physics_process(false)
	await process_frame
	await process_frame
	var count := 0
	for art in game.find_children("NestArt", "Node2D", true, false):
		if art.get_script() != ART:
			continue
		count += 1
		var site: Node2D = art.get_parent()
		var dressing: Node2D = site.get_parent()
		var physics := _physics_snapshot(dressing.room)
		var flags: Dictionary = state.unlocked_shortcuts.duplicate(true)
		_check(ART.attach(site) == art, "Duplicate nest art")
		art._build()
		_check(art.built and not art.is_processing() and art.sprites.size() == 6, "Nest art rebuilds, polls or has wrong coverage")
		_check(art.retired.size() == 9, "Wrong retired nursery leaves")
		for leaf in art.retired:
			_check(not leaf.visible and leaf.get_child_count() == 0, "Unsafe nest placeholder retirement")
		for sprite: Sprite2D in art.sprites:
			_check(sprite.get_parent().name in ["DormantPods", "SpentSilk"], "Sprite bypasses controller visibility")
			_check(is_equal_approx(sprite.scale.x, sprite.scale.y), "Nest art distorted")
			_check(is_zero_approx(sprite.get_rect().end.y) and is_zero_approx(sprite.position.y), "Nest art not floor anchored")
			_check(sprite.get_rect().size.y * sprite.scale.y <= 38.01, "Nest art too tall for low ledges")
			var bounds := sprite.global_transform * sprite.get_rect()
			for body in dressing.expansion.get_children():
				if not body is StaticBody2D:
					continue
				var shape: CollisionShape2D = body.get_node_or_null("CollisionShape2D")
				if shape == null or not shape.shape is RectangleShape2D:
					continue
				var size: Vector2 = shape.shape.size
				_check(not bounds.intersects(shape.global_transform * Rect2(-size * 0.5, size)), "Nursery sprite intersects platform: " + str(body.name))
		_check(art.find_children("*", "CollisionObject2D", true, false).is_empty(), "Cosmetics added collision")
		_check(_physics_snapshot(dressing.room) == physics and state.unlocked_shortcuts == flags, "Nest cosmetics changed gameplay")
	_check(count == 2, "Nest art escaped two nursery sites")
	var dressing: Node2D = game.get_node("EchoNest/LongTraversal/FieldDressing")
	state.set_current_room("echo_nest")
	await process_frame
	_cues(dressing, false, false)
	state.unlock_shortcut("echo_nest_field_station_0")
	_cues(dressing, true, false)
	state.unlock_shortcut("unrelated_nest_art_test")
	_cues(dressing, true, false)
	for id in ["training_passage", "echo_nest"]:
		state.set_current_room(id)
		await process_frame
	_cues(dressing, true, false)
	state.unlock_shortcut("echo_nest_field_station_1")
	_cues(dressing, true, true)
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("ECHO NEST ART TEST PASSED: two nurseries, twelve state variants, alpha/mipmaps, clearance and native visibility")
		quit(0)
	else:
		quit(1)


func _cues(dressing: Node2D, west: bool, east: bool) -> void:
	for data in [[1, west], [5, east]]:
		var site := dressing.get_node("Site%d" % data[0])
		for i in range(3):
			_check(site.get_node("DormantPods/Cocoon%d" % i).is_visible_in_tree() == not data[1], "Closed cocoon disagrees with controller")
			_check(site.get_node("SpentSilk/Husk%d" % i).is_visible_in_tree() == data[1], "Spent husk disagrees with controller")
