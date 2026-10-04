extends "res://tests/visual_style_slice_smoke.gd"

const ART := preload("res://EchoMachineryArt.gd")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_machinery_art_save.json"
	state.start_new_game("normal")
	for key in ART.SOURCES:
		var texture: Texture2D = load(ART.SOURCES[key][0])
		var picture := texture.get_image()
		_check(texture.get_width() >= 1200 and picture.has_mipmaps(), "Missing source resolution/mipmaps")
		_check(picture.detect_alpha() != Image.ALPHA_NONE and picture.get_pixel(0, 0).a == 0, "Machinery background is not transparent")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.get_node("Player").set_physics_process(false)
	await process_frame
	await process_frame
	var counts := {"pump": 0, "pressure": 0}
	for art in game.find_children("MachineArt", "Node2D", true, false):
		if art.get_script() != ART:
			continue
		counts[art.kind] += 1
		var site: Node2D = art.get_parent()
		var physics := _physics_snapshot(site.get_parent().room)
		var flags: Dictionary = state.unlocked_shortcuts.duplicate(true)
		var size: int = art.get_child_count()
		_check(ART.attach(site, art.kind) == art, "Machine art duplicated")
		art._build()
		_check(art.built and not art.is_processing() and art.get_child_count() == size, "Machine art polls or rebuilds")
		for leaf in art.retired:
			_check(not leaf.visible and leaf.get_child_count() == 0, "Unsafe placeholder retirement")
		var pump: Sprite2D = art.get_node("Pump")
		_check(pump.z_index < 0, "Machinery hides actors or readable plaques")
		_check(is_equal_approx(pump.scale.x, pump.scale.y), "Pump distorted")
		_check(is_zero_approx(pump.get_rect().end.y) and pump.position == Vector2.ZERO, "Pump not grounded")
		_check(pump.get_rect().size.y * pump.scale.y < 43, "Pump too tall for low ledges")
		if art.kind == "pressure":
			var dial: Sprite2D = art.get_node("Dial")
			var face := dial.global_transform * dial.get_rect()
			for body in site.get_parent().expansion.get_children():
				if not body is StaticBody2D:
					continue
				var collider: CollisionShape2D = body.get_node_or_null("CollisionShape2D")
				if collider == null or not collider.shape is RectangleShape2D:
					continue
				var dimensions: Vector2 = collider.shape.size
				var terrain := collider.global_transform * Rect2(-dimensions * 0.5, dimensions)
				_check(not face.intersects(terrain), "Platform obscures gauge: " + str(body.name))
		_check(art.find_children("*", "CollisionObject2D", true, false).is_empty(), "Machinery created interaction/collision")
		_check(_physics_snapshot(site.get_parent().room) == physics and state.unlocked_shortcuts == flags, "Cosmetics changed gameplay")
	var expected_pumps := 0
	for site in game.find_children("Site*", "Node2D", true, false):
		if not (site.has_node("Pipe") and site.has_node("Gauge") and site.has_node("GaugeNeedle")): continue
		expected_pumps += 1
		_check(site.has_node("MachineArt") and site.get_node("MachineArt").built, "Unpainted pump outside old biome whitelist: " + str(site.get_path()))
	_check(expected_pumps >= 3 and counts == {"pump": expected_pumps, "pressure": 2}, "Unexpected machinery coverage: " + str(counts))
	var dressing: Node2D = game.get_node("TideWell/LongTraversal/FieldDressing")
	var lower: Node2D = dressing.get_node("Site3/MachineArt")
	var upper: Node2D = dressing.get_node("Site9/MachineArt")
	_check(not lower.calmed and not upper.calmed and lower.needle_tip.x > 0, "Initial gauge status wrong")
	state.unlock_shortcut("echo_tide_field_station_0")
	_check(lower.calmed and lower.needle_tip.x < 0 and not upper.calmed, "First regulator did not independently update gauge")
	var refreshes: int = lower.refresh_count
	state.unlock_shortcut("unrelated_machine_art_test")
	_check(lower.refresh_count == refreshes, "Unrelated event redrew gauge")
	for id in ["echo_tide_well", "training_passage", "echo_tide_well"]:
		state.set_current_room(id)
		await process_frame
	_check(lower.calmed and not upper.calmed, "Room re-entry reset the gauge")
	state.unlock_shortcut("echo_tide_field_station_1")
	_check(upper.calmed and "CURRENT BANK CALMED" in dressing.get_node("Site9/RouteClue").text, "Upper gauge/clue disagrees with controller")
	# Native nodes still carry the original live state for other observers.
	_check(dressing.get_node("Site3/GaugeNeedle").points[1].x < 0, "Native state was replaced")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("ECHO MACHINERY ART TEST PASSED: ", counts.pump, " pumps, ", counts.pressure, " live gauges, alpha/mipmaps, unchanged gameplay")
		quit(0)
	else:
		quit(1)
