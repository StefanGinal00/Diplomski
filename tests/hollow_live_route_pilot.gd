extends "res://tests/hollow_full_navigation_smoke.gd"

# Configurable connected-route diagnostic. The dedicated normal smoke wrapper
# fixes a base, ordinary-health setup; fresh tier-one starter acceptance remains
# open. The optional 100-HP modes are functional diagnostics, not balance tests.
# Default: ordinary 5 HP, starter sword and a disclosed 36-Gold preparation
# allowance buying two herbs. --diagnostic-health opts into a 100-HP harness
# to investigate later obstacles, never normal-health/balance acceptance.
# The shared route places the player only at the entrance, then moves normally.
var room: Node2D
var ui: Node
var defeats := 0
var herbs_used := 0
var herbs_found := 0
var cache_herbs := 0
var supplies_trace: Array[String] = []
var hazard_waits := 0
var flank_direction := 0.0
var health_trace: Array[String] = []
var diagnostic_health := 5
var awakened_fixture := false
var purchased_herb_allowance := 2
var approach_floor_top := NAN
var advanced_steering := false
var wildlife_chase_range := INF
var overhead_wildlife_clearance := 28.0


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_hollow_live_route_save.json"
	awakened_fixture = OS.get_cmdline_user_args().has("--awakened-fixture")
	if awakened_fixture:
		state.save_path = "res://_tmp_hollow_awakened_route_save.json"
	if OS.get_cmdline_user_args().has("--diagnostic-health"):
		diagnostic_health = 100
	await _run_route()


func _run_route() -> void:
	var state := root.get_node("GameState")
	state.start_new_game("normal")
	if awakened_fixture:
		# Explicit tier-one fixture, not a claimed campaign/Warden playthrough.
		state.set_zone_tier("sunken_shaft", 1)
	var game := load("res://Game.tscn").instantiate() as Node
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	if diagnostic_health != 5:
		player.max_health = diagnostic_health
		player.current_health = diagnostic_health
	ui = game.get_node("UI")
	state.add_gold(36)
	ui._open_shop(game.get_node("WayfarerMerchant"))
	for purchase in range(2):
		ui.selected_shop_item_id = "healing_herb"
		ui._on_shop_buy_pressed()
	ui._close_shop()
	_check(state.inventory.get("healing_herb", 0) == 2 and state.gold == 0, "Finite purchased supplies setup failed")
	state.item_acquired.connect(_track_supplies)
	state.set_current_room("shaft_hollow")
	await process_frame
	room = game.get_node("ShaftHollow")
	for node in get_nodes_in_group("enemy"):
		if room.is_ancestor_of(node):
			_watch_foe(node)
	node_added.connect(_watch_foe)
	player.health_changed.connect(_trace_health)
	var ok := await _traverse(room)
	_check(ok and not player.is_dead and player.current_health > 0 and player.max_health == diagnostic_health, "Whole-room run failed (health allowance %d)" % diagnostic_health)
	_check(room.get_node("Relay").is_active, "Relay was not cleared during exploration")
	_check(room.get_node("ExpandedRoute/AuthoredDescent/HiddenDepthCache").opened, "Guarded side reward was skipped")
	if awakened_fixture:
		_check(room.get_node("ExpandedRoute/AuthoredDescent/ExplorationSites/AwakenedTrialReward").opened, "Awakened return-trial reward was skipped")
	_check(defeats >= 10 and hazard_waits > 0, "Connected run did not exercise enemies/hazards")
	_check(herbs_used <= 2 + herbs_found, "Healing exceeded purchased and physically acquired supplies")
	_check(herbs_used <= 2 + cache_herbs, "Run depended on random herb drops")
	_check(int(state.inventory.get("healing_herb", 0)) == 2 + herbs_found - herbs_used, "Herb inventory does not reconcile with real acquisitions/uses")
	print("LIVE HOLLOW: tier ", 1 if awakened_fixture else 0, " fixture, ", defeats, " defeats, ", herbs_used, " herbs used, ", player.current_health, "/", diagnostic_health, " HP, ", hazard_waits, " hazard steering frames")
	print("LIVE SUPPLIES: 2 bought before entry, ", herbs_found, " herbs acquired (", cache_herbs, " guaranteed cache herbs); random drops do not increase the healing allowance; ", supplies_trace)
	_release()
	if failures.is_empty():
		game = await _after_completed_route(game)
	state.delete_save()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("HOLLOW LIVE ROUTE TEST PASSED: tier %d fixture, %d-HP allowance; connected objective, all galleries, side cache, survey and lift return; all actors live" % [1 if awakened_fixture else 0, diagnostic_health])
		quit(0)
	else:
		print("HEALTH TRACE: ", health_trace)
		print("HOLLOW LIVE ROUTE TEST FAILED: ", failures.size())
		quit(1)


