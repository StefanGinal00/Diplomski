extends "res://tests/ash_field_operations_smoke.gd"

# Uses the real Player controller and room collision geometry, with combat
# disabled. Each hop starts on a real ledge; this is not a full playthrough.
const CASES := [["VerticalChamber", "DeepShaftTraversal"], ["EchoGrotto", "LongTraversal"], ["EchoGallery", "LongTraversal"], ["PrismArchive", "LongTraversal"], ["TideWell", "LongTraversal"], ["EchoNest", "LongTraversal"], ["CrystalCauseway", "LongTraversal"], ["UndertowVault", "LongTraversal"], ["EchoHaven", "NewDistricts"], ["EchoHavenOutskirts", "GateApproach"]]
var player: Player
var jumps := 0


func _bounds(body: StaticBody2D) -> Rect2:
	var collision := body.get_node("CollisionShape2D") as CollisionShape2D
	var size: Vector2 = collision.shape.size
	return Rect2(collision.global_position - size * 0.5, size)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_basic_jump_routes_save.json"
	state.start_new_game("normal")
	var template := load("res://Game.tscn").instantiate() as Node
	player = template.get_node("Player")
	template.remove_child(player)
	template.free()
	root.add_child(player)
	player.double_jump_unlocked = false
	player.dash_unlocked = false
	player.set_physics_process(false)
	for info in CASES:
		var prior_jumps := jumps
		var room := load("res://%s.tscn" % info[0]).instantiate() as Node2D
		room.process_mode = Node.PROCESS_MODE_DISABLED
		root.add_child(room)
		await process_frame
		for actor in room.find_children("*", "CollisionObject2D", true, false):
			actor.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if actor is Area2D or actor.is_in_group("enemy") or actor.is_in_group("neutral_creature") or actor.is_in_group("breakable"):
				actor.collision_layer = 0
				actor.collision_mask = 0
		var expansion := room.get_node(String(info[1]))
		var floors: Array[StaticBody2D] = []
		for body in expansion.get_children():
			if body is StaticBody2D and body.has_node("CollisionShape2D") and body.collision_layer != 0:
				var collision := body.get_node("CollisionShape2D") as CollisionShape2D
				if collision.shape is RectangleShape2D and collision.shape.size.y <= 22:
					floors.append(body)
		for from in floors:
			var source_name := String(from.name)
			if not ("Step" in source_name or "Rise" in source_name or "Stair" in source_name):
				continue
			var source := _bounds(from)
			var target: StaticBody2D
			var best := INF
			var pattern := RegEx.new()
			pattern.compile("^(.*?)([0-9]+)$")
			var part := pattern.search(source_name)
			var descending_number := "Rise" in source_name or "Link" in source_name or "HoistLoop" in source_name
			var next_number := int(part.get_string(2)) + (-1 if descending_number else 1)
			var digits := part.get_string(2)
			var next_name := part.get_string(1) + (str(next_number).pad_zeros(digits.length()) if digits.begins_with("0") else str(next_number))
			var next_step := expansion.get_node_or_null(next_name) as StaticBody2D
			for to in floors:
				if next_step != null and to != next_step:
					continue
				var dest := _bounds(to)
				var rise := source.position.y - dest.position.y
				var gap := maxf(source.position.x, dest.position.x) - minf(source.end.x, dest.end.x)
				if rise < 1 or rise > 78 or gap > 70:
					continue
				var score := absf(dest.get_center().x - source.get_center().x) + rise
				if score < best:
					best = score
					target = to
			_check(target != null, "%s/%s at %s has no next basic-jump landing" % [info[0], from.name, source])
			if target != null:
				await _hop(from, target, String(info[0]))
		_check(jumps > prior_jumps, "No jump coverage for " + String(info[0]))
		room.queue_free()
		await process_frame
	_release()
	player.queue_free()
	await process_frame
	state.delete_save()
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("BASIC JUMP ROUTES TEST PASSED: ", jumps, " real-controller hops in ", CASES.size(), " rooms")
		quit(0)
	else:
		print("BASIC JUMP ROUTES TEST FAILED: ", failures.size(), " / ", jumps)
		quit(1)


func _release() -> void:
	Input.action_release("ui_left")
	Input.action_release("ui_right")


func _hop(from: StaticBody2D, to: StaticBody2D, label: String) -> void:
	jumps += 1
	_release()
	player.set_physics_process(false)
	var source := _bounds(from)
	var dest := _bounds(to)
	var half: Vector2 = player.player_collision.shape.size * 0.5
	var x := clampf(dest.get_center().x, source.position.x + half.x + 5, source.end.x - half.x - 5)
	if not to.get_node("CollisionShape2D").one_way_collision:
		# Approach solid floors through the shaft mouth, not through their underside.
		var left := dest.position.x - half.x - 2
		var right := dest.end.x + half.x + 2
		x = left if absf(left - source.get_center().x) < absf(right - source.get_center().x) else right
		x = clampf(x, source.position.x + half.x + 2, source.end.x - half.x - 2)
	var landing_x := clampf(x, dest.position.x + half.x + 5, dest.end.x - half.x - 5)
	player.global_position = Vector2(x, source.position.y - half.y - 1)
	player.velocity = Vector2.ZERO
	player.jump_count = 0
	player.jump_buffer_remaining = 0
	player.set_physics_process(true)
	for frame in range(8):
		await physics_frame
	_check(player.is_on_floor(), "%s/%s cannot stand at takeoff" % [label, from.name])
	player.jump_buffer_remaining = 0.12
	var landed := false
	var ceilings: Array[String] = []
	for frame in range(80):
		_release()
		var dx := landing_x - player.global_position.x
		if absf(dx) > 2:
			Input.action_press("ui_right" if dx > 0 else "ui_left")
		await physics_frame
		if player.is_on_ceiling():
			for hit in range(player.get_slide_collision_count()):
				var hit_name := str(player.get_slide_collision(hit).get_collider().name)
				if not ceilings.has(hit_name):
					ceilings.append(hit_name)
		if frame > 4 and player.is_on_floor():
			for hit in range(player.get_slide_collision_count()):
				var body := player.get_slide_collision(hit).get_collider() as StaticBody2D
				# A crossing stair may catch the player ABOVE the requested landing.
				# This still proves the ascent when both footprints overlap.
				if body == to or (body != null and player.global_position.y + half.y <= dest.position.y + 1 and player.global_position.x >= dest.position.x and player.global_position.x <= dest.end.x):
					landed = true
			if landed:
				break
		if player.global_position.y > source.position.y + 120:
			break
	var last_body := "none"
	if player.get_slide_collision_count() > 0:
		last_body = str(player.get_slide_collision(0).get_collider().name)
	_check(landed, "%s: basic jump %s -> %s failed at %s, landing %s, ceilings %s, target %s" % [label, from.name, to.name, player.global_position, last_body, ceilings, dest])
	_release()
	player.set_physics_process(false)
