extends "res://tests/visual_style_slice_smoke.gd"

const ART := preload("res://EchoDeviceArt.gd")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_device_art_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.get_node("Player").set_physics_process(false)
	await process_frame
	for id in ["echo_grotto", "echo_gallery", "echo_archive", "echo_tide_well", "echo_nest", "echo_causeway", "echo_vault", "echo_depths"]:
		state.set_current_room(id)
		await process_frame
	var counts := {"resonator": 0, "valve": 0, "anchor": 0, "drain": 0, "receiver": 0}
	var flags: Dictionary = state.unlocked_shortcuts.duplicate(true)
	var compact := 0
	var full := 0
	for node in game.find_children("*", "Node2D", true, false):
		if node.get_script() != ART:
			continue
		# Newly migrated world terminals use surveyed floor/ceiling registration;
		# this suite retains its exact legacy Echo field-operations assertions.
		if node.bind_native_state: continue
		counts[node.kind] += 1
		var device := node.get_parent() as Node2D
		var before := _physics_snapshot(device)
		var children := device.get_child_count()
		_check(ART.attach(device, node.kind) == node and device.get_child_count() == children, "Art installation duplicated nodes")
		_check(not node.is_processing() and not node.is_physics_processing() and node.get_child_count() == 0, "Device art polls/adds gameplay children")
		_check(is_equal_approx(node.position.y + 25 * node.scale.y, 25), "Compact device foot shifted")
		if ART.PAINTED.has(node.kind):
			_check(node.scale == Vector2.ONE and node.position == Vector2.ZERO, "Painted device distorted/offset")
			if node.kind != "resonator":
				_check(is_equal_approx(node.painted_rect.end.y, 25), "Compact device foot moved")
			else:
				var expected: float = 31 if device.name == "LowerResonator" else 28
				_check(is_equal_approx(node.painted_rect.end.y, expected), "Resonator not registered to authored floor")
			_check(is_equal_approx(node.painted_rect.size.aspect(), ART.REGIONS[node.kind].size.aspect()), "Painted aspect changed")
			var pixels: Image = ART.PAINTED[node.kind].get_image()
			_check(pixels.has_mipmaps() and pixels.get_pixel(0, 0).a == 0, "Device alpha/mipmaps missing")
			if node.kind != "resonator":
				_check(node.painted_rect.position.y >= -11, "Painted device intersects low overhang")
			if node.kind in ["valve", "anchor", "drain"]:
				_check(not node.prompt_layout_unresolved, "No clear instruction band: " + str(device.get_path()))
				var prompt: Label = device.get_node("InteractionPrompt")
				_check(prompt.position.y <= -77 and prompt.z_index == 3, "Prompt remains buried in the floor")
				var art_bounds: Rect2 = node.global_transform * node.painted_rect
				var prompt_bounds: Rect2 = prompt.get_global_transform() * Rect2(Vector2.ZERO, prompt.size)
				var route: Node2D = device.get_parent().route
				for body in route.find_children("*", "StaticBody2D", true, false):
					var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
					if body.is_in_group("breakable") or collision == null or collision.disabled or not collision.shape is RectangleShape2D:
						continue
					var terrain: Rect2 = collision.global_transform * Rect2(-collision.shape.size * 0.5, collision.shape.size)
					_check(not art_bounds.intersects(terrain), "New device overlaps terrain: " + str(device.get_path()))
					_check(not prompt_bounds.intersects(terrain), "Device prompt overlaps terrain: " + str(device.get_path()))
		elif node.kind != "resonator":
			_check(node.position.y - 26 * node.scale.y >= -11, "Compact device protrudes into low overhang")
		for leaf in ["Core", "Glow", "Base", "Facet"]:
			if device.has_node(leaf):
				_check(not device.get_node(leaf).visible, "Placeholder still visible: " + String(device.get_path()))
		node.set_status(true)
		var refreshes: int = node.refresh_count
		node.set_status(true)
		_check(node.refresh_count == refreshes and node.active, "Art redraws unchanged state")
		node.set_status(false, true)
		_check(node.listening and not node.active, "Recording art state missing")
		node.set_status(false)
		_check(_physics_snapshot(device) == before, "Art changed interaction reach/shape/transform")
		if node.kind != "receiver":
			_check(not device.is_processing(), "Dressed device still spins hidden glow")
	_check(counts == {"resonator": 2, "valve": 2, "anchor": 2, "drain": 2, "receiver": 10}, "Wrong art coverage: " + str(counts))
	_check(state.unlocked_shortcuts == flags, "Cosmetic state changed task progress")
	for node in game.find_children("FieldOperations", "Node2D", true, false):
		if node.get_script() != load("res://EchoFieldOperations.gd"):
			continue
		for sign in node.signs:
			if int(sign.get_meta("station_index")) >= 0:
				compact += 1
				_check(sign.size == Vector2(440, 65) and sign.get_line_count() <= 3, "Compact sign exceeds planned bounds")
				_check("SAVE AT A LAMP" in sign.text, "Local save reminder missing")
			else:
				full += 1
				_check("CACHE:" in sign.text, "Entry exploration clue lost")
	_check(compact == 10 and full == 5, "Echo instructions coverage changed")
	# Live controller-to-art state updates (not just cosmetic setters).
	var lower := game.get_node("EchoGrotto/LowerResonator")
	var upper := game.get_node("EchoGrotto/UpperResonator")
	var player := game.get_node("Player") as Player
	var lower_art := lower.get_node("DeviceArt")
	var refreshed: int = lower_art.refresh_count
	state.unlock_shortcut("unrelated_visual_test")
	_check(lower_art.refresh_count == refreshed, "Unrelated flag refreshed resonator art")
	_check(lower.attune(player) and lower_art.active and not lower.attune(player), "Resonator activation/art/dedup failed")
	_check(upper.attune(player) and upper.get_node("DeviceArt").active and state.has_item("echo_charm"), "Resonator pair reward changed")
	var tide := game.get_node("TideWell/LongTraversal/FieldOperations")
	var control = tide.controls[0]
	_check(control.activate(player) and control.get_node("DeviceArt").active, "Valve activation not reflected by art")
	_check(not control.activate(player), "Dressed valve activated twice")
	_check("STATION COMPLETE" in tide.signs[0].text and "CURRENT BANKS" in tide.signs[1].text, "Local signs cannot distinguish partial completion")
	var post := game.get_node("EchoGrotto/LongTraversal/FieldDiscoveries/ListeningPost0")
	post.listening = true
	post._refresh()
	_check(post.get_node("DeviceArt").listening, "Listening controller did not refresh art")
	post.set_attuned(true)
	_check(post.get_node("DeviceArt").active and not post.get_node("DeviceArt").listening, "Recorded receiver state wrong")
	post.set_attuned(false)
	_check(not post.get_node("DeviceArt").active, "Sequence reset kept recorded art")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("ECHO DEVICE ART TEST PASSED: 18 devices, five silhouettes, immutable reach/flags, static/idempotent art, partial completion and 10 compact/5 full signs")
		quit(0)
	else:
		quit(1)
