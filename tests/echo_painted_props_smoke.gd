extends "res://tests/visual_style_slice_smoke.gd"

const ART := preload("res://EchoPaintedProps.gd")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_painted_props_save.json"
	state.start_new_game("normal")
	for kind in ART.SOURCES:
		var texture: Texture2D = load(ART.SOURCES[kind][0])
		var picture := texture.get_image()
		_check(picture.detect_alpha() != Image.ALPHA_NONE, "Raster has no alpha: " + kind)
		_check(picture.get_pixel(0, 0).a == 0 and picture.get_pixel(picture.get_width() - 1, picture.get_height() - 1).a == 0, "Opaque background: " + kind)
		_check(texture.get_width() >= 1400 and picture.has_mipmaps(), "High resolution/mipmaps missing: " + kind)
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.get_node("Player").set_physics_process(false)
	await process_frame
	await process_frame
	var total := {"cart": 0, "shelf": 0, "fern": 0, "tent": 0, "desk": 0, "book_cart": 0}
	var routes := 0
	for art in game.find_children("PaintedProps", "Node2D", true, false):
		if art.get_script() != ART:
			continue
		routes += 1
		var dressing := art.get_parent()
		# Exercise a fresh build, not merely the idempotent early return.
		for sprite in art.sprites:
			var kind: String = sprite.get_meta("painted_prop_kind")
			_check(sprite.get_rect().size.x * sprite.scale.x <= art.MAX_WIDTH[kind]+0.01, "Oversized field prop: " + kind)
			sprite.free()
		for leaf in art.retired:
			leaf.show()
		art.sprites.clear()
		art.retired.clear()
		art.counts = {"cart": 0, "shelf": 0, "fern": 0, "tent": 0, "desk": 0, "book_cart": 0}
		art.built = false
		var physics := _physics_snapshot(dressing.get_parent())
		var flags: Dictionary = state.unlocked_shortcuts.duplicate(true)
		art._build()
		_check(art.built and not art.is_processing() and art.get_child_count() == 0, "Art not static/built")
		for kind in total:
			total[kind] += art.counts[kind]
		for old in art.retired:
			_check(not old.visible and old.get_child_count() == 0, "Unsafe/missing placeholder retirement")
		for sprite in art.sprites:
			_check(sprite.texture is AtlasTexture and sprite.get_child_count() == 0, "Invalid sprite")
			_check(is_equal_approx(sprite.scale.x, sprite.scale.y), "Prop distorted")
			_check(is_zero_approx(sprite.offset.y + sprite.texture.get_height() * 0.5), "Prop foot anchor shifted")
			_check(sprite.get_parent().get_node("RouteClue").visible, "Clue hidden")
			_check(sprite.get_rect().size.y * sprite.scale.y <= 151, "Sprite covers clue band")
			if sprite.get_meta("painted_prop_kind") == "tent":
				_check(sprite.get_rect().size.y * sprite.scale.y <= 51, "Shelter exceeds low walkway clearance")
			if sprite.name == "PaintedReadingDesk":
				var shelf: Sprite2D = sprite.get_parent().get_node("PaintedBookshelf")
				_check(sprite.get_index() > shelf.get_index() and sprite.z_index == shelf.z_index, "Shelf hides reading desk")
		var before: int = art.sprites.size()
		art._build()
		_check(art.sprites.size() == before, "Repeated build duplicates sprites")
		_check(_physics_snapshot(dressing.get_parent()) == physics and state.unlocked_shortcuts == flags, "Art changed gameplay")
		print("PAINTED ECHO ", dressing.region, ": ", art.counts)
	_check(routes == 29 and total == {"cart": 35, "shelf": 8, "fern": 273, "tent": 19, "desk": 22, "book_cart": 1}, "Unexpected painted prop coverage: " + str(total))
	var archive := game.get_node("PrismArchive/LongTraversal/FieldDressing/Site4/PaintedCargo")
	_check(archive.get_meta("painted_prop_kind") == "book_cart", "Archive cargo is not books")
	for id in ["echo_grotto", "echo_gallery", "echo_archive", "echo_tide_well", "echo_nest", "echo_causeway", "echo_vault", "echo_depths"]:
		state.set_current_room(id)
		await process_frame
	# Re-entry must neither replace artwork nor duplicate static props.
	var sprite_id: int = archive.get_instance_id()
	state.set_current_room("training_passage")
	state.set_current_room("echo_archive")
	await process_frame
	_check(is_instance_valid(archive) and archive.get_instance_id() == sprite_id, "Static prop replaced on re-entry")
	_check(game.get_node("BrokenCauseway").find_children("PaintedProps", "Node2D", true, false).size()==1, "World prop migration omitted Ash causeway")
	# The predicate must never permit hiding a gameplay subtree.
	var sentinel := Polygon2D.new()
	sentinel.add_child(Node.new())
	var probe := ART.new()
	_check(not probe._safe_leaf(sentinel), "Child-bearing decoration accepted")
	probe.free()
	sentinel.free()
	print("TOTAL PAINTED ECHO ", total)
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("ECHO PAINTED PROPS TEST PASSED: generated alpha sprites, 29 routes, foot anchors, preserved physics/flags/clues")
		quit(0)
	else:
		quit(1)
