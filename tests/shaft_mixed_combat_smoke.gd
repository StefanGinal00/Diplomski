extends "res://tests/shaft_guard_combat_smoke.gd"

# Isolated encounter combat using actual player movement, jumping, sword
# ShapeCast and cooldown. No enemy damage callbacks or mid-fight teleports.
# Extra player health is a harness allowance, not a balance assertion.
const ROOMS := ["ShaftHollow", "DrownedCrossing", "FloodedGallery", "BlackwaterCistern", "WardenApproach"]
var battles := 0
var dives := 0
var volleys := 0
var health_budget := 100
var combat_warmup_frames := 110


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_shaft_mixed_combat_save.json"
	node_added.connect(_on_test_node_added)
	for tier in [0, 1]:
		for scene_name in ROOMS:
			state.start_new_game("normal")
			state.set_zone_tier("sunken_shaft", tier)
			await _battle(scene_name, tier)
	for scene_name in ROOMS:
		state.start_new_game("normal")
		state.set_zone_tier("sunken_shaft", 1)
		await _battle(scene_name, 1, true)
	state.delete_save()
	if failures.is_empty():
		print("SHAFT MIXED COMBAT TEST PASSED: ", battles, " encounters, ", dives, " with live dives, ", volleys, " hostile projectiles, ", attacks, " real sword attacks")
		quit(0)
	else:
		print("SHAFT MIXED COMBAT TEST FAILED: ", failures.size())
		quit(1)


func _on_test_node_added(node: Node) -> void:
	# The room is paused to isolate the encounter, but its newly fired shots
	# must really move/collide, just like the explicitly enabled guardians.
	if node.get_script() == load("res://EnemyProjectile.gd"):
		node.process_mode = Node.PROCESS_MODE_ALWAYS
		volleys += 1


func _battle(scene_name: String, tier: int, return_trial := false) -> void:
	player = _player()
	var room := load("res://%s.tscn" % scene_name).instantiate() as Node2D
	room.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(room)
	await process_frame
	for actor in room.find_children("*", "CollisionObject2D", true, false):
		actor.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
		if actor is Area2D or actor.is_in_group("enemy") or actor.is_in_group("neutral_creature") or actor.is_in_group("breakable"):
			actor.collision_layer = 0
			actor.collision_mask = 0
	var route := room.get_node("ExpandedRoute/AuthoredDescent")
	var floor_node := route.get_node("Branch5_Chamber" if return_trial else "Niche4_Crest") as StaticBody2D
	var trial := route.get_node("ExplorationSites/AwakenedTrial" if return_trial else "HiddenDepthAmbush")
	var reward := route.get_node("ExplorationSites/AwakenedTrialReward" if return_trial else "HiddenDepthCache")
	player.global_position = floor_node.global_position + Vector2(0, -30)
	player.velocity = Vector2.ZERO
	player.max_health = health_budget
	player.current_health = health_budget
	player.set_physics_process(true)
	for frame in range(20):
		await physics_frame
	trial._on_body_entered(player)
	await process_frame
	_check(trial.spawned_enemies.size() == 2 and not reward.open(player), scene_name + ": encounter/cache setup failed")
	for enemy in trial.spawned_enemies:
		enemy.process_mode = Node.PROCESS_MODE_ALWAYS
	var dive_seen := false
	var has_wisp := false
	var has_sentry := false
	var warning_seen := false
	var projectiles_before := volleys
	for enemy in trial.spawned_enemies:
		has_wisp = has_wisp or enemy.get_script() == load("res://ShaftWisp.gd")
		has_sentry = has_sentry or enemy.get_script() == load("res://ShaftSentry.gd")
	var partial_seen := false
	var context := "%s tier %d return %s" % [scene_name, tier, return_trial]
	for frame in range(3600):
		Input.action_release("ui_left")
		Input.action_release("ui_right")
		var target: Node2D
		var nearest := INF
		for enemy in trial.spawned_enemies:
			if not is_instance_valid(enemy) or enemy.is_dead:
				continue
			if enemy.get_script() == load("res://ShaftWisp.gd"):
				dive_seen = dive_seen or enemy.state == enemy.State.DIVE
			if enemy.get_script() == load("res://ShaftSentry.gd"):
				warning_seen = warning_seen or enemy.warning_ray.visible
			var distance: float = player.global_position.distance_to(enemy.global_position)
			if distance < nearest:
				nearest = distance
				target = enemy
		if trial.completed:
			break
		if trial.remaining_foes.size() == 1 and not partial_seen:
			partial_seen = true
			_check(not reward.open(player), context + ": reward released with a guardian alive")
		if frame > combat_warmup_frames and target != null:
			_drive_attack(target, floor_node)
		await physics_frame
		if player.is_dead or player.global_position.y > floor_node.global_position.y + 120:
			break
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	player.set_physics_process(false)
	if not trial.completed:
		for enemy in trial.spawned_enemies:
			if is_instance_valid(enemy):
				print("UNFINISHED FOE: ", enemy.get_script().resource_path, " at ", enemy.global_position, " health ", enemy.get("current_health"), " state ", enemy.get("state"))
	_check(not has_wisp or dive_seen, context + ": no live wisp dive exercised")
	_check(not has_sentry or (warning_seen and volleys - projectiles_before >= 3), context + ": sentry warning/spread not exercised")
	_check(partial_seen and trial.completed, context + ": mixed fight unfinished, player %s HP %d, floor %s, live foes %s" % [player.global_position, player.current_health, floor_node.global_position, trial.remaining_foes])
	_check(not player.is_dead and player.current_health > 0, context + ": player did not survive the encounter")
	_check(trial.completed and reward.open(player) and not reward.open(player), context + ": one-time reward failed")
	if dive_seen:
		dives += 1
	battles += 1
	room.queue_free()
	player.queue_free()
	for projectile in get_nodes_in_group("player_projectile"):
		projectile.queue_free()
	await process_frame


func _drive_attack(target: Node2D, floor_node: Node2D) -> void:
	var offset := target.global_position - player.global_position
	var desired_x := clampf(target.global_position.x, floor_node.global_position.x - 85, floor_node.global_position.x + 85)
	var dx := desired_x - player.global_position.x
	if absf(dx) > 22 or signf(offset.x) != player.facing_direction:
		Input.action_press("ui_right" if dx > 0 else "ui_left")
	if offset.y < -35 and absf(offset.x) < 70 and player.is_on_floor():
		player._try_jump()
	if absf(offset.x) < 48 and absf(offset.y) < 32 and player.try_attack():
		attacks += 1
