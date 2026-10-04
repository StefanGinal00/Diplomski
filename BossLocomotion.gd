extends RefCounted
## Shared walking acceleration; committed attack velocities remain native.
static func approach(current: float, desired: float, delta: float) -> float:
	var accelerating := current * desired >= 0 and absf(desired) > absf(current)
	return move_toward(current, desired, (220.0 if accelerating else 480.0) * delta)

static func stop_at_edge(actor: CharacterBody2D, left: float, right: float, recovery: float, global := false) -> void:
	var point := actor.global_position if global else actor.position
	point.x = clampf(point.x, left, right)
	if global: actor.global_position = point
	else: actor.position = point
	if (point.x <= left and actor.velocity.x < 0) or (point.x >= right and actor.velocity.x > 0):
		actor.velocity.x = 0
		if actor.charge_remaining > 0:
			actor.charge_remaining = 0
			actor.recovery_remaining = recovery