func _after_completed_route(game: Node) -> Node:
	# Optional earned-progression return stage; ordinary single-route wrappers
	# retain their fixed setup and cleanup ownership.
	return game


func _watch_foe(node: Node) -> void:
	if is_instance_valid(room) and node.is_in_group("enemy") and room.is_ancestor_of(node):
		node.defeated.connect(func(): defeats += 1)


func _route_geometry() -> Node2D:
	return room.get_node("ExpandedRoute/AuthoredDescent")


func _route_hazards() -> Array[Node]:
	return room.find_children("HollowRockfall*", "Area2D", true, false)


func _track_supplies(item_id: String, amount: int) -> void:
	if item_id != "healing_herb":
		return
	herbs_found += amount
	var stack := get_stack()
	var source: String = str(stack[2].source).get_file() if stack.size() > 2 else "unknown"
	if source == "ResonanceCache.gd":
		cache_herbs += amount
	supplies_trace.append("%d from %s at %s" % [amount, source, room.to_local(player.global_position)])


func _trace_health(hp: int, _maximum: int) -> void:
	var nearby: Array[String] = []
	if advanced_steering and OS.get_cmdline_user_args().has("--trace-combat"):
		for actor in room.find_children("*", "CharacterBody2D", true, false):
			if actor.global_position.distance_to(player.global_position) < 100:
				print("NEAR DAMAGE: ", actor.name, " ", room.to_local(actor.global_position), " groups ", actor.get_groups(), " health ", actor.get("current_health"))
	for node in get_nodes_in_group("enemy"):
		if room.is_ancestor_of(node) and node.global_position.distance_to(player.global_position) < 90:
			nearby.append("%s at %s HP %s" % [node.name, room.to_local(node.global_position), node.get("current_health")])
	for node in room.find_children("HollowRockfall*", "Area2D", true, false):
		if node.global_position.distance_to(player.global_position) < 130:
			nearby.append("%s %s" % [node.name, node.phase])
	var stack := get_stack()
	var source: String = str(stack[2].source).get_file() if stack.size() > 2 else "unknown"
	health_trace.append("HP %d from %s at %s near %s" % [hp, source, room.to_local(player.global_position), nearby])
	if OS.get_cmdline_user_args().has("--trace-combat") and source == "EnemyProjectile.gd":
		player.attack_cast.force_shapecast_update()
		var hits: Array[String] = []
		for index in player.attack_cast.get_collision_count():
			hits.append(str(player.attack_cast.get_collider(index).name))
		print("PROJECTILE DAMAGE: facing ", player.facing_direction, " attack hits ", hits, " passive blocker ", _passive_in_attack_cast())


func _gallery_objective(_room: Node2D, tier: int) -> bool:
	if tier == 1:
		var relay := room.get_node("Relay")
		if not await _walk_on_floor(relay.global_position.x, "Hollow/relay"):
			return false
		await _interact(relay)
		_check(relay.is_active, "Main relay did not activate physically")
		return relay.is_active
	return true


func _approach(route: Node2D, floor_y: float, desired_x: float) -> bool:
	if OS.get_cmdline_user_args().has("--trace-route"):
		print("APPROACH START ", room.to_local(player.global_position), " to ", Vector2(desired_x, floor_y))
	var previous_top := approach_floor_top
	approach_floor_top = _bounds(_floor_at(route, floor_y, desired_x)).position.y
	# An incidental side stair can hold the player above the corridor after a
	# fight. Descend onto its real floor before planning a distant shaft hop.
	var nearby_floor := _floor_at(route, floor_y, route.to_local(player.global_position).x)
	var nearby_bounds := _bounds(nearby_floor)
	var above := nearby_bounds.position.y - player.global_position.y - 10
	if advanced_steering and player.is_on_floor() and above > 5 and above < 150 and player.global_position.x > nearby_bounds.position.x and player.global_position.x < nearby_bounds.end.x:
		if not await _connected_step(nearby_floor, "Hollow/corridor-rejoin"):
			approach_floor_top = previous_top
			return false
	var result: bool = await super._approach(route, floor_y, desired_x)
	approach_floor_top = previous_top
	if OS.get_cmdline_user_args().has("--trace-route"):
		print("APPROACH END ", room.to_local(player.global_position), " result ", result)
	return result


