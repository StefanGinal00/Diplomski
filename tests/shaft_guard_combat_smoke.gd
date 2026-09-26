extends "res://tests/shaft_hollow_smoke.gd"

# Controlled live-AI regression, not balance/pacing: a large test health pool
# lets the attack loop finish. Damage to guardians comes ONLY from the real
# Player sword/ShapeCast with its normal cooldown, never direct damage calls.
var player: Player
var attacks := 0


func _player() -> Player:
	var template := load("res://Game.tscn").instantiate() as Node
	var result := template.get_node("Player") as Player
	template.remove_child(result)
	template.free()
	root.add_child(result)
	result.set_physics_process(false)
	return result


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_shaft_guard_combat_save.json"
	state.start_new_game("normal")
	player = _player()
	for tier in [0, 1]:
		state.set_zone_tier("sunken_shaft", tier)
		for side in [-1.0, 1.0]:
			for one_way in [false, true]:
				await _charge_edge(tier, side, one_way)
	state.set_zone_tier("sunken_shaft", 1)
	var room := load("res://ShaftHollow.tscn").instantiate() as Node2D
	room.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(room)
	await process_frame
	for actor in room.find_children("*", "CollisionObject2D", true, false):
		actor.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
		if actor is Area2D or actor.is_in_group("enemy") or actor.is_in_group("neutral_creature") or actor.is_in_group("breakable"):
			actor.collision_layer = 0
			actor.collision_mask = 0
	var route := room.get_node("ExpandedRoute/AuthoredDescent")
	var floor_node := route.get_node("Branch5_Chamber") as StaticBody2D
	var sites := route.get_node("ExplorationSites")
	var trial := sites.get_node("AwakenedTrial")
	var reward := sites.get_node("AwakenedTrialReward")
	player.global_position = floor_node.global_position + Vector2(0, -30)
	player.velocity = Vector2.ZERO
	player.max_health = 100
	player.current_health = 100
	player.set_physics_process(true)
	for frame in range(20):
		await physics_frame
	trial._on_body_entered(player)
	await process_frame
	_check(trial.spawned_enemies.size() == 2 and not reward.open(player), "Awakened fight/reward setup incorrect")
	for enemy in trial.spawned_enemies:
		enemy.process_mode = Node.PROCESS_MODE_ALWAYS
		_check(enemy.max_health == 5, "Awakened crawler health is wrong")
	var charge_seen := false
	var damage_taken := false
	for frame in range(2400):
		Input.action_release("ui_left")
		Input.action_release("ui_right")
		var target: Node2D
		var nearest := INF
		for enemy in trial.spawned_enemies:
			if not is_instance_valid(enemy) or enemy.is_dead:
				continue
			charge_seen = charge_seen or enemy.state == enemy.State.CHARGE
			_check(enemy.global_position.y < floor_node.global_position.y + 60, "Live guardian escaped below the branch")
			var distance: float = absf(enemy.global_position.x - player.global_position.x)
			if distance < nearest:
				nearest = distance
				target = enemy
		if trial.completed:
			break
		# Give the first real telegraph/charge time to occur before attacking.
		if frame > 100 and target != null:
			var dx := target.global_position.x - player.global_position.x
			if absf(dx) > 22 or signf(dx) != player.facing_direction:
				Input.action_press("ui_right" if dx > 0 else "ui_left")
			if nearest < 48 and player.try_attack():
				attacks += 1
		await physics_frame
		damage_taken = damage_taken or player.current_health < 100
		if player.is_dead or player.global_position.y > floor_node.global_position.y + 100:
			break
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	player.set_physics_process(false)
	_check(charge_seen and damage_taken, "Live encounter did not exercise enemy charge/contact damage")
	_check(trial.completed and attacks >= 5, "Real melee attacks did not finish both guardians")
	_check(reward.open(player) and not reward.open(player), "Combat completion did not release the one-time reserve")
	room.queue_free()
	player.queue_free()
	state.delete_save()
	await process_frame
	if failures.is_empty():
		print("SHAFT GUARD COMBAT TEST PASSED: 8 live edge charges, 2 awakened guardians, ", attacks, " real sword attacks, one-time reserve")
		quit(0)
	else:
		print("SHAFT GUARD COMBAT TEST FAILED: ", failures.size())
		quit(1)


func _charge_edge(tier: int, side: float, one_way: bool) -> void:
	var holder := Node2D.new()
	root.add_child(holder)
	var floor_node := StaticBody2D.new()
	floor_node.position = Vector2(0, 100)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(265, 16)
	collision.shape = shape
	collision.one_way_collision = one_way
	floor_node.add_child(collision)
	holder.add_child(floor_node)
	player.global_position = Vector2(side * 190, 80)
	var crawler := load("res://ShaftCrawler.tscn").instantiate() as CharacterBody2D
	crawler.position = Vector2(side * 80, 70)
	holder.add_child(crawler)
	var charged := false
	var recovered := false
	for frame in range(240):
		await physics_frame
		charged = charged or crawler.state == crawler.State.CHARGE
		recovered = recovered or (charged and crawler.state == crawler.State.RECOVER)
		if crawler.position.y > 145:
			break
	_check(charged and recovered and crawler.position.y < 100, "Tier %d side %d one-way %s: charge fell off edge or never entered recovery" % [tier, side, one_way])
	holder.queue_free()
	await process_frame
