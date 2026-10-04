extends "res://tests/visual_style_slice_smoke.gd"

const ART := preload("res://FieldReserveArt.gd")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_field_reserve_art_save.json"
	state.start_new_game("normal")
	var game := load("res://Game.tscn").instantiate() as Node2D
	root.add_child(game)
	current_scene = game
	game.get_node("Player").set_physics_process(false)
	await process_frame
	await process_frame
	var counts := {"shaft": 0, "ash": 0, "starfall": 0}
	var before_inventory: Dictionary = state.inventory.duplicate(true)
	var before_flags: Dictionary = state.unlocked_shortcuts.duplicate(true)
	for sprite in game.find_children("PaintedReserve", "Sprite2D", true, false):
		var kind: String = sprite.get_meta("reserve_art_kind")
		counts[kind] += 1
		var site: Node2D = sprite.get_parent()
		var room: Node2D = site.get_parent().room
		var physics := _physics_snapshot(room)
		var profile: Dictionary = ART.PROFILES[kind]
		if kind == "shaft":
			_check(site.z_index == -1, "Reserve is hidden behind mine braces or above walkable terrain")
		_check(not site.get_node(profile.body).visible, "Prototype body still visible: " + str(site.get_path()))
		_check(sprite.texture is AtlasTexture and sprite.texture.atlas.get_width() >= 1024, "Missing high-resolution reserve texture")
		_check(sprite.texture.atlas.get_image().detect_alpha() != Image.ALPHA_NONE, "Reserve has opaque background")
		_check(sprite.texture.atlas.get_image().has_mipmaps(), "Reserve texture lacks mipmaps")
		_check(is_equal_approx(sprite.get_rect().size.x * sprite.scale.x, 60.72), "Reserve footprint too large")
		_check(sprite.get_rect().size.y * sprite.scale.y <= 30, "Reserve taller than a normal supply coffer")
		_check(absf(sprite.get_rect().end.y * sprite.scale.y) < 0.01, "Reserve is not grounded at its site")
		_check(site.find_children("*", "CollisionObject2D", true, false).is_empty(), "Art introduced collision")
		var points: Array = []
		for i in range(2):
			var seal: Line2D = site.get_node(profile.seals[i])
			var center: Vector2 = seal.position + profile.old_centers[i] * seal.scale
			_check(center.is_equal_approx(profile.centers[i] * ART.DISPLAY_SCALE), "Live seal not aligned to painted socket")
			points.append(seal.transform)
		var original_id := sprite.get_instance_id()
		_check(ART.attach(site, kind).get_instance_id() == original_id, "Repeated art attachment duplicated a sprite")
		for i in range(2):
			_check(site.get_node(profile.seals[i]).transform == points[i], "Repeat attachment moved indicators twice")
		_check(_physics_snapshot(room) == physics, "Art changed room physics")
	_check(counts == {"shaft": 5, "ash": 6, "starfall": 7}, "Wrong reserve art coverage: " + str(counts))
	_check(state.inventory == before_inventory and state.unlocked_shortcuts == before_flags, "Decorative art awarded progress")
	# Native controllers still own the original live indicator nodes.
	var shaft := game.get_node("ShaftHollow/ExpandedRoute/FieldDressing/Site4")
	state.unlock_shortcut("shaft_hollow_hidden_depth_cleared")
	_check(not shaft.get_node("GuardianSeal0").visible and not shaft.get_node("GuardianSeal1").visible, "Shaft seals did not retire on victory")
	state.open_cache("shaft_hollow_depth_cache")
	_check("CLAIMED" in shaft.get_node("RouteClue").text, "Painted marker broke collection feedback")
	var ash := game.get_node("CinderForge/AshSwitchback/FieldDressing/Site6")
	state.unlock_shortcut("ash_forge_field_complete")
	state.unlock_shortcut("ash_forge_guarded_niche_cleared")
	_check(ash.get_node("FieldSeal").modulate.g == 1 and ash.get_node("GuardianSeal").modulate.g == 1, "Ash seal colors lost controller updates")
	var star := game.get_node("StarfallOutskirts/ExpandedRoute/FieldDressing/Site6")
	state.unlock_shortcut("starfall_outskirts_field_complete")
	state.unlock_shortcut("starfall_outskirts_niche_cleared")
	_check(star.get_node("TaskSeal").modulate.g == 1 and star.get_node("GuardSeal").modulate.g == 1, "Starfall seal colors lost controller updates")
	var fixture := Node2D.new()
	root.add_child(fixture)
	_check(ART.attach(fixture, "shaft") == null and fixture.get_child_count() == 0, "Malformed site partially replaced")
	fixture.queue_free()
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty(): print("FIELD RESERVE ART TEST PASSED: 18 markers, alpha/mipmaps, live seals and unchanged physics")
	quit(0 if failures.is_empty() else 1)
