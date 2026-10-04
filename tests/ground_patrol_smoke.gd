extends "res://tests/boss_combat_presentation_smoke.gd"

class Target extends CharacterBody2D:
	var is_dead := false

func _surface(host: Node, at: Vector2, size: Vector2, one_way := false) -> StaticBody2D:
	var floor_node := StaticBody2D.new()
	floor_node.position = at
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.one_way_collision = one_way
	floor_node.add_child(collision)
	host.add_child(floor_node)
	return floor_node

func _actor(host: Node, identity: String, side: int, at_x := 75.0) -> CharacterBody2D:
	var actor: CharacterBody2D = load("res://%s.tscn" % identity).instantiate()
	actor.position = Vector2(side * at_x, 65)
	if identity == "NeutralCreature":
		actor.start_resting = false
		actor.wander_seconds = 30
	host.add_child(actor)
	actor.direction = side
	return actor

func _edge_case(identity: String, side: int, one_way: bool, chase: bool, rate: int) -> void:
	var host := Node2D.new()
	root.add_child(host)
	_surface(host, Vector2(0, 100), Vector2(220, 16), one_way)
	var actor := _actor(host, identity, side)
	var target := Target.new()
	target.position = Vector2(side * 165, 80)
	host.add_child(target)
	if chase:
		if identity == "NeutralCreature":
			actor._wake_up()
			actor.grace_remaining = 0
		actor.target_player = target
	var turned := false
	for frame in range(rate * 3):
		await physics_frame
		turned = turned or actor.direction == -side
		if actor.position.y > 120: break
	var context := "%s side %d one-way %s chase %s @%d" % [identity, side, one_way, chase, rate]
	_check(actor.position.y < 100 and absf(actor.position.x) < 110, "Patrol fell from ledge: " + context)
	if chase:
		_check(is_zero_approx(actor.velocity.x), "Chase did not hold at unsafe edge: " + context)
		var before: float = actor.position.x
		target.position.x = 0
		for frame in range(rate / 2): await physics_frame
		_check(absf(actor.position.x) < absf(before) - 5, "Chase cannot resume toward reachable target: " + context)
	else:
		_check(turned, "Patrol never turned at ledge: " + context)
	if identity == "NeutralCreature" and not chase:
		_check(not actor.is_hostile and actor.target_player == null, "Terrain navigation provoked fauna")
	host.queue_free()
	await process_frame

func _wall_case(identity: String, side: int, rate: int) -> void:
	var host := Node2D.new()
	root.add_child(host)
	_surface(host, Vector2(0, 100), Vector2(500, 16))
	_surface(host, Vector2(side * 100, 60), Vector2(12, 80))
	var actor := _actor(host, identity, side)
	var turned := false
	for frame in range(rate * 2):
		await physics_frame
		turned = turned or actor.direction == -side
	_check(turned and side * actor.position.x < 80, "%s stayed walking into a wall side %d @%d: position %s direction %d turned %s" % [identity, side, rate, actor.position, actor.direction, turned])
	host.queue_free()
	await process_frame

func _small_step(identity: String, side: int) -> void:
	var host := Node2D.new()
	root.add_child(host)
	_surface(host, Vector2(-side * 60, 100), Vector2(120, 16))
	_surface(host, Vector2(side * 120, 112), Vector2(240, 16))
	var actor := _actor(host, identity, side, -35)
	actor.left_limit = -500
	actor.right_limit = 500
	for frame in range(240): await physics_frame
	_check(side * actor.position.x > 20 and actor.position.y > 90 and actor.position.y < 110, identity + " could not traverse a small downward step")
	host.queue_free()
	await process_frame

func _actor_probe_case(identity: String, side: int) -> void:
	var host := Node2D.new()
	root.add_child(host)
	_surface(host, Vector2(0, 100), Vector2(400, 16))
	var actor := _actor(host, identity, side, 0)
	actor.move_speed = 0
	if identity == "NeutralCreature": actor.passive_walk_speed = 0
	for frame in range(30): await physics_frame
	actor.set_physics_process(false)
	var obstruction := Target.new()
	obstruction.collision_mask = 0
	var half: Vector2 = actor.body_collision.shape.size * 0.5
	obstruction.global_position = actor.body_collision.global_transform * Vector2(side * half.x, half.y) + Vector2(side * 6, -2)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(8, 2)
	var collider := CollisionShape2D.new()
	collider.shape = shape
	obstruction.add_child(collider)
	host.add_child(obstruction)
	await physics_frame
	actor.velocity.x = side * 30
	actor._avoid_patrol_edges(1.0 / 60)
	_check(actor.velocity.x == side * 30 and actor.direction == side, identity + " mistook another actor for a missing floor")
	host.queue_free()
	await process_frame

func _physical_fall(identity: String, knockback: bool) -> void:
	var host := Node2D.new()
	root.add_child(host)
	if knockback: _surface(host, Vector2(0, 100), Vector2(220, 16))
	var actor := _actor(host, identity, 1, 95)
	if knockback:
		actor.move_speed = 0
		actor.chase_speed = 0
		if identity == "NeutralCreature": actor.passive_walk_speed = 0
		for frame in range(30): await physics_frame
		actor.hit_stun_duration = 0.8
		actor.knockback_recovery = 0
		actor.take_damage(1, Vector2(200, -40))
	for frame in range(60): await physics_frame
	_check(actor.position.y > 150, identity + " terrain safety blocked physical fall/knockback")
	host.queue_free()
	await process_frame

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_ground_patrol.json"
	state.start_new_game("normal")
	var previous_rate := Engine.physics_ticks_per_second
	var cases := 0
	for rate in [30, 60, 120]:
		Engine.physics_ticks_per_second = rate
		for identity in ["Enemy", "AshFiend", "NeutralCreature"]:
			for side in [-1, 1]:
				for one_way in [false, true]:
					for chase in [false, true]:
						await _edge_case(identity, side, one_way, chase, rate)
						cases += 1
				await _wall_case(identity, side, rate)
				cases += 1
	Engine.physics_ticks_per_second = 60
	for identity in ["Enemy", "AshFiend", "NeutralCreature"]:
		for side in [-1, 1]:
			await _small_step(identity, side)
			await _actor_probe_case(identity, side)
		await _physical_fall(identity, false)
		await _physical_fall(identity, true)
		cases += 6
	Engine.physics_ticks_per_second = previous_rate
	state.delete_save()
	if failures.is_empty():
		print("GROUND PATROL TEST PASSED: ", cases, " edge/wall/chase/fall cases at 30/60/120 Hz")
		quit(0)
	else:
		print("GROUND PATROL TEST FAILED: ", failures)
		quit(1)
