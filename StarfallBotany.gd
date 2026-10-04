extends RefCounted
## Deterministic, static 2D leaf geometry shared by city planters and outskirts.


static func leaf(canvas: CanvasItem, at: Vector2, direction: Vector2, length: float, tint: Color) -> void:
	var along := direction.normalized() * length
	var across := along.orthogonal() * 0.24
	canvas.draw_colored_polygon(PackedVector2Array([at, at + along * 0.40 + across, at + along, at + along * 0.40 - across]), tint)
	canvas.draw_line(at, at + along * 0.83, tint.darkened(0.3), 0.8, true)


static func shrub(canvas: CanvasItem, base: Vector2, height: float, variant: int, dry: bool = false) -> void:
	var bark := Color("696369") if dry else Color("786d67")
	var foliage: Color = Color("777582") if dry else [Color("69897e"), Color("7f9297"), Color("748567")][variant % 3]
	var tip := base + Vector2(-8 + variant % 4 * 4, -height)
	canvas.draw_polyline(PackedVector2Array([base, base.lerp(tip, 0.38) + Vector2(3, 0), tip]), bark, 3, true)
	for branch in range(7):
		var side := -1.0 if branch % 2 == 0 else 1.0
		var joint := base.lerp(tip, 0.2 + branch * 0.09)
		var end := joint + Vector2(side * height * (0.36 - branch * 0.025), -height * 0.22)
		canvas.draw_line(joint, end, bark, 1.5, true)
		for index in range(3 if dry else 5):
			var at := joint.lerp(end, 0.27 + index * 0.15)
			var tilt := Vector2(side * 0.7, -1.0 if index % 2 == 0 else 0.3)
			leaf(canvas, at, tilt, height * (0.13 if dry else 0.2), foliage.lightened((branch % 3) * 0.065))
		if variant % 3 == 2 and not dry:
			for petal in range(5):
				var angle := petal * TAU / 5.0
				canvas.draw_circle(end + Vector2.from_angle(angle) * 2.6, 2.0, Color("bba3bc"))
			canvas.draw_circle(end, 1.5, Color("d9c99a"))
