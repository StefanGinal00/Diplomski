extends RefCounted
## Small damped spring shared by grass/cloth, driven by ONE room manager.
## No collision objects, input hooks, per-prop callbacks or persistent state.
var bend := 0.0
var speed := 0.0
var contact_age := 100.0

static func crosses(bounds: Rect2, from: Vector2, to: Vector2) -> bool:
	var expanded := bounds.grow_individual(9,12,9,22)
	if expanded.has_point(from) or expanded.has_point(to): return true
	var corners := [expanded.position,Vector2(expanded.end.x,expanded.position.y),expanded.end,Vector2(expanded.position.x,expanded.end.y)]
	for i in 4:
		if Geometry2D.segment_intersects_segment(from,to,corners[i],corners[(i+1)%4]) != null: return true
	return false

func push(force: float) -> bool:
	var fresh := contact_age > 0.22
	contact_age = 0
	var target := clampf(force,-0.38,0.38)
	# Contact nudges the spring, rather than teleporting leaves to a pose.
	speed = clampf(speed+(target-bend)*5.5,-2.4,2.4)
	return fresh

func step(delta: float) -> bool:
	var remaining := clampf(delta,0,0.1)
	contact_age += remaining
	while remaining > 0:
		var dt := minf(remaining,1.0/120.0)
		speed += (-55.0*bend-9.0*speed)*dt
		bend = clampf(bend+speed*dt,-0.42,0.42)
		remaining -= dt
	if contact_age>0.2 and absf(bend)<0.0008 and absf(speed)<0.004:
		reset(); return false
	return true

func reset() -> void:
	bend = 0; speed = 0; contact_age = 100