func _side_objective(route: Node2D, tier: int, kind: String) -> bool:
	if kind == "Niche" and tier == 4:
		var reward := route.get_node("HiddenDepthCache")
		if not await _record(reward):
			return false
		_check(reward.opened, "High niche cache remains sealed")
		return reward.opened
	if awakened_fixture and kind == "Branch" and tier == 5:
		var reward := route.get_node("ExplorationSites/AwakenedTrialReward")
		if not await _record(reward):
			return false
		_check(reward.opened, "Return-trial cache remains sealed")
		return reward.opened
	return true


func _supplies() -> void:
	var state := root.get_node("GameState")
	# A conservative finite budget: random crate drops remain real inventory,
	# but do not increase this run's allowance. Only purchased supplies and
	# actual guaranteed cache rewards can extend the survival budget.
	if not player.is_dead and player.current_health <= 2 and herbs_used < purchased_herb_allowance + cache_herbs and state.has_item("healing_herb"):
		ui.selected_item_id = "healing_herb"
		var before: int = state.inventory.get("healing_herb", 0)
		ui._on_inventory_action_pressed()
		if state.inventory.get("healing_herb", 0) == before - 1:
			herbs_used += 1
	player.attack_cast.force_shapecast_update()
	for hit in player.attack_cast.get_collision_count():
		var collider := player.attack_cast.get_collider(hit) as Node
		# Use an available real sword hit even when the navigation target is a
		# different (e.g. airborne) foe. Waiting for that one target let nearby
		# crawlers make contact while the sword was already in range of them.
		if collider != null and (collider.is_in_group("breakable") or collider.is_in_group("enemy") or (collider.is_in_group("neutral_creature") and collider.is_hostile)):
			_safe_sword_attack()


func _record(object: Area2D) -> bool:
	# A fight can knock the player below a cache while preserving its target X.
	# Rejoin its real support before interacting; horizontal arrival alone is
	# not evidence of reaching the reward. No position reset is used here.
	for attempt in range(3):
		if not await _walk_on_floor(object.global_position.x, "Hollow/sample-or-reward"):
			return false
		_release()
		for frame in range(3):
			await physics_frame
		if object.get_overlapping_bodies().has(player):
			await _interact(object)
			return true
		var floor_body: StaticBody2D
		var closest := INF
		for node in _route_geometry().get_children():
			if not node is StaticBody2D or not node.has_node("CollisionShape2D") or not node.get_node("CollisionShape2D").shape is RectangleShape2D:
				continue
			var bounds := _bounds(node)
			var below := bounds.position.y - object.global_position.y
			if below >= 0 and below < minf(closest, 75.0) and object.global_position.x > bounds.position.x and object.global_position.x < bounds.end.x:
				floor_body = node
				closest = below
		if floor_body == null or not await _connected_step(floor_body, "Hollow/reward-rejoin"):
			_check(false, "Cannot physically rejoin reward support: " + str(object.name))
			return false
	_check(false, "Reward remained out of reach after physical retries: " + str(object.name))
	return false


func _safe_sword_attack() -> void:
	# Do not turn a passive animal into another combat encounter while trying
	# to break a crate behind it. The actual sword still uses normal collisions.
	if not _passive_in_attack_cast():
		player.try_attack()


func _passive_in_attack_cast() -> bool:
	for hit in player.attack_cast.get_collision_count():
		var body := player.attack_cast.get_collider(hit) as Node
		if body != null and body.is_in_group("neutral_creature") and not body.is_hostile:
			return true
	return false


func _foes() -> Array[Node]:
	var result: Array[Node] = get_nodes_in_group("enemy")
	for animal in get_nodes_in_group("neutral_creature"):
		if animal.is_hostile and not result.has(animal):
			result.append(animal)
	return result


