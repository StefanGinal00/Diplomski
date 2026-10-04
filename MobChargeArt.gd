extends RefCounted
## Shared painted anticipation; uses native countdown, never an independent clock.
static func frame(progress: float) -> int:
	return 1 if progress >= 0.5 else 0

static func stamp(canvas: Node2D, point: Vector2, world_direction: Vector2, progress: float, identity: int) -> void:
	var amount := clampf(progress, 0, 1)
	var local_direction := (canvas.to_local(canvas.global_position + world_direction) - canvas.to_local(canvas.global_position)).normalized()
	var radius := lerpf(5.0, 8.0, amount)
	# Flame cells are painted upward, the crystal/thorn cells toward the right.
	var angle := local_direction.angle() + (PI * 0.5 if identity == 13 else 0.0)
	canvas.draw_set_transform(point, angle)
	preload("res://CombatFlipbook.gd").stamp(canvas, identity, frame(amount), Rect2(-Vector2.ONE * radius, Vector2.ONE * radius * 2), Color(1, 1, 1, 0.4 + amount * 0.4))
	canvas.draw_set_transform(Vector2.ZERO)
