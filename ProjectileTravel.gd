extends RefCounted
## Continuous centre sweep supplements Area2D contacts, including thin cover
## crossed in one tick. The native contact handler remains the damage owner.
static func advance(shot: Area2D, distance: float, hit_targets: Dictionary = {}) -> float:
	var start := shot.global_position
	var end: Vector2 = start + shot.direction * maxf(distance,0)
	if start.is_equal_approx(end): return 0
	var excluded: Array[RID] = [shot.get_rid()]
	if is_instance_valid(shot.source) and shot.source is CollisionObject2D:
		excluded.append(shot.source.get_rid())
	for id in hit_targets:
		var target = instance_from_id(id)
		if is_instance_valid(target) and target is CollisionObject2D:
			excluded.append(target.get_rid())
			var hurt := target.get_node_or_null("CombatHurtbox") as Area2D
			if hurt != null: excluded.append(hurt.get_rid())
	var query := PhysicsRayQueryParameters2D.create(start,end,shot.collision_mask,excluded)
	query.hit_from_inside = true
	var hit := shot.get_world_2d().direct_space_state.intersect_ray(query)
	# World bodies and boss receivers have distinct queries. Enabling every
	# Area on the world layer would make spells hit pickup/interaction volumes.
	if (shot.collision_mask & preload("res://CombatHurtbox.gd").LAYER) != 0:
		var hurt_query := PhysicsRayQueryParameters2D.create(start,end,preload("res://CombatHurtbox.gd").LAYER,excluded)
		hurt_query.collide_with_bodies=false;hurt_query.collide_with_areas=true;hurt_query.hit_from_inside=true
		var hurt_hit := shot.get_world_2d().direct_space_state.intersect_ray(hurt_query)
		if not hurt_hit.is_empty() and (hit.is_empty() or start.distance_squared_to(hurt_hit.position)<start.distance_squared_to(hit.position)):
			hit=hurt_hit
	shot.global_position = end if hit.is_empty() else hit.position
	if not hit.is_empty(): shot._on_body_entered(hit.collider)
	return start.distance_to(shot.global_position)
