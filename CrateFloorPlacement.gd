extends RefCounted
## Resolve small legacy spawn clearances once, after room construction and
## population snapshot restore. No physics queries or per-frame polling.

const LAYOUT := preload("res://WorldLayout.gd")
const AUTHORED := preload("res://CrateSpawnAnchors.gd")
const MAX_DROP := 48.0
const MAX_CLEARANCE := 224.0
const EPSILON := 0.05
static var pending: Array[WeakRef] = []
static var scheduled := false


static func request(crate: StaticBody2D) -> void:
	pending.append(weakref(crate))
	if not scheduled:
		scheduled = true
		flush.call_deferred()


static func flush() -> void:
	var batch := pending
	pending = []
	scheduled = false
	# Resolve only reviewed authored exceptions before any automatic settling.
	# Restored/edited positions are not repeatedly offset on revisits.
	for reference in batch:
		var crate := reference.get_ref() as StaticBody2D
		if crate == null or not crate.is_inside_tree() or crate.is_queued_for_deletion() or crate.get("is_destroyed") or not crate.get("settle_on_floor"):
			continue
		var room := _room_for(crate)
		if room != null:
			AUTHORED.apply(crate, room)
	# All crates created by a population burst share one terrain scan per room.
	# This cache is deliberately batch-local: bridges/doors can change later.
	var floors_by_room: Dictionary = {}
	var crates_by_room: Dictionary = {}
	var actors_by_room: Dictionary = {}
	for reference in batch:
		var crate := reference.get_ref() as StaticBody2D
		if crate == null or not crate.is_inside_tree() or crate.is_queued_for_deletion() or crate.get("is_destroyed") or not crate.get("settle_on_floor"):
			continue
		var room := _room_for(crate)
		if room == null:
			continue
		var key := room.get_instance_id()
		if not floors_by_room.has(key):
			floors_by_room[key] = [terrain_rects(room), other_obstacles(room)]
			actors_by_room[key] = actor_spawn_rects(room)
			crates_by_room[key] = room.find_children("*", "StaticBody2D", true, false).filter(func(body: Node) -> bool: return body.is_in_group("breakable"))
		var obstacles: Array[Rect2] = []
		obstacles.append_array(floors_by_room[key][1])
		# Do not lower an intentionally stacked box into another breakable.
		# Read current positions because earlier boxes in this batch may move.
		for other in crates_by_room[key]:
			if other == crate or not is_instance_valid(other) or other.is_queued_for_deletion():
				continue
			var other_bounds := bounds(other.get_node_or_null("CollisionShape2D"))
			if other_bounds.has_area():
				obstacles.append(other_bounds)
		settle(crate, floors_by_room[key][0], obstacles)
		separate_spawn(crate, room, floors_by_room[key][0], obstacles, actors_by_room[key])

static func actor_spawn_rects(room: Node2D) -> Array[Rect2]:
	var actors: Array[Rect2] = []
	for actor in room.find_children("*", "CollisionObject2D", true, false):
		if not actor.is_in_group("enemy") or actor.is_queued_for_deletion(): continue
		var shape := actor.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape == null or shape.shape == null: continue
		var rect: Rect2 = shape.global_transform * shape.shape.get_rect()
		# Ordinary walkers settle by gravity just after this spawn batch.
		rect.size.y += 22
		actors.append(rect.grow(6))
	return actors

static func separate_spawn(crate: StaticBody2D, room: Node2D, terrain: Array[Rect2], obstacles: Array[Rect2], cached_actors: Array[Rect2] = []) -> bool:
	var current := bounds(crate.get_node_or_null("CollisionShape2D"))
	if not current.has_area(): return false
	var actors := cached_actors if not cached_actors.is_empty() else actor_spawn_rects(room)
	var overlaps := false
	for actor in actors:
		if actor.intersects(current): overlaps=true; break
	if not overlaps: return false
	var support := Rect2()
	for floor_rect in terrain:
		if absf(floor_rect.position.y - current.end.y) < 0.1 and current.position.x >= floor_rect.position.x and current.end.x <= floor_rect.end.x:
			if floor_rect.size.x > support.size.x: support = floor_rect
	if not support.has_area(): return false
	var reviewed := false
	for key in AUTHORED.ANCHORS:
		if String(crate.get_path()).ends_with("/"+key): reviewed=true; break
	for distance in range(8, int(MAX_CLEARANCE)+1, 8):
		for direction in [-1, 1]:
			var moved := Rect2(current.position + Vector2(distance * direction, 0), current.size)
			if moved.position.x < support.position.x + 4 or moved.end.x > support.end.x - 4: continue
			# These destructible boxes already occupy a route. Do not require a
			# full second player-height above one inside a low authored tunnel.
			var margin := Vector2(12,40) if reviewed else Vector2(4,8)
			var headroom := Rect2(moved.position - margin, moved.size + Vector2(margin.x*2,margin.y)).grow(-0.05)
			var clear := true
			for other in terrain + obstacles + actors:
				if headroom.intersects(other): clear = false; break
			if not clear: continue
			var before := crate.position
			crate.global_position.x += distance * direction
			crate.set_meta("spawn_clearance_offset", crate.position - before)
			return true
	return false


