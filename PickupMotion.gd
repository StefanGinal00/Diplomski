extends RefCounted
## Physics-tick loot motion. Terrain blocks both the fall and the magnet.
## Reward/uniqueness/persistence remain entirely owned by the pickup scripts.
const GRAVITY := 460.0
const MAX_FALL_SPEED := 230.0
const FOOT := 7.0
var fall_speed := 0.0
var grounded := false
var attracted := false
var rest_probe := 0.0
var spawn_checked := false

func tick(pickup: Area2D, delta: float, target: Node2D, radius: float, speed: float, can_attract: bool, settle := true) -> void:
	if pickup.is_queued_for_deletion() or pickup.claimed: return
	attracted = false
	var at := pickup.global_position
	if can_attract and is_instance_valid(target) and target.get("is_dead") != true:
		var destination := target.global_position
		if at.distance_squared_to(destination) <= radius * radius and terrain_hit(pickup, at, destination).is_empty():
			attracted = true
			grounded = false
			fall_speed = 0
			pickup.global_position = at.move_toward(destination, speed * delta)
			return
	if not settle: return
	if not spawn_checked:
		spawn_checked = true
		# A drop can be authored a few pixels into the floor. Lift only this
		# shallow initial overlap; never search up through a ceiling or wall.
		var initial := terrain_hit(pickup, at - Vector2(0, 2.1), at + Vector2(0, FOOT))
		if not initial.is_empty() and initial.normal.y < -0.45:
			pickup.global_position.y = initial.position.y - FOOT
			fall_speed = 0
			grounded = true
			rest_probe = 0.12
			return
	rest_probe -= delta
	if grounded and rest_probe > 0: return
	if grounded:
		rest_probe = 0.12
		var support := terrain_hit(pickup, at + Vector2(0, FOOT - 2), at + Vector2(0, FOOT + 3))
		if not support.is_empty() and support.normal.y < -0.45:
			pickup.global_position.y = support.position.y - FOOT
			return
		grounded = false
	fall_speed = minf(MAX_FALL_SPEED, fall_speed + GRAVITY * delta)
	var next := at + Vector2(0, fall_speed * delta)
	# Start at the center: the old foot-only sweep began inside thin ground
	# when its lower seven pixels already intersected the supporting ledge.
	var hit := terrain_hit(pickup, at, next + Vector2(0, FOOT))
	if not hit.is_empty() and hit.normal.y < -0.45:
		pickup.global_position.y = hit.position.y - FOOT
		fall_speed = 0
		grounded = true
		rest_probe = 0.12
	else:
		pickup.global_position = next

static func can_collect(pickup: Area2D, body: Node) -> bool:
	return body is Node2D and terrain_hit(pickup, pickup.global_position, body.global_position).is_empty()

static func retry_contacts(pickup: Area2D) -> void:
	# A rejected body_entered is not emitted again merely because cover was
	# removed. Retry cached native overlaps; reward ownership stays in scripts.
	if not pickup.monitoring or pickup.claimed or pickup.is_queued_for_deletion(): return
	for body in pickup.get_overlapping_bodies():
		if body.is_in_group("player"):
			pickup._on_body_entered(body)
			if pickup.claimed or pickup.is_queued_for_deletion(): return

static func terrain_hit(pickup: Area2D, from: Vector2, to: Vector2) -> Dictionary:
	if from.is_equal_approx(to): return {}
	var excluded: Array[RID] = [pickup.get_rid()]
	for attempt in 12:
		var query := PhysicsRayQueryParameters2D.create(from, to, 1, excluded)
		query.hit_from_inside = true
		var hit := pickup.get_world_2d().direct_space_state.intersect_ray(query)
		if hit.is_empty(): return {}
		var body: Object = hit.collider
		if body is StaticBody2D and not body.is_in_group("enemy"):
			return hit
		if body is CollisionObject2D: excluded.append(body.get_rid())
		else: return hit
	return {"blocked":true,"normal":Vector2.ZERO,"position":from}
