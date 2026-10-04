extends "res://tests/shaft_guard_combat_smoke.gd"
const SPECIES := {"Resonance Moth": "moth", "Whisper Bat": "bat", "Tide Skimmer": "skimmer", "Shard Crawler": "crawler", "Undertow Newt": "newt"}


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_fauna_art_save.json"
	state.start_new_game("normal")
	player = _player()
	player.collision_layer = 0
	player.get_node("Camera2D").enabled = false
	var floor_node := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1500, 20)
	collider.shape = shape
	floor_node.add_child(collider)
	floor_node.position.y = 30
	root.add_child(floor_node)
	for named in SPECIES:
		for side in [-1, 1]:
			await _live_case(named, side)
	for data in [["sunken_shaft", "Cave Moth"], ["starfall_reach", "Dusk Moth"], ["echo_grotto", "Mossling"], ["echo_grotto", "Spore Fern Grazer"], ["echo_grotto", "Unknown"]]:
		var actor: CharacterBody2D = load("res://NeutralCreature.tscn").instantiate()
		actor.zone_id = data[0]
		actor.creature_name = data[1]
		root.add_child(actor)
		var expected := str(data[1]).ends_with(" Moth")
		_check(actor.get_node("FaunaAppearance").enabled == expected, "Expanded fauna species scope wrong: " + str(data))
		_check(actor.sprite.visible != expected or actor.get_node("EchoAppearance").enabled, "Expanded fauna left placeholder visible")
		actor.queue_free()
	floor_node.queue_free()
	player.queue_free()
	await process_frame
	await _population_case(state)
	state.delete_save()
	if failures.is_empty():
		print("ECHO FAUNA APPEARANCE TEST PASSED: five families, ten live cycles, alpha/gutters/mipmaps, native neutrality/grace/hit, scope and actual streaming")
		quit(0)
	else:
		quit(1)


func _live_case(named: String, side: int) -> void:
	player.position = Vector2(side * 110, 10)
	var actor: CharacterBody2D = load("res://NeutralCreature.tscn").instantiate()
	actor.zone_id = "echo_grotto"
	actor.creature_name = named
	actor.position = Vector2(0, 10)
	actor.direction = side
	actor.rest_seconds = 0.2
	actor.wander_seconds = 0.9
	root.add_child(actor)
	var art := actor.get_node("FaunaAppearance")
	art.set_process(false)
	_check(art.enabled and art.species == SPECIES[named] and not actor.sprite.visible and not actor.get_node("EchoAppearance").enabled, "Species selection/old art conflict")
	var geometry := {}
	for path in ["CollisionShape2D", "DetectionArea/CollisionShape2D", "AwarenessArea/CollisionShape2D", "TopHitbox/CollisionShape2D"]:
		var node := actor.get_node(path)
		geometry[path] = [node.transform, node.shape.get_rid()]
	_check(not actor._damage_player_if_possible(player), "Neutral fauna attacks first")
	actor._on_awareness_area_body_entered(player)
	_check(actor.target_player == null, "Neutral fauna gained sight aggro")
	var poses := {}
	for tick in range(80):
		await physics_frame
		art._process(1.0 / 60.0)
		poses[art.frame] = true
		_check(art.flip_h == (actor.direction < 0), "Fauna facing mismatch")
		if actor.resting:
			_check(art.frame == 0 and actor.sleep_label.visible, "Rest pose disagrees with native state")
	_check(poses.has(0) and poses.has(1) and poses.has(2), "Rest/stride pose coverage incomplete")
	actor.take_damage(1)
	art._process(0)
	_check(art.frame == 3 and art.modulate.r > art.modulate.g and actor.current_health == 2, "Hit feedback missing")
	var warning_ticks := 0
	for tick in range(38):
		await physics_frame
		art._process(1.0 / 60.0)
		if actor.grace_remaining > 0 and not is_zero_approx(actor.grace_remaining):
			warning_ticks += 1
			_check(art.frame == 3 and actor.sleep_label.text == "!" and not actor._damage_player_if_possible(player), "Provocation grace changed")
	_check(warning_ticks >= 31 and actor.is_hostile, "Native wake window lost")
	actor.set_physics_process(false)
	actor.restore_streamed_state({"current_health": 2, "is_hostile": false, "resting": true, "direction": -side})
	art._process(0.1)
	_check(art.frame == 0 and art.flip_h == (-side < 0), "Restored rest/facing missing")
	actor.hide()
	actor.position.x += 1000
	var travel: float = art.travel
	art._process(1)
	actor.show()
	actor.resting = false
	art._process(1)
	_check(art.frame == 0 and art.travel == travel, "Hidden relocation animates")
	actor.position.x += 1000
	art._process(0.001)
	_check(art.frame == 0, "Teleport animates")
	for path in geometry:
		var node := actor.get_node(path)
		_check(geometry[path] == [node.transform, node.shape.get_rid()], "Fauna collision changed")
	_check(actor.xp_reward == 1 and actor.gold_reward == 3 and actor.max_health == 3 and actor.is_in_group("neutral_creature"), "Fauna rewards/quest family changed")
	var pixels: Image = art.texture.get_image()
	_check(pixels.get_size() == Vector2i(1254, 1254) and pixels.has_mipmaps(), "Sheet size/mipmaps wrong")
	for at in [Vector2i.ZERO, Vector2i(626, 0), Vector2i(627, 627), Vector2i(1253, 1253)]:
		_check(pixels.get_pixelv(at).a == 0, "Opaque background/gutter")
	for pose in range(4):
		art._apply_pose(pose, side < 0, Color.WHITE)
		_check(art.frame == pose and art.scale.x == art.scale.y and art.position == Vector2(0, 9), "Pose distortion/pivot wrong")
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	_check(not art.can_process(), "Inactive fauna still processing")
	actor.queue_free()
	await process_frame