static func _room_for(crate: Node2D) -> Node2D:
	var ancestor := crate.get_parent()
	var fallback: Node2D
	while ancestor is Node2D:
		fallback = ancestor
		if LAYOUT.ROOM_NODES.find_key(String(ancestor.name)) != null:
			return ancestor
		ancestor = ancestor.get_parent()
	return fallback


static func bounds(collision: CollisionShape2D) -> Rect2:
	if collision == null or collision.disabled or not collision.shape is RectangleShape2D:
		return Rect2()
	var transform := collision.global_transform
	# No AABB approximation for slopes/rotated geometry: it could invent a floor.
	if absf(transform.x.y) > 0.0001 or absf(transform.y.x) > 0.0001:
		return Rect2()
	var size: Vector2 = collision.shape.size * Vector2(absf(transform.x.x), absf(transform.y.y))
	return Rect2(transform.origin - size * 0.5, size)


static func terrain_rects(room: Node2D) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for node in room.find_children("*", "CollisionShape2D", true, false):
		var collision := node as CollisionShape2D
		var body := collision.get_parent() as StaticBody2D
		if body == null or body.is_queued_for_deletion() or body.is_in_group("breakable") or body.is_in_group("enemy") or body.is_in_group("neutral_creature") or not body.get_collision_layer_value(1):
			continue
		var rect := bounds(collision)
		if rect.has_area():
			result.append(rect)
	return result


static func other_obstacles(room: Node2D) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for node in room.find_children("*", "Node2D", true, false):
		if not node is CollisionShape2D and not node is CollisionPolygon2D:
			continue
		var body := node.get_parent() as StaticBody2D
		if body == null or body.is_queued_for_deletion() or body.is_in_group("breakable") or not body.get_collision_layer_value(1) or node.disabled:
			continue
		if node is CollisionShape2D:
			if node.shape != null and not bounds(node).has_area():
				# Non-rectangular/rotated shapes cannot support snapping, but their
				# conservative AABB must still block a move through them.
				result.append(node.global_transform * node.shape.get_rect())
		elif not node.polygon.is_empty():
			var rect := Rect2(node.to_global(node.polygon[0]), Vector2.ZERO)
			for point in node.polygon:
				rect = rect.expand(node.to_global(point))
			result.append(rect)
	return result


static func settle(crate: StaticBody2D, terrain: Array[Rect2], obstacles: Array[Rect2] = []) -> bool:
	var collider := crate.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var current := bounds(collider)
	if not current.has_area():
		return false
	var drop := INF
	for floor_rect in terrain:
		# Both feet must fit on a horizontal support, not a wall or a ledge edge.
		if floor_rect.size.x < floor_rect.size.y or current.position.x < floor_rect.position.x - EPSILON or current.end.x > floor_rect.end.x + EPSILON:
			continue
		var gap := floor_rect.position.y - current.end.y
		if gap >= -EPSILON and gap <= MAX_DROP:
			drop = minf(drop, maxf(gap, 0.0))
	if not is_finite(drop) or drop <= EPSILON:
		return false
	var swept := Rect2(current.position, current.size + Vector2(0, drop))
	for obstacle in terrain + obstacles:
		# Tiny inset avoids treating contact with the supporting floor as overlap.
		if swept.grow(-EPSILON).intersects(obstacle):
			return false
	crate.global_position += Vector2(0, drop)
	return true
