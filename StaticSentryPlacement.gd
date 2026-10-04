extends RefCounted
## Authored sentries do not have gravity. Settle their real body once, after
## generators and streamed snapshots assign positions. Stable actor paths stay.
const Floors := preload("res://CrateFloorPlacement.gd")
static var pending: Array[WeakRef] = []
static var scheduled := false

static func request(actor: StaticBody2D) -> void:
	pending.append(weakref(actor))
	if scheduled: return
	scheduled = true
	flush.call_deferred()

static func flush() -> void:
	var batch := pending
	pending = []
	scheduled = false
	var cached := {}
	for weak in batch:
		var actor := weak.get_ref() as StaticBody2D
		if actor == null or not actor.is_inside_tree() or actor.is_queued_for_deletion() or actor.is_dead: continue
		var room := Floors._room_for(actor)
		if room == null: continue
		var key := room.get_instance_id()
		if not cached.has(key): cached[key] = Floors.terrain_rects(room)
		settle(actor, cached[key])

static func settle(actor: StaticBody2D, terrain: Array[Rect2]) -> bool:
	var box := Floors.bounds(actor.get_node_or_null("CollisionShape2D"))
	if not box.has_area(): return false
	# A few authored ledges were built through the initial body. Lift that body
	# onto the ledge (never drop it through the solid), with a bounded edge fit.
	for ledge in terrain:
		if ledge.size.x <= ledge.size.y or not box.intersects(ledge): continue
		var correction := Vector2(clampf(box.get_center().x,ledge.position.x+box.size.x*0.5+1,ledge.end.x-box.size.x*0.5-1)-box.get_center().x,ledge.position.y-box.end.y)
		if correction.y >= 0 or correction.y < -40 or absf(correction.x)>24: continue
		var moved := Rect2(box.position+correction,box.size).grow(-0.05)
		var clear := true
		for solid in terrain:
			if moved.intersects(solid): clear=false; break
		if clear:
			actor.global_position += correction
			actor.set_meta("support_spawn_offset",correction)
			return true
	var drop := INF
	for floor_rect in terrain:
		if floor_rect.size.x <= floor_rect.size.y or box.position.x < floor_rect.position.x or box.end.x > floor_rect.end.x: continue
		var gap := floor_rect.position.y - box.end.y
		if gap >= -0.05 and gap <= 96: drop = minf(drop, maxf(gap, 0))
	if not is_finite(drop) or drop < 0.05: return false
	var swept := Rect2(box.position, box.size + Vector2(0, drop)).grow(-0.05)
	for solid in terrain:
		if swept.intersects(solid): return false
	actor.global_position.y += drop
	actor.set_meta("support_drop", drop)
	return true
