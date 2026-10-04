extends "res://tests/shaft_hollow_smoke.gd"

const PLACEMENT := preload("res://CrateFloorPlacement.gd")
const CRATE := preload("res://DestructibleCrate.tscn")
const LAYOUT := preload("res://WorldLayout.gd")


func _floor(room: Node2D, at: Vector2, size: Vector2, disabled: bool = false, layer: int = 1, angle: float = 0.0) -> StaticBody2D:
	var floor_node := StaticBody2D.new()
	floor_node.position = at
	floor_node.collision_layer = layer
	floor_node.rotation = angle
	var collider := CollisionShape2D.new()
	collider.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = size
	collider.shape = shape
	collider.disabled = disabled
	floor_node.add_child(collider)
	room.add_child(floor_node)
	return floor_node


func _unit_cases() -> void:
	for case in ["normal", "scaled", "offset", "disabled", "layer_zero", "slope", "ledge", "shaft", "wall", "blocked", "rotated_obstacle", "round_obstacle", "polygon_obstacle", "stacked", "opt_out", "destroyed", "one_way", "already_grounded"]:
		var room := Node2D.new()
		root.add_child(room)
		room.position = Vector2(370, -200)
		if case == "scaled":
			room.scale = Vector2(1.5, 1.5)
		var crate = CRATE.instantiate()
		crate.random_seed = 15
		crate.settle_on_floor = case != "opt_out"
		room.add_child(crate)
		if case == "offset":
			crate.get_node("CollisionShape2D").position.y = 3
		var size := Vector2(120, 12)
		var at := Vector2(0, 42)
		if case == "ledge":
			at.x = 65
		elif case == "shaft":
			at.y = 110
		elif case == "wall":
			size = Vector2(26, 150)
			at.y = 100
		elif case == "already_grounded":
			at.y = 18
		var floor_node := _floor(room, at, size, case == "disabled", 0 if case == "layer_zero" else 1, 0.2 if case == "slope" else 0.0)
		floor_node.get_node("CollisionShape2D").one_way_collision = case == "one_way"
		if case == "blocked":
			_floor(room, Vector2(13, 17), Vector2(8, 15))
		elif case == "rotated_obstacle":
			_floor(room, Vector2(13, 17), Vector2(8, 15), false, 1, 0.3)
		elif case == "round_obstacle":
			var round_body := _floor(room, Vector2(13, 17), Vector2(8, 15))
			var circle := CircleShape2D.new()
			circle.radius = 6
			round_body.get_node("CollisionShape2D").shape = circle
		elif case == "polygon_obstacle":
			var obstacle := StaticBody2D.new()
			var polygon := CollisionPolygon2D.new()
			polygon.polygon = PackedVector2Array([Vector2(8, 18), Vector2(16, 14), Vector2(16, 27)])
			obstacle.add_child(polygon)
			room.add_child(obstacle)
		elif case == "stacked":
			var lower_box = CRATE.instantiate()
			lower_box.position = Vector2(0, 24)
			room.add_child(lower_box)
		if case == "destroyed":
			crate.empty_drop_chance = 1
			crate.take_damage(99)
		var original: Vector2 = crate.global_position
		var health: int = crate.current_health
		var rng_before: int = crate.rng.state
		PLACEMENT.flush()
		var should_move: bool = case in ["normal", "scaled", "offset", "one_way"]
		_check((crate.global_position != original) == should_move, "Unexpected placement result: " + case)
		_check(crate.global_position.x == original.x and crate.current_health == health and crate.rng.state == rng_before, "Placement changed X/health/RNG: " + case)
		if should_move:
			var box := PLACEMENT.bounds(crate.get_node("CollisionShape2D"))
			var floor_box := PLACEMENT.bounds(floor_node.get_node("CollisionShape2D"))
			_check(is_equal_approx(box.end.y, floor_box.position.y), "Box not flush with support: " + case)
			_check(not PLACEMENT.settle(crate, PLACEMENT.terrain_rects(room)), "Placement is not idempotent")
		room.queue_free()
		await process_frame
	# Weak references do not keep an abandoned population or its room alive.
	var doomed := Node2D.new()
	root.add_child(doomed)
	doomed.add_child(CRATE.instantiate())
	doomed.free()
	PLACEMENT.flush()
	_check(PLACEMENT.pending.is_empty() and not PLACEMENT.scheduled, "Placement queue leaked")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_crate_floor_placement_save.json"
	state.start_new_game("normal")
	await _unit_cases()
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.get_node("Player").set_physics_process(false)
	await process_frame
	var total := 0
	var moved := 0
	var repaired := 0
	var unsupported: Array[String] = []
	for id in LAYOUT.ROOM_NODES:
		state.set_current_room(id)
		var room := game.get_node(LAYOUT.ROOM_NODES[id]) as Node2D
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var terrain := PLACEMENT.terrain_rects(room)
		var positions: Dictionary = {}
		var crates: Array[Node] = []
		for candidate in room.find_children("*", "StaticBody2D", true, false):
			if candidate.get_script() == load("res://DestructibleCrate.gd") and not candidate.is_queued_for_deletion():
				crates.append(candidate)
				positions[candidate.get_instance_id()] = candidate.global_position
		PLACEMENT.flush()
		_check(terrain == PLACEMENT.terrain_rects(room), "Crate placement changed terrain in " + id)
		for crate in crates:
			total += 1
			var delta: Vector2 = crate.global_position - positions[crate.get_instance_id()]
			var key := String(game.get_path_to(crate))
			var authored: Dictionary = PLACEMENT.AUTHORED.ANCHORS
			if authored.has(key):
				repaired += 1
				_check(crate.position.distance_to(authored[key][1]+crate.get_meta("spawn_clearance_offset",Vector2.ZERO)) < 0.02, "Reviewed anchor not applied: " + key)
				_check(absf(delta.x) <= 480 and absf(delta.y) <= 48, "Reviewed anchor exceeded its correction envelope: " + key)
				_check(not PLACEMENT.AUTHORED.apply(crate, room), "Reviewed anchor applied twice: " + key)
			else:
				var clearance: Vector2 = crate.get_meta("spawn_clearance_offset",Vector2.ZERO)
				_check((is_zero_approx(delta.x) or is_equal_approx(delta.x,clearance.x)) and absf(clearance.x)<=PLACEMENT.MAX_CLEARANCE and delta.y >= 0 and delta.y <= PLACEMENT.MAX_DROP, "Crate moved out of safe range: " + String(crate.get_path()))
			if delta.y > PLACEMENT.EPSILON:
				moved += 1
			var bounds := PLACEMENT.bounds(crate.get_node("CollisionShape2D"))
			if delta != Vector2.ZERO:
				for other in crates:
					if other != crate:
						_check(not bounds.grow(-PLACEMENT.EPSILON).intersects(PLACEMENT.bounds(other.get_node("CollisionShape2D"))), "Placement overlapped another crate: " + String(crate.get_path()))
			var supported := false
			for floor_rect in terrain:
				if absf(bounds.end.y - floor_rect.position.y) < 0.1 and bounds.position.x >= floor_rect.position.x - 0.05 and bounds.end.x <= floor_rect.end.x + 0.05:
					supported = true
			_check(supported or delta == Vector2.ZERO, "Moved crate is not supported")
			if authored.has(key):
				var headroom := Rect2(bounds.position - Vector2(12, 40), Vector2(48, 64)).grow(-0.05)
				for obstacle in terrain + PLACEMENT.other_obstacles(room):
					_check(not headroom.intersects(obstacle), "Reviewed anchor blocks headroom: " + key)
			if not supported:
				unsupported.append(String(crate.get_path()).trim_prefix("/root/Game/"))
			_check(not crate.is_processing() and not crate.is_physics_processing(), "Settled crate keeps processing")
		await process_frame
	print("CRATE SUPPORT AUDIT: %d visited, %d moved, %d unchanged unsupported: %s" % [total, moved, unsupported.size(), str(unsupported)])
	_check(total == 556 and repaired == 85 and unsupported.is_empty(), "World grounding coverage regressed")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("CRATE FLOOR PLACEMENT TEST PASSED: bounded room-local batches, terrain safety, 18 edge cases and complete mapped-room audit")
		quit(0)
	else:
		quit(1)