func _connected_step(target: StaticBody2D, label: String) -> bool:
	for foe in _foes():
		if is_instance_valid(foe) and not foe.is_dead and room.is_ancestor_of(foe) and foe.global_position.distance_to(player.global_position) < 95 and absf(foe.global_position.y - player.global_position.y) < (90 if advanced_steering else 65):
			if not await _walk_on_floor(player.global_position.x, "Hollow/side-destination-clear"):
				return false
			break
	# Stepping off an actor (or defeating it while standing on it) can leave
	# is_on_floor describing the previous tick. Allow gravity to settle onto
	# a real support before planning another jump from that stale contact.
	for settle in range(90):
		var probe := PhysicsRayQueryParameters2D.create(player.global_position + Vector2(0, 9), player.global_position + Vector2(0, 18), 1, [player.get_rid()])
		var standing := player.get_world_2d().direct_space_state.intersect_ray(probe)
		if player.is_on_floor() and not standing.is_empty():
			break
		_release()
		await physics_frame
	for recovery in range(12):
		if player.is_dead:
			return false
		var feet_y := player.global_position.y + 10
		var destination := _bounds(target)
		if advanced_steering and String(target.name).begins_with("ShaftCrossing"):
			# Combat can leave the takeoff on an incidental stair AFTER the
			# corridor approach. Rejoin its floor before a long crossing jump.
			var gap := maxf(destination.position.x - player.global_position.x, player.global_position.x - destination.end.x)
			if gap > 150:
				var support_floor: StaticBody2D
				var closest_drop := 150.0
				for floor_node in _route_geometry().get_children():
					if not floor_node is StaticBody2D or not String(floor_node.name).begins_with("Chamber") or not String(floor_node.name).contains("Floor"):
						continue
					var floor_bounds := _bounds(floor_node)
					var drop := floor_bounds.position.y - feet_y
					if drop > 5 and drop < closest_drop and player.global_position.x > floor_bounds.position.x and player.global_position.x < floor_bounds.end.x:
						support_floor = floor_node
						closest_drop = drop
				if support_floor != null:
					if not await _connected_step(support_floor, label + "/floor-rejoin"):
						return false
					var floor_bounds := _bounds(support_floor)
					if not await _walk_on_floor(clampf(destination.get_center().x, floor_bounds.position.x + 16, floor_bounds.end.x - 16), label + "/takeoff"):
						return false
					continue
		# Combat may already have landed on the overlapping crest, three pixels
		# above its final approach plank. This is the same landing tolerance as
		# the shared step driver; do not deliberately drop past a reached step.
		if player.is_on_floor() and absf(feet_y - destination.position.y) < 4 and player.global_position.x > destination.position.x and player.global_position.x < destination.end.x:
			return true
		if feet_y - destination.position.y <= 85:
			return await super._connected_step(target, label)
		# A live knockback can drop the player below the next authored step.
		# Find an actual intermediate support reachable with the basic jump.
		var intermediate: StaticBody2D
		var best := INF
		var reachable_left := player.global_position.x - 60
		var reachable_right := player.global_position.x + 60
		var floor_query := PhysicsRayQueryParameters2D.create(player.global_position + Vector2(0, 9), player.global_position + Vector2(0, 18), 1, [player.get_rid()])
		var standing := player.get_world_2d().direct_space_state.intersect_ray(floor_query)
		if not standing.is_empty() and standing.collider is StaticBody2D and standing.collider.has_node("CollisionShape2D") and standing.collider.get_node("CollisionShape2D").shape is RectangleShape2D:
			var actual := _bounds(standing.collider)
			reachable_left = actual.position.x - 45
			reachable_right = actual.end.x + 45
		for node in _route_geometry().get_children():
			if not node is StaticBody2D or not node.has_node("CollisionShape2D"):
				continue
			if not node.get_node("CollisionShape2D").shape is RectangleShape2D:
				continue
			var bounds := _bounds(node)
			var rise := feet_y - bounds.position.y
			if bounds.size.y > 22 or rise < 8 or rise > 80 or bounds.end.x < reachable_left or bounds.position.x > reachable_right:
				continue
			var score := bounds.position.y - destination.position.y + absf(bounds.get_center().x - destination.get_center().x) * 0.2
			if score < best:
				best = score
				intermediate = node
		if intermediate == null:
			_check(false, label + ": no rejoin step from " + str(room.to_local(player.global_position)) + " to " + str(target.name))
			return false
		if not await super._connected_step(intermediate, label + "/rejoin"):
			return false
	_check(false, label + ": could not rejoin after knockback")
	return false