func _population_case(state: Node) -> void:
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.get_node("Player").set_physics_process(false)
	await process_frame
	var route := game.get_node("EchoGrotto/LongTraversal")
	_check(not route.has_node("QuietCaveLife0"), "Unvisited fauna eagerly loaded")
	state.set_current_room("echo_grotto")
	var actor := route.get_node("QuietCaveLife0")
	actor.set_physics_process(false)
	actor.take_damage(1)
	var identity: int = actor.get_instance_id()
	state.set_current_room("training_passage")
	_check(not actor.get_node("FaunaAppearance").can_process(), "Off-room fauna art active")
	game.get_node("WorldPopulation").unload_room_population("EchoGrotto")
	await process_frame
	_check(not route.has_node("QuietCaveLife0"), "Fauna appearance prevents unload")
	state.set_current_room("echo_grotto")
	actor = route.get_node("QuietCaveLife0")
	actor.set_physics_process(false)
	actor.get_node("FaunaAppearance")._process(0)
	_check(actor.get_instance_id() != identity and actor.is_hostile and actor.current_health == 2 and actor.get_node("FaunaAppearance").frame == 3, "Reloaded appearance/native state lost")
	var coverage := {}
	var rooms := {}
	for id in ["echo_grotto", "echo_gallery", "echo_archive", "echo_tide_well", "echo_nest", "echo_causeway", "echo_vault", "echo_depths", "echo_haven", "echo_haven_outskirts"]:
		state.set_current_room(id)
		await process_frame
		if preload("res://WorldLayout.gd").ROOM_NODES.has(id):
			var room := game.get_node(preload("res://WorldLayout.gd").ROOM_NODES[id])
			var entry := room.get_node_or_null("LongTraversal/QuietCaveLife0") as Node2D
			if entry != null:
				var supported := false
				for floor_node in entry.get_parent().get_children():
					if floor_node is StaticBody2D and String(floor_node.name).begins_with("Chamber00Floor"):
						var collider := floor_node.get_node("CollisionShape2D") as CollisionShape2D
						var half: float = collider.shape.size.x * 0.5
						if entry.left_limit - 15 >= collider.global_position.x - half and entry.right_limit + 15 <= collider.global_position.x + half:
							supported = true
				_check(supported, "Entry fauna patrol extends beyond its floor")
				for door in room.get_children():
					if door.is_in_group("room_door") and absf(door.global_position.y - entry.global_position.y) < 100:
						_check(absf(door.global_position.x - entry.global_position.x) >= 159, "Entry fauna patrol overlaps return portal")
		for art in game.find_children("FaunaAppearance", "Sprite2D", true, false):
			if art.enabled:
				coverage[art.get_parent().get_instance_id()] = art.species
				rooms[id] = true
	var families := {}
	for kind in coverage.values():
		families[kind] = true
	_check(families.size() == 5 and coverage.size() >= 40, "World fauna coverage incomplete")
	print("FAUNA COVERAGE ", coverage.size(), " actors; families ", families.keys())
	game.queue_free()
	await process_frame
