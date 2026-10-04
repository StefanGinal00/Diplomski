extends Node2D
## Short-lived, non-damaging release effects. Never owns combat timing/collision.
var tint := Color.WHITE
var kind := "ring"
var extent := Vector2(36, 36)
var duration := 0.4
var age := 0.0
var texture_frame := -1
var animation_frame := 2
var paint_rotation := 0.0

static func spawn(parent: Node, point: Vector2, color: Color, style := "ring", size := Vector2(36, 36), seconds := 0.4, painted_frame := -1) -> Node2D:
	if not is_instance_valid(parent) or not parent.is_inside_tree():
		return null
	if parent.is_queued_for_deletion() or (parent is CanvasItem and not parent.is_visible_in_tree()):
		return null
	var transition := parent.get_node_or_null("/root/RoomTransition")
	if transition != null and transition.is_transitioning:
		return null
	if parent.get_tree().get_nodes_in_group("boss_cosmetic_effect").size() >= 64:
		return null
	var effect := new()
	effect.texture_frame = painted_frame
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	effect.tint = color
	effect.kind = style
	effect.animation_frame = 4 if style == "impact" else 2
	effect.extent = size
	effect.duration = maxf(seconds, 0.001)
	effect.z_index = 3
	parent.add_child(effect)
	effect.global_position = point
	effect.add_to_group("boss_cosmetic_effect")
	return effect

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	var state := get_node_or_null("/root/GameState")
	if state != null:
		state.room_changed.connect(_retire)
		state.checkpoint_resting.connect(_retire)
	var transition := get_node_or_null("/root/RoomTransition")
	if transition != null:
		transition.transition_started.connect(_retire)

func _retire(_unused: String = "") -> void:
	hide()
	queue_free()

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		_retire()

func _process(delta: float) -> void:
	age += delta
	animation_frame = 4 + mini(1, int(age / duration * 2)) if kind == "impact" else preload("res://CombatFlipbook.gd").phase(age, duration)
	if age >= duration:
		_retire()
	else:
		queue_redraw()

func _draw() -> void:
	var t := clampf(age / duration, 0.0, 1.0)
	var fade := 1.0 - t
	if texture_frame >= 0:
		var size := extent * 2.0 * (0.8 + 0.2 * t)
		var rect := Rect2(-size * 0.5, size)
		if kind == "pillar":
			size = Vector2(extent.x * 2, extent.y * (0.7 + 0.3 * sin(t * PI)))
			rect = Rect2(Vector2(-size.x * 0.5, -size.y), size)
		draw_set_transform(Vector2.ZERO, paint_rotation)
		preload("res://CombatFlipbook.gd").stamp(self, texture_frame, animation_frame, rect, Color(1, 1, 1, fade), kind == "pillar")
		draw_set_transform(Vector2.ZERO)
		# Keep a thin boundary cue; do not draw legacy pillar scaffolding over art.
		if kind == "pillar":
			draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.14))
			draw_arc(Vector2.ZERO, extent.x * fade, 0, TAU, 40, Color(tint, fade * 0.4), 1, true)
			draw_set_transform(Vector2.ZERO)
		elif kind == "ring":
			draw_set_transform(Vector2.ZERO, 0, Vector2(1, extent.y / maxf(extent.x, 1)))
			draw_arc(Vector2.ZERO, extent.x * (0.25 + 0.75 * t), 0, TAU, 48, Color(tint, fade * 0.5), 1, true)
			draw_set_transform(Vector2.ZERO)
		return
	if kind == "pillar":
		# Width matches the existing damage lane; height stays within its warning.
		for i in range(5):
			var x := (i / 4.0 * 2.0 - 1.0) * extent.x * 0.83
			var height := extent.y * (0.7 + 0.3 * sin(i * 2.7)) * (1.0 - t * 0.55)
			var points := PackedVector2Array()
			var width := minf(extent.x / 6.0, 9.0) * fade
			for side in [-1.0, 1.0]:
				for step in range(17):
					var u := (step if side < 0 else 16 - step) / 16.0
					var sway := sin(u * 7 + i + t * 12) * u * 7
					points.append(Vector2(x + sway + side * width * (1 - u), -height * u))
			draw_colored_polygon(points, Color(tint, fade * 0.6))
			var core := PackedVector2Array()
			for step in range(17):
				var u := step / 16.0
				core.append(Vector2(x + sin(u * 7 + i + t * 12) * u * 7, -height * u))
			draw_polyline(core, Color(tint.lightened(0.65), fade * 0.8), 1.0, true)
		draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.14))
		draw_arc(Vector2.ZERO, extent.x, 0, TAU, 48, Color(tint, fade), 2, true)
	else:
		draw_set_transform(Vector2.ZERO, 0, Vector2(1, extent.y / maxf(extent.x, 1)))
		var radius := extent.x * (0.25 + 0.75 * t)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(tint, fade * 0.85), 1.0 + fade * 2.0, true)
		draw_arc(Vector2.ZERO, radius * 0.72, t * 3, t * 3 + PI * 1.5, 36, Color(tint, fade * 0.35), 1.0, true)
	draw_set_transform(Vector2.ZERO)
	for i in range(10):
		var direction := Vector2.RIGHT.rotated(i * TAU / 10.0)
		var point := direction * (8.0 + t * minf(extent.x, 50))
		if kind == "pillar":
			point.y -= t * extent.y * 0.65
		var tail := point - direction * (2 + fade * 6)
		if kind == "ring" and extent.y < extent.x * 0.4:
			# Grounded launch/braking dust must not spray through the floor.
			point.y = -absf(direction.y) * (2 + t * 8)
			tail.y = minf(0, point.y + 2)
		draw_line(point, tail, Color(tint, fade), 1.2, true)