func _clear_landing_obstruction() -> bool:
	if player.is_dead or not failures.is_empty():
		return false
	var feet := player.global_position + Vector2(0, 9)
	var query := PhysicsRayQueryParameters2D.create(feet, feet + Vector2(0, 8), 1)
	query.exclude = [player.get_rid()]
	var hit := player.get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and (hit.collider.is_in_group("enemy") or hit.collider.is_in_group("breakable") or hit.collider.is_in_group("neutral_creature")):
		return await _walk_on_floor(player.global_position.x + 70, "Hollow/blocked-landing")
	# A niche ambush can spawn during the jump, after the takeoff scan. Fight
	# it from the actual landing instead of holding still against repeated hits.
	for foe in _foes():
		if is_instance_valid(foe) and not foe.is_dead and room.is_ancestor_of(foe) and foe.global_position.distance_to(player.global_position) < 95 and absf(foe.global_position.y - player.global_position.y) < 65:
			return await _walk_on_floor(player.global_position.x, "Hollow/side-destination-clear")
	return false


func _step_frame() -> void:
	# Keep ordinary available sword/healing input during jump traversal too.
	# Walking is not the only time a live stair ambush can reach the player.
	_supplies()


func _recover_failed_step(target: StaticBody2D, label: String) -> bool:
	# A mid-jump ambush can knock the player down after takeoff planning.
	# Reuse the real intermediate-ledges recovery, with a finite retry cap.
	if advanced_steering and not player.is_dead and player.is_on_floor() and player.global_position.y + 10 > _bounds(target).position.y + 4 and label.count("/knockback-retry") < 3:
		return await _connected_step(target, label + "/knockback-retry")
	return false


func _settle_upper_step(target: StaticBody2D, label: String) -> bool:
	# A higher ledge can overlap only the near end of a shaft span. Descend
	# onto the span before using it for the next jump across the far rim.
	if not advanced_steering or not String(target.name).begins_with("ShaftCrossing"):
		return true
	if label.count("/upper-rejoin") >= 3:
		_check(false, "Could not descend onto crossed span: " + str(target.name))
		return false
	return await _connected_step(target, label + "/upper-rejoin")


func _allow_horizontal_cover() -> bool:
	return advanced_steering


