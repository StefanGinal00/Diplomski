extends RefCounted
## Terrain-only perception. Actors and loot never masquerade as cover/floor.
static func terrain_hit(actor: CollisionObject2D, start: Vector2, finish: Vector2) -> Dictionary:
	var excluded: Array[RID] = [actor.get_rid()]
	for attempt in 16:
		var query := PhysicsRayQueryParameters2D.create(start,finish,1,excluded)
		query.hit_from_inside=true
		var hit := actor.get_world_2d().direct_space_state.intersect_ray(query)
		if hit.is_empty(): return {}
		if hit.collider is StaticBody2D and not hit.collider.is_in_group("enemy"): return hit
		excluded.append(hit.rid)
	return {"blocked":true}

static func clear_sight(actor: CollisionObject2D, target: Node2D, start := Vector2.INF) -> bool:
	if not is_instance_valid(target): return false
	return terrain_hit(actor,actor.global_position if start==Vector2.INF else start,target.global_position).is_empty()

static func floor_ahead(actor: CharacterBody2D, direction: float, distance: float, depth := 20.0) -> bool:
	var shape := actor.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape==null or not shape.shape is RectangleShape2D: return true
	var half: Vector2 = shape.shape.size*0.5
	var foot := actor.to_global(shape.position+Vector2(direction*(half.x+distance),half.y))
	var hit := terrain_hit(actor,foot-Vector2(0,5),foot+Vector2(0,depth))
	return not hit.is_empty() and hit.has("normal") and hit.normal.y < -0.5
