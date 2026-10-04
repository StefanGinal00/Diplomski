extends "res://tests/npc_portrait_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_town_nameplate_layout_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	state.set_current_room("echo_haven")
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var hero := game.get_node("Player")
	hero.get_node("Camera2D").enabled = false
	var room := game.get_node("EchoHaven") as Node2D
	var layout := room.get_node("NameplateLayout")
	var crowd := [room.get_node("Neris"), room.get_node("Calen"), room.get_node("Ivara"), room.get_node("GlowmarketTrader")]
	for actor in get_nodes_in_group("friendly_npc"):
		if room.is_ancestor_of(actor) and not actor in crowd:
			actor.hide()
	for actor in crowd:
		actor.position = Vector2(450, 129)
	hero.global_position = crowd[0].global_position + Vector2(25, 0)
	crowd[0].set_player_dialogue_active(true)
	var original_shapes := {}
	for actor in crowd:
		original_shapes[actor] = [actor.position, actor.get_node("CollisionShape2D").shape.get_rid()]
	for resolution in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		root.content_scale_size = resolution
		await process_frame
		for zoom in [1.0, 2.5]:
			root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), Vector2(resolution) * 0.5 - crowd[0].global_position * zoom)
			layout._rescan()
			layout.refresh_layout()
			for actor in crowd:
				_check(actor.position == original_shapes[actor][0], "Name layout moved an NPC")
			_check(crowd[0].name_label.visible, "Active speaker name lost priority")
			_check(crowd[3].name_label.visible, "Service name lost priority")
			var shown := 0
			for a in range(crowd.size()):
				var label: Label = crowd[a].get_node("NameLabel")
				if not label.visible:
					continue
				shown += 1
				_check(Rect2(Vector2.ZERO, Vector2(resolution)).encloses(layout.text_screen_rect(label)), "Name leaves viewport")
				for b in range(a + 1, crowd.size()):
					var other: Label = crowd[b].get_node("NameLabel")
					if other.visible:
						_check(not layout.text_screen_rect(label).intersects(layout.text_screen_rect(other)), "Visible names overlap")
			_check(shown >= 2 and shown < crowd.size(), "Crowded labels not culled")
			var positions: Array = crowd.map(func(actor): return actor.get_node("NameLabel").position)
			layout.refresh_layout()
			_check(positions == crowd.map(func(actor): return actor.get_node("NameLabel").position), "Stationary label layout jitters")
	# Moving apart restores names without changing interactions or colliders.
	for index in range(crowd.size()):
		crowd[index].position.x += float(index) * 160
	root.canvas_transform = Transform2D.IDENTITY
	root.canvas_transform.origin = Vector2(170, 300) - crowd[0].global_position
	layout.refresh_layout()
	for actor in crowd:
		_check(actor.get_node("NameLabel").visible, "Separated label did not return")
		_check(actor.get_node("CollisionShape2D").shape.get_rid() == original_shapes[actor][1], "Name layout changed interaction collider")
	var bubble := crowd[0].get_node("SocialBubble") as Label
	bubble.show()
	layout.refresh_layout()
	var bubble_rect: Rect2 = bubble.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, bubble.size)
	for rect in layout.visible_rects:
		_check(not rect.intersects(bubble_rect), "Name overlaps a social bubble")
	bubble.hide()
	crowd[1].hide()
	layout.refresh_layout()
	_check(not crowd[1].name_label.visible, "Indoor resident retains name")
	# Newly streamed residents join the registry, and freed residents are pruned.
	var newcomer: Node2D = load("res://TownResident.tscn").instantiate()
	newcomer.position = Vector2(950, 129)
	room.add_child(newcomer)
	layout.registry_clock = 0.5
	layout.refresh_layout()
	_check(layout.entries.any(func(entry): return entry.actor == newcomer), "Streamed resident not registered")
	newcomer.queue_free()
	await process_frame
	layout._rescan()
	_check(layout.entries.all(func(entry): return is_instance_valid(entry.actor)), "Freed resident retained")
	var clock_before: float = layout.refresh_clock
	room.hide()
	layout._process(1.0)
	_check(layout.refresh_clock == clock_before, "Hidden room continues name layout")
	for named in ["CinderHearth", "StarfallCitadel"]:
		_check(game.get_node(named).has_node("NameplateLayout"), "Missing settlement name layout")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("TOWN NAMEPLATE LAYOUT TEST PASSED: crowded names, priority, 3 viewports/2 zooms, stability, separation, bubbles, streaming, inactive rooms and collider invariants")
		quit(0)
	else:
		quit(1)