func _walk_on_floor(goal_x: float, label: String) -> bool:
	var takeoff := label.ends_with("/takeoff")
	var side_walk := label.contains("side-destination") or label.contains("sample-or-reward")
	var walk_bounds := Rect2(player.global_position - Vector2(120, 0), Vector2(240, 0))
	var feet := player.global_position + Vector2(0, 9)
	var query := PhysicsRayQueryParameters2D.create(feet, feet + Vector2(0, 9), 1)
	query.exclude = [player.get_rid()]
	var support := player.get_world_2d().direct_space_state.intersect_ray(query)
	var supported: bool = not support.is_empty() and support.collider is StaticBody2D and support.collider.has_node("CollisionShape2D") and support.collider.get_node("CollisionShape2D").shape is RectangleShape2D
	if supported:
		walk_bounds = _bounds(support.collider)
	# Corridor bridges are handled as explicit jumps by _approach. Combat and
	# rockfall avoidance must not chase a target off the current solid gallery.
	# Only use confirmed geometry here, never the fallback 240-pixel rectangle.
	# A side destination can lie on the wide crest below an incidental narrow
	# stair. Do not clamp that destination to the stair and prevent stepping off.
	var bounded_walk: bool = supported and (side_walk or label == "Hollow/corridor-approach") and goal_x >= walk_bounds.position.x and goal_x <= walk_bounds.end.x
	# An emergency combat hold can begin inside the lip margin after landing.
	# Once foes are gone, stop at a safe point on this same ledge rather than
	# waiting forever for the original (deliberately clamped-away) edge point.
	if bounded_walk and label.ends_with("side-destination-clear"):
		goal_x = clampf(goal_x, walk_bounds.position.x + 16, walk_bounds.end.x - 16)
	if OS.get_cmdline_user_args().has("--trace-route") and side_walk:
		print("SIDE WALK ", room.to_local(player.global_position), " goal ", goal_x - room.global_position.x, " bounds ", walk_bounds, " confirmed ", supported)
	var focus_id := 0
	var focus_health := -1
	var focus_since := 0
	var deferred_foes: Dictionary = {}
	for frame in range(4800):
		_release()
		_supplies()
		if player.is_dead:
			_check(false, label + ": player died at " + str(room.to_local(player.global_position)))
			return false
		var here := player.global_position
		if bounded_walk and player.is_on_floor() and here.y + 10 < walk_bounds.position.y - 5:
			# Combat jumps can land on an overlapping upper niche. Return to the
			# intended gallery with the normal drop input before chasing below.
			player._try_drop_through()
		var target_x := goal_x
		var repositioning := false
		var foe: Node2D
		var nearest := 150.0
		for candidate in ([] if takeoff else _foes()):
			if not is_instance_valid(candidate) or candidate.is_dead or not room.is_ancestor_of(candidate):
				continue
			# Defend against provoked fauna in actual sword range, but do not
			# turn optional wildlife into an endless chase away from the route.
			if (candidate.is_in_group("neutral_creature") and here.distance_to(candidate.global_position) > wildlife_chase_range) or frame < int(deferred_foes.get(candidate.get_instance_id(), 0)):
				continue
			if bounded_walk and candidate.global_position.y > walk_bounds.position.y + 5:
				continue
			# Continue off an incidental upper plank before fighting a creature
			# far below it; standing above that creature cannot land a sword hit.
			if advanced_steering and candidate.global_position.y > here.y + 45:
				continue
			var distance: float = here.distance_to(candidate.global_position)
			if distance < nearest and absf(here.y - candidate.global_position.y) < 90:
				nearest = distance
				foe = candidate
		if advanced_steering and foe != null:
			if focus_id != foe.get_instance_id() or focus_health != foe.current_health:
				focus_id = foe.get_instance_id()
				focus_health = foe.current_health
				focus_since = frame
			elif frame - focus_since > 120:
				# No hit for two seconds: advance to the next real foothold
				# instead of repeatedly jumping at an unreachable firing post.
				# The foe remains active; required guardians still must die.
				deferred_foes[focus_id] = frame + 120
				foe = null
				focus_id = 0
		if foe != null:
			target_x = foe.global_position.x
			player.attack_cast.force_shapecast_update()
			for hit in player.attack_cast.get_collision_count():
				if player.attack_cast.get_collider(hit) == foe:
					_safe_sword_attack()
			if (advanced_steering or not bounded_walk) and foe.global_position.y > here.y + 15 and player.is_on_floor():
				if flank_direction == 0:
					flank_direction = 1.0 if target_x >= here.x else -1.0
					if bounded_walk:
						flank_direction = 1.0 if walk_bounds.end.x - here.x > here.x - walk_bounds.position.x else -1.0
				target_x = here.x + flank_direction * 70
				repositioning = advanced_steering
			elif absf(foe.global_position.y - here.y) < 25:
				flank_direction = 0
			if foe.global_position.y < here.y - 15 and absf(target_x - here.x) < 90 and player.is_on_floor():
				if advanced_steering and foe.is_in_group("neutral_creature") and absf(foe.global_position.x - here.x) < overhead_wildlife_clearance:
					# A solid animal directly overhead blocks the upward jump.
					# Make room beside it before jumping into sword height.
					target_x = foe.global_position.x - (1.0 if foe.global_position.x >= here.x else -1.0) * (overhead_wildlife_clearance + 18.0)
					repositioning = true
				else:
					player._try_jump()
			if foe.get_script() == load("res://ShaftCrawler.gd") and foe.state == foe.State.WARNING and foe.state_remaining < 0.2 and player.is_on_floor():
				player._try_jump()
			if advanced_steering and _passive_in_attack_cast() and player.is_on_floor():
				# Reposition across a passive blocker rather than bouncing in
				# place while a sentry keeps firing through the shared lane.
				player._try_jump()
				target_x = here.x + player.facing_direction * 70
				repositioning = true
			if bounded_walk:
				target_x = clampf(target_x, walk_bounds.position.x + 16, walk_bounds.end.x - 16)
		else:
			flank_direction = 0
		var avoiding := false
		for hazard in ([] if takeoff else _route_hazards()):
			if hazard.disabled:
				continue
			var half: Vector2 = hazard.get_node("CollisionShape2D").shape.size * hazard.global_scale * 0.5
			var center: Vector2 = hazard.global_position
			if absf(here.y - center.y) > half.y + 20:
				continue
			var left := center.x - half.x - 24
			var right := center.x + half.x + 24
			# Low, wide water pulses cannot be walked end-to-end in one idle
			# window. Cross during idle and use the real jump over their warning
			# pulse instead of waiting forever for an impossible walking window.
			if half.y <= 20 and hazard.phase != "active":
				if hazard.phase == "warning" and hazard.phase_remaining < 0.2 and here.x > left and here.x < right and player.is_on_floor():
					player._try_jump()
					hazard_waits += 1
				continue
			var heading := signf(target_x - here.x)
			var safe_seconds: float = hazard.phase_remaining + hazard.warning_duration if hazard.phase == "idle" else (hazard.phase_remaining if hazard.phase == "warning" else 0.0)
			var exit_x := right if heading > 0 else left
			var exit_seconds := absf(exit_x - here.x) / player.move_speed + 0.2
			if heading != 0 and safe_seconds > exit_seconds:
				continue
			if here.x > left and here.x < right:
				target_x = left if here.x < center.x else right
				avoiding = true
			elif (here.x <= left and target_x > left) or (here.x >= right and target_x < right):
				# Approach the warning boundary, not a distant waiting point.
				# Enter only when the current safe window covers the crossing.
				target_x = left - 3 if here.x <= left else right + 3
				avoiding = true
		if avoiding:
			hazard_waits += 1
			if takeoff:
				# Stay on the stair while waiting; retreating sideways can walk
				# off a narrow step and invalidate the planned ascent.
				target_x = here.x
		if bounded_walk:
			# A hazard retreat must respect the same ledge edges as combat.
			target_x = clampf(target_x, walk_bounds.position.x + 16, walk_bounds.end.x - 16)
		var dx := target_x - here.x
		if not avoiding and foe == null and absf(goal_x - here.x) <= 3 and player.is_on_floor():
			if label == "Hollow/corridor-approach" and is_finite(approach_floor_top) and here.y + 10 > approach_floor_top + 5:
				_check(false, label + ": reached x on the wrong lower floor at " + str(room.to_local(here)))
				return false
			return true
		if absf(dx) > (42 if foe != null and not avoiding and not repositioning else 3) or (foe != null and not avoiding and signf(dx) != player.facing_direction):
			Input.action_press("ui_right" if dx > 0 else "ui_left")
		if player.is_on_wall() and player.is_on_floor():
			var crate_wall := false
			for index in range(player.get_slide_collision_count()):
				var hit := player.get_slide_collision(index)
				var collider := hit.get_collider() as Node
				if is_instance_valid(collider) and absf(hit.get_normal().x) > 0.5 and collider.is_in_group("breakable"):
					crate_wall = true
			# Wait for the second ordinary sword swing instead of jumping on
			# a half-broken crate and falling directly onto the crawler behind it.
			# If passive fauna share the swing, the safe attack is intentionally
			# withheld. Hop the obstacle instead of waiting forever for that hit.
			if not crate_wall or _passive_in_attack_cast():
				player._try_jump()
		await physics_frame
	for candidate in _foes():
		if room.is_ancestor_of(candidate) and candidate.global_position.distance_to(player.global_position) < 180:
			print("STALLED FOE: ", candidate.name, " ", room.to_local(candidate.global_position), " HP ", candidate.current_health)
	for index in range(player.get_slide_collision_count()):
		print("STALLED COLLISION ", player.get_slide_collision(index).get_collider().name, " ", player.get_slide_collision(index).get_normal())
	_check(false, label + ": live walk timed out at " + str(room.to_local(player.global_position)) + " goal x " + str(goal_x - room.global_position.x))
	return false
